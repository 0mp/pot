#!/bin/sh
. ../share/pot/common.sh
EXIT="return"

# common stubs
. monitor.sh

##### recognized pots
# name					running	type	level	ip			vnet
# test-pot				no		multi	1		inherit		undef
# test-pot-2			no		multi	2		10.1.2.3	yes
# test-pot-run			yes		multi	1		undef		undef
# test-pot-run-2		yes		multi	2		undef		undef
# test-pot-0			no		multi	0		inherit		undef
# test-pot-nosnap		no		multi	1		inherit		undef
# test-pot-single		no		single	0		10.1.2.3	yes
# test-pot-single-run	yes		single	0		undef		yes
# test-pot-3			?		?		?		10.1.2.3	no


_error()
{
	__monitor ERROR "$@"
	[ "$ERROR_DEBUG" = "YES" ]  && echo "_error: $*"
}

_info()
{
	__monitor INFO "$@"
	[ "$INFO_DEBUG" = "YES" ] && echo "_info: $*"
}

_debug()
{
	__monitor DEBUG "$@"
	[ "$DEBUG_DEBUG" = "YES" ] && echo "_debug: $*"
}

_is_verbose() {
	if [ $_POT_VERBOSITY -gt 1 ]; then
		return 0
	else
		return 1
	fi
}

_is_uid0()
{
	__monitor ISUID0 "$@"
	return 0 # true
}

_is_flavourdir()
{
	__monitor ISFLVDIR "$@"
	return 0 # true
}

_is_pot()
{
	__monitor ISPOT "$@"
	case "$1" in
		test-pot|test-pot-run|\
		test-pot-2|test-pot-run-2|\
		test-pot-0|test-pot-nosnap|\
		test-pot-single|test-pot-single-run|\
		${POT_DNS_NAME})
			return 0 # true
			;;
	esac
	return 1 # false
}

_is_pot_running()
{
	__monitor ISPOTRUN "$@"
	case "$1" in
		test-pot-run|test-pot-run-2|\
		test-pot-single-run)
			return 0 # true
			;;
	esac
	return 1 # false
}

_is_base()
{
	__monitor ISBASE "$@"
	case "$1" in
		test-base|11.1)
			return 0 # true
			;;
	esac
	return 1 # false
}

_is_flavour()
{
	case $1 in
		default|flap|flap2)
			return 0 # true
			;;
	esac
	return 1 # false
}

_get_conf_var()
{
	__monitor GETCONFVAR "$@"
	case "$2" in
	"pot.level")
		case "$1" in
		test-pot|test-pot-run|\
		test-pot-nosnap)
			echo "1"
			;;
		test-pot-2|test-pot-run-2)
			echo "2"
			;;
		test-pot-0|test-pot-single|test-pot-single-run)
			echo "0"
			;;
		esac
		;;
	"pot.potbase")
		case "$1" in
		test-pot-2)
			echo "test-pot"
			;;
		test-pot-run-2)
			echo "test-pot-run"
			;;
		esac
		;;
	"ip4")
		case $1 in
		test-pot|test-pot-0)
			echo "inherit"
			;;
		test-pot-2|test-pot-3|\
		test-pot-single)
			echo "10.1.2.3"
			;;
		esac
		;;
	"pot.type")
		case $1 in
		test-pot|test-pot-0|\
		test-pot-run|test-pot-nosnap|\
		test-pot-2|test-pot-run-2)
			echo "multi"
			;;
		test-pot-single|test-pot-single-run)
			echo "single"
		esac
		;;
	"vnet")
		case $1 in
		test-pot-2|test-pot-single|test-pot-single-run)
			echo "true"
			;;
		test-pot-3)
			echo "false"
			;;
		esac
		;;
	esac
}

_get_pot_base()
{
	__monitor GETPOTBASE "$@"
	case "$1" in
		test-pot|test-pot-run|\
		test-pot-2|test-pot-run-2|\
		test-pot-single|test-pot-single-run)
			echo "11.1"
			;;
	esac
}

_zfs_exist()
{
	__monitor ZFSEXIST "$@"
	case "$1" in
		/fscomp/test-fscomp)
			return 0 # true
			;;
	esac
	return 1 # false
}

_pot_zfs_snap()
{
	__monitor POTZFSSNAP "$@"
}

_pot_zfs_snap_full()
{
	__monitor POTZFSSNAPFULL "$@"
}

_fscomp_zfs_snap()
{
	__monitor FSCOMPZFSSNAP "$@"
}

common_setUp()
{
	_POT_VERBOSITY=1
	POT_DNS_NAME=dns
	ERROR_CALLS=0
	INFO_CALLS=0
	DEBUG_CALLS=0
	ISUID0_CALLS=0
	ISPOT_CALLS=0
	ISPOTRUN_CALLS=0
	ISBASE_CALLS=0
	GETCONFVAR_CALLS=0
	GETPOTBASE_CALLS=0
	ZFSEXIST_CALLS=0
	POTZFSSNAP_CALLS=0
	POTZFSSNAPFULL_CALLS=0
	FSCOMPZFSSNAP_CALLS=0
}

