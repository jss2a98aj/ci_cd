# Stage 1: Base environment setup using Fedora 40
FROM fedora:40 AS base

WORKDIR /root

ENV DOTNET_NOLOGO=1
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV SCON_VERSION=4.8.0

# Install dependencies for .NET, Python SCons, and essential packages
RUN dnf -y install --setopt=install_weak_deps=False \
    bash bzip2 curl file findutils gettext git make nano patch pkgconfig python3-pip unzip which xz \
    dotnet-sdk-8.0 java-17-openjdk-devel ncurses-compat-libs && \
    pip install scons==${SCON_VERSION} && \
    rm -rf /var/lib/apt/lists/*

# Stage 2: Godot and Android NDK setup
FROM base AS godot_android

WORKDIR /root

ENV ANDROID_SDK_ROOT=/root/sdk
ENV ANDROID_NDK_VERSION=23.2.8568313
ENV ANDROID_NDK_ROOT=${ANDROID_SDK_ROOT}/ndk/${ANDROID_NDK_VERSION}

# Create SDK directory
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools

# Download the Android command-line tools
RUN curl -LO https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && \
    unzip commandlinetools-linux-11076708_latest.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
    rm commandlinetools-linux-11076708_latest.zip

# Accept licenses
RUN yes | ${ANDROID_SDK_ROOT}/cmdline-tools/bin/sdkmanager --sdk_root="${ANDROID_SDK_ROOT}" --licenses

# Install Android SDK components including NDK, build-tools, platforms, and cmake
RUN ${ANDROID_SDK_ROOT}/cmdline-tools/bin/sdkmanager --sdk_root="${ANDROID_SDK_ROOT}" \
    "ndk;${ANDROID_NDK_VERSION}" 'cmdline-tools;latest' 'build-tools;34.0.0' 'platforms;android-34' 'cmake;3.22.1'

CMD /bin/bash
