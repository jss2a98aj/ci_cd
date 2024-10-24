# Stage 1: Base environment setup using Fedora 40
FROM fedora:40 AS base

WORKDIR /root

ENV DOTNET_NOLOGO=1
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV SCON_VERSION=4.8.0

RUN dnf update -y

# Install bash, curl, and other basic utilities
RUN dnf install -y --setopt=install_weak_deps=False \
    bash bzip2 curl file findutils gettext \
    git make nano patch pkg-config unzip xz cmake gdb --best


# Install 32bit Deps seperately
RUN dnf install -y \
    gcc-c++ gcc-c++.i686 glibc-devel glibc-devel.i686 \
    libcxx-devel libcxx \
    libstdc++-devel libstdc++ libstdc++.i686 --allowerasing --best

# Bypass dnf search, it is not pulling the newest version it keeps trying to install 14.0.x
RUN curl -O https://rpmfind.net/linux/fedora/linux/updates/40/Everything/x86_64/Packages/l/libstdc++-devel-14.2.1-3.fc40.i686.rpm \
    && dnf install -y ./libstdc++-devel-14.2.1-3.fc40.i686.rpm \
    && rm -f libstdc++-devel-14.2.1-3.fc40.i686.rpm

# Install Python and pip for SCons
RUN dnf install -y python3-pip

# Install SCons
RUN pip install scons==${SCON_VERSION}

# Install .NET SDK
RUN dnf install -y dotnet-sdk-8.0

# Install Wayland development tools
RUN dnf install -y wayland-devel

RUN dnf clean all

# Stage 2: Godot SDK setup
FROM base AS godot_sdk

WORKDIR /root

ENV GODOT_SDK_VERSIONS="x86_64 i686 aarch64 arm"
ENV GODOT_SDK_BASE_URL="https://downloads.tuxfamily.org/godotengine/toolchains/linux/2024-01-17"
ENV GODOT_SDK_PATH="/root"

# Download and install Godot SDKs for various architectures
RUN for arch in $GODOT_SDK_VERSIONS; do \
    if [ "$arch" = "arm" ]; then \
      sdk_file="arm-godot-linux-gnueabihf_sdk-buildroot.tar.bz2"; \
    else \
      sdk_file="${arch}-godot-linux-gnu_sdk-buildroot.tar.bz2"; \
    fi; \
    echo "Downloading SDK for $arch..." && \
    curl -LO ${GODOT_SDK_BASE_URL}/$sdk_file && \
    tar xf $sdk_file && \
    rm -f $sdk_file && \
    cd ${arch}-godot-linux-gnu_sdk-buildroot || cd arm-godot-linux-gnueabihf_sdk-buildroot && \
    ./relocate-sdk.sh && \
    cd /root; \
done

CMD /bin/bash
