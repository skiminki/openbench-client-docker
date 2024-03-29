#!/bin/bash
set -e
cd "$(dirname $0)"
PWD="$(pwd)"
IMAGE=skiminki/openbench-client:latest
CONFIG=config.sh

if [ -f "${PWD}/${CONFIG}" ]
then
	source "${PWD}/${CONFIG}"
	args=("--mount" "type=bind,source=${PWD}/${CONFIG},target=/config.sh,readonly")
	if [ -n "${SYZYGY}" ]
	then
		args+=("--mount" "type=bind,source=${SYZYGY},target=/syzygy/,readonly")
	fi
	if [ -n "${CACHE}" ]
	then
		args+=("--mount" "type=bind,source=${CACHE},target=/cache/")
	fi
	docker run -it --rm --name openbench-client --user "$(id -u):$(id -g)" ${args[@]} "${IMAGE}" "$@"
else
	docker run -it --rm --name openbench-client --user "$(id -u):$(id -g)" "${IMAGE}"
fi
