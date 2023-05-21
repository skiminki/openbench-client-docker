#!/bin/bash
#
# Docker image for OpenBench client
# Copyright (C) 2022-2023  Sami Kiminki
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

set -e

export HOME="/openbench"

source /openbench-client-functions.bash

# determine default action based on whether /config.sh is mounted
if [ -f /config.sh ]
then
    CMD="start"
else
    CMD="help"
fi

if [ $# -ge 1 ]
then
    case "$1" in
	"bash")      CMD="bash"      ; shift ;;
	"bench-all") CMD="bench-all" ; shift ;;
	"status")    CMD="status"    ; shift ;;
	"start")     CMD="start"     ; shift ;;
	"stop")      CMD="stop"      ; shift ;;
	"scripts")   CMD="scripts"   ; shift ;;
    esac
fi

# options
DO_WAIT=
DO_DRY_RUN=
while [ $# -gt 0 ]
do
    case "$1" in
	--dry-run)    DO_DRY_RUN=1   ; shift ;;
	--wait)       DO_WAIT=1      ; shift ;;
	*)            CMD="help"     ; shift ;;
    esac
done

# action
case "${CMD}" in

    "start")
	# already running?
	set_worker_pid
	if [ "${WORKER_PID}" ]
	then
	    echo "Client is already launched!"
	    exit 3
	fi
	configure_openbench_client
	rm -f "$WORKER_EXIT_FILE"
	launch_openbench_client
	;;

    "stop")
	set_worker_pid

	if [ "${WORKER_PID}" ]
	then
	    echo "Signaling client to stop after the current batch"
	    touch "$WORKER_EXIT_FILE"
	    if [ "${DO_WAIT}" = "1" ]
	    then
		echo "Waiting for client to stop... (PID=${WORKER_PID})"
		tail --pid="${WORKER_PID}" -f /dev/null
	    fi
	else
	    echo "Client not launched"
	fi
	;;

    "help")
	print_help
	;;

    "scripts")
	print_scripts_extract
	;;

    "status")
	print_status_info
	;;

    "bash")
	cd /openbench
	exec bash
	;;

    "bench-all")
	configure_openbench_client
	update_openbench_bench_repos
	launch_openbench_bench_all
	;;

esac
