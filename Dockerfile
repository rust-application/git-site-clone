FROM rust:1.90-alpine AS builder

WORKDIR /build

COPY Cargo.toml Cargo.lock ./
COPY rust-toolchain.toml ./
COPY src ./src

RUN apk add --no-cache musl-dev && \
    rustup target add aarch64-unknown-linux-musl && \
    cargo build --release --target aarch64-unknown-linux-musl

FROM alpine:3.20 AS test-alpine

RUN apk add --no-cache git qemu-aarch64

COPY --from=builder /build/target/aarch64-unknown-linux-musl/release/git-site-clone /usr/local/bin/

RUN rm -rf /root/.config/git-site-clone

RUN git-site-clone -v config show 2>&1 && \
    git-site-clone -v config show 2>&1 | grep -q "Configuration path:" && \
    git-site-clone -v config show 2>&1 | grep -q 'base = "/root/git"' && \
    echo "PASS: Alpine auto-config test" || (echo "FAIL: Alpine auto-config test" && exit 1)

RUN rm -rf /root/.config/git-site-clone

RUN git-site-clone -v config base /custom/path && \
    git-site-clone -v config show 2>&1 | grep -q 'base = "/custom/path"' && \
    echo "PASS: Alpine config base test" || (echo "FAIL: Alpine config base test" && exit 1)

FROM alpine:3.20 AS test-ubuntu

RUN apk add --no-cache git qemu-aarch64

COPY --from=builder /build/target/aarch64-unknown-linux-musl/release/git-site-clone /usr/local/bin/

RUN rm -rf /root/.config/git-site-clone

RUN git-site-clone -v config show 2>&1 && \
    git-site-clone -v config show 2>&1 | grep -q "Configuration path:" && \
    git-site-clone -v config show 2>&1 | grep -q 'base = "/root/git"' && \
    echo "PASS: Ubuntu auto-config test" || (echo "FAIL: Ubuntu auto-config test" && exit 1)

RUN rm -rf /root/.config/git-site-clone

RUN git-site-clone -v config base /custom/path && \
    git-site-clone -v config show 2>&1 | grep -q 'base = "/custom/path"' && \
    echo "PASS: Ubuntu config base test" || (echo "FAIL: Ubuntu config base test" && exit 1)