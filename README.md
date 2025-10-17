# Apache Guacamole Multi-Version Container

A single, self-contained Docker image supporting Apache Guacamole versions 1.5.2, 1.5.5, and 1.6.0 with embedded or external guacd.

## Key Features

- **Single Container** - No docker-compose, no external config files
- **Multi-Version** - Choose version at runtime (1.5.2, 1.5.5, 1.6.0)
- **Embedded guacd** - Optional built-in guacd for standalone operation
- **External guacd** - Or connect to existing guacd server
- **Environment-Driven** - All configuration via environment variables
- **Alpine-Based** - Small, efficient image (~400-500MB)
- **Clear Help** - Built-in usage documentation

## Quick Start

### SSH Connection with Embedded guacd

```bash
docker run -d --name vanilla-guacamole-1 -p 8080:8080 \
  -e GUACAMOLE_VERSION=1.5.5 \
  -e USE_EMBEDDED_GUACD=true \
  -e TARGET_PROTOCOL=ssh \
  -e TARGET_HOST=192.168.1.100 \
  -e TARGET_PORT=22 \
  -e TARGET_USER=ubuntu \
  -e TARGET_PASSWORD=secret \
  cyolosec/vanilla-guacamole:latest
```

Then access: **http://localhost:8080**

**Login:** `admin` / `admin`

### RDP Connection with External guacd

```bash
docker run -d --name vanilla-guacamole-1 -p 8080:8080 \
  -e GUACAMOLE_VERSION=1.5.5 \
  -e USE_EMBEDDED_GUACD=false \
  -e GUACD_HOST=192.168.1.50 \
  -e GUACD_PORT=4822 \
  -e TARGET_PROTOCOL=rdp \
  -e TARGET_HOST=192.168.1.200 \
  -e TARGET_PORT=3389 \
  -e TARGET_USER=Administrator \
  -e TARGET_PASSWORD=winpass \
  cyolosec/vanilla-guacamole:latest
```

**Login:** `admin` / `admin`

### View Help

```bash
docker run --rm cyolosec/vanilla-guacamole:latest --help
```

## Connecting to Cyolo IDAC Production guacd

When using Vanilla Guacamole with a production guacd instance launched by Cyolo IDAC, you'll need to ensure proper network connectivity between the containers.

### Setup Steps

1. **Create a Docker bridge network** (if not already exists):
   ```bash
   docker network create guacamole-net
   ```

2. **Connect your existing IDAC guacd container to the network**:
   ```bash
   docker network connect guacamole-net <guacd-container-name>
   ```
   
   For example, if your guacd container is named `guacd_1`:
   ```bash
   docker network connect guacamole-net guacd_1
   ```

