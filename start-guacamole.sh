#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Help message
show_help() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════"
    echo -e "  Vanilla Guacamole Multi-Version Container"
    echo -e "═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}USAGE:${NC}"
    echo "  docker run -p 8080:8080 [OPTIONS] guacamole-client"
    echo ""
    echo -e "${GREEN}REQUIRED ENVIRONMENT VARIABLES:${NC}"
    echo -e "  ${YELLOW}GUACAMOLE_VERSION${NC}     Guacamole version: 1.5.2, 1.5.5, or 1.6.0"
    echo -e "  ${YELLOW}USE_EMBEDDED_GUACD${NC}    Use embedded guacd: true or false"
    echo -e "  ${YELLOW}TARGET_PROTOCOL${NC}       Connection protocol: ssh, rdp, or vnc"
    echo -e "  ${YELLOW}TARGET_HOST${NC}           Target server hostname or IP"
    echo -e "  ${YELLOW}TARGET_PORT${NC}           Target server port"
    echo -e "  ${YELLOW}TARGET_USER${NC}           Username for target server (not required for VNC)"
    echo -e "  ${YELLOW}TARGET_PASSWORD${NC}       Password for target server"
    echo ""
    echo -e "${GREEN}CONDITIONAL (if USE_EMBEDDED_GUACD=false):${NC}"
    echo -e "  ${YELLOW}GUACD_HOST${NC}            External guacd hostname or IP"
    echo -e "  ${YELLOW}GUACD_PORT${NC}            External guacd port (default: 4822)"
    echo ""
    echo -e "${GREEN}OPTIONAL:${NC}"
    echo -e "  ${YELLOW}IGNORE_CERT${NC}           Ignore SSL cert for RDP (true/false, default: true)"
    echo -e "  ${YELLOW}ENABLE_DRIVE${NC}          Enable drive redirection for RDP (true/false)"
    echo -e "  ${YELLOW}DRIVE_PATH${NC}            Path for drive redirection (default: /tmp/guac-drive)"
    echo ""
    echo -e "${GREEN}EXAMPLE WITH EMBEDDED GUACD:${NC}"
    echo "  docker run -p 8080:8080 \\"
    echo "    -e GUACAMOLE_VERSION=1.5.5 \\"
    echo "    -e USE_EMBEDDED_GUACD=true \\"
    echo "    -e TARGET_PROTOCOL=ssh \\"
    echo "    -e TARGET_HOST=192.168.1.100 \\"
    echo "    -e TARGET_PORT=22 \\"
    echo "    -e TARGET_USER=ubuntu \\"
    echo "    -e TARGET_PASSWORD=secret \\"
    echo "    guacamole-client"
    echo ""
    echo -e "${YELLOW}Note:${NC} Login to Guacamole web UI with ${GREEN}admin${NC} / ${GREEN}admin${NC}"
    echo ""
    echo -e "${GREEN}EXAMPLE WITH EXTERNAL GUACD:${NC}"
    echo "  docker run -p 8080:8080 \\"
    echo "    -e GUACAMOLE_VERSION=1.5.5 \\"
    echo "    -e USE_EMBEDDED_GUACD=false \\"
    echo "    -e GUACD_HOST=192.168.1.50 \\"
    echo "    -e GUACD_PORT=4822 \\"
    echo "    -e TARGET_PROTOCOL=rdp \\"
    echo "    -e TARGET_HOST=192.168.1.200 \\"
    echo "    -e TARGET_PORT=3389 \\"
    echo "    -e TARGET_USER=Administrator \\"
    echo "    -e TARGET_PASSWORD=winpass \\"
    echo "    guacamole-client"
    echo ""
    echo -e "${YELLOW}Note:${NC} Login to Guacamole web UI with ${GREEN}admin${NC} / ${GREEN}admin${NC}"
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    exit 0
}

# Show help if requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
fi

# Validation function
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    echo -e "${YELLOW}Run with --help for usage information${NC}" >&2
    exit 1
}

# Supported versions
SUPPORTED_VERSIONS="1.5.2 1.5.5 1.6.0"

# Validate required variables
[ -z "$GUACAMOLE_VERSION" ] && error_exit "GUACAMOLE_VERSION is required"
[ -z "$USE_EMBEDDED_GUACD" ] && error_exit "USE_EMBEDDED_GUACD is required (true/false)"
[ -z "$TARGET_PROTOCOL" ] && error_exit "TARGET_PROTOCOL is required (ssh/rdp/vnc)"
[ -z "$TARGET_HOST" ] && error_exit "TARGET_HOST is required"
[ -z "$TARGET_PORT" ] && error_exit "TARGET_PORT is required"
[ -z "$TARGET_PASSWORD" ] && error_exit "TARGET_PASSWORD is required"

