#!/bin/sh
TEMP=`getopt -o a:hpfdOL -n "$0" -- "$@"`

unset DRY_RUN

if [ $? != 0 ] ; then
	echo "getopt error - terminating..." >&2;
	exit 1;
fi

eval set -- "$TEMP"

while true; do
	case "$1" in
		-h )
			echo "Usage: $0 -a <buildroot_arch> [-pfd]"
			echo "          -a zynq | x86_64 | i686"
			echo "          -p omit patching buildroot (if already done)"
			echo "          -f force rerun (if already done)"
			echo "          -L just update linux configuration"
			echo "          -d dry-run"
			echo "          -O out-of-tree build (not too useful, though)"
			exit 0
		;;
		-p )
			NOPATCH="y";
			shift
		;;
		-f )
			FORCE="y";
			shift
		;;
		-d )
			DRY_RUN="--dry-run";
			shift
		;;
		-a )
			case "$2" in
				"zynq" | "i686" | "x86_64")
					ARCH="$2"
				;;
				*)
					echo "Unsupported arch/config '$2'" ;
					exit 1
				;;
			esac
			shift 2
		;;
		-O )
			OOF_TREE="y"
			shift
		;;
		-L )
			LCONF="y"
			shift
		;;
		--) shift; break
		;;
		*) echo "Invalid option $1" >&2; exit 1
		;;
	esac
done

get_makevar() {
        make ${MKOUTDIR} printvars VARS=${1} | awk 'BEGIN{ FS="[ =]" }/'"${1}"'/{print $2}'
}

restore() {
	rm ${CONF_DIR}/.config ${CONF_DIR}/.config.orig
	if [ -f ${CONF_DIR}/.config.bup ] ; then
		mv ${CONF_DIR}/.config.bup ${CONF_DIR}/.config
	fi
	if [ -f ${CONF_DIR}/.config.old.bup ] ; then
		mv ${CONF_DIR}/.config.old.bup ${CONF_DIR}/.config.old
	fi
	if [ -f ${CONF_DIR}/linux-${LINUX_VER}.config.bup ] ; then
		mv ${CONF_DIR}/linux-${LINUX_VER}.config.bup ${CONF_DIR}/linux-${LINUX_VER}.config
	fi
}

install_linux_conf() {
	if [ -f ${CONF_DIR}/linux-${LINUX_VER}.config ] ; then
		mv ${CONF_DIR}/linux-${LINUX_VER}.config ${CONF_DIR}/linux-${LINUX_VER}.config.bup
	fi
	if [ -f site/config/linux-${LINUX_VER}-common.config -a -f site/config/linux-${LINUX_VER}-${KARCH}.config ] ; then
		cat site/config/linux-${LINUX_VER}-common.config site/config/linux-${LINUX_VER}-${KARCH}.config  > ${CONF_DIR}/linux-${LINUX_VER}.config
		cp ${CONF_DIR}/linux-${LINUX_VER}.config ${CONF_DIR}/linux-${LINUX_VER}.config.orig
		if [ -f ${CONF_DIR}/output/build/linux-${LINUX_VER}/.config ] ; then
			cp -b ${CONF_DIR}/output/build/linux-${LINUX_VER}/.config ${CONF_DIR}/output/build/linux-${LINUX_VER}/.config.bup
			rm -f ${CONF_DIR}/output/build/linux-${LINUX_VER}/.stamp_configured
		fi
		rm -f 
	else
		echo "Error: linux config snippets for linux-${LINUX_VER} not found" >&2
		if [ -z "${LCONF}" ] ; then
			restore;
		fi
		exit 1
	fi
}

if [ -z "${OOF_TREE}" -a -f ./.stamp_br_installconf ] ; then
	BR_ARCH_VARIANT=`cat ./.stamp_br_installconf`
	if [ -z "${ARCH}" ] ; then
		ARCH="${BR_ARCH_VARIANT}"
	else if [ -n "${BR_ARCH_VARIANT}" -a "${ARCH}" != "${BR_ARCH_VARIANT}" ] ; then
			echo "Error: arch '${ARCH}' requested but already configured for '${BR_ARCH_VARIANT}'"
			exit 1;
		fi
	fi
