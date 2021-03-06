# Docker 17.05 or higher required for multi-stage builds
FROM rust:1.26.0-stretch as builder
ADD . /app
WORKDIR /app
# Make sure that this matches in .travis.yml
ARG RUST_TOOLCHAIN=nightly-2018-08-06
RUN \
    apt-get -qq update && \
    apt-get -qq install -y default-libmysqlclient-dev && \
    \
    rustup default ${RUST_TOOLCHAIN} && \
    cargo --version && \
    rustc --version && \
    mkdir -m 755 bin && \
    mkdir -m 755 bin/config && \
    cargo build --release && \
    cp -R /app/config/* /app/bin/config && \
    cp /app/target/release/fxa_email_send /app/bin && \
    cp /app/target/release/fxa_email_queues /app/bin
COPY version.json /app


FROM debian:stretch-slim
# FROM debian:stretch  # for debugging docker build
RUN \
    groupadd --gid 10001 app && \
    useradd --uid 10001 --gid 10001 --home /app --create-home app && \
    \
    apt-get -qq update && \
    apt-get -qq install -y default-libmysqlclient-dev libssl-dev ca-certificates && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists

COPY --from=builder /app/version.json /app/version.json
COPY --from=builder /app/bin /app/bin

WORKDIR /app/bin
USER app

ENV FXA_EMAIL_ENV production
ENV ROCKET_ENV production

CMD ["/app/bin/fxa_email_send"]
