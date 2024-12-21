# Docker image for OpenBench client
# Copyright (C) 2022-2024  Sami Kiminki
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
FROM ubuntu:24.04

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
    libclang-rt-dev \
    libglib2.0-bin \
    llvm \
    make \
    python3 \
    python3-requests \
    python3-setuptools \
    rustc \
    wget \
    && \
    rm -rf /var/lib/apt/lists/*

# Non-root user to run the tests and /cache
RUN groupadd openbench && \
    useradd -m --no-log-init -g openbench -d /openbench openbench && \
    chmod 755 /openbench && \
    mkdir /cache && \
    chown openbench:openbench /cache && chmod 777 /cache
USER openbench:openbench

# Download the client from github, clean-up some unneeded files and directories
# to save some space.
#
# Note: argument OPENBENCH_GIT_HASH must be set
ARG OPENBENCH_GIT_HASH
RUN cd /openbench && \
    git lfs install && \
    git clone --single-branch --branch master https://github.com/skiminki/OpenBench.git && \
    cd OpenBench && \
    git config advice.detachedHead false && \
    git checkout "${OPENBENCH_GIT_HASH}" && \
    rm -r .git CoreFiles/cutechess-windows.exe

# Rename the client directory. The contents of Client.orig are going is going to be copied
# Client (which is at /cache/Client) on launch.
# on launch.
RUN mv /openbench/OpenBench/Client /openbench/OpenBench/Client.orig && \
    ln -snf /cache/Client /openbench/OpenBench/ && \
    ln -snf /cache/.cargo /cache/.cache /openbench/ && \
    ln -snf /cache/Scripts/Networks /cache/Scripts/Repositories /cache/Scripts/Binaries /openbench/OpenBench/Scripts/

# Entrypoint bash scripts
COPY openbench-entrypoint.sh \
     openbench-client-functions.bash \
     /

# Shortcut files to make "docker exec" behave
COPY bin/* /usr/local/bin/

# Built-in frontend scripts for easy container management
COPY scripts/* /scripts/

LABEL description="OpenBench Testing Framework client for http://chess.grantnet.us/ . \
Please see https://hub.docker.com/repository/docker/skiminki/openbench-client \
on how to configure the container. Sources to build the Docker image at \
https://github.com/skiminki/openbench-client-docker . \
OpenBench Testing Framework client git commit: ${OPENBENCH_GIT_HASH}"

ENTRYPOINT ["/openbench-entrypoint.sh"]
