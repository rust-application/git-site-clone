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

FROM alpine:3.20 AS test-init-alpine

RUN apk add --no-cache git zsh

COPY --from=builder /build/target/release/git-site-clone /usr/local/bin/

RUN rm -f /root/.zshrc

ENV SHELL=/bin/zsh

RUN git-site-clone -v init 2>&1 | grep -q "Detected shell: zsh" && \
    echo "PASS: Alpine init test" || (echo "FAIL: Alpine init test" && exit 1)

RUN grep -q "function gsc" /root/.zshrc && \
    echo "PASS: Alpine init adds gsc function" || (echo "FAIL: Alpine init adds gsc function" && exit 1)

RUN rm -f /root/.zshrc

RUN git-site-clone -v init && \
    git-site-clone -v init && \
    test "$(grep -c "function gsc" /root/.zshrc)" -eq 1 && \
    echo "PASS: Alpine init idempotency" || (echo "FAIL: Alpine init idempotency" && exit 1)

FROM ubuntu:24.04 AS test-init-ubuntu

RUN apt-get update && apt-get install -y --no-install-recommends git zsh ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/target/release/git-site-clone /usr/local/bin/

RUN rm -f /root/.zshrc

ENV SHELL=/bin/zsh

RUN git-site-clone -v init 2>&1 | grep -q "Detected shell: zsh" && \
    echo "PASS: Ubuntu init test" || (echo "FAIL: Ubuntu init test" && exit 1)

RUN grep -q "function gsc" /root/.zshrc && \
    echo "PASS: Ubuntu init adds gsc function" || (echo "FAIL: Ubuntu init adds gsc function" && exit 1)

RUN rm -f /root/.zshrc

RUN git-site-clone -v init && \
    git-site-clone -v init && \
    test "$(grep -c "function gsc" /root/.zshrc)" -eq 1 && \
    echo "PASS: Ubuntu init idempotency" || (echo "FAIL: Ubuntu init idempotency" && exit 1)