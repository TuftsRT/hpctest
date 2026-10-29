#!/bin/bash
#@ description: node basics: clock sync, user/group lookup, DNS, /tmp space, file systems respond and are writable
#@ param fs_paths =
#@ param fs_write =
#@ param tmp_min_gb = 10
#@ param clock_max_offset = 0.5
#@ ntasks: 1
#@ time: 5
#@ tags: node quick

# fs_paths: directories that must be mounted and answer within 15 s, besides $HOME.
# fs_write: directories where a 1 MB file must be writable (default: the job directory).
# A hung NFS/Lustre mount blocks forever, so every file-system probe runs under timeout.

ok() { echo "$1: ok"; }
bad() { echo "$1: FAILED ($2)"; }

# Clock: chrony is the RHEL/Rocky default; fall back to systemd's NTP flag.
if command -v chronyc >/dev/null 2>&1 && out=$(timeout 10 chronyc -n tracking 2>/dev/null); then
    leap=$(echo "$out" | awk -F': ' '/^Leap status/ {print $2}')
    offset=$(echo "$out" | awk '/^System time/ {print $4}')
    if [[ $leap != Normal ]]; then bad clock "chrony leap status '$leap', not synchronised"
    elif awk -v o="$offset" -v m="$clock_max_offset" 'BEGIN {exit !(o <= m)}'; then ok clock
    else bad clock "offset ${offset}s > ${clock_max_offset}s"; fi
elif [[ $(timedatectl show -p NTPSynchronized --value 2>/dev/null) == yes ]]; then ok clock
else bad clock "neither chronyc nor timedatectl reports NTP sync"; fi

# Identity: the job's user and its groups resolve through NSS (LDAP/sssd).
user=$(id -un)
if ! timeout 15 getent passwd "$user" >/dev/null; then bad users "getent passwd $user failed"
elif [[ $(id -Gn 2>&1) == *"cannot find name"* ]]; then bad users "id -Gn: $(id -Gn 2>&1 | head -1)"
else ok users; fi

# DNS: this node's own name resolves.
if timeout 15 getent hosts "$(hostname)" >/dev/null; then ok dns
else bad dns "getent hosts $(hostname) failed"; fi

# /tmp: enough free space for jobs that use node-local scratch.
free_gb=$(df -Pk /tmp | awk 'NR == 2 {print int($4 / 1048576)}')
if (( free_gb >= tmp_min_gb )); then ok "tmp space"
else bad "tmp space" "/tmp has ${free_gb} GB free, need ${tmp_min_gb}"; fi

fails=0
for p in "$HOME" $fs_paths; do
    if ! timeout 15 stat -t "$p" >/dev/null 2>&1 || ! timeout 15 ls "$p" >/dev/null 2>&1; then
        echo "file system $p: not mounted or not responding"; fails=$((fails + 1))
    fi
done
for p in ${fs_write:-$PWD}; do
    f=$p/.hpctest-write.$(hostname -s).$$
    if ! timeout 30 dd if=/dev/zero of="$f" bs=1M count=1 conv=fsync status=none 2>/dev/null; then
        echo "file system $p: not writable"; fails=$((fails + 1))
    fi
    rm -f "$f"
done
if (( fails == 0 )); then ok "file systems"; fi
