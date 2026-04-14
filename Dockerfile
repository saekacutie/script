FROM teddysun/xray:latest
COPY config.json /etc/xray/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
# Critical: Launch via the entrypoint script to fix the port
ENTRYPOINT ["/entrypoint.sh"]
