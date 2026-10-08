FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV WORKDIR=/home/build
ENV HOME=/home/builder
ENV BR2_CCACHE_DIR=/home/builder/.buildroot-ccache

# Locales + Basis-Tools
RUN apt update && apt install -y --no-install-recommends \
    locales \
    ca-certificates \
    git \
    build-essential \
    wget \
    curl \
    cpio \
    unzip \
    zip \
    rsync \
    bc \
    file \
    python3 \
    python3-dev \
    python3-setuptools \
    python3-pip \
    libncurses5 \
    libncurses5-dev \
    libncursesw5-dev \
    patch \
    perl \
    tar \
    gzip \
    bzip2 \
    xz-utils \
    findutils \
    gawk \
    sed \
    diffutils \
    bison \
    flex \
    libssl-dev \
    sudo \
    sqlite3 \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# CMake 3.25.3
RUN curl -fsSL https://github.com/Kitware/CMake/releases/download/v3.25.3/cmake-3.25.3-linux-x86_64.tar.gz \
    | tar -xz -C /usr/local --strip-components=1 \
    && cmake --version

# Non-root User
ARG HOST_UID=1000
ARG HOST_GID=1000
RUN groupadd -g ${HOST_GID} builder \
    && useradd -m -u ${HOST_UID} -g ${HOST_GID} -s /bin/bash builder \
    && echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder \
    && chmod 0440 /etc/sudoers.d/builder

# Work- and Ccache-Directories
RUN mkdir -p ${WORKDIR} ${BR2_CCACHE_DIR} \
    && chown -R builder:builder ${WORKDIR} ${HOME}

WORKDIR ${WORKDIR}

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER builder

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
