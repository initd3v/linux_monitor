#!/bin/bash

# Author: Martin Manegold
# Description: Server Check

function f_quit() {
    /usr/bin/false
	TMP_FALSE=$?
    TMP_CHILD_PIDS=$( /usr/bin/pstree -p $$ | /usr/bin/grep -oP '\(\K[^\)]+' | /usr/bin/grep -v $$ )
    if [ "${SCRIPT_ERROR}" != "errorlock" ] ; then
        /usr/bin/rmdir "${SCRIPT_LOCK}" > /dev/null 2>&1
    fi
	if [ "${TMP_CHILD_PIDS}x" != "x" ] && [ "${SCRIPT_ERROR}x" != "x" ] ; then
		for TMP_CHILD_PIDS_KILL in ${TMP_CHILD_PIDS} ; do
			/usr/bin/kill -15 ${TMP_CHILD_PIDS_KILL} > /dev/null 2>&1
		done
        sleep 2
		TMP_CHILD_PIDS=$( /usr/bin/pstree -p $$ | /usr/bin/grep -oP '\(\K[^\)]+' | /usr/bin/grep -v $$ )
		if [ "${TMP_CHILD_PIDS}x" != "x" ] && [ "${SCRIPT_ERROR}x" != "x" ] ; then
            for TMP_CHILD_PIDS_KILL in ${TMP_CHILD_PIDS} ; do
                /usr/bin/kill -9 ${TMP_CHILD_PIDS_KILL} > /dev/null 2>&1
            done
        fi
		exit ${TMP_FALSE}
    else
        exit ${TMP_TRUE}
	fi
}

