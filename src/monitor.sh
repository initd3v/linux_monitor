#!/bin/bash

# Author: Martin Manegold
# Description: Server Check

function f_quit() {
    if [ "${SCRIPT_ERRORLOCK}x" == "0x" ] ; then
        /usr/bin/rmdir "${SCRIPT_LOCK}" > /dev/null 2>&1
    fi

	if [ "${CHECK_ERROR}x" != "x" ] ; then
		exit ${TMP_FALSE}
    else
        exit ${TMP_TRUE}
	fi
}

function f_out(){
    if [ "${1}x" != "x" ] ; then
        if [ -f "${SCRIPT_LOG}" ] ; then
            ${CMD_ECHO} "${1}" >> "${SCRIPT_LOG}"
        fi
        ${CMD_ECHO} -e "${1}"
    fi
}

function f_init() {

    # set script relevant variables
	SCRIPT_NAME=$( /usr/bin/realpath "$0" )
	SCRIPT_PATH=$( /usr/bin/dirname "$SCRIPT_NAME" )
	SCRIPT_LOCK="/tmp/.monitor.lck"
	SCRIPT_CONF="${SCRIPT_PATH}/monitor.conf"
	SCRIPT_ERRORLOCK=0

	# set check relevant variables
	CHECK_ERROR=""

	# set exit codes
	/usr/bin/true
	TMP_TRUE=$?
	/usr/bin/false
	TMP_FALSE=$?

	# set output format variables
	TMP_OUTPUT_COLOR_RED="\033[31m"
    TMP_OUTPUT_COLOR_GREEN="\033[32m"
    TMP_OUTPUT_COLOR_YELLOW="\033[33m"
    TMP_OUTPUT_COLOR_RESET="\033[0m"
    TMP_OUTPUT_CHECK="✓"
    TMP_OUTPUT_CROSS="✗"

	# set command binary paths
	CMD_ECHO="/bin/echo"
	CMD_AWK="/usr/bin/awk"
	CMD_WHEREIS="/usr/bin/whereis"
	CMD_DATE=$( ${CMD_WHEREIS} date | ${CMD_AWK} '{ print $2 }' )
	CMD_DATE=${CMD_DATE:-/usr/bin/date}
	CMD_MKDIR=$( ${CMD_WHEREIS} mkdir | ${CMD_AWK} '{ print $2 }' )
	CMD_MKDIR=${CMD_MKDIR:-/usr/bin/mkdir}
	CMD_DF=$( ${CMD_WHEREIS} df | ${CMD_AWK} '{ print $2 }' )
	CMD_DF=${CMD_DF:-/usr/bin/df}
	CMD_TAIL=$( ${CMD_WHEREIS} tail | ${CMD_AWK} '{ print $2 }' )
	CMD_TAIL=${CMD_TAIL:-/usr/bin/tail}
	CMD_GREP=$( ${CMD_WHEREIS} grep | ${CMD_AWK} '{ print $2 }' )
	CMD_GREP=${CMD_GREPCMD_MKDIR:-/usr/bin/grep}
	CMD_PS=$( ${CMD_WHEREIS} ps | ${CMD_AWK} '{ print $2 }' )
	CMD_PS=${CMD_PS:-/usr/bin/ps}
	CMD_PING=$( ${CMD_WHEREIS} ping | ${CMD_AWK} '{ print $2 }' )
	CMD_PING=${CMD_PING:-/usr/bin/ping}
	CMD_WC=$( ${CMD_WHEREIS} wc | ${CMD_AWK} '{ print $2 }' )
	CMD_WC=${CMD_WC:-/usr/bin/wc}
	CMD_CAT=$( ${CMD_WHEREIS} cat | ${CMD_AWK} '{ print $2 }' )
	CMD_CAT=${CMD_CAT:-/usr/bin/cat}
	CMD_ID=$( ${CMD_WHEREIS} id | ${CMD_AWK} '{ print $2 }' )
	CMD_ID=${CMD_ID:-/usr/bin/id}
	CMD_DMESG=$( ${CMD_WHEREIS} dmesg | ${CMD_AWK} '{ print $2 }' )
	CMD_DMESG=${CMD_DMESG:-/usr/bin/dmesg}
	CMD_FREE=$( ${CMD_WHEREIS} free | ${CMD_AWK} '{ print $2 }' )
	CMD_FREE=${CMD_FREE:-/usr/bin/free}
	CMD_HEAD=$( ${CMD_WHEREIS} head | ${CMD_AWK} '{ print $2 }' )
	CMD_HEAD=${CMD_HEAD:-/usr/bin/head}
	CMD_BC=$( ${CMD_WHEREIS} bc | ${CMD_AWK} '{ print $2 }' )
	CMD_BC=${CMD_BC:-/usr/bin/bc}

	for TMP in "${CMD_ECHO}" "${CMD_AWK}" "${CMD_WHEREIS}" "${CMD_DATE}" "${CMD_MKDIR}" "${CMD_DF}" "${CMD_TAIL}" "${CMD_GREP}" "${CMD_PS}" "${CMD_PING}" "${CMD_WC}" "${CMD_CAT}" "${CMD_ID}" "${CMD_DMESG}" "${CMD_FREE}" "${CMD_HEAD}" "${CMD_BC}" ; do
		if [ "${TMP}x" == "x" ] && [ -f "${TMP}" ] ; then
			TMP_NAME=(${!TMP@})
            f_out "[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The bash variable '${TMP_NAME}' with value '${TMP}' does not reference to a valid command binary path or is empty.]"
            f_quit
		fi
	done

	# include configuration
    if [ -f "${SCRIPT_CONF}" ] && [ -r "${SCRIPT_CONF}" ] ; then
        source "${SCRIPT_CONF}"
    else
        f_out "[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The default configuration file '${SCRIPT_CONF}' could not be found or is not readable by the current user.]"
        f_quit
    fi

    # check SCRIPT_BASE_PATH variable
    if [ "${SCRIPT_BASE_PATH}x" == "x" ] || [ ! -d "${SCRIPT_BASE_PATH}" ] ; then
        f_out "[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The base path variable 'SCRIPT_BASE_PATH' can not be empty and must be an existing folder. Please set it in the configuration file.]"
        f_quit
    fi

    # set log file
    if [ ! -w "${SCRIPT_BASE_PATH}" ]  ; then
        SCRIPT_LOG="/tmp/monitor.log"
    else
        SCRIPT_LOG="${SCRIPT_BASE_PATH}/monitor.log"
    fi

    ${CMD_ECHO} "[STARTING]" > "${SCRIPT_LOG}"

    # check / set script lock
    if [ -d "${SCRIPT_LOCK}" ] ; then
        SCRIPT_ERRORLOCK=1
        f_out "[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [There is already a instance of the script running due to the lock folder '${SCRIPT_LOCK}'.]"
        f_quit
    else
        ${CMD_MKDIR} "${SCRIPT_LOCK}"  > /dev/null 2>&1
        if [ $? -eq ${TMP_FALSE} ] ; then
            f_out "[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The lock folder '${SCRIPT_LOCK}' could not be created.]"
            f_quit
        fi
    fi

    # check / set filesystem limit variable CHECK_FS_LIMIT
    CHECK_FS_LIMIT=${CHECK_FS_LIMIT:=80}
	if [ "${CHECK_FS_LIMIT}x" != "x" ] ; then
        if ! [[ ${CHECK_FS_LIMIT} =~ ^[0-9]+$ ]] || ! [ ${CHECK_FS_LIMIT} -ge 0 ] || ! [ ${CHECK_FS_LIMIT} -le 100 ] ; then
            f_out "[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The variable 'CHECK_FS_LIMIT' needs to be an int value between 0 and 100 but is '${CHECK_FS_LIMIT}'.]"
            f_quit
        fi
    fi
}

