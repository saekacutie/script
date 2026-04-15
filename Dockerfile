FROM teddysun/xray:latest
COPY config.json /etc/xray/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    mkdir -p /var/log/xray && \
    chmod -R 777 /var/log/xray
ENTRYPOINT ["/entrypoint.sh"]
