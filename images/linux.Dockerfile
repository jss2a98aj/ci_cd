# Stage 1: Base environment setup using Ubuntu 22.04
FROM ubuntu:22.04 AS base

WORKDIR /root

ENV DOTNET_NOLOGO=1
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV SCON_VERSION=4.8.0

# Install dependencies for .NET, Python SCons, and Wayland development tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash bzip2 curl file findutils gettext git make nano patch pkg-config python3-pip unzip xz-utils \
    dotnet-sdk-8.0 wayland-dev && \
    pip install scons==${SCON_VERSION} && \
    rm -rf /var/lib/apt/lists/*

# Stage 2: Godot SDK setup
FROM base AS godot_sdk

WORKDIR /root

ENV GODOT_SDK_VERSIONS="x86_64 i686 aarch64 arm"
ENV GODOT_SDK_BASE_URL="https://downloads.tuxfamily.org/godotengine/toolchains/linux/2024-01-17"
ENV GODOT_SDK_PATH="/root"

# Install Godot SDKs for various architectures
RUN for arch in $GODOT_SDK_VERSIONS; do \
      curl -LO ${GODOT_SDK_BASE_URL}/${arch}-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
      tar xf ${arch}-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
      rm -f ${arch}-godot-linux-gnu_sdk-buildroot.tar.bz2 && \
      cd ${arch}-godot-linux-gnu_sdk-buildroot && \
      ./relocate-sdk.sh && \
      cd /root; \
    done

CMD /bin/bash
