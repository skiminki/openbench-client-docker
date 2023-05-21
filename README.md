Introduction
------------

This is a fully-featured image for OpenBench client with support for
all OpenBench engines.


Setup and running the container:
--------------------------------

**Run the following command in an empty directory:**
```
docker run -it --rm --name openbench-client skiminki/openbench-client scripts | bash
```

This extracts scripts for easy container management with a template
for configuration file. In addition, the cache subdirectory is created
to speed up successive launches of the container.

**Fill in the info in config.sh.**

Use config.sh.template as the starting point.

**Start the container**

```
./start-openbench-client.sh
```

**Stop the container** (in another terminal)

```
./stop-openbench-client.sh --wait
```


Configuring the container: (manual)
-----------------------------------

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


Starting the container: (manual)
--------------------------------

Launch the container with the following mounts:
- /config.sh (mandatory, read-only) --- The configuration and credentials file
- /syzygy (optional, read-only) --- The Syzygy 6-men tablebase files. Optional, used when available.
- /cache (optional, read-write) --- Cache for persistent files such as engine builds, fetched networks, and .cargo directory for fetched rust packages.

Example:
```
docker run -it --rm --name openbench-client \
    --mount type=bind,source="/projects/openbench-client/config.sh",target="/config.sh",readonly \
    --mount type=bind,source="/data/syzygy/",target="/syzygy",readonly \
    skiminki/openbench-client
```


Stopping the container: (manual)
--------------------------------

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


Links:
------

- OpenBench: http://chess.grantnet.us/
- Docker hub repository: https://hub.docker.com/repository/docker/skiminki/openbench-client
- GitHub repository for building the Docker image: https://github.com/skiminki/openbench-client-docker
