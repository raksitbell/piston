FROM buildpack-deps:bullseye AS isolate

RUN apt-get update \
    && apt-get install -y --no-install-recommends git libcap-dev \
    && git clone https://github.com/envicutor/isolate.git /tmp/isolate \
    && cd /tmp/isolate \
    && git checkout af6db68042c3aa0ded80787fbb78bc0846ea2114 \
    && make -j"$(nproc)" install \
    && rm -rf /tmp/isolate /var/lib/apt/lists/*

FROM node:22-bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive \
    NODE_ENV=production \
    PISTON_DATA_DIRECTORY=/piston

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        binutils build-essential coreutils curl git gnupg libarpack2-dev \
        libblas-dev libcap-dev libc6-dev libedit-dev libevent-dev libfftw3-dev \
        libglpk-dev libgmp3-dev liblapack-dev libncurses5 libncurses6 \
        libpcre2-dev libpcre3-dev libqhull-dev libqrupdate-dev libreadline-dev \
        libseccomp-dev libsuitesparse-dev libsundials-dev libxml2 locales procps \
        python3 rename tar util-linux \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --no-create-home piston

COPY --from=isolate /usr/local/bin/isolate /usr/local/bin/isolate
COPY --from=isolate /usr/local/etc/isolate /usr/local/etc/isolate

WORKDIR /piston

COPY core/api/package.json core/api/package-lock.json ./core/api/
RUN cd core/api && npm ci --omit=dev

COPY core/api/src ./core/api/src
COPY core/cli/install.js ./core/cli/install.js
COPY scripts/entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

VOLUME ["/piston/packages", "/piston/data"]
EXPOSE 2000

ENTRYPOINT ["/piston/entrypoint.sh"]
