# Stage 1: Base environment setup using Fedora 40
FROM fedora:40 AS base

WORKDIR /root

ENV DOTNET_NOLOGO=1 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1

# Install dependencies for .NET, Python SCons, and necessary tools
RUN dnf -y install --setopt=install_weak_deps=False \
    bash bzip2 curl file findutils gettext git make nano patch pkgconfig python3-pip unzip which xz \
    dotnet-sdk-8.0 && \
    pip install scons==4.8.0

# Stage 2: Godot and Emscripten setup
FROM base AS godot_emscripten

WORKDIR /root

ENV EMSCRIPTEN_VERSION=3.1.64

# Clone and set up Emscripten SDK
RUN git clone --branch ${EMSCRIPTEN_VERSION} --depth 1 https://github.com/emscripten-core/emsdk && \
    ./emsdk/emsdk install ${EMSCRIPTEN_VERSION} && \
    ./emsdk/emsdk activate ${EMSCRIPTEN_VERSION}

CMD /bin/bash