# TARGET_USER is required for SSH and RDP, but optional for VNC
if [ "$TARGET_PROTOCOL" != "vnc" ] && [ -z "$TARGET_USER" ]; then
    error_exit "TARGET_USER is required for $TARGET_PROTOCOL protocol"
fi

# Validate version
if ! echo "$SUPPORTED_VERSIONS" | grep -wq "$GUACAMOLE_VERSION"; then
    error_exit "Unsupported GUACAMOLE_VERSION: $GUACAMOLE_VERSION (supported: $SUPPORTED_VERSIONS)"
fi

# Validate USE_EMBEDDED_GUACD
if [ "$USE_EMBEDDED_GUACD" != "true" ] && [ "$USE_EMBEDDED_GUACD" != "false" ]; then
    error_exit "USE_EMBEDDED_GUACD must be 'true' or 'false'"
fi

# Validate protocol
if [ "$TARGET_PROTOCOL" != "ssh" ] && [ "$TARGET_PROTOCOL" != "rdp" ] && [ "$TARGET_PROTOCOL" != "vnc" ]; then
    error_exit "TARGET_PROTOCOL must be ssh, rdp, or vnc"
fi

# Validate external guacd settings
if [ "$USE_EMBEDDED_GUACD" = "false" ]; then
    [ -z "$GUACD_HOST" ] && error_exit "GUACD_HOST is required when USE_EMBEDDED_GUACD=false"
    GUACD_PORT=${GUACD_PORT:-4822}
fi

# Set defaults for optional parameters
IGNORE_CERT=${IGNORE_CERT:-true}
DRIVE_PATH=${DRIVE_PATH:-/tmp/guac-drive}

# Fixed admin credentials for Guacamole web interface
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

# Banner
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Vanilla Guacamole Client${NC}"
echo -e "${BLUE}  Version: ${GREEN}${GUACAMOLE_VERSION}${BLUE}${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

# Deploy the selected Guacamole version
WAR_FILE="/opt/guacamole-wars/guacamole-${GUACAMOLE_VERSION}.war"
if [ ! -f "$WAR_FILE" ]; then
    error_exit "WAR file not found: $WAR_FILE"
fi

echo -e "${GREEN}✓${NC} Deploying Guacamole $GUACAMOLE_VERSION..."
rm -rf ${CATALINA_HOME}/webapps/ROOT ${CATALINA_HOME}/webapps/ROOT.war
cp "$WAR_FILE" ${CATALINA_HOME}/webapps/ROOT.war

# Determine guacd settings
if [ "$USE_EMBEDDED_GUACD" = "true" ]; then
    echo -e "${GREEN}✓${NC} Using embedded guacd ${GUACAMOLE_VERSION}"
    GUACD_HOST="localhost"
    GUACD_PORT=4822
    GUACD_BIN="/opt/guacd-${GUACAMOLE_VERSION}/bin/guacd"
    GUACD_LIB="/opt/guacd-${GUACAMOLE_VERSION}/lib"
    
    if [ ! -f "$GUACD_BIN" ]; then
        error_exit "guacd binary not found: $GUACD_BIN"
    fi
else
    echo -e "${GREEN}✓${NC} Using external guacd at ${GUACD_HOST}:${GUACD_PORT}"
fi

# Create guacamole.properties
echo -e "${GREEN}✓${NC} Creating guacamole.properties..."
cat > ${GUACAMOLE_HOME}/guacamole.properties <<EOF
# Guacamole configuration
guacd-hostname: ${GUACD_HOST}
guacd-port: ${GUACD_PORT}

# Authentication provider
auth-provider: net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider
basic-user-mapping: ${GUACAMOLE_HOME}/user-mapping.xml
EOF

# Generate user-mapping.xml
echo -e "${GREEN}✓${NC} Generating user-mapping.xml..."
cat > ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<user-mapping>
    <authorize username="${ADMIN_USER}" password="${ADMIN_PASSWORD}">
        <connection name="Remote Server">
            <protocol>${TARGET_PROTOCOL}</protocol>
            <param name="hostname">${TARGET_HOST}</param>
            <param name="port">${TARGET_PORT}</param>
EOF

# Add username only if provided (VNC doesn't require it)
if [ -n "$TARGET_USER" ]; then
    cat >> ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
            <param name="username">${TARGET_USER}</param>
EOF
fi

cat >> ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
            <param name="password">${TARGET_PASSWORD}</param>
