##################################################
## "base" stage
##################################################

FROM docker.io/python:3.14-slim-trixie@sha256:486b8092bfb12997e10d4920897213a06563449c951c5506c2a2cfaf591c599f AS base

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
