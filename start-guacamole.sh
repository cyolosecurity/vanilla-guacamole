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
    echo "  docker run -p 8080:8080 [OPTIONS] vanilla-guacamole"
    echo ""
    echo -e "${GREEN}REQUIRED ENVIRONMENT VARIABLES:${NC}"
    echo -e "  ${YELLOW}GUACAMOLE_VERSION${NC}     Guacamole version: 1.5.2, 1.5.5, or 1.6.0"
    echo -e "  ${YELLOW}USE_EMBEDDED_GUACD${NC}    Use embedded guacd: true or false"
    echo -e "                         ${RED}NOTE: Embedded guacd doesn't work on Linux ARM64${NC}"
    echo -e "                         ${RED}(macOS ARM64 is OK; Linux ARM64 users must use external guacd)${NC}"
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
    echo -e "${GREEN}OPTIONAL RDP PARAMETERS:${NC}"
    echo -e "  ${YELLOW}RDP_DOMAIN${NC}            Windows domain for authentication"
    echo -e "  ${YELLOW}RDP_SERVER_LAYOUT${NC}     Keyboard layout (e.g., en-us-qwerty, de-de-qwertz)"
    echo -e "  ${YELLOW}RDP_SECURITY${NC}          Security mode: any, nla, tls, rdp, vmconnect (default: any)"
    echo -e "  ${YELLOW}RDP_DISABLE_AUTH${NC}      Bypass authentication (true/false)"
    echo -e "  ${YELLOW}RDP_RESIZE_METHOD${NC}     Display resize: display-update, reconnect"
    echo -e "  ${YELLOW}RDP_CONSOLE${NC}           Connect to admin/console session (true/false)"
    echo ""
    echo -e "${GREEN}OPTIONAL VNC PARAMETERS:${NC}"
    echo -e "  ${YELLOW}VNC_COLOR_DEPTH${NC}       Color depth: 8, 16, 24, 32"
    echo -e "  ${YELLOW}VNC_CURSOR${NC}            Cursor rendering: local, remote"
    echo -e "  ${YELLOW}VNC_READ_ONLY${NC}         View-only mode (true/false)"
    echo -e "  ${YELLOW}VNC_DISABLE_DISPLAY_RESIZE${NC}  Prevent display auto-resize (true/false)"
    echo ""
    echo -e "${GREEN}OPTIONAL SSH PARAMETERS:${NC}"
    echo -e "  ${YELLOW}SSH_FONT_SIZE${NC}         Terminal font size (e.g., 12)"
    echo -e "  ${YELLOW}SSH_COLOR_SCHEME${NC}      Color scheme: black-white, gray-black, green-black, etc."
    echo -e "  ${YELLOW}SSH_SCROLLBACK${NC}        Terminal scrollback buffer size (e.g., 1024)"
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
    echo "    vanilla-guacamole"
    echo ""
    echo -e "${YELLOW}Note:${NC} Login to Guacamole web UI with ${GREEN}admin${NC} / ${GREEN}admin${NC}"
    echo ""
    echo -e "${GREEN}EXAMPLE WITH EXTERNAL GUACD:${NC}"
    echo ""
    echo -e "${CYAN}If guacd is launched by IDAC (either directly, or via docker-compose) - use Docker Network:${NC}"
    echo "  # 1. Create network"
    echo "  docker network create guacamole-net"
    echo ""
    echo "  # 2. Connect guacd container (e.g., guacd_1)"
    echo "  docker network connect guacamole-net guacd_1"
    echo ""
    echo "  # 3. Run Vanilla Guacamole on same network"
    echo "  docker run -p 8080:8080 --network guacamole-net \\"
    echo "    -e GUACAMOLE_VERSION=1.5.5 \\"
    echo "    -e USE_EMBEDDED_GUACD=false \\"
    echo "    -e GUACD_HOST=guacd_1 \\"
    echo "    -e GUACD_PORT=4822 \\"
    echo "    -e TARGET_PROTOCOL=rdp \\"
    echo "    -e TARGET_HOST=192.168.1.200 \\"
    echo "    -e TARGET_PORT=3389 \\"
    echo "    -e TARGET_USER=Administrator \\"
    echo "    -e TARGET_PASSWORD=winpass \\"
    echo "    vanilla-guacamole"
    echo ""
    echo -e "${CYAN}If guacd is launched as standalone - use IP:Port:${NC}"
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
    echo "    vanilla-guacamole"
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

