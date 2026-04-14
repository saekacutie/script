#!/bin/sh
/health &
/usr/bin/xray run -c /etc/xray/config.json
