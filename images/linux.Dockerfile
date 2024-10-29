# Stage 1: Base environment setup using Fedora 39
FROM fedora:39 AS base

WORKDIR /root

ENV DOTNET_NOLOGO=1
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV SCON_VERSION=4.8.0

# Install bash, curl, and other basic utilities
RUN sudo dnf -y install --setopt=install_weak_deps=False \
    bash \
    bzip2 \
    curl \
    file \
    findutils \
    gettext \
    git \
    make \
    nano \
    patch \
    pkgconfig \
    python3-pip \
    unzip \
    wayland-devel \
    which \
    xz \
    dotnet-sdk-8.0

# Install SCons
RUN pip install scons==${SCON_VERSION}

# Stage 2: Godot SDK setup
FROM base AS godot_sdk

ENV ORIGINAL_PATH=${PATH}

# x86_64
RUN cd /root && \
    curl -O https://downloads.tuxfamily.org/godotengine/toolchains/linux/x86_64-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
    tar xf x86_64-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
    rm -f x86_64-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
    cd x86_64-godot-linux-gnu_sdk-buildroot && \
    ./relocate-sdk.sh

# i686
RUN cd /root && \
    curl -O https://downloads.tuxfamily.org/godotengine/toolchains/linux/i686-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
    tar xf i686-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
    rm -f i686-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
    cd i686-godot-linux-gnu_sdk-buildroot && \
    ./relocate-sdk.sh

# aarch64
RUN cd /root && \
    curl -O https://downloads.tuxfamily.org/godotengine/toolchains/linux/aarch64-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
    tar xf aarch64-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
    rm -f aarch64-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
    cd aarch64-godot-linux-gnu_sdk-buildroot && \
    ./relocate-sdk.sh

# arm
RUN cd /root && \
    curl -O https://downloads.tuxfamily.org/godotengine/toolchains/linux/arm-godot-linux-gnueabihf_sdk-buildroot.tar.bz2 && \
    tar xf arm-godot-linux-gnueabihf_sdk-buildroot.tar.bz2 && \
    rm -f arm-godot-linux-gnueabihf_sdk-buildroot.tar.bz2 && \
    cd arm-godot-linux-gnueabihf_sdk-buildroot && \
    ./relocate-sdk.sh

CMD /bin/bash
