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

WORKER_EXIT_FILE="/openbench/OpenBench/Client/openbench.exit"
WORKER_SHELL_PIDFILE="/tmp/worker-shell.pid"

print_help ()
{
    echo "Usage: [<command>] [options]

The usual commands:
  start        Start the OpenBench worker client. To only test the container,
               add --dry-run.
  stop         Signal the OpenBench worker to stop after the current batch.
               To wait until the worker exits, add --wait.

Other useful commands:
  help         This help.
  status       Check the client status.
  scripts      Output a command that extracts start/stop/check scripts and
               a template for the config file.
  bash         Start a shell. Useful for debugging.

Note: If /config.sh is mounted for the container, the default command is
'start'. Otherwise, the default command is 'help'.

Options:
  --dry-run    Do everything else except actually launching the client.
  --wait       Wait until the operation completes.

Container mounts:
  /config.sh   Configuration file for the container. The script is expected
               to set the following shell variables:

               USERNAME    User name for OpenBench                  (mandatory)
               PASSWORD    Password for OpenBench                   (mandatory)
               THREADS     Number of threads          (autodetected if omitted)
               EXTRA_OPTS  Extra client options                      (optional)

  /syzygy/     Directory for the Syzygy endgame tablebases           (optional)
"
}

print_scripts_extract ()
{
    cd /scripts/
    echo "# Command to extract front-end scripts for container management:"
    echo "echo \"$(tar cf - -C /scripts/ . | gzip -9 | base64 -w 0)\" | base64 -d | tar xfz - #"
}

configure_openbench_client ()
{
    if [ \! -f /config.sh ]
    then
	echo
	echo "Error: File /config.sh not mounted"
	echo
	exit 1
    fi

    # convert config.sh to Unix newlines before sourcing
    TMPFILE="$(mktemp)"
    sed -e 's/\r$//' /config.sh >"${TMPFILE}"
    source "${TMPFILE}"
    rm -- "${TMPFILE}"

    if [    "${USERNAME:-<unset>}" = "<unset>" \
	 -o "${PASSWORD:-<unset>}" = "<unset>" ]
    then
	echo "USERNAME and PASSWORD must be set when launching the openbench container"
	exit 2
    fi

    if [ -z "${THREADS}" ]
    then
	echo "Detecting concurrency..."
	# print CPU information -- remove couple spaces for pretty printing
	printf -- "- "
	lscpu | grep "^Model name:" | sed -e 's/Model name: */Model name: /'

	local NUM_PHYSICAL_CORES="$(lscpu --parse==SOCKET,CORE | grep -v '^#' | sort -u | wc -l)"
	local NUM_LOGICAL_CORES="$(lscpu --parse==SOCKET,CORE | grep -v '^#' | wc -l)"

	echo "- Total physical cores: ${NUM_PHYSICAL_CORES}"
	echo "- Total logical cores (incl. HT): ${NUM_LOGICAL_CORES}"

	if [ $NUM_PHYSICAL_CORES -lt $NUM_LOGICAL_CORES ]
	then
	    THREADS=$NUM_PHYSICAL_CORES
	else
	    THREADS=$(($NUM_PHYSICAL_CORES - 1))
	fi
	echo "- Using concurrency: ${THREADS}"
    fi

    if [ -d /syzygy ]
    then
	SYZYGYENABLED=yes
    else
	SYZYGYENABLED=
    fi

    # setup cache
    mkdir -p /cache/Client /cache/{.cache,.cargo} /cache/Scripts/{Networks,Repositories,Binaries}
    cp /openbench/OpenBench/Client.orig/* /cache/Client/

    echo "========================================================="
    echo "OpenBench username:        ${USERNAME:-<unset>}"
    echo "OpenBench threads:         ${THREADS:-<unset>} threads"
    echo "Syzygy:                    ${SYZYGYENABLED:-no}"
    echo "Extra client opts:         ${EXTRA_OPTS}"
    echo "========================================================="
}

set_worker_pid ()
{
    if [ -f "${WORKER_SHELL_PIDFILE}" ]
    then
	WORKER_PID="$(cat "${WORKER_SHELL_PIDFILE}")"
    else
	WORKER_PID=
    fi
}

launch_openbench_client ()
{
    # launch the client!
    echo -n "$$" > "${WORKER_SHELL_PIDFILE}"
    if [ -d /syzygy ]
    then
	SYZYGYPARM="--syzygy /syzygy"
    else
	SYZYGYPARM=
    fi

    cd /openbench/OpenBench/Client/
    if [ -z "${DO_DRY_RUN}" ]
    then
	export OPENBENCH_USERNAME="${USERNAME}"
	export OPENBENCH_PASSWORD="${PASSWORD}"

	python3 Client.py -T "${THREADS}" -S "http://chess.grantnet.us/" ${SYZYGYPARM} ${EXTRA_OPTS}
    else
	echo "Dry-run requested, skipping client launch"
    fi

    # client has exited
    rm -f "${WORKER_SHELL_PIDFILE}" "${WORKER_EXIT_FILE}"
}

print_status_info ()
{
    set_worker_pid

    if [ "${WORKER_PID}" ]
    then
	if [ -f "${WORKER_EXIT_FILE}" ]
	then
	    echo "OpenBench client status:  RUNNING (pid in container=${WORKER_PID}), EXIT REQUESTED"
	else
	    echo "OpenBench client status:  RUNNING (pid in container=${WORKER_PID})"
	fi
    else
	echo "OpenBench client status:  STOPPED"
    fi
}
