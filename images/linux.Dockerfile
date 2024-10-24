FROM ubuntu:22.04 AS base

WORKDIR /root

ENV DOTNET_NOLOGO=1
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV SCON_VERSION=4.8.0

RUN apt-get update -y && apt-get upgrade -y

RUN dpkg --add-architecture i386

RUN apt-get install -y --no-install-recommends \
    bash bzip2 curl file gettext \
    git make nano patch pkg-config unzip xz-utils cmake gdb


RUN apt-get install -y \
    scons \
    pkg-config \
    libx11-dev \
    libxcursor-dev \
    libxrandr-dev \
    libxinerama-dev \
    libxi-dev \
    libwayland-dev \
    libgl-dev \
    libglu-dev \
    libasound2-dev \
    libpulse-dev \
    libudev-dev \
    g++ \
    libatomic1 \
    libfreetype6-dev \
    libssl-dev \
    libc++-dev \
    libc++abi-dev

RUN apt-get install -y \
    gcc-multilib \
    g++-multilib \
    libc6-dev:i386 \
    libstdc++6:i386 \
    libx11-dev:i386

RUN apt-get install -y python3-pip

RUN pip install scons==${SCON_VERSION}

RUN apt-get install -y dotnet-sdk-8.0

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

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
