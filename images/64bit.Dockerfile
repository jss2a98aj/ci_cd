# Stage 1: Base environment setup using Fedora 40
FROM fedora:39 AS base

WORKDIR /root

ENV DOTNET_NOLOGO=1
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV SCON_VERSION=4.8.0

#RUN dnf update -y

# Install bash, curl, and other basic utilities
RUN dnf install -y --setopt=install_weak_deps=False \
    bash bzip2 curl file findutils gettext \
    git make nano patch pkg-config unzip \
    xz cmake gdb ccache patch yasm mold lld


# Needed for buildroot
RUN dnf install -y \
    wget \
    which \
    cpio \
    rsync \
    bc \
    diffutils \
    perl perl-core perl-ExtUtils-MakeMaker

RUN dnf install -y \
        pkgconfig \
        libX11-devel \
        libXcursor-devel \
        libXrandr-devel \
        libXinerama-devel \
        libXi-devel \
        wayland-devel \
        mesa-libGL-devel \
        mesa-libGLU-devel \
        alsa-lib-devel \
        pulseaudio-libs-devel \
        libudev-devel \
        gcc-c++ \
        libstdc++-static \
        libatomic-static \
        freetype-devel \
        openssl openssl-devel \
        libcxx-devel libcxx \
        zlib-devel \
        libmpc-devel mpfr-devel gmp-devel clang \
        vulkan xz gcc  \
        parallel \
        libxml2-devel \
        embree3-devel \
        enet-devel \
        glslang-devel \
        graphite2-devel \
        harfbuzz-devel \
        libicu-devel \
        libsquish-devel \
        libtheora-devel \
        libvorbis-devel \
        libwebp-devel \
        libzstd-devel \
        mbedtls-devel \
        miniupnpc-devel \
        embree embree-devel \
        glibc-devel \
        libstdc++ libstdc++-devel


# Install Python and pip for SCons
RUN dnf install -y python3-pip

# Install SCons
RUN pip install scons==${SCON_VERSION}

# Install .NET SDK
RUN dnf install -y dotnet-sdk-8.0

RUN dnf clean all

# Stage 2: Godot SDK setup
FROM base AS godot_sdk

WORKDIR /root

ENV GODOT_SDK_VERSIONS="x86_64 aarch64"
ENV BUILDROOT_REPO="https://github.com/godotengine/buildroot.git"

# Clone the buildroot repository
RUN git clone ${BUILDROOT_REPO} buildroot

RUN pwd

# For buildroot
ENV FORCE_UNSAFE_CONFIGURE=1

# Build SDKs for each architecture https://github.com/godotengine/buildroot#using-buildroot-to-generate-sdks
RUN cd /root/buildroot && \
    for arch in $GODOT_SDK_VERSIONS; do \
        echo "::group::Building SDK for $arch" && \
        echo "Setting up configuration for $arch..." && \
        config_file="config-godot-$arch"; \
        cp $config_file .config && \
        make olddefconfig && \
        # Clean up any previous builds
        echo "::debug::Removing previous output directory for clean build" && \
        rm -rf output && mkdir output && \
        echo "Starting clean build for $arch..." && \
        make clean sdk && \
        # Determine correct naming for the SDK output directory and tar file
        if [ "$arch" = "armv7" ]; then \
            sdk_output_dir="/root/${arch}-godot-linux-gnueabihf_sdk"; \
            sdk_file="arm-godot-linux-gnueabihf_sdk-buildroot.tar.bz2"; \
        else \
            sdk_output_dir="/root/${arch}-godot-linux-gnu_sdk"; \
            sdk_file="${arch}-godot-linux-gnu_sdk-buildroot.tar.gz"; \
        fi; \
        echo "::debug::Setting sdk_output_dir to ${sdk_output_dir} and sdk_file to ${sdk_file}" && \
        # Move and extract SDK to the specified output directory
        if [ -f "output/images/${sdk_file}" ]; then \
            echo "::group::Extracting SDK for $arch" && \
            echo "Extracting SDK for $arch to ${sdk_output_dir}..." && \
            mkdir -p "${sdk_output_dir}" && \
            tar -xf "output/images/${sdk_file}" -C "${sdk_output_dir}" && \
            rm -f "output/images/${sdk_file}" && \
            cd "${sdk_output_dir}" && \
            ./relocate-sdk.sh && \
            cd /root/buildroot && \
            echo "::endgroup::" && \
        else \
            echo "::warning::SDK file for $arch not found. Skipping extraction step." && \
        fi; \
        echo "::notice::SDK for $arch built and extracted to ${sdk_output_dir}" && \
        echo "::endgroup::" && \
    done && \
    # Log summary of all output directories
    echo "::group::SDK Build Summary" && \
    echo "SDKs have been built for the following architectures and are located at:" && \
    for arch in $GODOT_SDK_VERSIONS; do \
        if [ "$arch" = "armv7" ]; then \
            sdk_output_dir="/root/${arch}-godot-linux-gnueabihf_sdk"; \
        else \
            sdk_output_dir="/root/${arch}-godot-linux-gnu_sdk"; \
        fi; \
        echo "::notice::${arch} SDK directory: ${sdk_output_dir}" && \
    done && \
    echo "::endgroup::" && \
    echo "::notice::SDK build process complete. All logs are summarized above."


CMD /bin/bash
