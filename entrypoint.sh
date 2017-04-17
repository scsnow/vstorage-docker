#!/bin/sh

VSTORAGE_USER="vstorage"
CONFIG_DIR="/etc/vstorage"
CS_PORT="12510"

MDS_IP="${MDS_SERVICE_HOST:-}"
SELF_IP="${SELF_IP:-}"
MDS_INIT="${MDS_INIT:-false}"
CLUSTER_PASSWORD="${CLUSTER_PASSWORD:-passw0rd}"
CLUSTER_NAME="${CLUSTER_NAME:-vstorage}"
VSTORAGE_DIR="${VSTORAGE_DIR:-/var/lib/vstorage}"
ULIMIT_NUM_FILES="${ULIMIT_NUM_FILES:-10240}"

vz_sysctl_enable() {
    local fname="$1"

    [ -f "$fname" ] &&
    if [ x$(cat "$fname") != x1 ]; then
        echo "1" >"$fname" && return 0
        echo "Failed to set sysctl $fname!"
        return 1
    fi
    return 0
}

make_dir() 
{
    local dir=$1
    [ -d $dir ] && return 0

    mkdir $dir && chgrp $(id -g "$VSTORAGE_USER") $dir &&
        chmod g+rwx $dir || return 1

    return 0
}

shm_init()
{
    VSTORAGE_SHM_DIR="/dev/shm/vstorage"

    make_dir "$VSTORAGE_SHM_DIR"
    make_dir "$VSTORAGE_SHM_DIR/$CLUSTER_NAME"
}

sysctl_init()
{
    vz_sysctl_enable /proc/sys/fs/fsync-enable
    vz_sysctl_enable /proc/sys/fs/odirect_enable
}

ulimit_init()
{
    [ -n "$ULIMIT_NUM_FILES" ] && ulimit -n $ULIMIT_NUM_FILES
}

uuid_gen()
{
    /usr/bin/uuidgen -r | tr '-' ' ' | awk '{print $1$2$3}' > ${CONFIG_DIR}/host_id
}

auth_node()
{
    echo $CLUSTER_PASSWORD | /usr/bin/vstorage -c $CLUSTER_NAME auth-node -b $MDS_IP -P
}

make_cs()
{
    auth_node

    #FIXME: we assume that cs has been already created if repo dir exists
    [ -d $VSTORAGE_DIR/cs ] && return 0

    /usr/bin/vstorage -c $CLUSTER_NAME make-cs -r $VSTORAGE_DIR/cs -a $SELF_IP:$CS_PORT -b $MDS_IP
}

make_mds()
{
    if [ "$MDS_INIT" = true ]; then
        #FIXME: we assume that mds has been already created if repo dir exists
        [ -d $VSTORAGE_DIR/mds ] && return 0

        echo $CLUSTER_PASSWORD | /usr/bin/vstorage -c $CLUSTER_NAME make-mds -I -a $SELF_IP -r $VSTORAGE_DIR/mds -P
    else
        auth_node

        #FIXME: we assume that mds has been already created if repo dir exists
        [ -d $VSTORAGE_DIR/mds ] && return 0

        /usr/bin/vstorage -c $CLUSTER_NAME make-mds -a $SELF_IP -r $VSTORAGE_DIR/mds -b $MDS_IP
    fi
}

start_cs()
{
    make_cs
    uuid_gen
    sysctl_init
    shm_init
    ulimit_init
    /usr/bin/csd -r $VSTORAGE_DIR/cs -u $VSTORAGE_USER
}

start_mds()
{
    make_mds
    shm_init
    ulimit_init
    /usr/bin/mdsd -r $VSTORAGE_DIR/mds -u $VSTORAGE_USER
}

case $1 in
    "mds") start_mds
    ;;
    "cs") start_cs
    ;;
    *) echo "$0 [mds|cs]"
esac
