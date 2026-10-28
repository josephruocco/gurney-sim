FROM debian:bookworm-slim AS download
ARG GODOT_VERSION=4.7.2
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip && rm -rf /var/lib/apt/lists/*
RUN curl -fL --retry 3 "https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" -o /tmp/godot.zip \
    && unzip /tmp/godot.zip -d /tmp/godot \
    && mv /tmp/godot/Godot* /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates libfontconfig1 libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 libgl1 libasound2 libpulse0 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 10001 gurney
COPY --from=download /usr/local/bin/godot /usr/local/bin/godot
WORKDIR /app
COPY --chown=gurney:gurney project.godot server.gd ./
USER gurney
ENV PORT=10000
EXPOSE 10000
CMD ["godot", "--headless", "--path", "/app", "--script", "res://server.gd"]