fi
if [ -z "$ARCH" ] ; then
	echo "Error: No target architecture given" >&2
	echo "Usage: $0 -a <zynq | i686 | x86_64>" >&2
	exit 1;
fi

case "${ARCH}" in
	"i686" | "x86_64") KARCH="x86"      ;;
	*)                 KARCH="${ARCH}"  ;;
esac

##NOTE the buildroot out-of-tree feature is not
##     really useful since it still duplicates
##     source extraction in each output directory
if [ "y" = "${OOF_TREE}" ] ; then
	CONF_DIR=output-${ARCH}
	MKOUTDIR="O=${CONF_DIR}"
	SP=" "
	if [ ! -d ${CONF_DIR} ] ; then
		mkdir ${CONF_DIR}
	fi
else
	SP=""
	CONF_DIR=.
fi

if [ "$LCONF"x != "yx" ] ; then

	if [ -f ${CONF_DIR}/.stamp_br_installconf ] ; then
		if [ -z "$FORCE" ] ; then
			echo "Error: $0 was already executed (use -f to force, -fp to avoid repatching)!" >&2
			exit 1;
		fi
		rm ${CONF_DIR}/.stamp_br_installconf
		if [ -z "$NOPATCH" ] ; then
			rm .stamp_br_patched
		fi
	fi

	if [ -f .stamp_br_patched -o "$NOPATCH" = "y" ] ; then
		if [ "$NOPATCH" = "y" ] ; then
			touch .stamp_br_patched
		fi
	else
		if cat site/br-patches/buildroot* | patch ${DRY_RUN} --posix --verbose -p0 -b ; then
			if [ -z "${DRY_RUN}" ] ; then
				touch .stamp_br_patched
			fi
		fi
	fi
fi

BR_VER=`make print-version`
if [ $? != 0 ]; then
	echo "Error: unable to determine buildroot version" >&2
	exit 1
fi

if [ "$LCONF"x != "yx" ] ; then

	if [ -f ${CONF_DIR}/.config ] ; then
		mv ${CONF_DIR}/.config ${CONF_DIR}/.config.bup
	fi
	echo "cat site/config/br-${BR_VER}-${ARCH}.config site/config/br-${BR_VER}-common.config > ${CONF_DIR}/.config"
	cat site/config/br-${BR_VER}-${ARCH}.config site/config/br-${BR_VER}-common.config > ${CONF_DIR}/.config
	if [ $? != 0 ] ; then
		echo "Error: unable to install .config file" >&2
		restore
		exit 1
	fi
	cp ${CONF_DIR}/.config ${CONF_DIR}/.config.orig
	if [ -f ${CONF_DIR}/.config.old ] ; then
		cp ${CONF_DIR}/.config.old ${CONF_DIR}/.config.old.bup
	fi

	make ${MKOUTDIR} olddefconfig

fi

LINUX_VER=`get_makevar LINUX_VERSION`

if [ $? != 0 -o -z "${LINUX_VER}" ]; then
	echo "Error: unable to determine linux version" >&2
	restore;
	exit 1
fi

if [ -d site/pkg-patches/linux/${LINUX_VER} ] ; then
	true
else
	echo "Error: no linux kernel patches for ${LINUX_VER} found!?!" >&2
	echo "(Must have at least a directory for them)" >&2
	restore;
	exit 1
fi

echo "BR version $BR_VER"
echo "LI version '$LINUX_VER'"
echo "ARCH ${ARCH}"
echo "KARCH ${KARCH}"

if [ -n "${DRY_RUN}" ] ; then
	restore;
	exit 0
fi

install_linux_conf;

if [ "$LCONF"x != "yx" ] ; then
	echo "${ARCH}" > ${CONF_DIR}/.stamp_br_installconf

	echo "Now type 'make${SP}${MKOUTDIR}' to build"
fi
