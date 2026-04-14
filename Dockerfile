FROM teddysun/xray:latest
COPY config.json /etc/xray/config.json
# Xray image runs automatically on port 8080 based on the config above
