FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install -y --no-install-recommends \
        build-essential \
        file \
        ca-certificates \
        gpg \
        wget \
        git \
        cpio \
        unzip \
        rsync \
        bc \
        sqlite3
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null
RUN echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ jammy main' | tee /etc/apt/sources.list.d/kitware.list >/dev/null
RUN apt update && \
    apt install -y --no-install-recommends \
        cmake=3.25.2-0kitware1ubuntu22.04.1 cmake-data=3.25.2-0kitware1ubuntu22.04.1 \
        && \
        apt clean && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN useradd -m -s /bin/bash x6100 \
    && mkdir -p /home/x6100/build \
    && chown -R x6100:x6100 /home/x6100

USER x6100
WORKDIR /home/x6100/build

CMD ["/bin/bash"]
