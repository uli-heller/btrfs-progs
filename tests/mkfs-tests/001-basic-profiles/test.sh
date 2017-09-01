#!/bin/bash
# test various blockgroup profile combinations, use loop devices as block
# devices

source $TOP/tests/common

check_prereq mkfs.btrfs
check_prereq btrfs

setup_root_helper

setup_loopdevs()
{
	if [ -z "$1" ]; then
		_fail "setup_loopdevs needs a number"
	fi
	nloopdevs="$1"
	loopdev_prefix=img
	declare -a loopdevs

}

prepare_loopdevs()
{
	for i in `seq $nloopdevs`; do
		touch $loopdev_prefix$i
		chmod a+rw $loopdev_prefix$i
		truncate -s0 $loopdev_prefix$i
		truncate -s2g $loopdev_prefix$i
		loopdevs[$i]=`run_check_stdout $SUDO_HELPER losetup --find --show $loopdev_prefix$i`
	done
}

cleanup_loopdevs()
{
	for dev in ${loopdevs[@]}; do
		run_check $SUDO_HELPER losetup -d $dev
	done
	for i in `seq $nloopdevs`; do
		truncate -s0 $loopdev_prefix$i
	done
	run_check $SUDO_HELPER losetup --all
}

test_get_info()
{
	run_check $SUDO_HELPER $TOP/btrfs inspect-internal dump-super $dev1
	run_check $SUDO_HELPER $TOP/btrfs check $dev1
	run_check $SUDO_HELPER mount $dev1 $TEST_MNT
	run_check $TOP/btrfs filesystem df $TEST_MNT
	run_check $SUDO_HELPER $TOP/btrfs filesystem usage $TEST_MNT
	run_check $SUDO_HELPER $TOP/btrfs device usage $TEST_MNT
	run_check $SUDO_HELPER umount "$TEST_MNT"
}
test_do_mkfs()
{
	run_check $SUDO_HELPER $TOP/mkfs.btrfs -f	\
		$@
}

test_mkfs_single()
{
	test_do_mkfs $@ $dev1
	test_get_info
}
test_mkfs_multi()
{
	test_do_mkfs $@ ${loopdevs[@]}
	test_get_info
}

setup_loopdevs 4
prepare_loopdevs
dev1=${loopdevs[1]}

test_mkfs_single
test_mkfs_single  -d  single  -m  single
test_mkfs_single  -d  single  -m  single  --mixed
test_mkfs_single  -d  single  -m  dup
test_mkfs_single  -d  dup     -m  single
test_mkfs_single  -d  dup     -m  dup
test_mkfs_single  -d  dup     -m  dup     --mixed

test_mkfs_multi
test_mkfs_multi   -d  single  -m  single
test_mkfs_multi   -d  single  -m  single  --mixed
test_mkfs_multi   -d  raid0   -m  raid0
test_mkfs_multi   -d  raid0   -m  raid0   --mixed
test_mkfs_multi   -d  raid1   -m  raid1
test_mkfs_multi   -d  raid1   -m  raid1   --mixed
test_mkfs_multi   -d  raid10  -m  raid10
test_mkfs_multi   -d  raid10  -m  raid10  --mixed
test_mkfs_multi   -d  raid5   -m  raid5
test_mkfs_multi   -d  raid5   -m  raid5   --mixed
test_mkfs_multi   -d  raid6   -m  raid6
test_mkfs_multi   -d  raid6   -m  raid6   --mixed
test_mkfs_multi   -d  dup     -m  dup
test_mkfs_multi   -d  dup     -m  dup     --mixed

cleanup_loopdevs