function f_check_fs() {
    # check filesystem usage
    V_CHECK_FS_LIST=$( ${CMD_DF} -Thl -x tmpfs -x devtmpfs 2>/dev/null | ${CMD_AWK} '{ print $1,$3,substr($6, 1, length($6)-1),$7 }' | ${CMD_TAIL} -n +2 )

    if [ "${V_CHECK_FS_LIST}x" != "x" ] ; then
        while IFS= read -r V_LINE ; do
            V_CHECK_FS_USAGE=$( ${CMD_AWK} '{print $3}' <<< ${V_LINE} );
            if [ "${V_CHECK_FS_USAGE}x" != "x" ] && [[ ${V_CHECK_FS_USAGE} =~ ^[0-9]+$ ]] && [ ${V_CHECK_FS_USAGE} -ge 0 ] && [ ${V_CHECK_FS_USAGE} -le 100 ] ; then
                if [ ${V_CHECK_FS_USAGE} -gt ${CHECK_FS_LIMIT} ] ; then
                    V_CHECK_FS_DEVICE=$( ${CMD_AWK} '{ print $1 }' <<< ${V_LINE} )
                    V_CHECK_FS_MOUNTPOINT=$( ${CMD_AWK} '{ print $4 }' <<< ${V_LINE} )
                    V_CHECK_FS_MAXSIZE=$( ${CMD_AWK} '{ print $2 }' <<< ${V_LINE} )
                    TMP_TIME=$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )
                    CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] ['${V_CHECK_FS_USAGE}%' of disk space on device '${V_CHECK_FS_DEVICE}' with mount point '${V_CHECK_FS_MOUNTPOINT}' and a maximum size of '${V_CHECK_FS_MAXSIZE}' already used.]\n"
                fi
            else
                CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The filesystem '${V_LINE}' could not be checked as the usage '${V_CHECK_FS_USAGE}' could not be identified as a number or is empty.]\n"
            fi
        done <<< "${V_CHECK_FS_LIST}"
    fi

    # check filesystem inode usage
    V_CHECK_FS_LIST=$( ${CMD_DF} -i -Thl -x tmpfs -x devtmpfs 2>/dev/null | ${CMD_AWK} '{ if($6=="-") { inode="0%" } else { inode=$6 } ; print $1,$3,substr(inode, 1, length(inode)-1),$7 }' | ${CMD_TAIL} -n +2 )

    if [ "${V_CHECK_FS_LIST}x" != "x" ] ; then
        while IFS= read -r V_LINE ; do
            V_CHECK_FS_USAGE=$( ${CMD_AWK} '{print $3}' <<< ${V_LINE} );
            if [ "${V_CHECK_FS_USAGE}x" != "x" ] && [[ ${V_CHECK_FS_USAGE} =~ ^[0-9]+$ ]] && [ ${V_CHECK_FS_USAGE} -ge 0 ] && [ ${V_CHECK_FS_USAGE} -le 100 ] ; then
                if [ ${V_CHECK_FS_USAGE} -gt ${CHECK_FS_LIMIT} ] ; then
                    V_CHECK_FS_DEVICE=$( ${CMD_AWK} '{ print $1 }' <<< ${V_LINE} )
                    V_CHECK_FS_MOUNTPOINT=$( ${CMD_AWK} '{ print $4 }' <<< ${V_LINE} )
                    V_CHECK_FS_MAXSIZE=$( ${CMD_AWK} '{ print $2 }' <<< ${V_LINE} )
                    CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] ['${V_CHECK_FS_USAGE}%' of inode space on device '${V_CHECK_FS_DEVICE}' with mount point '${V_CHECK_FS_MOUNTPOINT}' and a maximum size of '${V_CHECK_FS_MAXSIZE}' already used.]\n"
                fi
            else
                CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The filesystem '${V_LINE}' could not be checked as the usage '${V_CHECK_FS_USAGE}' could not be identified as a number or is empty.]\n"
            fi
        done <<< "${V_CHECK_FS_LIST}"
    fi

    # check btrfs
    if [ -d "/sys/fs/btrfs/" ] ; then
        V_CHECK_FS_LIST=$( ${CMD_CAT} /sys/fs/btrfs/*/devinfo/*/missing 2>&1 | ${CMD_GREP} ${TMP_FALSE} )
        if [ "${V_CHECK_FS_LIST}x" != "x" ] ; then
            CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [There is a btrfs device missing.]\n"
        fi
    fi

    # check ext4
    if [ -d "/sys/fs/ext4/" ] ; then
        V_CHECK_FS_LIST=$( ${CMD_CAT} /sys/fs/ext4/*/errors_count 2>&1 | ${CMD_GREP} ${TMP_FALSE} )
        if [ "${V_CHECK_FS_LIST}x" != "x" ] ; then
            CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [A consistency check is needed due to a error count greater 0 on a ext4 filesystem.]\n"
        fi
    fi

    return
}

function f_check_block() {
    if [ "${CHECK_DISK_AVAIL}x" != "x" ] ; then
        for i in ${CHECK_DISK_AVAIL[@]} ; do
            if [ ! -b "/dev/block/${i}" ] && [ ! -b "${i}" ] && [ ! -b "/dev/${i}" ] ; then
                CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The disk '${i}' is missing.]\n"
            fi
        done
    fi

    return
}

function f_check_raid() {
    # check md raid
    if [ -f /proc/mdstat ] ; then
        V_CHECK_RAID=$( ${CMD_GREP} -e "[*_*]" /proc/mdstat )
        if [ "${V_CHECK_RAID}x" != "x" ] ; then
            CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [There is a md raid degraded due to a missing storage device.]\n"
        fi
    fi

    return
}

function f_check_process() {
    V_CHECK_PROCESS=$( ${CMD_PS} -eo pid,user,stat,cmd,time | ${CMD_AWK} '{ split($5,a,/:/); print $1,$2,$3,$4,a[3]*60+a[2]*3600+a[1]*86400 }' | ${CMD_AWK} '{ if(($3~"D" || $3~"Z") && $5 > 1800) print $1,$2,$4 }' )
    if [ "${V_CHECK_PROCESS}x" != "x" ] ; then
        while IFS= read -r V_LINE ; do
            CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The process with the ID '$( ${CMD_AWK} '{ print $1 }' <<< ${V_LINE} )' from user '$( ${CMD_AWK} '{ print $2 }' <<< ${V_LINE} )' and comamnd '$( ${CMD_AWK} '{ print $3 }' <<< ${V_LINE} )' is running more than 30 minutes and indicates an disk sleep or zombie state.]\n"
        done <<< "${V_CHECK_PROCESS}"
    fi

    # check defined process existence
    if [ "${CHECK_PS}x" != "x" ] ; then
        V_CHECK_PROCESS_COUNT=$( ${CMD_AWK} -F ":::" '{print NF}' <<< "${CHECK_PS}" )
        V_CHECK_PROCESS=$( ${CMD_BC} <<< "${V_CHECK_PROCESS_COUNT} % 2" )
        if [ ${V_CHECK_PROCESS} -eq 0 ] ; then
            V_CHECK_PROCESS_COUNTER=1
            while [ ${V_CHECK_PROCESS_COUNTER} -lt ${V_CHECK_PROCESS_COUNT} ]; do
                V_CHECK_PROCESS_USER=$( ${CMD_AWK} -v var=${V_CHECK_PROCESS_COUNTER} -F ":::" '{print $var}' <<< "${CHECK_PS}" )
                V_CHECK_PROCESS_CMD=$( ${CMD_AWK} -v var=${V_CHECK_PROCESS_COUNTER} -F ":::" '{print $(var+1)}' <<< "${CHECK_PS}" )
                V_CHECK_PROCESS=$( ${CMD_ID} -u "${V_CHECK_PROCESS_USER}" >/dev/null 2>&1 )
                if [ $? -eq ${TMP_TRUE} ] ; then
                    V_CHECK_PROCESS=$( ${CMD_PS} -U "${V_CHECK_PROCESS_USER}" -o pid,user,stat,cmd,time | ${CMD_GREP} -i "${V_CHECK_PROCESS_CMD}" | ${CMD_GREP} -v grep )
                    if [ "${V_CHECK_PROCESS}x" == "x" ] ; then
                       CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The process '${V_CHECK_PROCESS_CMD}' of user '${V_CHECK_PROCESS_USER}' is not running.]\n"
                    fi
                else
                    CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The user for process check '${V_CHECK_PROCESS_USER}' does not exist. Please check the configuration.]\n"
                fi
                V_CHECK_PROCESS_COUNTER=$(( V_CHECK_PROCESS_COUNTER + 2 ))
            done
        else
            CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The optional defined variable 'CHECK_PS' must consist of an equal number of elements represented by '<USER_NAME>:::<PROCESS_NAME>' for each entry. Multiple entries are also divided by ':::'.]\n"
        fi
    fi

    return
}

function f_check_service() {
    V_CHECK_INIT_SYSTEM=""
    V_CHECK_INIT_CMD=""

    f_get_init

    if [ "${V_CHECK_INIT_SYSTEM}x" != "x" ] && [ "${V_CHECK_INIT_CMD}x" != "x" ] && [ -f "${V_CHECK_INIT_CMD}" ] ; then
        case "${V_CHECK_INIT_SYSTEM}" in
            "systemd")
                V_CHECK_SERVICE=$( ${V_CHECK_INIT_CMD} list-units --state=failed | ${CMD_GREP} -i "failed" | ${CMD_AWK} '{ print $2 }' )
                if [ "${V_CHECK_SERVICE}x" != "x" ] ; then
                    for i in ${V_CHECK_SERVICE} ; do
                        CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The service '${i}' is in state 'failed'.]\n"
                    done
                fi
                ;;
            "openrc")
                V_CHECK_SERVICE=$( ${V_CHECK_INIT_CMD} | ${CMD_GREP} -i "crashed" | ${CMD_AWK} '{ print $1 }' )
                if [ "${V_CHECK_SERVICE}x" != "x" ] ; then
                    for i in ${V_CHECK_SERVICE} ; do
                        CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The service '${i}' is in state 'crashed'.]\n"
                    done
                fi
                ;;
            "sysv")
                V_CHECK_SERVICE=$( ${V_CHECK_INIT_CMD} --status-all | ${CMD_GREP} -i "- ]" | ${CMD_AWK} -F "]" '{ print $2 }' )
                if [ "${V_CHECK_SERVICE}x" != "x" ] ; then
                    for i in ${V_CHECK_SERVICE} ; do
                        CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The service '${i}' is in state 'stopped'.]\n"
                    done
                fi
                ;;
            "*")
                ;;
        esac
    fi

    return
}

function f_check_kmsg() {
    V_CHECK_KMSG=$( ${CMD_CAT} /proc/sys/kernel/dmesg_restrict )
    if ([ "${V_CHECK_KMSG}x" != "x" ] && [ ${V_CHECK_KMSG} -eq 0 ]) || [ $( ${CMD_ID} -u ) -eq 0 ] ; then
        V_CHECK_KMSG=`${CMD_DMESG} -T -l err,emerg,crit | ${CMD_GREP} "$( ${CMD_DATE} '+%a, %d. %b %Y, %H' )"`
        if [ "${V_CHECK_KMSG}x" != "x" ] ; then
            CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The following errors occured in the Linux kernel log: '${V_CHECK_KMSG}'.]\n"
        fi
    fi

    return
}

function f_check_network() {
    if [ "${CHECK_NET_AVAIL}x" != "x" ] ; then
        for i in ${CHECK_NET_AVAIL[@]} ; do
            V_CHECK_NETWORK=$( ${CMD_PING} -q -c 3 -i 0.5 "${i}" 2>/dev/null | ${CMD_GREP} -i "packet loss" | ${CMD_AWK} -F ' packet loss' '{ print $1 }' |  ${CMD_AWK} -F ', ' '{print $NF}' | ${CMD_AWK} -F '%' '{ print int($1) }' )
            if [ "${V_CHECK_NETWORK}x" != "x" ] ; then
                if [ ${V_CHECK_NETWORK} -ge 80 ] ; then
                    CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The ICMP ping of IP or DNS address '${i}' has more than 80% packet loss]\n"
                fi
            else
               CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The ICMP ping of IP or DNS address '${i}' could not be performed. If '${i}' is a DNS name please check if it can be resolved.]\n"
            fi
        done
    fi

    return
}

function f_check_memory() {
    # check memory usage
    V_CHECK_MEMORY=$( ${CMD_FREE} -m | ${CMD_TAIL} -n +2 | ${CMD_HEAD} -n 1 | ${CMD_AWK} '{ print int($3*100/$2) }' )
    if [ "${V_CHECK_MEMORY}x" != "x" ] && [ ${V_CHECK_MEMORY} -ge 95 ] ; then
        CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The memory usage is higher or equal than 95%.]\n"
    fi

    # check swap usage
    if [ "${CHECK_SWAP}" == "1" ] ; then
        V_CHECK_MEMORY=$( ${CMD_FREE} -m | ${CMD_TAIL} -n +2 | ${CMD_TAIL} -n 1 | ${CMD_AWK} '{ print int($3*100/$2) }' )
        if [ "${V_CHECK_MEMORY}x" != "x" ] && [ ${V_CHECK_MEMORY} -ge 50 ] ; then
        CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The swap usage is higher or equal than 50%.]\n"
        fi
    fi
}

function f_send_mail() {
    if [ "${MAIL_RECEIVER}x" != "x" ] ; then
        V_SEND_MAIL=$( ${CMD_AWK} -F '@' '{ print $1,$2,$3 }' <<< "${MAIL_RECEIVER}" | ${CMD_WC} -w )
        if [ ${V_SEND_MAIL} -eq 2 ] ; then
            V_SEND_MAIL_CMD=$( ${CMD_WHEREIS} mail | ${CMD_AWK} '{ print $2 }' )
            if [ "${V_SEND_MAIL_CMD}x" != "x" ] && [ -f "${V_SEND_MAIL_CMD}" ] ; then
               ${CMD_ECHO} -e "The following errors occured:\n\n${CHECK_ERROR}" | ${V_SEND_MAIL_CMD} --subject="Monitor Error - Host: ${HOSTNAME}" "${MAIL_RECEIVER}"
            else
                 CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The email could not be send as the command binary 'mail' could not be found.]\n"
            fi
        else
             CHECK_ERROR+="[${TMP_OUTPUT_CROSS}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [The email address should consist of 2 elements combined by character '@' but has '${V_SEND_MAIL}' elements.]\n"
        fi
    fi

    return
}

function f_action() {
    ACTION_RESULT=$1
    if [ "${ACTION_RESULT}x" != "x" ] && ( [ ${ACTION_RESULT} -eq ${TMP_TRUE} ] || [ ${ACTION_RESULT} -eq ${TMP_FALSE} ] ) ; then
        if [ ${ACTION_RESULT} -eq ${TMP_TRUE} ] ; then
             f_out "[${TMP_OUTPUT_CHECK}] [$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )] [Everything seems to be 'OK'.]"
        else
            f_send_mail
            f_out "${CHECK_ERROR}"
        fi
    else
        f_out "warning" "The passed action result is not a valid number of either '${TMP_TRUE}' or '${TMP_FALSE}' but is '${ACTION_RESULT}'."
    fi
}

function f_get_init() {
    V_CHECK_INIT=$( ${CMD_PS} -p 1 -o comm= )
    case "${V_CHECK_INIT}" in
        "systemd")
            V_CHECK_INIT_CMD=$( ${CMD_WHEREIS} systemctl | ${CMD_AWK} '{ print $2 }' )
            if [ "${V_CHECK_INIT_CMD}x" != "x" ] && [ -f "${V_CHECK_INIT_CMD}" ] ; then
                V_CHECK_INIT_SYSTEM="systemd"
            fi
            ;;
        "init")
            V_CHECK_INIT_CMD=$( ${CMD_WHEREIS} rc-status | ${CMD_AWK} '{ print $2 }' )
            if [ "${V_CHECK_INIT_CMD}x" != "x" ] && [ -f "${V_CHECK_INIT_CMD}" ] ; then
                V_CHECK_INIT_SYSTEM="openrc"
            else
                V_CHECK_INIT_CMD=$( ${CMD_WHEREIS} service | ${CMD_AWK} '{ print $2 }' )
                if [ "${V_CHECK_INIT_CMD}x" != "x" ] && [ -f "${V_CHECK_INIT_CMD}" ] ; then
                    V_CHECK_INIT_SYSTEM="sysv"
                fi
            fi
            ;;
        *)
            ;;
    esac

    return
}

# set version information
VERSION="1.1"

# trap signal codes
trap f_quit SIGQUIT
trap f_quit SIGINT
trap f_quit SIGHUP
trap f_quit SIGTERM
trap f_quit EXIT

case "${1}" in
    "check" | "--check" | "-c")
        # start initialization
        f_init

        # start block device availability check
        if [ "${CHECK_DISK_AVAIL[@]}x" != "x" ] ; then
            f_check_block
        fi

        # start raid check
        f_check_raid

        # start filesystem check
        f_check_fs

        # start process check
        f_check_process

        # start network check
        if [ "${CHECK_NET_AVAIL[@]}x" != "x" ] ; then
            f_check_network
        fi

        # start service check
        f_check_service

        # start kmsg check
        f_check_kmsg

        # start memory check
        f_check_memory

        # perform action
        if [ "${CHECK_ERROR}x" == "x" ] ; then
            f_action ${TMP_TRUE}
        else
            f_action ${TMP_FALSE}
        fi
        ;;
    "help" | "--help" | "-h")
        if [ -f "/usr/bin/man" ] ; then
            /usr/bin/man "./man.1"
        else
            /bin/echo -e "Please use the following parameter options:\n\tcheck | --check | -c\n\thelp | --help | -u\n\tversion | --version | -v"
        fi
        ;;
    "version" | "--version" | "-v")
        /bin/echo -e "repositorysync.sh (Version: ${VERSION})"
        ;;
    *)
       /bin/echo -e  "Please use the following parameter options:\n\tcheck | --check | -c\n\thelp | --help | -u\n\tversion | --version | -v"
        ;;
esac
