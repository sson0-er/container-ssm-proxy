#!/bin/sh
socat TCP-LISTEN:${PORT},fork,reuseaddr TCP:127.0.0.1:${PORT} &
(
    while true; do
        sleep 300
        nc -z -w 5 127.0.0.1 "${PORT}" >/dev/null 2>&1
    done
) &

while true; do
    aws ssm start-session \
        --profile "${PROFILE}" \
        --region "${REGION}" \
        --target "${INSTANCE}" \
        --document-name AWS-StartPortForwardingSession \
        --parameters "portNumber=${PORT},localPortNumber=${PORT}"
    echo "session ended, reconnecting in 5s ..." >&2
    sleep 5
done