function f_out(){
    # 0 = no log
    # 1 = log error
    # 2 = stdout error
    # 3 = log & stdout error
    # 4 = log warnings + error
    # 5 = stdout warning + error
    # 6 = log & stdout warning + error
    # 7 = log warning + error + info
    # 8 = stdout warning + error + info
    # 9 = log & stdout warning + error + info

    TMP_OUTPUT_COLOR_RED="\033[31m"
    TMP_OUTPUT_COLOR_GREEN="\033[32m"
    TMP_OUTPUT_COLOR_YELLOW="\033[33m"
    TMP_OUTPUT_COLOR_RESET="\033[0m"

    if [ "${CMD_ECHO}x" == "x" ] ; then
        CMD_ECHO="/bin/echo"
    fi

    if [ "${CMD_DATE}x" == "x" ] ; then
        CMD_DATE="/bin/date"
    fi

    if [ "${VERBOSITY_LEVEL}x" == "x" ] ; then
        VERBOSITY_LEVEL=2
    fi

	case $1 in
		"error")
            if [ "${CHECK_ERROR}x" != "x" ] ; then
                TMP_CLEAN_INPUT=$( ${CMD_SED} 's/\(.*\)\ |\ /\1/g' <<< ${2} )
            else
                TMP_CLEAN_INPUT=${2}
            fi
            TMP_TIME=$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )
            case "${VERBOSITY_LEVEL}" in
                "1"|"4"|"7")
                    if [ -d "${SCRIPT_BASE_PATH}" ] ; then
                        ${CMD_ECHO} "[ERRO] [${TMP_TIME}] [$TMP_CLEAN_INPUT]" >> "${SCRIPT_LOG}"
                    fi
                    if [ "${CMD_SYSTEMDCAT}" != "x" ] && [ -f ${CMD_SYSTEMDCAT} ] ; then
                        ${CMD_ECHO} "[ERRO] [${TMP_TIME}] [$TMP_CLEAN_INPUT]" | ${CMD_SYSTEMDCAT} -t Monitoring >/dev/null 2>&1
                    fi
                    ;;
                "2"|"5"|"8")
                    ${CMD_ECHO} -e "[${TMP_OUTPUT_COLOR_RED}ERRO${TMP_OUTPUT_COLOR_RESET}] [${TMP_TIME}] [$TMP_CLEAN_INPUT]"
                    ;;
                "3"|"6"|"9")
                    if [ -d "${SCRIPT_BASE_PATH}" ] ; then
                        ${CMD_ECHO} "[ERRO] [${TMP_TIME}] [$TMP_CLEAN_INPUT]" >> "${SCRIPT_LOG}"
                    fi
                    if [ "${CMD_SYSTEMDCAT}" != "x" ] && [ -f ${CMD_SYSTEMDCAT} ] ; then
                        ${CMD_ECHO} "[ERRO] [${TMP_TIME}] [$TMP_CLEAN_INPUT]" | ${CMD_SYSTEMDCAT} -t Monitoring >/dev/null 2>&1
                    fi
					${CMD_ECHO} -e "[${TMP_OUTPUT_COLOR_RED}ERRO${TMP_OUTPUT_COLOR_RESET}] [${TMP_TIME}] [$TMP_CLEAN_INPUT]"
                    ;;
                *)
                    ;;
            esac
			;;
        "warning")
            TMP_TIME=$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )
            case "${VERBOSITY_LEVEL}" in
                "4"|"7")
                    if [ -d "${SCRIPT_BASE_PATH}" ] ; then
                        ${CMD_ECHO} "[WARN] [${TMP_TIME}] [$2]" >> "${SCRIPT_LOG}"
                    fi
                    if [ "${CMD_SYSTEMDCAT}" != "x" ] && [ -f ${CMD_SYSTEMDCAT} ] ; then
                        ${CMD_ECHO} "[WARN] [${TMP_TIME}] [$2]" | ${CMD_SYSTEMDCAT} -t Monitoring >/dev/null 2>&1
                    fi
                    ;;
                "5"|"8")
					${CMD_ECHO} -e "[${TMP_OUTPUT_COLOR_YELLOW}WARN${TMP_OUTPUT_COLOR_RESET}] [${TMP_TIME}] [$2]"
                    ;;
                "6"|"9")
                    if [ -d "${SCRIPT_BASE_PATH}" ] ; then
                        ${CMD_ECHO} "[WARN] [${TMP_TIME}] [$2]" >> "${SCRIPT_LOG}"
                    fi
                    if [ "${CMD_SYSTEMDCAT}" != "x" ] && [ -f ${CMD_SYSTEMDCAT} ] ; then
                        ${CMD_ECHO} "[WARN] [${TMP_TIME}] [$2]" | ${CMD_SYSTEMDCAT} -t Monitoring >/dev/null 2>&1
                    fi
					${CMD_ECHO} -e "[${TMP_OUTPUT_COLOR_YELLOW}WARN${TMP_OUTPUT_COLOR_RESET}] [${TMP_TIME}] [$2]"
                    ;;
                *)
                    ;;
            esac
            ;;
		"message")
			TMP_TIME=$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )
            case "${VERBOSITY_LEVEL}" in
                "7")
                    if [ -d "${SCRIPT_BASE_PATH}" ] ; then
                        ${CMD_ECHO} "[INFO] [${TMP_TIME}] [$2]" >> "${SCRIPT_LOG}"
                    fi
                    if [ "${CMD_SYSTEMDCAT}" != "x" ] && [ -f ${CMD_SYSTEMDCAT} ] ; then
                        ${CMD_ECHO} "[INFO] [${TMP_TIME}] [$2]" | ${CMD_SYSTEMDCAT} -t Monitoring >/dev/null 2>&1
                    fi
                    ;;
                "8")
					${CMD_ECHO} -e "[${TMP_OUTPUT_COLOR_GREEN}INFO${TMP_OUTPUT_COLOR_RESET}] [${TMP_TIME}] [$2]"
                    ;;
                "9")
                    if [ -d "${SCRIPT_BASE_PATH}" ] ; then
                        ${CMD_ECHO} "[INFO] [${TMP_TIME}] [$2]" >> "${SCRIPT_LOG}"
                    fi
                    if [ "${CMD_SYSTEMDCAT}" != "x" ] && [ -f ${CMD_SYSTEMDCAT} ] ; then
                        ${CMD_ECHO} "[INFO] [${TMP_TIME}] [$2]" | ${CMD_SYSTEMDCAT} -t Monitoring >/dev/null 2>&1
                    fi
					${CMD_ECHO} -e "[${TMP_OUTPUT_COLOR_GREEN}INFO${TMP_OUTPUT_COLOR_RESET}] [${TMP_TIME}] [$2]"
                    ;;
                *)
                    ;;
            esac
            ;;
		*)
            TMP_TIME=$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )
            case "${VERBOSITY_LEVEL}" in
                "1"|"4"|"7")
                    if [ -d "${SCRIPT_BASE_PATH}" ] ; then
                        ${CMD_ECHO} -e "[ERRO] [${TMP_TIME}] [No valid event can be prosecessed. Possibly script error exists for subroutine call f_out().]" >> "${SCRIPT_LOG}"
                    fi
                    if [ "${CMD_SYSTEMDCAT}" != "x" ] && [ -f ${CMD_SYSTEMDCAT} ] ; then
                        ${CMD_ECHO} "[ERRO] [${TMP_TIME}] [No valid event can be prosecessed. Possibly script error exists for subroutine call f_out().]" | ${CMD_SYSTEMDCAT} -t Monitoring >/dev/null 2>&1
                    fi
                    ;;
                "2"|"5"|"8")
                    ${CMD_ECHO} -e "${TMP_OUTPUT_COLOR_YELLOW} ERRO ${TMP_OUTPUT_COLOR_RESET}] [${TMP_TIME}] [No valid event can be prosecessed. Possibly script error exists for subroutine call f_out().]"
                    ;;
                "3"|"6"|"9")
                    if [ -d "${SCRIPT_BASE_PATH}" ] ; then
                        ${CMD_ECHO} -e "[ERRO] [${TMP_TIME}] [No valid event can be prosecessed. Possibly script error exists for subroutine call f_out().]" >> "${SCRIPT_LOG}"
                    fi
                    if [ "${CMD_SYSTEMDCAT}" != "x" ] && [ -f ${CMD_SYSTEMDCAT} ] ; then
                        ${CMD_ECHO} "[ERRO] [${TMP_TIME}] [No valid event can be prosecessed. Possibly script error exists for subroutine call f_out().]" | ${CMD_SYSTEMDCAT} -t Monitoring >/dev/null 2>&1
                    fi
					${CMD_ECHO} -e "${TMP_OUTPUT_COLOR_YELLOW} ERRO ${TMP_OUTPUT_COLOR_RESET}] [${TMP_TIME}] [No valid event can be prosecessed. Possibly script error exists for subroutine call f_out().]"
                    ;;
                *)
                    ;;
            esac
			;;
	esac
}

