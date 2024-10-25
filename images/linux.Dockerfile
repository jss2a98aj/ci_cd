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

# RUN dnf downgrade libstdc++ libstdc++-devel gcc gcc-c++ --allowerasing -y


RUN dnf install -y \
#        scons \
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
        which \
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

# RUN dnf downgrade libstdc++ libstdc++-devel -y

# # Install 32bit Deps seperately
# RUN dnf install -y \
#     gcc-c++.i686 \
#     glibc-devel.i686 \
#     glslang-devel.i686 \
#     libstdc++-13.2.1-3.fc39.i686 \
#     libstdc++-devel-13.2.1-3.fc39.i686 \
#     --allowerasing



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

ENV GODOT_SDK_VERSIONS="x86_64 i686 aarch64 armv7"
ENV BUILDROOT_REPO="https://github.com/godotengine/buildroot.git"

# Clone the buildroot repository
RUN git clone ${BUILDROOT_REPO} buildroot

RUN pwd

# Build SDKs for each architecture https://github.com/godotengine/buildroot#using-buildroot-to-generate-sdks
RUN cd /root/buildroot && \
    for arch in $GODOT_SDK_VERSIONS; do \
        echo "Building SDK for $arch..." && \
        config_file="config-godot-$arch"; \
        cp $config_file .config && \
        make olddefconfig && \
        # Move previous builds to avoid conflicts
        rm -rf output && mkdir output && \
        make clean sdk && \
        # Determine correct naming for the SDK output directory and tar file
        if [ "$arch" = "armv7" ]; then \
            sdk_output_dir="output/images/arm-godot-linux-gnueabihf_sdk-buildroot"; \
            sdk_file="arm-godot-linux-gnueabihf_sdk-buildroot.tar.bz2"; \
        else \
            sdk_output_dir="output/images/${arch}-godot-linux-gnu_sdk-buildroot"; \
            sdk_file="${arch}-godot-linux-gnu_sdk-buildroot.tar.gz"; \
        fi; \
        # Extract and execute relocate script
        if [ -f "${sdk_output_dir}.tar.bz2" ] || [ -f "${sdk_output_dir}.tar.gz" ]; then \
            echo "Extracting SDK for $arch..." && \
            tar -xf "${sdk_file}" -C "${sdk_output_dir}" && \
            rm -f "${sdk_file}" && \
            cd "${sdk_output_dir}" && \
            ./relocate-sdk.sh && \
            cd /root/buildroot; \
        fi; \
    done

CMD /bin/bash
