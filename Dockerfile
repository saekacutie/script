FROM teddysun/xray:latest
RUN apk update && apk add --no-cache sqlite3 curl && rm -rf /var/cache/apk/*
COPY config.json /etc/xray/config.json
COPY log-user.sh /usr/bin/log-user.sh
RUN chmod +x /usr/bin/log-user.sh
EXPOSE 8080
ENTRYPOINT ["/usr/bin/xray", "run", "-c", "/etc/xray/config.json"]