function f_create_folder() {
    TMP_CREATE_FOLDER_PATH="${1}"

    if [ "${TMP_CREATE_FOLDER_PATH}x" != "x" ] ; then
        if [ ! -d "${TMP_CREATE_FOLDER_PATH}" ] ; then
            ${CMD_MKDIR} -p "${TMP_CREATE_FOLDER_PATH}" >/dev/null 2>&1
            if [ $? -eq ${TMP_TRUE} ] ; then
                f_out "message" "The target folder '${TMP_CREATE_FOLDER_PATH}' was successfully created."
            else
                SCRIPT_ERROR="error"
                f_out "error" "The target folder '${TMP_CREATE_FOLDER_PATH}' could not be created."
            fi
        else
            f_out "warning" "The target folder '${TMP_CREATE_FOLDER_PATH}' already exists. The creation will be skipped."
        fi
    else
        SCRIPT_ERROR="error"
        f_out "error" "The target folder '${TMP_CREATE_FOLDER_PATH}' is not defined."
    fi

    if [ "${SCRIPT_ERROR}x" != "x" ] ; then
        f_quit
    fi
}

function f_init() {

    # set script relevant variables
	SCRIPT_NAME=$( /usr/bin/realpath "$0" )
	SCRIPT_PATH=$( /usr/bin/dirname "$SCRIPT_NAME" )
	SCRIPT_LOCK="/tmp/.monitor.lck"
	SCRIPT_CONF="${SCRIPT_PATH}/monitor.conf"
	SCRIPT_ERROR=""

	# set check relevant variables
	CHECK_ERROR=""

	# set exit codes
	/usr/bin/true
	TMP_TRUE=$?
	/usr/bin/false
	TMP_FALSE=$?

	# set command binary paths
	CMD_ECHO="/bin/echo"
	CMD_AWK="/usr/bin/awk"
	CMD_WHEREIS="/usr/bin/whereis"
	CMD_DATE=$( ${CMD_WHEREIS} date | ${CMD_AWK} '{ print $2 }' )
	CMD_MKDIR=$( ${CMD_WHEREIS} mkdir | ${CMD_AWK} '{ print $2 }' )
	CMD_DF=$( ${CMD_WHEREIS} df | ${CMD_AWK} '{ print $2 }' )
	CMD_TAIL=$( ${CMD_WHEREIS} tail | ${CMD_AWK} '{ print $2 }' )
	CMD_GREP=$( ${CMD_WHEREIS} grep | ${CMD_AWK} '{ print $2 }' )
	CMD_PS=$( ${CMD_WHEREIS} ps | ${CMD_AWK} '{ print $2 }' )
	CMD_PING=$( ${CMD_WHEREIS} ping | ${CMD_AWK} '{ print $2 }' )
	CMD_WC=$( ${CMD_WHEREIS} wc | ${CMD_AWK} '{ print $2 }' )
	CMD_CAT=$( ${CMD_WHEREIS} cat | ${CMD_AWK} '{ print $2 }' )
	CMD_ID=$( ${CMD_WHEREIS} id | ${CMD_AWK} '{ print $2 }' )
	CMD_DMESG=$( ${CMD_WHEREIS} dmesg | ${CMD_AWK} '{ print $2 }' )
	CMD_FREE=$( ${CMD_WHEREIS} free | ${CMD_AWK} '{ print $2 }' )
	CMD_HEAD=$( ${CMD_WHEREIS} head | ${CMD_AWK} '{ print $2 }' )
	CMD_SED=$( ${CMD_WHEREIS} sed | ${CMD_AWK} '{ print $2 }' )
	CMD_BC=$( ${CMD_WHEREIS} bc | ${CMD_AWK} '{ print $2 }' )

	for TMP in "${CMD_ECHO}" "${CMD_AWK}" "${CMD_WHEREIS}" "${CMD_DATE}" "${CMD_MKDIR}" "${CMD_DF}" "${CMD_TAIL}" "${CMD_GREP}" "${CMD_PS}" "${CMD_PING}" "${CMD_WC}" "${CMD_CAT}" "${CMD_ID}" "${CMD_DMESG}" "${CMD_FREE}" "${CMD_HEAD}" "${CMD_SED}" "${CMD_BC}" ; do
		if [ "${TMP}x" == "x" ] && [ -f "${TMP}" ] ; then
			TMP_NAME=(${!TMP@})
			SCRIPT_ERROR="error"
            f_out "error" "The bash variable '${TMP_NAME}' with value '${TMP}' does not reference to a valid command binary path or is empty."
		fi
	done

    # include configuration
    if [ -f "${SCRIPT_CONF}" ] && [ -r "${SCRIPT_CONF}" ] ; then
        source "${SCRIPT_CONF}"
    else
        SCRIPT_ERROR="error"
        f_out "error" "The default configuration file '${SCRIPT_CONF}' could not be found or is not readable by the current user."
    fi

    # set log file
    if [ "${SCRIPT_BASE_PATH}x" != "x" ] ; then
        if [ ! -w "${SCRIPT_BASE_PATH}" ] ; then
            SCRIPT_LOG="/tmp/monitor.log"
            f_out "warning" "The defined base path '${SCRIPT_BASE_PATH}' is not writable for the current user '${USER}'. Using log path '${SCRIPT_LOG}'."
        else
            SCRIPT_LOG="${SCRIPT_BASE_PATH}/monitor.log"
        fi
    else
        SCRIPT_LOG="/tmp/monitor.log"
        SCRIPT_ERROR="error"
        f_out "error" "The base path variable 'SCRIPT_BASE_PATH' can not be empty. Please set it in the configuration file. Used log path '${SCRIPT_LOG}'."
    fi

    if [ "${SCRIPT_ERROR}x" != "x" ] ; then
		f_quit
	fi

    # initialize log
    if [ "${VERBOSITY_LEVEL}x" == "x" ] ; then
        f_out "warning" "The verbosity level variable is not set. Assuming verbosity level 6 (warnings & errors)."
        VERBOSITY_LEVEL=3
    fi

	TMP_TIME=$( ${CMD_DATE} +"%d%m%Y_%H%M%S" )
	case "${VERBOSITY_LEVEL}" in
        "4"|"7")
            if [ -d "${SCRIPT_BASE_PATH}" ] ; then
                ${CMD_ECHO} "[STARTING]" > "${SCRIPT_LOG}"
            fi
            ;;
        "5"|"8")
            f_out "message" "Starting Logging at '${TMP_TIME}' with log level '${VERBOSITY_LEVEL}'."
            ;;
        "6"|"9")
            if [ -d "${SCRIPT_BASE_PATH}" ] ; then
                ${CMD_ECHO} "[STARTING]" > "${SCRIPT_LOG}"
            fi
            f_out "message" "Starting Logging at '${TMP_TIME}' with log level '${VERBOSITY_LEVEL}'."
            ;;
        *)
            ;;
    esac

    if [ "${SCRIPT_ERROR}x" != "x" ] ; then
		f_quit
	fi

	# set script lock
	if [ -d "${SCRIPT_LOCK}" ] ; then
        SCRIPT_ERROR="errorlock"
        f_out "error" "There is already a instance of the script running due to the lock folder '${SCRIPT_LOCK}'."
    fi

    ${CMD_MKDIR} "${SCRIPT_LOCK}"  > /dev/null 2>&1
	if [ $? -eq ${TMP_TRUE} ] ; then
		f_out "message" "The lock folder '${SCRIPT_LOCK}' was successfully created to prevent multiple script execution."
	else
		SCRIPT_ERROR="error"
        f_out "error" "The lock folder '${SCRIPT_LOCK}' could not be created."
	fi

	if [ "${SCRIPT_ERROR}x" != "x" ] ; then
		f_quit
	fi

    if [ "${SCRIPT_ERROR}x" != "x" ] ; then
		f_quit
	fi

	f_out "message" "The configuration was successfully checked."
}