# Show spinner while waiting
show_spinner() {
    local message="$1"
    local check_command="$2"
    local spinstr='|/-\'
    local temp
    
    while ! eval "$check_command" 2>/dev/null; do
        temp=${spinstr#?}
        printf "\r%s [%c]  " "$message" "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep 0.15
    done
    printf "\r%-80s\r%s " "" "$message"
}

# Cleanup function for graceful shutdown
cleanup() {
    echo ""
    echo "Shutting down..."
    if [ "$USE_EMBEDDED_GUACD" = "true" ]; then
        supervisorctl stop all >/dev/null 2>&1
        supervisorctl shutdown >/dev/null 2>&1
    else
        # Stop Tomcat gracefully
        ${CATALINA_HOME}/bin/catalina.sh stop >/dev/null 2>&1
    fi
    exit 0
}

# Trap signals for graceful shutdown
trap cleanup SIGTERM SIGINT

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

# Check for Linux ARM64 with embedded guacd (not supported - macOS ARM is OK due to QEMU)
if [ "$USE_EMBEDDED_GUACD" = "true" ]; then
    OS=$(uname -s)
    ARCH=$(uname -m)
    if [ "$OS" = "Linux" ] && ([ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]); then
        error_exit "Embedded guacd is not supported on Linux ARM64. Please use USE_EMBEDDED_GUACD=false with an external guacd server. (Note: macOS ARM64 works fine due to Docker Desktop's emulation)"
    fi
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

# Protocol-specific parameter validation
validate_rdp_security() {
    if [ -n "$RDP_SECURITY" ]; then
        case "$RDP_SECURITY" in
            any|nla|tls|rdp|vmconnect) ;;
            *) error_exit "RDP_SECURITY must be one of: any, nla, tls, rdp, vmconnect" ;;
        esac
    fi
}

validate_rdp_resize_method() {
    if [ -n "$RDP_RESIZE_METHOD" ]; then
        case "$RDP_RESIZE_METHOD" in
            display-update|reconnect) ;;
            *) error_exit "RDP_RESIZE_METHOD must be one of: display-update, reconnect" ;;
        esac
    fi
}

validate_vnc_color_depth() {
    if [ -n "$VNC_COLOR_DEPTH" ]; then
        case "$VNC_COLOR_DEPTH" in
            8|16|24|32) ;;
            *) error_exit "VNC_COLOR_DEPTH must be one of: 8, 16, 24, 32" ;;
        esac
    fi
}

validate_vnc_cursor() {
    if [ -n "$VNC_CURSOR" ]; then
        case "$VNC_CURSOR" in
            local|remote) ;;
            *) error_exit "VNC_CURSOR must be one of: local, remote" ;;
        esac
    fi
}

validate_boolean() {
    local param_name="$1"
    local param_value="$2"
    if [ -n "$param_value" ]; then
        case "$param_value" in
            true|false) ;;
            *) error_exit "$param_name must be 'true' or 'false'" ;;
        esac
    fi
}

# Validate protocol-specific parameters
if [ "$TARGET_PROTOCOL" = "rdp" ]; then
    validate_rdp_security
    validate_rdp_resize_method
    validate_boolean "RDP_DISABLE_AUTH" "$RDP_DISABLE_AUTH"
    validate_boolean "RDP_CONSOLE" "$RDP_CONSOLE"
