# Understanding how Ansible handles apt caches

This exercise demonstrates how Ansible's apt-repository and apt modules manage the apt cache, particularly around the need for cache updates after modifying apt sources.

## Context

An ansible project I recently worked on would explicitly refresh apt caches after apt source changes through a defined handler and a flush
handlers operation. I suspected that this was unnecessary, as Ansible should handle apt cache updates automatically when using the `apt` module, but I wanted to confirm this.


## Findings

Running a sample playbook against a fresh target, we can see that Ansible will automatically update the apt cache when a new apt source is added, without needing to explicitly call `apt-get update` or use a handler. This is evident in the "Update apt cache" task, which shows that no change was needed because the cache was already updated after adding the new PPA.

```
$ make start
docker compose up -d
[+] Running 2/2
 ✔ Container apt-cache-target-1  Running                                                         0.0s
 ✔ Container apt-cache-server-1  Started                                                         0.3s

$ make ansible-playbook
docker compose exec -u ansible server ansible-playbook -i inventory.yml playbook.yml

PLAY [Example Playbook] ******************************************************************************

TASK [Gathering Facts] *******************************************************************************
ok: [target]

TASK [Add ppa:ondrej/nginx] **************************************************************************
changed: [target]

TASK [Update apt cache] ******************************************************************************
ok: [target]

TASK [Install nginx] *********************************************************************************
changed: [target]

PLAY RECAP *******************************************************************************************
target                     : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

Running the playbook again against the same target, we can see that Ansible recognizes that the apt cache is already up to date and does not attempt to update it again.

```
$ make ansible-playbook
docker compose exec -u ansible server ansible-playbook -i inventory.yml playbook.yml

PLAY [Example Playbook] ******************************************************************************

TASK [Gathering Facts] *******************************************************************************
ok: [target]

TASK [Add ppa:ondrej/nginx] **************************************************************************
ok: [target]

TASK [Update apt cache] ******************************************************************************
ok: [target]

TASK [Install nginx] *********************************************************************************
ok: [target]

PLAY RECAP *******************************************************************************************
target                     : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

We can even fake the need for a cache update by pruning the apt cache and setting its timestamp to a very old date. This simulates a stale cache, and when we run the playbook again, Ansible will update the cache as expected.

```

# Fake a stale cache
$ docker compose exec target bash -c 'rm -rf /var/lib/apt/lists/*'
$ docker compose exec target touch -d '1970-01-01 0:00:00' /var/lib/apt/lists/

$ make ansible-playbook
docker compose exec -u ansible server ansible-playbook -i inventory.yml playbook.yml

PLAY [Example Playbook] ******************************************************************************

TASK [Gathering Facts] *******************************************************************************
ok: [target]

TASK [Add ppa:ondrej/nginx] **************************************************************************
ok: [target]

TASK [Update apt cache] ******************************************************************************
changed: [target]

TASK [Install nginx] *********************************************************************************
ok: [target]

PLAY RECAP *******************************************************************************************
target                     : ok=4    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

```
