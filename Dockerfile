FROM teddysun/xray:latest                    # ← Xray binary is here (/usr/bin/xray)
RUN apk update && apk add --no-cache sqlite3 curl && rm -rf /var/cache/apk/*
COPY config.json /etc/xray/config.json        # ← Xray config
COPY log-user.sh /usr/bin/log-user.sh         # ← Optional logging script
RUN chmod +x /usr/bin/log-user.sh
EXPOSE 8080
ENTRYPOINT ["/usr/bin/xray", "run", "-c", "/etc/xray/config.json"]  # ← Starts Xray
