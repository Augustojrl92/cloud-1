FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    git \
    python3 \
    python3-pip \
    openssh-client \
    ca-certificates \
    gnupg \
    lsb-release \
    make \
    && rm -rf /var/lib/apt/lists/*

# Ansible
RUN python3 -m pip install --no-cache-dir ansible

# Terraform
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && apt-get install -y terraform \
    && rm -rf /var/lib/apt/lists/*

# Google Cloud CLI
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] \
    https://packages.cloud.google.com/apt cloud-sdk main" \
    > /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && apt-get update \
    && apt-get install -y google-cloud-cli \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["/bin/bash"]
