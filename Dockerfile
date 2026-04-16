FROM teddysun/xray:latest
COPY config.json /etc/xray/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
# Entrypoint handles the port mapping and startup
ENTRYPOINT ["/entrypoint.sh"]
