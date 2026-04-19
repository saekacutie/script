FROM teddysun/xray:latest

# Install Python and dependencies for dashboard
RUN apk update && apk add --no-cache python3 sqlite3 curl && \
    rm -rf /var/cache/apk/*

# Copy Xray configuration
COPY config.json /etc/xray/config.json

# Copy dashboard server
COPY server.py /usr/bin/server.py
RUN chmod +x /usr/bin/server.py

# Create entrypoint script that starts BOTH services
RUN cat > /entrypoint.sh <<'EOF'
#!/bin/sh
# Start dashboard on port 8888
python3 /usr/bin/server.py &
# Start Xray on port 8080
exec /usr/bin/xray run -c /etc/xray/config.json
EOF

RUN chmod +x /entrypoint.sh

EXPOSE 8080 8888
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
