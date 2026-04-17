# inotify-scp

A small container image that watches a directory for new/modified files and ships them off to a remote host via `scp`, deleting the local copy on success.

Built on top of [`devodev/inotify`](https://hub.docker.com/r/devodev/inotify), with `openssh-client` layered in and a script (`send.sh`) wired up as the inotify handler.

## How it works

The base `devodev/inotify` image runs `inotifywait` against a watched directory and invokes `$INOTIFY_SCRIPT` for each event. This image sets `INOTIFY_SCRIPT=/send.sh`, which:

1. Checks that the changed file still exists (filters out transient events).
2. Runs `scp -i $IDENTITY_FILE <file> $DESTINATION`.
3. On success, removes the local file. On failure, leaves it in place and exits non-zero.

## Environment variables

| Variable        | Purpose                                                                  |
| --------------- | ------------------------------------------------------------------------ |
| `IDENTITY_FILE` | Path (inside the container) to the SSH private key used by `scp`.       |
| `DESTINATION`   | `scp` destination, e.g. `user@host:/remote/path/`.                       |

Plus whatever variables the upstream `devodev/inotify` base supports to configure the watched directory and events (see its docs).

## Usage

```bash
docker run -d \
  --name inotify-scp \
  -v /local/outbox:/watch \
  -v /path/to/key:/keys/id_rsa:ro \
  -e IDENTITY_FILE=/keys/id_rsa \
  -e DESTINATION=user@remote.host:/inbox/ \
  ghcr.io/samsonnguyen/inotify-scp:latest
```

Drop a file into `/local/outbox` and it will be copied to `remote.host:/inbox/` and removed locally.

### SSH host keys

`scp` will refuse to connect to an unknown host. Either pre-populate `~/.ssh/known_hosts` inside the container, mount one in, or add `StrictHostKeyChecking=no` to the `scp` call in `send.sh` if you know what you're doing.

## Building locally

```bash
docker build -t inotify-scp .
```

## Releases

Images are published to GHCR by the `build` GitHub Actions workflow on every push to `main` and on version tags (`v*`):

- `ghcr.io/samsonnguyen/inotify-scp:latest` — latest `main`
- `ghcr.io/samsonnguyen/inotify-scp:<tag>` — tagged release
