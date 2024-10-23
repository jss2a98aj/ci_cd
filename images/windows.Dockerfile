# Stage 1: Base environment setup using Fedora 40
FROM fedora:40 AS base

WORKDIR /root

ENV DOTNET_NOLOGO=1 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1

# Install dependencies for .NET, Python SCons, and MinGW
RUN dnf -y install --setopt=install_weak_deps=False \
    bash bzip2 curl file findutils gettext git make nano patch pkgconfig python3-pip unzip which xz \
    dotnet-sdk-8.0 mingw32-gcc mingw32-gcc-c++ mingw32-winpthreads-static \
    mingw64-gcc mingw64-gcc-c++ mingw64-winpthreads-static && \
    pip install scons==4.8.0

# Stage 2: Godot and LLVM MinGW setup
FROM base AS godot_mingw

WORKDIR /root

# Download and setup LLVM MinGW
RUN curl -LO https://github.com/mstorsjo/llvm-mingw/releases/download/20240619/llvm-mingw-20240619-ucrt-ubuntu-20.04-x86_64.tar.xz && \
    tar xf llvm-mingw-20240619-ucrt-ubuntu-20.04-x86_64.tar.xz && \
    rm -f llvm-mingw-20240619-ucrt-ubuntu-20.04-x86_64.tar.xz && \
    mv llvm-mingw-20240619-ucrt-ubuntu-20.04-x86_64 /root/llvm-mingw

CMD /bin/bash
