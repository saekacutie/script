FROM teddysun/xray:latest
RUN apk update && apk add --no-cache sqlite3 curl python3 && rm -rf /var/cache/apk/*
COPY config.json /etc/xray/config.json
COPY server.py /usr/bin/server.py
COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh
EXPOSE 8080
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
