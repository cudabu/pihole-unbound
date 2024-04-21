FROM debian:bookworm as build-base
LABEL maintainer="Curtis Bunch"

ARG TARGETARCH

RUN build_deps="gcc libc-dev libevent-dev libexpat1-dev libnghttp2-dev make" && \
    set -x && \
    DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
      $build_deps \
      bsdmainutils \
      ca-certificates \
      ldnsutils \
      libevent-2.1-7 \
      libexpat1-dev \
      libprotobuf-dev \
      protobuf-c-compiler

ARG UNBOUND_UID=101
ARG UNBOUND_GID=102

RUN addgroup-S -g ${UNBOUND_GID} unbound \
    && adduser -S -g unbound -h /var/unbound -u ${UNBOUND_UID} -D -H -G unbound unbound

FROM build-base AS unbound

WORKDIR /src

ARG UNBOUND_VERSION=1.19.3
# https://nlnetlabs.nl/downloads/unbound/unbound-1.19.3.tar.gz.sha256
ARG UNBOUND_SHA256="3ae322be7dc2f831603e4b0391435533ad5861c2322e34a76006a9fb65eb56b9"

ADD https://nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz unbound.tar.gz

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN echo "${UNBOUND_SHA256} unbound.tar.gz" | sha256sum -c - \
    && tar -zxf unbound.tar.gz --strip-components=1

# https://unbound.docs.nlnetlabs.nl/en/latest/getting-started/installation.html#building-from-source-compiling
RUN ./configure\
    --prefix=/opt/unbound \
    --with-conf-file=/etc/unbound/unbound.conf \
    --with-run-dir=/var/unbound \
    --with-chroot-dir=/var/unbound \
    --with-pidfile=/var/unbound/unbound.pid \
    --with-rootkey-file=/var/unbound/root.key \
    --disable-static \
    --disable-shared \
    --disable-rpath \
    --enable-dnscrypt \
    --enable-subnet \
    --enable-cachedb \
    --with-pthreads \
    --with-libevent \
    --with-libhiredis \
    --with-ssl \
    --with-username=unbound