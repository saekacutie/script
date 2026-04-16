FROM teddysun/xray:latest

# Ensure correct workspace
WORKDIR /etc/xray

# Copy your configuration and startup script
COPY config.json /etc/xray/config.json
COPY entrypoint.sh /entrypoint.sh

# Fix permissions for the startup script
RUN chmod +x /entrypoint.sh

# Run as a background-ready service
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