elif [ "$TARGET_PROTOCOL" = "vnc" ]; then
    validate_vnc_color_depth
    validate_vnc_cursor
    validate_boolean "VNC_DISABLE_DISPLAY_RESIZE" "$VNC_DISABLE_DISPLAY_RESIZE"
    validate_boolean "VNC_READ_ONLY" "$VNC_READ_ONLY"
fi

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
    # Add security parameter (default to 'any' if not specified)
    cat >> ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
            <param name="security">${RDP_SECURITY:-any}</param>
            <param name="ignore-cert">${IGNORE_CERT}</param>
EOF
    
    # Optional RDP parameters (only add if set)
    [ -n "$RDP_DOMAIN" ] && cat >> ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
            <param name="domain">${RDP_DOMAIN}</param>
EOF
    
    [ -n "$RDP_SERVER_LAYOUT" ] && cat >> ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
            <param name="server-layout">${RDP_SERVER_LAYOUT}</param>
EOF
    
    [ -n "$RDP_DISABLE_AUTH" ] && cat >> ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
            <param name="disable-auth">${RDP_DISABLE_AUTH}</param>
EOF
    
    [ -n "$RDP_RESIZE_METHOD" ] && cat >> ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
            <param name="resize-method">${RDP_RESIZE_METHOD}</param>
EOF
    
    [ -n "$RDP_CONSOLE" ] && cat >> ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
            <param name="console">${RDP_CONSOLE}</param>
EOF
    
    if [ "$ENABLE_DRIVE" = "true" ]; then
        mkdir -p ${DRIVE_PATH}
        cat >> ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
            <param name="enable-drive">true</param>
            <param name="drive-path">${DRIVE_PATH}</param>
EOF
    fi
elif [ "$TARGET_PROTOCOL" = "vnc" ]; then
    # Optional VNC parameters (only add if set)
    [ -n "$VNC_COLOR_DEPTH" ] && cat >> ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
            <param name="color-depth">${VNC_COLOR_DEPTH}</param>
EOF
    
    [ -n "$VNC_CURSOR" ] && cat >> ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
            <param name="cursor">${VNC_CURSOR}</param>
EOF
    
    [ -n "$VNC_READ_ONLY" ] && cat >> ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
            <param name="read-only">${VNC_READ_ONLY}</param>
EOF
    
    [ -n "$VNC_DISABLE_DISPLAY_RESIZE" ] && cat >> ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
            <param name="disable-display-resize">${VNC_DISABLE_DISPLAY_RESIZE}</param>
EOF

elif [ "$TARGET_PROTOCOL" = "ssh" ]; then
    # Optional SSH parameters (only add if set)
    [ -n "$SSH_FONT_SIZE" ] && cat >> ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
            <param name="font-size">${SSH_FONT_SIZE}</param>
EOF
    
    [ -n "$SSH_COLOR_SCHEME" ] && cat >> ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
            <param name="color-scheme">${SSH_COLOR_SCHEME}</param>
EOF
    
    [ -n "$SSH_SCROLLBACK" ] && cat >> ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
            <param name="scrollback">${SSH_SCROLLBACK}</param>
EOF
fi

# Close the real connection and add a dummy connection to prevent auto-connect
cat >> ${GUACAMOLE_HOME}/user-mapping.xml <<EOF
        </connection>
        <connection name="zzz - Dummy connection (won't connect)">
            <protocol>vnc</protocol>
            <param name="hostname">127.0.0.1</param>
            <param name="port">5901</param>
            <param name="password">dummy</param>
        </connection>
    </authorize>
</user-mapping>
EOF

# Configuration summary
echo ""
echo -e "${BLUE}Configuration:${NC}"
echo -e "  Guacamole Version: ${GREEN}${GUACAMOLE_VERSION}${NC}"
echo -e "  Embedded guacd: ${GREEN}${USE_EMBEDDED_GUACD}${NC}"
if [ "$USE_EMBEDDED_GUACD" = "false" ]; then
    echo -e "  guacd endpoint: ${GREEN}${GUACD_HOST}:${GUACD_PORT}${NC}"
