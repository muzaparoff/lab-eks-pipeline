FROM --platform=linux/amd64 hashicorp/terraform:1.5.7

RUN apk add --no-cache \
    aws-cli \
    git \
    bash \
    curl \
    jq

# Install kubectl with proper permissions and verification
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" && \
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum -c && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl kubectl.sha256

WORKDIR /workspace

COPY docker/terraform-wrapper.sh /usr/local/bin/terraform-wrapper
RUN chmod +x /usr/local/bin/terraform-wrapper

ENTRYPOINT ["/usr/local/bin/terraform-wrapper"]
