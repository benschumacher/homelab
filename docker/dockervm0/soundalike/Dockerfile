FROM debian:bookworm-slim

ARG SOUNDALIKE_VERSION=0.1.2
ENV SOUNDALIKE_VERSION=${SOUNDALIKE_VERSION}

# Install dependencies
RUN    set -ex \
    && apt update \
    && apt install -y \
    	ca-certificates \
	curl \
    	libchromaprint-tools \
	wget \
	unzip \
    && rm -rf /var/lib/apt/lists/*

# Create directory for audio files
RUN mkdir -p /audio

# Get soundalike binary (option 1 - prebuilt)
# The following is for Linux amd64 - adjust URL for other platforms if needed
RUN    set -ex \
    && mkdir -p /opt/soundalike \
    && curl -o /opt/soundalike.tar.gz \
    	-L https://codeberg.org/derat/soundalike/releases/download/v${SOUNDALIKE_VERSION}/soundalike-${SOUNDALIKE_VERSION}-linux-amd64.tar.gz \
    && tar -xvzf /opt/soundalike.tar.gz -C /opt/soundalike \
    && chmod +x /opt/soundalike/soundalike \
    && ln -nsf /opt/soundalike/soundalike /usr/local/bin/soundalike

# Create directory to store fingerprint database
RUN mkdir -p /data

# Set the working directory
WORKDIR /audio

# Create an entrypoint script that provides usage help
COPY start.sh /usr/local/bin/start.sh
RUN    set -ex \
    && chmod +x /usr/local/bin/start.sh

# Set volume mount points
VOLUME ["/audio", "/data"]
WORKDIR "/audio"

ENTRYPOINT ["/usr/local/bin/start.sh"]
