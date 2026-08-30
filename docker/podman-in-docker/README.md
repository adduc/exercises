# Running Podman inside Docker, without `--privileged`

This exercise nests a container runtime inside a container: a Docker
container running `quay.io/podman/stable`, from which Podman starts its own
container, and the whole thing runs without Docker's `--privileged` flag.

## Context

`--privileged` is the reflexive answer to "container-in-a-container won't
start," but it grants everything: every capability, a disabled seccomp
filter, a disabled AppArmor/SELinux profile, and access to every host
device. I wanted to find the narrower set of grants that Podman actually
needs, so the outer container stays as close to Docker's default sandbox as
possible.

## What's actually required

Starting from a completely default (non-privileged) container and adding
grants one at a time, in the order the failures appeared:

1. **`--device /dev/fuse`** — Podman's storage driver needs FUSE
   (`fuse-overlayfs`) to build an overlay filesystem without real root on
   the host.
2. **`--cap-add SYS_ADMIN`** — without it, Podman's `crun` fails immediately
   with `cannot clone: Operation not permitted`. Docker's default seccomp
   profile only allows the `clone`/`unshare` syscalls to pass the combined
   namespace flags a container runtime needs (mount, PID, UTS, IPC, net
   namespaces together) when the caller already holds `CAP_SYS_ADMIN`.
3. **A custom seccomp profile allowing `keyctl` and `pivot_root`** — even
   with `SYS_ADMIN`, Podman still failed, first with
   `crun: join keyctl ... Operation not permitted`, then (once `keyctl` was
   allowed) with `crun: pivot_root: Operation not permitted`. Neither
   syscall appears anywhere in Docker's default seccomp profile
   (`moby/profiles/seccomp/default.json`), for any capability set — a
   normal container never needs to call them, since it's `containerd`/`runc`
   outside the container that does the equivalent setup before the
   sandboxed process even starts. Here, though, `crun` *is* the sandboxed
   process, doing that setup for its own nested container, so it needs
   these itself.

   The initial version of this exercise reached for
   `--security-opt seccomp=unconfined` here, which works but throws away
   the entire syscall filter — every syscall becomes permitted, not just
   these two. [`seccomp-podman.json`](seccomp-podman.json) is Docker's
   default profile with one rule appended, in the same shape as the
   existing `mount`/`unshare`/`setns` rule it already ships: `keyctl` and
   `pivot_root` are allowed only for containers that also hold
   `CAP_SYS_ADMIN`. Everything else Docker's default profile blocks stays
   blocked. Use it with `--security-opt seccomp=./seccomp-podman.json`
   (paths are resolved relative to the Compose project directory).

That's the full list. `HostConfig.Privileged` stays `false`, the container
has one added capability and one added device, and the seccomp filter is
Docker's default plus a two-syscall exception scoped to the same capability
— a much smaller blast radius than `--privileged`, which hands over roughly
40 capabilities, full device access, and drops the syscall filter entirely.

## Risk of the added `keyctl`/`pivot_root` rule

The two syscalls in that rule aren't equally risky. `pivot_root` adds
little on its own: it only rearranges which mounts a process's own mount
namespace can see, and this container already has `mount`/`unshare`/`clone`
via the same `CAP_SYS_ADMIN` gate, so it doesn't cross any boundary that
wasn't already crossable.

`keyctl` is different, and worth calling out on its own. It's a single
syscall multiplexing dozens of subcommands into the kernel's key-management
subsystem, and Docker's default profile excludes it — with no capability
able to unlock it — specifically because that class of syscall (rich
subcommand surface, less-audited kernel code) has a track record of
kernel memory-safety bugs. The canonical example is
[CVE-2016-0728](https://nvd.nist.gov/vuln/detail/CVE-2016-0728), a refcount
overflow in the keyring code that let a local process corrupt kernel memory
and take over kernel execution. That CVE is long patched and isn't a live
threat to a current kernel; it's cited here as the shape of risk this rule
reopens, not a claim that this exercise is exploitable today.

The reason that shape of risk matters more than it might for other
capability grants: a kernel exploit doesn't run "inside the container" in
any meaningful sense. Namespaces, capabilities, and seccomp are all
enforced by the one kernel every container shares, so hijacking kernel
execution has no container boundary left to cross — it's already
equivalent to code execution on the host. And on this host specifically,
`docker info --format '{{.SecurityOptions}}'` shows no `userns` entry, so
there isn't even a UID-remapping layer between this container's root and
the host's: root here already is host root. The custom profile is still
the right trade against `seccomp=unconfined` — it's the *only* extra
syscall surface taken on, instead of every syscall Docker's default
profile would otherwise block — but it's a trade, not a free lunch, and
it's one this exercise accepts because there's no way to run nested Podman
without `crun` calling `keyctl`.

One thing I expected to need but didn't: `--security-opt label=disable`.
This host runs Fedora with SELinux enforcing, and I assumed the container
policy (`container_t`) would block Podman's mount and keyring operations
the way it blocks so much else — but it didn't come up. Worth re-checking
first if you hit `Permission denied` (as opposed to `Operation not
permitted`) errors on a different SELinux policy or distro; that's the
signature of an SELinux denial rather than a seccomp one, and
`ausearch -m avc -ts recent` will confirm it.

## Rootless vs. rootful

Note what this setup is *not*: fully rootless, nested Podman. The
`quay.io/podman/stable` image runs as `root` by default, so
`podman info --format '{{.Host.Security.Rootless}}'` reports `false`
inside the container — Podman is creating a normal (rootful) container,
not a user-namespace-remapped rootless one. Rootless-in-rootless nesting is
a separate, harder problem (subuid/subgid ranges, nested user namespaces,
`slirp4netns`/`pasta` for networking) that this exercise doesn't attempt.
"Not privileged" and "rootless" are independent properties — this
demonstrates the former.

## Usage

```
make up     # start the outer (non-privileged) Docker container
make demo   # have Podman, inside that container, run its own container
make shell  # open a shell in the outer container to poke around
make down   # tear everything down
```

## Thoughts

The failure modes here are a useful reminder that "needs privileged"
often means "needs one specific capability plus a couple of specific
syscalls," not "needs everything." Reading each error (`cannot clone`,
`join keyctl`, `pivot_root`) pointed straight at the fix, rather than
reaching for `--privileged` — or its seccomp-only equivalent,
`seccomp=unconfined` — and never finding out what was actually being
blocked. `seccomp=unconfined` is worth calling out specifically: unlike
`--cap-add`, which only ever grants what you name, it doesn't add an
exception — it removes the entire filter, which is exactly as permissive
as `--privileged` on that one axis even though capabilities and devices
stay locked down. A profile with two syscalls added back keeps the
"narrower than privileged" claim true in every dimension, not just two out
of three.
