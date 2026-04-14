FROM teddysun/xray:latest

# Copy the configuration file
COPY config.json /etc/xray/config.json

# Build the startup script internally to prevent formatting crashes
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'PORT=${PORT:-8080}' >> /start.sh && \
    echo 'sed -i "s/10000/$PORT/g" /etc/xray/config.json' >> /start.sh && \
    echo 'exec /usr/bin/xray run -c /etc/xray/config.json' >> /start.sh && \
    chmod +x /start.sh

# Start the container
ENTRYPOINT ["/start.sh"]