EOF

# Add protocol-specific parameters
if [ "$TARGET_PROTOCOL" = "rdp" ]; then
    cat >> ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
            <param name="security">any</param>
            <param name="ignore-cert">${IGNORE_CERT}</param>
EOF
    
    if [ "$ENABLE_DRIVE" = "true" ]; then
        mkdir -p ${DRIVE_PATH}
        cat >> ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
            <param name="enable-drive">true</param>
            <param name="drive-path">${DRIVE_PATH}</param>
EOF
    fi
fi

# Close the XML
cat >> ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
        </connection>
    </authorize>
</user-mapping>
EOF

# Configuration summary
echo ""
echo -e "${BLUE}Configuration:${NC}"
echo -e "  Guacamole Version: ${GREEN}${GUACAMOLE_VERSION}${NC}"
echo -e "  Embedded guacd: ${GREEN}${USE_EMBEDDED_GUACD}${NC}"
echo -e "  guacd endpoint: ${GREEN}${GUACD_HOST}:${GUACD_PORT}${NC}"
echo -e "  Target: ${GREEN}${TARGET_PROTOCOL}://${TARGET_HOST}:${TARGET_PORT}${NC}"
echo -e "  Web UI login: ${GREEN}${ADMIN_USER}${NC} / ${GREEN}${ADMIN_PASSWORD}${NC}"
echo ""

# Start services using supervisor or standalone
if [ "$USE_EMBEDDED_GUACD" = "true" ]; then
    echo -e "${GREEN}✓${NC} Starting services with supervisor..."
    
    # Create supervisor config with correct guacd path and library path
    cat > /etc/supervisord.conf <<EOF
[supervisord]
nodaemon=false
silent=true
user=root
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:guacd]
command=/bin/sh -c 'LD_LIBRARY_PATH=$GUACD_LIB $GUACD_BIN -b 0.0.0.0 -L trace -f'
autostart=true
autorestart=true
stdout_logfile=/var/log/guacd.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=10
redirect_stderr=true
priority=1
environment=LD_LIBRARY_PATH="$GUACD_LIB"

[program:tomcat]
command=/opt/tomcat/bin/catalina.sh run
autostart=true
autorestart=true
stdout_logfile=/var/log/tomcat.log
stdout_logfile_maxbytes=50MB
stdout_logfile_backups=10
redirect_stderr=true
priority=2
EOF
    
    echo -e "${GREEN}✓${NC} Services configured"
    echo ""
    
    # Start supervisor in background to monitor startup
    /usr/bin/supervisord -c /etc/supervisord.conf
    
    # Wait for guacd to be ready
    echo -n "Starting guacd... "
    for i in {1..30}; do
        if grep -q "Listening on host" /var/log/guacd.log 2>/dev/null; then
            echo -e "${GREEN}✓ guacd is ready${NC}"
            break
        fi
        sleep 0.5
    done
    
    # Wait for Tomcat to be ready
    echo -n "Starting Guacamole Web Application... "
    for i in {1..60}; do
        if grep -q "Server startup" /var/log/tomcat.log 2>/dev/null; then
            echo -e "${GREEN}✓ Guacamole Web Application is ready${NC}"
            break
        fi
        sleep 0.5
    done
    
    echo ""
    echo -e "${YELLOW}➜${NC}  Access Guacamole at: ${BLUE}http://localhost:8080/guacamole${NC}"
    echo ""
    echo -e "${CYAN}📋 Logs:${NC}"
    echo -e "   guacd:  ${BLUE}/var/log/guacd.log${NC}"
    echo -e "   Tomcat: ${BLUE}/var/log/tomcat.log${NC}"
    echo ""
    echo -e "${CYAN}💡 Tips:${NC}"
    echo -e "   Follow guacd:  ${BLUE}docker exec <container> tail -f /var/log/guacd.log${NC}"
    echo -e "   Follow Tomcat: ${BLUE}docker exec <container> tail -f /var/log/tomcat.log${NC}"
    echo ""
    
    # Keep container running
    tail -f /var/log/supervisor/supervisord.log >/dev/null 2>&1
else
    echo -e "${GREEN}✓${NC} Starting Tomcat..."
    echo ""
    echo -e "${YELLOW}➜${NC}  Access Guacamole at: ${BLUE}http://localhost:8080/guacamole${NC}"
    echo ""
    echo -e "${CYAN}📋 Log Files:${NC}"
    echo -e "   Tomcat logs:    Check container stdout with ${BLUE}docker logs <container>${NC}"
    echo ""
    exec ${CATALINA_HOME}/bin/catalina.sh run
fi

