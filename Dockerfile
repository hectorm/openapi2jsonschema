##################################################
## "base" stage
##################################################

FROM docker.io/python:3.12-slim-bookworm@sha256:2fba8e70a87bcc9f6edd20dda0a1d4adb32046d2acbca7361bc61da5a106a914 AS base

ARG USER=oasch
ARG UID=49374

RUN useradd -u "${UID:?}" -g 0 -m "${USER:?}" \
	&& mkdir -m 777 /schemas/

##################################################
## "build" stage
##################################################

FROM base AS build

RUN apt-get update && apt-get install -y make

COPY --chown=0:0 ./Makefile /work/
RUN --mount=type=cache,uid=0,gid=0,dst=/root/.cache/ \
	make -C /work/ venv

COPY --chown=0:0 ./requirements*.txt /work/
RUN --mount=type=cache,uid=0,gid=0,dst=/root/.cache/ \
	make -C /work/ deps

COPY --chown=0:0 ./ /work/
RUN --mount=type=cache,uid=0,gid=0,dst=/root/.cache/ \
	make -C /work/ all

##################################################
## "main" stage
##################################################

FROM base AS main

RUN --mount=type=bind,from=build,src=/work/dist/,dst=/work/dist/ \
	--mount=type=cache,uid=0,gid=0,dst=/root/.cache/ \
	python -m pip install /work/dist/*.whl

USER ${UID}:0

ENTRYPOINT ["/usr/local/bin/openapi2jsonschema"]
CMD ["--help"]
