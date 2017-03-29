#!/bin/sh

VSTORAGE_USER="vstorage"

vz_sysctl_enable() {
        local fname="$1"

        [ -f "$fname" ] &&
        if [ x$(cat "$fname" 2>/dev/null) != x1 ]; then
                echo "1" 2>/dev/null >"$fname" && return 0
                echo "Failed to fix sysctl $fname!"
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

start_cs()
{
	echo $CLUSTER_PASSWORD | /usr/bin/vstorage -c $CLUSTER_NAME auth-node -b $MDS_IP -P
	vstorage -c $CLUSTER_NAME make-cs -r $VSTORAGE_DIR -b $MDS_IP
	sysctl_init
	shm_init
	/usr/bin/csd -r $VSTORAGE_DIR -u $VSTORAGE_USER
}

start_mds()
{
	echo $CLUSTER_PASSWORD | /usr/bin/vstorage -c $CLUSTER_NAME make-mds -I -a $MDS_IP -r $VSTORAGE_DIR -P
	shm_init
	/usr/bin/mdsd -r $VSTORAGE_DIR -u $VSTORAGE_USER
}

case $1 in
        "mds") start_mds
        ;;
        "cs") start_cs
        ;;
        *) echo "$0 [mds|cs]"
esac
