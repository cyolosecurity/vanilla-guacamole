# Apache Guacamole Multi-Version Container

A single, self-contained Docker image supporting Apache Guacamole versions 1.5.2, 1.5.5, and 1.6.0 with embedded or external guacd.

## Key Features

- 🎯 **Single Container** - No docker-compose, no external config files
- 🔄 **Multi-Version** - Choose version at runtime (1.5.2, 1.5.5, 1.6.0)
- 📦 **Embedded guacd** - Optional built-in guacd for standalone operation
- 🔌 **External guacd** - Or connect to existing guacd server
- ⚙️ **Environment-Driven** - All configuration via environment variables
- 🏔️ **Alpine-Based** - Small, efficient image (~400-500MB)
- 📝 **Clear Help** - Built-in usage documentation

## Quick Start

### SSH Connection with Embedded guacd

```bash
docker run -d -p 8080:8080 \
  -e GUACAMOLE_VERSION=1.5.5 \
  -e USE_EMBEDDED_GUACD=true \
  -e TARGET_PROTOCOL=ssh \
  -e TARGET_HOST=192.168.1.100 \
  -e TARGET_PORT=22 \
  -e TARGET_USER=ubuntu \
  -e TARGET_PASSWORD=secret \
  guacamole-client
```

Then access: **http://localhost:8080**

**Login:** `admin` / `admin`

### RDP Connection with External guacd

```bash
docker run -d -p 8080:8080 \
  -e GUACAMOLE_VERSION=1.5.5 \
  -e USE_EMBEDDED_GUACD=false \
  -e GUACD_HOST=192.168.1.50 \
  -e GUACD_PORT=4822 \
  -e TARGET_PROTOCOL=rdp \
  -e TARGET_HOST=192.168.1.200 \
  -e TARGET_PORT=3389 \
  -e TARGET_USER=Administrator \
  -e TARGET_PASSWORD=winpass \
  guacamole-client
```

**Login:** `admin` / `admin`

### View Help

```bash
docker run --rm guacamole-client --help
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
| `TARGET_USER` | Username for target | `ubuntu`, `Administrator` |
| `TARGET_PASSWORD` | Password for target server | `your-password` |

**Note:** Guacamole web UI uses fixed credentials: **`admin`** / **`admin`**

### Conditional (when USE_EMBEDDED_GUACD=false)

| Variable | Description | Default |
|----------|-------------|---------|
| `GUACD_HOST` | External guacd hostname/IP | - |
| `GUACD_PORT` | External guacd port | `4822` |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `IGNORE_CERT` | Ignore SSL cert (RDP) | `true` |
| `ENABLE_DRIVE` | Enable drive redirection (RDP) | `false` |
| `DRIVE_PATH` | Path for drive redirection | `/tmp/guac-drive` |

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
  guacamole-client
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
  guacamole-client
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
  guacamole-client

# Or use version 1.6.0
docker run -d -p 8080:8080 \
  -e GUACAMOLE_VERSION=1.6.0 \
  ...
```

## Building the Image

```bash
# Clone the repository
git clone https://github.com/your-repo/vanila-guacamole.git
cd vanila-guacamole

# Build
docker build -t guacamole-client .

# Run
docker run -d -p 8080:8080 \
  -e GUACAMOLE_VERSION=1.5.5 \
  -e USE_EMBEDDED_GUACD=true \
  -e TARGET_PROTOCOL=ssh \
  -e TARGET_HOST=192.168.1.100 \
  -e TARGET_PORT=22 \
  -e TARGET_USER=ubuntu \
  -e TARGET_PASSWORD=password \
  guacamole-client
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
- **Alpine Linux 3.19** - Minimal, secure base (~5MB)

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
docker run --rm guacamole-client --help
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

## Security Considerations

1. **Use strong passwords** - Don't use default passwords in production
2. **HTTPS** - Put behind a reverse proxy with SSL
3. **Network isolation** - Use Docker networks to restrict access
4. **Secrets management** - Consider using Docker secrets for passwords
5. **Regular updates** - Rebuild image with latest security patches

## Production Deployment

### With HTTPS Reverse Proxy

```bash
# Run Guacamole
docker run -d --name guacamole \
  -e GUACAMOLE_VERSION=1.5.5 \
  -e USE_EMBEDDED_GUACD=true \
  -e TARGET_PROTOCOL=ssh \
  -e TARGET_HOST=backend-server \
  -e TARGET_PORT=22 \
  -e TARGET_USER=sysadmin \
  -e ADMIN_USER=admin \
  -e ADMIN_PASSWORD=secure-random-password \
  guacamole-client

# Run nginx as reverse proxy
docker run -d --name nginx \
  -p 443:443 \
  -v /path/to/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v /path/to/ssl:/etc/ssl:ro \
  --link guacamole:guacamole \
  nginx
```

### Using Docker Secrets (Swarm/Compose)

```bash
# Create secrets
echo "admin-password" | docker secret create guac_admin_pass -
echo "target-password" | docker secret create target_pass -

# Reference in deployment
# (requires additional scripting to read from /run/secrets/)
```

## License

Apache Guacamole is licensed under the Apache License 2.0.

## References

- [Apache Guacamole Documentation](https://guacamole.apache.org/doc/gug/)
- [Guacamole Protocol Reference](https://guacamole.apache.org/doc/gug/guacamole-protocol.html)
- [Connection Configuration](https://guacamole.apache.org/doc/gug/configuring-guacamole.html)
