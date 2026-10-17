# Builds the Flutter web app and serves it with nginx.
#
# Two stages, because the Flutter SDK is 1.5 GB and the runtime is 25 MB. Only
# the second stage ends up in the deployed image.
#
# The SDK install is deliberately its own early layer: Render caches Docker
# layers between builds, so the 1.5 GB download happens once and later deploys
# only rebuild from the source copy downwards.

# ---------------------------------------------------------------- build stage
FROM debian:bookworm-slim AS build

# Pinned to the exact version this project was developed and tested against.
# Bumping Flutter should be a deliberate commit, not whatever the build machine
# happened to have.
ARG FLUTTER_VERSION=3.47.7

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      unzip \
      xz-utils \
 && rm -rf /var/lib/apt/lists/*

# Flutter is a git checkout, and git refuses to touch a repository owned by a
# different user — which is exactly what happens inside a container. Without
# this, every flutter command fails with "detected dubious ownership".
RUN git config --global --add safe.directory /opt/flutter

RUN curl -fsSL \
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
      -o /tmp/flutter.tar.xz \
 && tar -xJf /tmp/flutter.tar.xz -C /opt \
 && rm /tmp/flutter.tar.xz

ENV PATH="/opt/flutter/bin:${PATH}"

# Downloads the Dart SDK and the web engine. Baked into this layer so it is not
# repeated on every build.
RUN flutter --version && flutter precache --web

WORKDIR /app

# Manifests first, on their own, so dependency resolution is cached separately
# from the source. Editing lib/ then does not re-resolve the whole package set.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# --no-wasm-dry-run: the wasm dry run only reports warnings from flutter_tts's
# web implementation and adds a minute to every build.
RUN flutter build web --release --no-wasm-dry-run

# ---------------------------------------------------------------- serve stage
FROM nginx:alpine

# Render assigns the port through the PORT variable, defaulting to 10000.
# nginx's entrypoint runs envsubst over /etc/nginx/templates, but by default it
# substitutes *every* variable — which would destroy nginx's own $uri and $host.
# The filter limits substitution to PORT only.
ENV NGINX_ENVSUBST_FILTER=PORT

COPY deploy/nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 10000

CMD ["nginx", "-g", "daemon off;"]
