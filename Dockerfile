# Docker image for OpenBench client
# Copyright (C) 2022  Sami Kiminki
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

# Baseline
FROM ubuntu:22.04

# Update and install packages needed to run OpenBench engine testing
RUN apt-get update && \
    apt-get dist-upgrade -y && \
    DEBIAN_FRONTEND="noninteractive" TZ="Europe/Helsinki" apt-get install --no-install-recommends -y \
    cargo \
    clang \
    curl \
    g++ \
    gcc \
    git \
    git-lfs \
    golang \
    libglib2.0-bin \
    llvm \
    make \
    python3 \
    python3-distutils \
    python3-requests \
    rustc \
    wget \
    && \
    rm -rf /var/lib/apt/lists/*

# Non-root user to run the tests and /cache
RUN groupadd openbench && \
    useradd -m --no-log-init -g openbench -d /openbench openbench && \
    mkdir /cache && \
    chown openbench:openbench /cache
USER openbench:openbench

# Download the client from github, clean-up some unneeded files and directories
# to save some space
RUN cd /openbench && \
    git lfs install && \
    git clone --single-branch --branch master https://github.com/AndyGrant/OpenBench.git && \
    cd OpenBench && \
    rm -r .git CoreFiles/cutechess-windows.exe

# Entrypoint bash scripts
COPY openbench-entrypoint.sh \
     openbench-client-functions.bash \
     /

# Shortcut files to make "docker exec" behave
COPY bin/* /usr/local/bin/

# Built-in frontend scripts for easy container management
COPY scripts/* /scripts/

LABEL description="OpenBench Testing Framework client for http://chess.grantnet.us/ . \
Please see https://hub.docker.com/repository/docker/skiminki/openbench-client\
on how to configure the container. Sources to build the Docker image at \
https://github.com/skiminki/openbench-client-docker ."

ENTRYPOINT ["/openbench-entrypoint.sh"]
