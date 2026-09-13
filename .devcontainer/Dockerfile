FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV GODOT_VERSION=4.3
ENV GODOT_RELEASE=stable

# Install basic dependencies and tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    unzip \
    git \
    make \
    python3 \
    python3-pip \
    openjdk-21-jdk \
    libfontconfig1 \
    libxcursor1 \
    libxinerama1 \
    libxrandr2 \
    libxi6 \
    libasound2 \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

# Install GDToolkit linter/formatter
RUN pip3 install --no-cache-dir gdtoolkit

# Download and install Godot 4 Headless binary
RUN curl -LO https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-${GODOT_RELEASE}/Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_linux.x86_64.zip \
    && unzip Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_linux.x86_64.zip \
    && mv Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_linux.x86_64 /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm Godot_v${GODOT_VERSION}-${GODOT_RELEASE}_linux.x86_64.zip

WORKDIR /workspace

CMD ["bash"]
