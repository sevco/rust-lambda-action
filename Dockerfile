FROM ekidd/rust-musl-builder:1.51.0

USER root

ENV CARGO_HOME=/opt/rust/cargo

RUN mkdir -p /github
RUN useradd -m -d /github/home -u 1001 github

RUN apt-get update --yes \
    && apt-get install --yes --no-install-recommends \
    git \
    jq \
    zip \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN echo '\n[net] \n\
    git-fetch-with-cli = true' >> /opt/rust/cargo/config


ADD lambda.sh cleanup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/lambda.sh && \
    chmod +x /usr/local/bin/cleanup.sh 

USER github
WORKDIR /github/home

ENTRYPOINT ["/usr/local/bin/lambda.sh"]
