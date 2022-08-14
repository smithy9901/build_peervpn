FROM ubuntu:18.04 AS stage1
ARG REPO_NAME
WORKDIR /app/peervpn
COPY peervpn/ .

RUN apt-get update \
    && apt install -y libssl1.0-dev build-essential zlib1g-dev gettext-base

RUN make

WORKDIR /app/deb
COPY ${REPO_NAME}/template/ .

RUN mkdir -p \
    package/DEBIAN \
    package/usr/local/bin

RUN mv /app/peervpn/peervpn /app/deb/package/usr/local/bin

RUN export SIZE=$(du /app/deb/package/usr/local/bin/peervpn | awk '{print $1}') \
    && export APP_VERSION=$(/app/deb/package/usr/local/bin/peervpn | head -n1 | awk '{print $2}' | cut -c2-) \
    && envsubst < /app/deb/control.template > /app/deb/package/DEBIAN/control

RUN dpkg-deb --build ./package


FROM scratch AS export-stage
COPY --from=stage1 /app/deb/package.deb ./peervpn.deb
