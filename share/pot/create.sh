#!/bin/sh

create-help()
{
	echo "pot create [-hv] -p potname -b base [-i ipaddr] [-l lvl] [-f flavour]"
	echo '  -h print this help'
	echo '  -v verbose'
	echo '  -p potname : the pot name (mandatory)'
	echo '  -b base : the base pot (mandatory)'
	echo '  -i ipaddr : an ip address'
	echo '  -l lvl : pot level'
	echo '  -f flavour : flavour to be used'
}

# $1 pot name
# $2 base name
# $3 level
_cj_zfs()
{
	local _pname _base _jdset _snap
	_pname=$1
	_base=$2
	_lvl=$3
	_jdset=${POT_ZFS_ROOT}/jails/$_pname
	# Create the main jail zfs dataset
	if ! _zfs_is_dataset $_jdset ; then
		zfs create $_jdset
	else
		_info "$_jdset exists already"
	fi
	# Create the root mountpoint
	if [ ! -d "${POT_FS_ROOT}/jails/$_pname/m" ]; then
		mkdir -p ${POT_FS_ROOT}/jails/$_pname/m
	fi
	# lvl 0 images mount directly usr.local and custom
	if [ $_lvl -eq 0 ]; then
		return 0 # true
	fi
	# Clone the usr.local dataset
	if ! _zfs_is_dataset $_jdset/usr.local ; then
		_snap=$(_zfs_last_snap ${POT_ZFS_ROOT}/bases/$_base/usr.local)
		if [ -n "$_snap" ]; then
			_debug "Clone zfs snapshot ${POT_ZFS_ROOT}/bases/$_base/usr.local@$_snap"
			zfs clone -o mountpoint=${POT_FS_ROOT}/jails/$_pname/usr.local ${POT_ZFS_ROOT}/bases/$_base/usr.local@$_snap $_jdset/usr.local
		else
			_error "no snapshot found for ${POT_ZFS_ROOT}/bases/$_base/usr.local"
			return 1 # false
		fi
	else
		_info "$_jdset/usr.local exists already"
	fi
	# Clone the custom dataset
	if ! _zfs_is_dataset $_jdset/custom ; then
		_snap=$(_zfs_last_snap ${POT_ZFS_ROOT}/bases/$_base/custom)
		if [ -n "$_snap" ]; then
			_debug "Clone zfs snapshot ${POT_ZFS_ROOT}/bases/$_base/custom@$_snap"
			zfs clone -o mountpoint=${POT_FS_ROOT}/jails/$_pname/custom ${POT_ZFS_ROOT}/bases/$_base/custom@$_snap $_jdset/custom
		else
			_error "no snapshot found for ${POT_ZFS_ROOT}/bases/$_base/custom"
			return 1 # false
		fi
	else
		_info "$_jdset/custom exists already"
	fi
	return 0 # true
}

# $1 pot name
# $2 base name
# $3 ip
# $4 level
_cj_conf()
{
	local _pname _base _ip _lvl _jdir _bdir
	_pname=$1
	_base=$2
	_ip=$3
	_lvl=$4
	_jdir=${POT_FS_ROOT}/jails/$_pname
	_bdir=${POT_FS_ROOT}/bases/$_base
	if [ ! -d $_jdir/conf ]; then
		mkdir -p $_jdir/conf
	fi
	(
		if [ $_lvl -eq 0 ]; then
			echo "$_bdir ${_jdir}/m"
			echo "$_bdir/usr/local ${_jdir}/m/usr/local"
			echo "$_bdir/opt/custom ${_jdir}/m/opt/custom"
		else
			echo "$_bdir ${_jdir}/m ro"
			echo "$_jdir/usr.local ${_jdir}/m/usr/local"
			echo "$_jdir/custom ${_jdir}/m/opt/custom"
		fi
	) > $_jdir/conf/fs.conf
	(
		echo "${_pname} {"
		echo "  host.hostname = \"${_pname}.$( hostname )\";"
		echo "  path = ${_jdir}/m ;"
		echo "  osrelease = \"${_base}-RELEASE\";"
		echo "  mount.devfs;"
		echo "  allow.set_hostname;"
		echo "  allow.mount;"
		echo "  allow.mount.fdescfs;"
		echo "  allow.raw_sockets;"
		echo "  allow.socket_af;"
		echo "  allow.sysvipc;"
		echo "  exec.start = \"sh /etc/rc\";"
		echo "  exec.stop = \"sh /etc/rc.shutdown\";"
		echo "  persist;"
		if [ "$_ip" = "inherit" ]; then
			echo "  ip4 = inherit;"
		else
			echo "  interface = lo1;"
			echo "  ip4.addr = ${_ipaddr};"
		fi
		echo "}"
	) > $_jdir/conf/jail.conf
}

# $1 pot name
# $2 flavour name
_cj_flv()
{
	local _pname _flv
	_pname=$1
	_flv=$2
	while read -r line ; do
		pot-cmd $line -p $_pname
	done < ${_POT_FLAVOUR_DIR}/${_flv}
	if [ -r ${_POT_FLAVOUR_DIR}/${_flv}-shell ]; then
		# pot start
		# copy it
		# execute it in the jail
	else
		_debug "No shell script available for the flavour $_flv"
	fi
}

pot-create()
{
	local _pname _ipaddr _lvl _base _flv
	_pname=
	_base=
	_ipaddr=inherit
	_lvl=1
	_flv=
	args=$(getopt hvp:i:l:b:f: $*)
	if [ $? -ne 0 ]; then
		create-help
		exit 1
	fi
	set -- $args
	while true; do
		case "$1" in
		-h)
			create-help
			exit 0
			;;
		-v)
			_POT_VERBOSITY=$(( _POT_VERBOSITY + 1))
			shift
			;;
		-p)
			_pname=$2
			shift 2
			;;
		-i)
			_ipaddr=$2
			shift 2
			;;
		-l)
			_lvl=$2
			shift 2
			;;
		-b)
			_base=$2
			# TODO: parameter validtion
			shift 2
			;;
		-f)
			if [ -z "${_POT_FLAVOUR_DIR}" -o ! -d "${_POT_FLAVOUR_DIR}" ]; then
				_error "The flavour dir is missing"
				exit 1
			fi
			if [ -r "${_POT_FLAVOUR_DIR}/$2" ]; then
				_flv=$2
			else
				_error "The flavour $2 not found"
				_debug "Looking in the flavour dir ${_POT_FLAVOUR_DIR}"
				exit 1
			fi
			shift 2
			;;
		--)
			shift
			break
			;;
		esac
	done

	if [ -z "$_pname" ]; then
		_error "pot name is missing"
		create-help
		exit 1
	fi
	if ! _cj_zfs $_pname $_base $_lvl ; then
		exit 1
	fi
	if ! _cj_conf $_pname $_base $_ipaddr $_lvl ; then
		exit 1
	fi
	if [ -n "$_flv" ]; then
		_cj_flv $_pname $_flv
	fi
}