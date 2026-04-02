FROM ubuntu:latest
COPY ./scripts/docker /tmp/docker
RUN /tmp/docker/install-dependencies.sh
WORKDIR /app