fi
echo -e "  Target: ${GREEN}${TARGET_PROTOCOL}://${TARGET_HOST}:${TARGET_PORT}${NC}"
echo -e "  Web UI login: ${GREEN}${ADMIN_USER}${NC} / ${GREEN}${ADMIN_PASSWORD}${NC}"
echo ""

# Test guacd connectivity for external guacd before starting services
if [ "$USE_EMBEDDED_GUACD" = "false" ]; then
    echo -n "Testing connection to guacd at ${GUACD_HOST}:${GUACD_PORT}... "
    if timeout 3 nc -z "${GUACD_HOST}" "${GUACD_PORT}" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Connected"
        echo ""
    else
        echo -e "${RED}✗${NC} Failed"
        echo ""
        echo -e "${RED}ERROR: Cannot connect to guacd at ${GUACD_HOST}:${GUACD_PORT}${NC}"
        echo ""
        echo -e "Please use one of the following ${CYAN}Connection Methods:${NC}"
        echo ""
        echo -e "${CYAN}If guacd is launched by IDAC (either directly, or via docker-compose):${NC}"
        echo "  Use Docker Network approach (container name-based)"
        echo -e "  1. Create network: ${BLUE}docker network create guacamole-net${NC}"
        echo -e "  2. Connect guacd: ${BLUE}docker network connect guacamole-net <guacd-container>${NC}"
        echo -e "  3. Run this container with: ${BLUE}--network guacamole-net${NC}"
        echo -e "  4. Set GUACD_HOST to guacd container name (e.g., ${BLUE}guacd_1${NC})"
        echo ""
        echo -e "${CYAN}If guacd is launched as standalone:${NC}"
        echo "  Use IP:Port approach"
        echo "  - Set GUACD_HOST to the IP address or hostname"
        echo -e "  - Set GUACD_PORT to the exposed port (default: ${BLUE}4822${NC})"
        echo ""
        exit 1
    fi
fi

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
    
    # Start supervisor in background (suppress all startup output)
    /usr/bin/supervisord -c /etc/supervisord.conf >/dev/null 2>&1
    
    # Wait for guacd to be ready with spinner
    show_spinner "Starting guacd..." "grep -q 'Listening on host' /var/log/guacd.log"
    echo -e "${GREEN}✓${NC} guacd is ready"
    
    # Wait for Guacamole Client Web Application to be ready with spinner
    show_spinner "Starting Guacamole Client Web Application..." "grep -q 'Server startup' /var/log/tomcat.log"
    echo -e "${GREEN}✓${NC} Guacamole Client Web Application is ready"
    
    echo ""
    echo -e "${CYAN}Access Guacamole at:${NC} ${BLUE}http://localhost:8080${NC}"
    echo -e "${CYAN}(Ensure you ran docker with${NC} ${BLUE}-p 8080:8080${CYAN})${NC}"
    echo ""
    
    # Keep container running - wait indefinitely
    while true; do
        sleep 1
    done
else
    # Start Tomcat in background with logs redirected
    ${CATALINA_HOME}/bin/catalina.sh run > /var/log/tomcat.log 2>&1 &
    
    # Wait for Guacamole Client Web Application to be ready with spinner
    show_spinner "Starting Guacamole Client Web Application..." "grep -q 'Server startup' /var/log/tomcat.log"
    echo -e "${GREEN}✓${NC} Guacamole Client Web Application is ready"
    
    echo ""
    echo -e "${CYAN}Access Guacamole at:${NC} ${BLUE}http://localhost:8080${NC}"
    echo -e "${CYAN}(Ensure you ran docker with${NC} ${BLUE}-p 8080:8080${CYAN})${NC}"
    echo ""
    
    # Keep container running - wait indefinitely
    while true; do
        sleep 1
    done
fi

