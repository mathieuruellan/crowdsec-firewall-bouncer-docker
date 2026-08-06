FROM debian:bookworm-slim
RUN apt update && apt install -y --no-install-recommends wget ca-certificates nftables \
    && rm -rf /var/lib/apt/lists/*
RUN wget -qO /tmp/bouncer.tgz https://github.com/crowdsecurity/cs-firewall-bouncer/releases/download/v0.0.36/crowdsec-firewall-bouncer-linux-amd64.tgz \
    && tar -xzf /tmp/bouncer.tgz -C /tmp/ \
    && mv /tmp/crowdsec-firewall-bouncer-v0.0.36/crowdsec-firewall-bouncer /usr/local/bin/ \
    && rm -rf /tmp/bouncer.tgz /tmp/crowdsec-firewall-bouncer-v0.0.36
COPY config/crowdsec-firewall-bouncer.yaml /etc/crowdsec/crowdsec-firewall-bouncer.yaml
ENTRYPOINT ["crowdsec-firewall-bouncer"]
CMD ["-c", "/etc/crowdsec/crowdsec-firewall-bouncer.yaml"]
