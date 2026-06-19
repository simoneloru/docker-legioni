FROM node:20-bookworm

ARG LEGIONI_VERSION=0.5.1
ARG GH_VERSION=2.95.0

RUN apt-get update && apt-get install -y \
    git \
    bash \
    curl \
    wget \
    python3 \
    python3-pip \
    python3-venv \
    default-jdk \
    maven \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --break-system-packages pytest

RUN npm install -g legioni@${LEGIONI_VERSION}

COPY package.json /tmp/build-package.json
RUN npm install -g opencode-ai@$(node -p "require('/tmp/build-package.json').devDependencies['opencode-ai']") && rm /tmp/build-package.json

RUN apt-get update && apt-get install -y \
    ca-certificates \
    gnupg \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh=${GH_VERSION} \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r dev && useradd -m -r -g dev -s /bin/bash dev

RUN mkdir -p /home/dev/.legioni /home/dev/.config/opencode/agents \
    && chown -R dev:dev /home/dev/.legioni /home/dev/.config

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER dev

RUN git config --global user.name "Dev User" \
    && git config --global user.email "dev@localhost" \
    && git config --global core.autocrlf input \
    && git config --global init.defaultBranch main

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
