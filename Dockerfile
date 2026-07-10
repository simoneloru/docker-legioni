FROM node:26-slim AS base

ARG LEGIONI_VERSION=0.6.0
ARG GH_VERSION=2.96.0

RUN apt-get update && apt-get install -y \
    git \
    bash \
    curl \
    wget \
    ca-certificates \
    gnupg \
    sudo \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --break-system-packages pytest

RUN npm install -g legioni@${LEGIONI_VERSION}

COPY package.json /tmp/build-package.json
RUN OPENCODE_VER=$(node -p "require('/tmp/build-package.json').devDependencies['opencode-ai']") \
    && ARCH=$(uname -m | sed 's/x86_64/x64/;s/aarch64/arm64/') \
    && curl -fsSL "https://github.com/anomalyco/opencode/releases/download/v${OPENCODE_VER}/opencode-linux-${ARCH}.tar.gz" \
       -o /tmp/opencode.tar.gz \
    && tar -xzf /tmp/opencode.tar.gz -C /usr/local/bin \
    && chmod 755 /usr/local/bin/opencode \
    && rm /tmp/opencode.tar.gz /tmp/build-package.json

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh=${GH_VERSION} \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1001 dev && useradd --uid 1001 --gid 1001 -m -s /bin/bash dev \
    && echo "dev ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev

RUN mkdir -p /home/dev/.legioni /home/dev/.config/opencode/agents \
    && chown -R dev:dev /home/dev/.legioni /home/dev/.config

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV GIT_CONFIG_GLOBAL=/home/dev/.config/.gitconfig

RUN su dev -c "git config --global user.name 'Dev User' \
    && git config --global user.email 'dev@localhost' \
    && git config --global core.autocrlf input \
    && git config --global init.defaultBranch main"

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

FROM base AS dev

FROM base AS go
ARG GO_VERSION=1.26.3
RUN curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

FROM base AS java
ARG JAVA_VERSION=21
RUN apt-get update && apt-get install -y maven \
    && wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor -o /usr/share/keyrings/adoptium.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb bookworm main" > /etc/apt/sources.list.d/adoptium.list \
    && apt-get update && apt-get install -y temurin-${JAVA_VERSION}-jdk \
    && rm -rf /var/lib/apt/lists/*

FROM base AS php
ARG PHP_VERSION=8.3
RUN apt-get update && apt-get install -y lsb-release curl \
    && curl -sSLo /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
    && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list \
    && apt-get update && apt-get install -y php${PHP_VERSION}-cli php${PHP_VERSION}-mbstring php${PHP_VERSION}-xml php${PHP_VERSION}-curl php${PHP_VERSION}-zip php${PHP_VERSION}-mysql php${PHP_VERSION}-gd php${PHP_VERSION}-bcmath php${PHP_VERSION}-opcache \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && rm -rf /var/lib/apt/lists/*
