FROM ubuntu:26.04
COPY ./scripts/docker /tmp/docker
RUN /tmp/docker/install-dependencies.sh
WORKDIR /app
