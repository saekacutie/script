FROM teddysun/xray:latest

# Install Python and dependencies
RUN apk update && apk add --no-cache python3 sqlite3 curl && \
    rm -rf /var/cache/apk/*

# Copy Xray configuration
COPY config.json /etc/xray/config.json

# Copy dashboard server
COPY server.py /usr/bin/server.py
RUN chmod +x /usr/bin/server.py

# Ensure server.py binds to 0.0.0.0:8888
RUN sed -i "s/HTTPServer(('0.0.0.0', [0-9]*)/HTTPServer(('0.0.0.0', 8888)/g" /usr/bin/server.py || true

# Entrypoint: Start dashboard on 8888, Xray on 8080
RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo 'python3 /usr/bin/server.py &' >> /entrypoint.sh && \
    echo 'exec /usr/bin/xray run -c /etc/xray/config.json' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

EXPOSE 8080 8888
ENTRYPOINT ["/entrypoint.sh"]
