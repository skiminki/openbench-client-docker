Introduction
------------

This is a fully-featured image for OpenBench client with support for
all OpenBench engines.


Configuration
-------------

Create file config.sh with the following info:

```
# openbench credentials
USERNAME='<unset>'
PASSWORD='<unset>'

# Threads used by openbench; blank = autodetect
# General recommendation:
# - HT machines: physical core count = logical CPUs / 2
# - non-HT machines: physical core count - 1
THREADS=

# extra options to be passed to the client (try -h for help)
EXTRA_OPTS=''
```

Starting the container:
-----------------------

Launch the container with the following mounts:
- /config.sh --- The configuration and credentials file
- /syzygy (optional) --- The Syzygy 6-men tablebase files. Optional, used when available.

Example:
```
docker run -it --rm --name openbench-client \
    --mount type=bind,source="/projects/openbench-client/config.sh",target="/config.sh",readonly \
    --mount type=bind,source="/data/syzygy/",target="/syzygy",readonly \
    skiminki/openbench-client
```


Stopping the container:
-----------------------

The recommended way to stop the container is to signal and wait for exit:
```
docker exec -it openbench-client stop --wait
```
This may take a few minutes.


Built-in help and additional options:
-------------------------------------

Use the following command for built-in help:
```
docker run -it --rm --name openbench-client skiminki/openbench-client help
```

The container can also produce bash scripts for starting, stopping,
and checking the status:
```
docker run -it --rm --name openbench-client skiminki/openbench-client scripts | bash
```

Links:
------

- OpenBench: http://chess.grantnet.us/
- Docker hub repository: https://hub.docker.com/repository/docker/skiminki/openbench-client
- GitHub repository for building the Docker image: https://github.com/skiminki/openbench-client-docker
