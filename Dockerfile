FROM rust:1.90-alpine AS builder

WORKDIR /build

COPY Cargo.toml Cargo.lock ./
COPY rust-toolchain.toml ./
COPY src ./src

RUN apk add --no-cache musl-dev mimalloc2 && \
    LD_PRELOAD=/usr/lib/libmimalloc2.so cargo build --release

FROM alpine:3.20 AS test-alpine

RUN apk add --no-cache git

COPY --from=builder /build/target/release/git-site-clone /usr/local/bin/

RUN rm -rf /root/.config/git-site-clone

RUN git-site-clone -v config show 2>&1 && \
    git-site-clone -v config show 2>&1 | grep -q "Configuration path:" && \
    git-site-clone -v config show 2>&1 | grep -q 'base = "/root"' && \
    echo "PASS: Alpine auto-config test" || (echo "FAIL: Alpine auto-config test" && exit 1)

RUN rm -rf /root/.config/git-site-clone

RUN git-site-clone -v config base /custom/path && \
    git-site-clone -v config show 2>&1 | grep -q 'base = "/custom/path"' && \
    echo "PASS: Alpine config base test" || (echo "FAIL: Alpine config base test" && exit 1)

RUN rm -rf /root/.config/git-site-clone

RUN git-site-clone -v --no-cwd https://github.com/octocat/Hello-World && \
    test -d /root/github.com/octocat/Hello-World && \
    echo "PASS: Alpine clone test" || (echo "FAIL: Alpine clone test" && exit 1)

FROM ubuntu:24.04 AS test-ubuntu

RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/target/release/git-site-clone /usr/local/bin/

RUN rm -rf /root/.config/git-site-clone

RUN git-site-clone -v config show 2>&1 && \
    git-site-clone -v config show 2>&1 | grep -q "Configuration path:" && \
    git-site-clone -v config show 2>&1 | grep -q 'base = "/root"' && \
    echo "PASS: Ubuntu auto-config test" || (echo "FAIL: Ubuntu auto-config test" && exit 1)

RUN rm -rf /root/.config/git-site-clone

RUN git-site-clone -v config base /custom/path && \
    git-site-clone -v config show 2>&1 | grep -q 'base = "/custom/path"' && \
    echo "PASS: Ubuntu config base test" || (echo "FAIL: Ubuntu config base test" && exit 1)

RUN rm -rf /root/.config/git-site-clone

RUN git-site-clone -v --no-cwd https://github.com/octocat/Hello-World && \
    test -d /root/github.com/octocat/Hello-World && \
    echo "PASS: Ubuntu clone test" || (echo "FAIL: Ubuntu clone test" && exit 1)