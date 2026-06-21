FROM node:20-slim AS base

ARG LEGIONI_VERSION=0.5.5
ARG GH_VERSION=2.95.0

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

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
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

FROM base AS slim

FROM base AS go
RUN apt-get update && apt-get install -y golang \
    && rm -rf /var/lib/apt/lists/*

FROM base AS java
RUN apt-get update && apt-get install -y openjdk-17-jdk maven \
    && rm -rf /var/lib/apt/lists/*

FROM base AS php
RUN apt-get update && apt-get install -y php-cli php-mbstring php-xml php-curl php-zip \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && rm -rf /var/lib/apt/lists/*
