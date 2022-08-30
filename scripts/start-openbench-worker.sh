#!/bin/bash
set -e
cd "$(dirname $0)"
PWD="$(pwd)"
IMAGE=skiminki/openbench-client
CONFIG=config.sh

if [ -f  "${PWD}/${CONFIG}" ]
then
	source "${PWD}/${CONFIG}"
	if [ -n "${SYZYGY}" ]
	then
		docker run -it --rm --name openbench-client \
			--mount type=bind,source="${PWD}/${CONFIG}",target="/${CONFIG}",readonly \
			--mount type=bind,source="${SYZYGY}/",target="/syzygy",readonly \
			"${IMAGE}" "$@"
	else
		docker run -it --rm --name openbench-client \
			--mount type=bind,source="${PWD}/${CONFIG}",target="/${CONFIG}",readonly \
			"${IMAGE}" "$@"
	fi
else
	docker run -it --rm --name openbench-client "${IMAGE}"
fi
