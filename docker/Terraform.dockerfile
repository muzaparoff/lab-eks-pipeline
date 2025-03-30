FROM --platform=linux/amd64 hashicorp/terraform:1.5.7

RUN apk add --no-cache \
    aws-cli \
    git \
    bash \
    curl \
    jq

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

WORKDIR /workspace

COPY docker/terraform-wrapper.sh /usr/local/bin/terraform-wrapper
RUN chmod +x /usr/local/bin/terraform-wrapper

ENTRYPOINT ["/usr/local/bin/terraform-wrapper"]
