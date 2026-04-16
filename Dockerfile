FROM teddysun/xray:latest

# Switch to root to set up permissions
USER root

# Create directory just in case
RUN mkdir -p /etc/xray

# Copy your files
COPY config.json /etc/xray/config.json
COPY entrypoint.sh /entrypoint.sh

# CRITICAL: Fix permissions so the container can start
RUN chmod +x /entrypoint.sh && \
    chown -R nobody:nobody /etc/xray && \
    chmod -R 777 /etc/xray

# Start as root to allow the port-swap script to run, 
# then it will launch Xray
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
