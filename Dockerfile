FROM teddysun/xray:latest

RUN apk add --no-cache python3 sqlite curl

COPY config.json /etc/xray/config.json
COPY entrypoint.sh /entrypoint.sh
COPY server.py /server.py
COPY log-user.sh /log-user.sh
COPY network-monitor.sh /network-monitor.sh
COPY ip-manager.sh /ip-manager.sh

RUN chmod +x /entrypoint.sh
RUN chmod +x /server.py
RUN chmod +x /log-user.sh
RUN chmod +x /network-monitor.sh
RUN chmod +x /ip-manager.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