3. **Run Vanilla Guacamole on the same network**:
   ```bash
   docker run --rm \
     --name vanilla-guacamole-1 \
     --network guacamole-net \
     -p 8080:8080 \
     -e GUACAMOLE_VERSION=1.5.5 \
     -e USE_EMBEDDED_GUACD=false \
     -e GUACD_HOST=guacd_1 \
     -e GUACD_PORT=4822 \
     -e TARGET_PROTOCOL=ssh \
     -e TARGET_HOST=your-target-server \
     -e TARGET_PORT=22 \
     -e TARGET_USER=ubuntu \
     -e TARGET_PASSWORD=your-password \
     cyolosec/vanilla-guacamole:latest
   ```

   **Key points:**
   - Use `--network guacamole-net` to place Vanilla Guacamole on the same network
   - Set `GUACD_HOST` to the name of your guacd container (Docker's DNS will resolve it)
   - Use `-p 8080:8080` to expose the web interface

4. **Access the Guacamole web interface**:
   - Open browser to: `http://<host-ip>:8080`
   - Login with: `admin` / `admin`

### Cleanup

When you're done, disconnect the guacd container from the network:

```bash
# Stop Vanilla Guacamole (if using --rm, it auto-removes)
docker stop vanilla-guacamole-1

# Disconnect guacd from the network
docker network disconnect guacamole-net guacd_1

# Optional: Remove the network (only if no other containers are using it)
docker network rm guacamole-net
```

### Checking Network Connectivity

To verify containers are on the same network:

```bash
# List all containers on the network
docker network inspect guacamole-net

# Test connectivity from Vanilla Guacamole to guacd
docker exec vanilla-guacamole-1 ping -c 2 guacd_1
```

## Environment Variables

### Required

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `GUACAMOLE_VERSION` | Guacamole version | `1.5.2`, `1.5.5`, `1.6.0` |
| `USE_EMBEDDED_GUACD` | Use built-in guacd | `true`, `false` |
| `TARGET_PROTOCOL` | Connection protocol | `ssh`, `rdp`, `vnc` |
| `TARGET_HOST` | Target server IP/hostname | `192.168.1.100` |
| `TARGET_PORT` | Target server port | `22`, `3389`, `5901` |
| `TARGET_USER` | Username for target (optional for VNC) | `ubuntu`, `Administrator` |
| `TARGET_PASSWORD` | Password for target server | `your-password` |

**Note:** Guacamole web UI uses fixed credentials: **`admin`** / **`admin`**

### Conditional (when USE_EMBEDDED_GUACD=false)

| Variable | Description | Default |
|----------|-------------|---------|
| `GUACD_HOST` | External guacd hostname/IP | - |
| `GUACD_PORT` | External guacd port | `4822` |

### Protocol-Specific Optional Parameters

#### RDP Parameters

| Variable | Description | Possible Values | Default | Notes |
|----------|-------------|-----------------|---------|-------|
| `IGNORE_CERT` | Ignore SSL certificate errors | `true`, `false` | `true` | Bypass certificate validation |
| `ENABLE_DRIVE` | Enable drive redirection | `true`, `false` | `false` | Share local drive with RDP session |
| `DRIVE_PATH` | Path for drive redirection | Any path | `/tmp/guac-drive` | Must exist in container |
| `RDP_DOMAIN` | Windows domain | Any string | - | e.g., `MYCOMPANY` |
| `RDP_SERVER_LAYOUT` | Keyboard layout | `en-us-qwerty`, `de-de-qwertz`, etc. | - | See [Guacamole docs](https://guacamole.apache.org/doc/gug/configuring-guacamole.html#rdp) |
| `RDP_SECURITY` | Security mode | `any`, `nla`, `tls`, `rdp`, `vmconnect` | `any` | Authentication security |
| `RDP_DISABLE_AUTH` | Bypass authentication | `true`, `false` | - | For auto-login scenarios |
| `RDP_RESIZE_METHOD` | Display resize method | `display-update`, `reconnect` | - | How to handle resolution changes |
| `RDP_CONSOLE` | Admin/console session | `true`, `false` | - | Connect to console session |

**RDP Example:**
```bash
docker run -d -p 8080:8080 \
  -e GUACAMOLE_VERSION=1.5.5 \
  -e USE_EMBEDDED_GUACD=true \
  -e TARGET_PROTOCOL=rdp \
  -e TARGET_HOST=windows-server \
  -e TARGET_PORT=3389 \
  -e TARGET_USER=Administrator \
  -e TARGET_PASSWORD=password \
  -e RDP_DOMAIN=CORP \
  -e RDP_SERVER_LAYOUT=en-us-qwerty \
  -e RDP_SECURITY=nla \
  cyolosec/vanilla-guacamole:latest
```

#### VNC Parameters

| Variable | Description | Possible Values | Notes |
|----------|-------------|-----------------|-------|
| `VNC_COLOR_DEPTH` | Color depth | `8`, `16`, `24`, `32` | Higher = better quality, more bandwidth |
| `VNC_CURSOR` | Cursor rendering | `local`, `remote` | `local` recommended for performance |
| `VNC_READ_ONLY` | View-only mode | `true`, `false` | Disable keyboard/mouse input |
| `VNC_DISABLE_DISPLAY_RESIZE` | Prevent auto-resize | `true`, `false` | Lock display size |

**Note:** `TARGET_USER` is **optional** for VNC (VNC only requires password)

**VNC Example:**
```bash
docker run -d -p 8080:8080 \
  -e GUACAMOLE_VERSION=1.5.5 \
  -e USE_EMBEDDED_GUACD=true \
  -e TARGET_PROTOCOL=vnc \
  -e TARGET_HOST=vnc-server \
  -e TARGET_PORT=5900 \
  -e TARGET_PASSWORD=vncpass \
  -e VNC_COLOR_DEPTH=24 \
  -e VNC_CURSOR=local \
  cyolosec/vanilla-guacamole:latest
```

#### SSH Parameters

| Variable | Description | Possible Values | Notes |
|----------|-------------|-----------------|-------|
| `SSH_FONT_SIZE` | Terminal font size | Any integer | e.g., `12`, `14`, `16` |
| `SSH_COLOR_SCHEME` | Terminal color scheme | `black-white`, `white-black`, `gray-black`, `green-black`, `blue-black` | Light/dark themes |
| `SSH_SCROLLBACK` | Scrollback buffer size | Any integer | e.g., `1024`, `2048` (lines) |

**SSH Example:**
```bash
docker run -d -p 8080:8080 \
  -e GUACAMOLE_VERSION=1.5.5 \
  -e USE_EMBEDDED_GUACD=true \
  -e TARGET_PROTOCOL=ssh \
  -e TARGET_HOST=linux-server \
  -e TARGET_PORT=22 \
  -e TARGET_USER=ubuntu \
  -e TARGET_PASSWORD=password \
  -e SSH_FONT_SIZE=14 \
  -e SSH_COLOR_SCHEME=black-white \
  -e SSH_SCROLLBACK=2048 \
  cyolosec/vanilla-guacamole:latest
```

### Parameter Validation

The container validates parameters at startup and will exit with an error if invalid values are provided:

**RDP Security Validation:**
- Valid: `any`, `nla`, `tls`, `rdp`, `vmconnect`
- Invalid: Any other value

**RDP Resize Method Validation:**
- Valid: `display-update`, `reconnect`  
- Invalid: Any other value

**VNC Color Depth Validation:**
- Valid: `8`, `16`, `24`, `32`
- Invalid: Any other number

**VNC Cursor Validation:**
- Valid: `local`, `remote`
- Invalid: Any other value

**Boolean Parameters:**
- Valid: `true`, `false`
- Invalid: Any other value (yes/no, 1/0, etc. are NOT accepted)
- Applies to: `RDP_DISABLE_AUTH`, `RDP_CONSOLE`, `VNC_READ_ONLY`, `VNC_DISABLE_DISPLAY_RESIZE`

**Example validation error:**
```bash
docker run ... -e RDP_SECURITY=invalid ...
# Output: ERROR: RDP_SECURITY must be one of: any, nla, tls, rdp, vmconnect
```

## Examples

### VNC Connection

```bash
docker run -d -p 8080:8080 \
  -e GUACAMOLE_VERSION=1.5.5 \
  -e USE_EMBEDDED_GUACD=true \
  -e TARGET_PROTOCOL=vnc \
  -e TARGET_HOST=192.168.1.150 \
  -e TARGET_PORT=5901 \
  -e TARGET_USER=vncuser \
  -e TARGET_PASSWORD=vncpass \
  cyolosec/vanilla-guacamole:latest
```

### RDP with Drive Redirection

```bash
docker run -d -p 8080:8080 \
  -e GUACAMOLE_VERSION=1.6.0 \
  -e USE_EMBEDDED_GUACD=true \
  -e TARGET_PROTOCOL=rdp \
  -e TARGET_HOST=windows-server \
  -e TARGET_PORT=3389 \
  -e TARGET_USER=Administrator \
  -e TARGET_PASSWORD=password \
  -e ENABLE_DRIVE=true \
  -e DRIVE_PATH=/tmp/shared \
  cyolosec/vanilla-guacamole:latest
```

### Using Different Guacamole Versions

```bash
# Test with version 1.5.2
docker run -d -p 8080:8080 \
  -e GUACAMOLE_VERSION=1.5.2 \
  -e USE_EMBEDDED_GUACD=true \
  -e TARGET_PROTOCOL=ssh \
  -e TARGET_HOST=server.example.com \
  -e TARGET_PORT=22 \
  -e TARGET_USER=user \
  -e TARGET_PASSWORD=password \
  cyolosec/vanilla-guacamole:latest

# Or use version 1.6.0
docker run -d -p 8080:8080 \
  -e GUACAMOLE_VERSION=1.6.0 \
  ...
```

## Building the Image

```bash
# Clone the repository
git clone https://github.com/your-repo/vanilla-guacamole.git
cd vanilla-guacamole

# Build
docker build -t vanilla-guacamole .

# Run
docker run -d -p 8080:8080 \
  -e GUACAMOLE_VERSION=1.5.5 \
  -e USE_EMBEDDED_GUACD=true \
  -e TARGET_PROTOCOL=ssh \
  -e TARGET_HOST=192.168.1.100 \
  -e TARGET_PORT=22 \
  -e TARGET_USER=ubuntu \
  -e TARGET_PASSWORD=password \
  vanilla-guacamole
```

## Container Management

```bash
# View logs
docker logs -f <container-id>

# Stop container
docker stop <container-id>

# Remove container
docker rm <container-id>

# Restart with different settings
docker stop <container-id>
docker rm <container-id>
docker run -d -p 8080:8080 \
  -e GUACAMOLE_VERSION=1.6.0 \
  ...
```

## Architecture

### Base Image
- **Alpine Linux 3.18.5** - Minimal, secure base (~5MB) - matches guacd image version

### Components
- **OpenJDK 11** - Java runtime from Alpine packages
- **Apache Tomcat 9.0.93** - Servlet container
- **guacd 1.5.2, 1.5.5, 1.6.0** - All three versions included
- **Supervisor** - Process manager for embedded guacd mode

### Structure
```
/opt/
├── tomcat/                    # Apache Tomcat
├── guacamole-wars/
│   ├── guacamole-1.5.2.war
│   ├── guacamole-1.5.5.war
│   └── guacamole-1.6.0.war
├── guacd-1.5.2/               # guacd binaries and libs
├── guacd-1.5.5/
├── guacd-1.6.0/
└── start-guacamole.sh         # Startup script

/etc/guacamole/
├── guacamole.properties       # Generated at startup
└── user-mapping.xml           # Generated from env vars
```

### Startup Process

1. **Validate** environment variables
2. **Select** Guacamole version and matching guacd
3. **Deploy** selected WAR to Tomcat
4. **Generate** guacamole.properties
5. **Generate** user-mapping.xml from env vars
6. **Start** guacd (if embedded) + Tomcat via supervisor

## Technical Details

- **Java**: OpenJDK 11 (Alpine package)
- **Tomcat**: 9.0.93
- **Guacamole**: 1.5.2, 1.5.5, 1.6.0
- **guacd**: 1.5.2, 1.5.5, 1.6.0 (from official guacamole/guacd images)
- **Supervisor**: For process management in embedded mode
- **Image Size**: ~400-500MB
- **Ports**: 8080 (Guacamole web), 4822 (guacd, internal only in embedded mode)

## Troubleshooting

### Container won't start

```bash
# Check logs for error messages
docker logs <container-id>

# Verify all required env vars are set
docker run --rm cyolosec/vanilla-guacamole:latest --help
```

### Cannot connect to target server

```bash
# Test from container
docker exec <container-id> ping TARGET_HOST

# Check if target port is accessible
docker exec <container-id> nc -zv TARGET_HOST TARGET_PORT
```

### guacd connection issues

```bash
# Check guacd is running (embedded mode)
docker exec <container-id> ps aux | grep guacd

# Check guacd logs
docker exec <container-id> cat /var/log/supervisor/guacd.log
```

### External guacd not reachable

```bash
# Test from container
docker exec <container-id> nc -zv GUACD_HOST GUACD_PORT
```

## License

Apache Guacamole is licensed under the Apache License 2.0.

## References

- [Apache Guacamole Documentation](https://guacamole.apache.org/doc/gug/)
- [Guacamole Protocol Reference](https://guacamole.apache.org/doc/gug/guacamole-protocol.html)
- [Connection Configuration](https://guacamole.apache.org/doc/gug/configuring-guacamole.html)
