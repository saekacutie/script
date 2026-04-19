FROM teddysun/xray:latest

# Install Python for dashboard
RUN apk update && apk add --no-cache python3 sqlite3 curl && \
    rm -rf /var/cache/apk/*

# Copy Xray configuration
COPY config.json /etc/xray/config.json

# Copy dashboard server
COPY server.py /usr/bin/server.py
RUN chmod +x /usr/bin/server.py

# Entrypoint: Start dashboard on 8888, Xray on 8080
RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo 'python3 /usr/bin/server.py &' >> /entrypoint.sh && \
    echo 'exec /usr/bin/xray run -c /etc/xray/config.json' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

EXPOSE 8080 8888
ENTRYPOINT ["/entrypoint.sh"]