function f_check_fs() {
    CHECK_FS_LIMIT=${CHECK_FS_LIMIT:=80}
	if [ "${CHECK_FS_LIMIT}x" != "x" ] ; then
        if ! [[ ${CHECK_FS_LIMIT} =~ ^[0-9]+$ ]] || ! [ ${CHECK_FS_LIMIT} -ge 0 ] || ! [ ${CHECK_FS_LIMIT} -le 100 ] ; then
            f_out "error" "The variable 'CHECK_FS_LIMIT' needs to be an int value between 0 and 100 but is '${CHECK_FS_LIMIT}'."
        fi
    fi

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
                    f_out "warning" "'${V_CHECK_FS_USAGE}%' of disk space on device '${V_CHECK_FS_DEVICE}' with mount point '${V_CHECK_FS_MOUNTPOINT}' and a maximum size of '${V_CHECK_FS_MAXSIZE}' already used."
                    CHECK_ERROR+="'${V_CHECK_FS_USAGE}%' of disk space on device '${V_CHECK_FS_DEVICE}' with mount point '${V_CHECK_FS_MOUNTPOINT}' and a maximum size of '${V_CHECK_FS_MAXSIZE}' already used. | "
                fi
            else
                f_out "warning" "The filesystem '${V_LINE}' could not be checked as the usage '${V_CHECK_FS_USAGE}' could not be identified as a number or is empty."
            fi
        done <<< "${V_CHECK_FS_LIST}"
    else
        f_out "warning" "No valid filesystem could be found."
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
                    f_out "warning" "'${V_CHECK_FS_USAGE}%' of inode space on device '${V_CHECK_FS_DEVICE}' with mount point '${V_CHECK_FS_MOUNTPOINT}' and a maximum size of '${V_CHECK_FS_MAXSIZE}' already used."
                    CHECK_ERROR+="'${V_CHECK_FS_USAGE}%' of inode space on device '${V_CHECK_FS_DEVICE}' with mount point '${V_CHECK_FS_MOUNTPOINT}' and a maximum size of '${V_CHECK_FS_MAXSIZE}' already used. | "
                fi
            else
                f_out "warning" "The filesystem '${V_LINE}' could not be checked as the usage '${V_CHECK_FS_USAGE}' could not be identified as a number or is empty."
            fi
        done <<< "${V_CHECK_FS_LIST}"
    else
        f_out "warning" "No valid filesystem could be found."
    fi

    # check btrfs
    if [ -d "/sys/fs/btrfs/" ] ; then
        V_CHECK_FS_LIST=$( ${CMD_CAT} /sys/fs/btrfs/*/devinfo/*/missing 2>&1 | ${CMD_GREP} ${TMP_FALSE} )
        if [ "${V_CHECK_FS_LIST}x" != "x" ] ; then
            f_out "warning" "There is a btrfs device missing."
            CHECK_ERROR+="There is a btrfs device missing. | "
        fi
    fi

    # check ext4
    if [ -d "/sys/fs/ext4/" ] ; then
        V_CHECK_FS_LIST=$( ${CMD_CAT} /sys/fs/ext4/*/errors_count 2>&1 | ${CMD_GREP} ${TMP_FALSE} )
        if [ "${V_CHECK_FS_LIST}x" != "x" ] ; then
            f_out "warning" "A consistency check is needed due to a error count greater 0 on a ext4 filesystem."
            CHECK_ERROR+="A consistency check is needed due to a error count greater 0 on a ext4 filesystem. | "
        fi
    fi

    return
}

function f_check_block() {
    if [ "${CHECK_DISK_AVAIL}x" != "x" ] ; then
        for i in ${CHECK_DISK_AVAIL[@]} ; do
            if [ ! -b "/dev/block/${i}" ] && [ ! -b "${i}" ] && [ ! -b "/dev/${i}" ] ; then
                f_out "warning" "The disk '${i}' is missing."
                CHECK_ERROR+="The disk '${i}' is missing. | "
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
            f_out "warning" "There is a md raid degraded due to a missing storage device."
            CHECK_ERROR+="There is a md raid degraded due to a missing storage device. | "
        fi
    fi

    return
}

function f_check_process() {
    V_CHECK_PROCESS=$( ${CMD_PS} -eo pid,user,stat,times,cmd | ${CMD_AWK} '{ if(($3~"D" || $3~"Z") && $4 > 1800) print $1,$2,$5 }' )
    if [ "${V_CHECK_PROCESS}x" != "x" ] ; then
        while IFS= read -r V_LINE ; do 
            f_out "warning" "The process with the ID '$( ${CMD_AWK} '{ print $1 }' <<< ${V_LINE} )' from user '$( ${CMD_AWK} '{ print $2 }' <<< ${V_LINE} )' and comamnd '$( ${CMD_AWK} '{ print $3 }' <<< ${V_LINE} )' is running more than 30 minutes and indicates an disk sleep or zombie state."
            CHECK_ERROR+="The process with the ID '$( ${CMD_AWK} '{ print $1 }' <<< ${V_LINE} )' from user '$( ${CMD_AWK} '{ print $2 }' <<< ${V_LINE} )' and comamnd '$( ${CMD_AWK} '{ print $3 }' <<< ${V_LINE} )' is running more than 30 minutes and indicates an disk sleep or zombie state. | "
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
                    V_CHECK_PROCESS=$( ${CMD_PS} -U "${V_CHECK_PROCESS_USER}" -o pid,user,stat,times,cmd | ${CMD_GREP} -i "${V_CHECK_PROCESS_CMD}" | ${CMD_GREP} -v grep )
                    if [ "${V_CHECK_PROCESS}x" == "x" ] ; then
                       f_out "warning" "The process '${V_CHECK_PROCESS_CMD}' of user '${V_CHECK_PROCESS_USER}' is not running." 
                       CHECK_ERROR+="The process '${V_CHECK_PROCESS_CMD}' of user '${V_CHECK_PROCESS_USER}' is not running. | "
                    fi
                else
                    f_out "warning" "The user '${V_CHECK_PROCESS_USER}' does not exist. Please check the configuration."
                fi
                V_CHECK_PROCESS_COUNTER=$(( V_CHECK_PROCESS_COUNTER + 2 ))
            done
        else
            f_out "warning" "The optional defined variable 'V_CHECK_PROCESS' must consist of an equal number of elements represented by '<USER_NAME>:::<PROCESS_NAME>' for each entry. Multiple entries are also divided by ':::'."
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
                        f_out "warning" "The service '${i}' is in state 'failed'."
                        CHECK_ERROR+="The service '${i}' is in state 'failed'. | "
                    done
                fi
                ;;
            "openrc")
                V_CHECK_SERVICE=$( ${V_CHECK_INIT_CMD} | ${CMD_GREP} -i "crashed" | ${CMD_AWK} '{ print $1 }' )
                if [ "${V_CHECK_SERVICE}x" != "x" ] ; then
                    for i in ${V_CHECK_SERVICE} ; do
                        f_out "warning" "The service '${i}' is in state 'crashed'."
                        CHECK_ERROR+="The service '${i}' is in state 'crashed'. | "
                    done
                fi
                ;;
            "sysv")
                V_CHECK_SERVICE=$( ${V_CHECK_INIT_CMD} --status-all | ${CMD_GREP} -i "- ]" | ${CMD_AWK} -F "]" '{ print $2 }' )
                if [ "${V_CHECK_SERVICE}x" != "x" ] ; then
                    for i in ${V_CHECK_SERVICE} ; do
                        f_out "warning" "The service '${i}' is in state 'stopped'."
                        CHECK_ERROR+="The service '${i}' is in state 'stopped'. | "
                    done
                fi
                ;;
            "*")
                ;;
        esac
    else
        f_out "warning" "The init system could not be detected."
    fi

    return
}

function f_check_kmsg() {
    V_CHECK_KMSG=$( ${CMD_CAT} /proc/sys/kernel/dmesg_restrict )
    if ([ "${V_CHECK_KMSG}x" != "x" ] && [ ${V_CHECK_KMSG} -eq 0 ]) || [ $( ${CMD_ID} -u ) -eq 0 ] ; then
        V_CHECK_KMSG=`${CMD_DMESG} -T -l err,emerg,crit | ${CMD_GREP} "$( ${CMD_DATE} '+%a, %d. %b %Y, %H' )"`
        if [ "${V_CHECK_KMSG}x" != "x" ] ; then
            f_out "warning" "The following errors occured in the Linux kernel log: '${V_CHECK_KMSG}'. |"
            CHECK_ERROR+="The following errors occured in the Linux kernel log: '${V_CHECK_KMSG}'. | "
        fi
    else
        f_out "warning" "The kernel messages are only readable by the root user."
    fi

    return
}

function f_check_network() {
    if [ "${CHECK_NET_AVAIL}x" != "x" ] ; then
        for i in ${CHECK_NET_AVAIL[@]} ; do
            V_CHECK_NETWORK=$( ${CMD_PING} -q -c 3 -i 0.5 "${i}" 2>/dev/null | ${CMD_GREP} -i "packet loss" | ${CMD_AWK} -F ' packet loss' '{ print $1 }' |  ${CMD_AWK} -F ', ' '{print $NF}' | ${CMD_AWK} -F '%' '{ print int($1) }' )
            if [ "${V_CHECK_NETWORK}x" != "x" ] ; then
                if [ ${V_CHECK_NETWORK} -ge 80 ] ; then
                    f_out "warning" "The ICMP ping of IP or DNS address '${i}' has more than 80% packet loss."
                    CHECK_ERROR+="The ICMP ping of IP or DNS address '${i}' has more than 80% packet loss. | "
                fi
            else
                f_out "warning" "The ICMP ping of IP or DNS address '${i}' could not be performed. If '${i}' is a DNS name please check if it can be resolved."
            fi
        done  
    fi
    
    return
}

function f_check_memory() {
    # check memory usage
    V_CHECK_MEMORY=$( ${CMD_FREE} -m | ${CMD_TAIL} -n +2 | ${CMD_HEAD} -n 1 | ${CMD_AWK} '{ print int($3*100/$2) }' )
    if [ "${V_CHECK_MEMORY}x" != "x" ] && [ ${V_CHECK_MEMORY} -ge 95 ] ; then
        f_out "warning" "The memory usage is higher or equal than 95%."
        CHECK_ERROR+="The memory usage is higher or equal than 95%. | "
    fi

    # check swap usage
    V_CHECK_MEMORY=$( ${CMD_FREE} -m | ${CMD_TAIL} -n +2 | ${CMD_TAIL} -n 1 | ${CMD_AWK} '{ print int($3*100/$2) }' )
    if [ "${V_CHECK_MEMORY}x" != "x" ] && [ ${V_CHECK_MEMORY} -ge 50 ] ; then
        f_out "warning" "The swap usage is higher or equal than 50%."
        CHECK_ERROR+="The swap usage is higher or equal than 50%. | "
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
                f_out "warning" "The email could not be send as the command binary 'mail' could not be found."
            fi
        else
            f_out "warning" "The email address should consist of 2 elements combined by character '@' but has '${V_SEND_MAIL}' elements."
        fi
    fi
    
    return
}

function f_action() {
    ACTION_RESULT=$1
    if [ "${ACTION_RESULT}x" != "x" ] && ( [ ${ACTION_RESULT} -eq ${TMP_TRUE} ] || [ ${ACTION_RESULT} -eq ${TMP_FALSE} ] ) ; then
        if [ ${ACTION_RESULT} -eq ${TMP_TRUE} ] ; then
            ${CMD_ECHO} "success"
        else
            f_send_mail
            f_out "error" "${CHECK_ERROR}"
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
VERSION="1.0"

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
        ERROR="error"
        f_out "error" "Please use the following parameter options:\n\tcheck | --check | -c\n\thelp | --help | -u\n\tversion | --version | -v"
        if [ "${SCRIPT_ERROR}x" != "x" ] ; then
            f_quit
        fi
        ;;
esac
