FROM teddysun/xray:latest
COPY config.json /etc/xray/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
# Critical: Do not call xray directly; call the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]
