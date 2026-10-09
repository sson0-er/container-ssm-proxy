# ssm-proxy

A container that keeps an AWS SSM Session Manager port-forwarding session running on [Apple Container](https://github.com/apple/container).
If the session drops, it reconnects automatically after 5 seconds.

> [!NOTE]
> This image is for Apple Container (Apple Silicon Mac) only. It bundles the arm64 build of session-manager-plugin.

## How it works

```
Mac ──TCP:PORT──▶ [container] socat ──▶ 127.0.0.1:PORT ──SSM──▶ EC2 (INSTANCE):PORT
```

- `aws ssm start-session` (`AWS-StartPortForwardingSession`) listens on `127.0.0.1:PORT` inside the container.
- `socat` accepts connections from outside the container and relays them to that port.
- Every 5 minutes, a connection is made to the local port to prevent the session from being closed due to idleness.

## Environment variables

| Variable | Description | Example |
| --- | --- | --- |
| `PROFILE` | AWS profile name | `my-profile` |
| `REGION` | AWS region | `us-east-1` |
| `INSTANCE` | Target EC2 instance ID | `i-0123456789abcdef0` |
| `PORT` | Port to forward (same on remote and local) | `8080` |

## Build

```sh
container build --no-cache -t ssm-proxy .
```

## Run

### With an SSO profile

Log in on the host first:

```sh
aws sso login --profile my-profile
```

```sh
container run --rm --name ssm-proxy \
  -v ~/.aws:/root/.aws-mounted:ro \
  -v ~/.aws/sso:/root/.aws/sso \
  -e AWS_CONFIG_FILE=/root/.aws-mounted/config \
  -e PROFILE=my-profile \
  -e REGION=us-east-1 \
  -e INSTANCE=i-0123456789abcdef0 \
  -e PORT=8080 \
  ssm-proxy
```

- `~/.aws` is mounted read-only, and only `config` is referenced via `AWS_CONFIG_FILE`.
- `~/.aws/sso` is mounted writable because the CLI updates the SSO token cache (`sso/cache`).

### With an access key profile (non-SSO)

```sh
container run --rm --name ssm-proxy \
  -v ~/.aws:/root/.aws:ro \
  -e PROFILE=my-profile \
  -e REGION=us-east-1 \
  -e INSTANCE=i-0123456789abcdef0 \
  -e PORT=8080 \
  ssm-proxy
```

- `~/.aws/config` and `~/.aws/credentials` are read from a read-only mount.

## Connect

Find the container's IP address and connect to `PORT`:

```sh
container ls
curl http://<container-ip>:8080/
```

## Stop

```sh
container stop ssm-proxy
```
