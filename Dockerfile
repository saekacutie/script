FROM teddysun/xray:latest
COPY config.json /etc/xray/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
# Critical: Use the entrypoint to map the port correctly
ENTRYPOINT ["/entrypoint.sh"]
