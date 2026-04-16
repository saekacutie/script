FROM teddysun/xray:latest

# Set working directory
WORKDIR /etc/xray

# Copy your local files into the image
COPY config.json /etc/xray/config.json
COPY entrypoint.sh /entrypoint.sh

# Fix permissions
RUN chmod +x /entrypoint.sh

# Launch using the shell script
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
