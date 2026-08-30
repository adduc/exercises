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
3. **`--security-opt seccomp=unconfined`** — even with `SYS_ADMIN`, Podman
   still failed with `crun: join keyctl ... Operation not permitted`.
   `crun` joins a new session keyring via the `keyctl` syscall, which
   Docker's default seccomp profile blocks outright. There's no cap that
   unblocks a single syscall — only a looser (or custom) seccomp profile
   does.

That's the full list. `HostConfig.Privileged` stays `false`, and the
container only has one added capability and one added device — a much
smaller blast radius than `--privileged`, which hands over roughly 40
capabilities plus full device access.

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

The two failure modes here are a useful reminder that "needs privileged"
often means "needs one specific capability plus one specific seccomp
allowance," not "needs everything." Reading the actual error
(`cannot clone` vs. `join keyctl`) pointed straight at the fix each time,
rather than reaching for `--privileged` and never finding out what was
really being blocked.
