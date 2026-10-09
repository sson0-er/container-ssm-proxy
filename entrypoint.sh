#!/bin/sh
case "${PORT}" in
    ''|*[!0-9]*) echo "PORT must be a number: '${PORT}'" >&2; exit 1 ;;
esac
# socat listens on all interfaces including loopback, so the plugin must bind a
# different port; otherwise socat forwards to itself and forks until OOM.
if [ "${PORT}" -le 55535 ]; then
    LOCAL_PORT=$((PORT + 10000))
else
    LOCAL_PORT=$((PORT - 10000))
fi

socat TCP-LISTEN:${PORT},fork,reuseaddr TCP:127.0.0.1:${LOCAL_PORT} &
(
    while true; do
        sleep 300
        nc -z -w 5 127.0.0.1 "${LOCAL_PORT}" >/dev/null 2>&1
    done
) &

while true; do
    aws ssm start-session \
        --profile "${PROFILE}" \
        --region "${REGION}" \
        --target "${INSTANCE}" \
        --document-name AWS-StartPortForwardingSession \
        --parameters "portNumber=${PORT},localPortNumber=${LOCAL_PORT}"
    echo "session ended, reconnecting in 5s ..." >&2
    sleep 5
done
