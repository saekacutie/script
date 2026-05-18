FROM teddysun/xray:latest
RUN apk add --no-cache python3 curl
COPY config.json /etc/xray/config.json
COPY entrypoint.sh /entrypoint.sh
COPY server.py /server.py
RUN chmod +x /entrypoint.sh /server.py
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
