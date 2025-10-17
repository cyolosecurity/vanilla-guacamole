# Multi-stage build for Apache Guacamole with embedded guacd support
# Each guacd version is extracted from official images

# Enable BuildKit for multi-platform support
# syntax=docker/dockerfile:1

# Stage 1: Extract guacd 1.5.2
FROM --platform=$TARGETPLATFORM guacamole/guacd:1.5.2 AS guacd-1.5.2

# Stage 2: Extract guacd 1.5.5
FROM --platform=$TARGETPLATFORM guacamole/guacd:1.5.5 AS guacd-1.5.5

# Stage 3: Extract guacd 1.6.0
FROM --platform=$TARGETPLATFORM guacamole/guacd:1.6.0 AS guacd-1.6.0

# Final stage: Alpine-based image with Java, Tomcat, and all guacd versions
# Using Alpine 3.18.5 to match guacd images for library compatibility
FROM --platform=$TARGETPLATFORM alpine:3.18.5

# Set environment variables
ENV GUACAMOLE_HOME=/etc/guacamole \
    CATALINA_HOME=/opt/tomcat \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk \
    PATH=$PATH:/opt/tomcat/bin

# Install runtime dependencies
RUN apk add --no-cache \
    openjdk11-jre \
    wget \
    ca-certificates \
    supervisor \
    bash \
    cairo \
    libjpeg-turbo \
    libpng \
    pango \
    libwebp \
    freerdp \
    libssh2 \
    libvncserver \
    pulseaudio \
    openssl \
    openssl1.1-compat \
    libvorbis \
    libwebsockets \
    terminus-font \
    ttf-dejavu \
    ttf-liberation

# Verify Java version
RUN java -version

# Install Tomcat 9
RUN wget -q https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.93/bin/apache-tomcat-9.0.93.tar.gz -O /tmp/tomcat.tar.gz && \
    mkdir -p ${CATALINA_HOME} && \
    tar -xzf /tmp/tomcat.tar.gz -C ${CATALINA_HOME} --strip-components=1 && \
    rm /tmp/tomcat.tar.gz && \
    chmod +x ${CATALINA_HOME}/bin/*.sh

# Create directories
RUN mkdir -p ${GUACAMOLE_HOME} \
    ${GUACAMOLE_HOME}/extensions \
    ${GUACAMOLE_HOME}/lib \
    /opt/guacamole-wars \
    /opt/guacd-1.5.2/bin \
    /opt/guacd-1.5.2/lib \
    /opt/guacd-1.5.5/bin \
    /opt/guacd-1.5.5/lib \
    /opt/guacd-1.6.0/bin \
    /opt/guacd-1.6.0/lib \
    /var/log/supervisor

# Copy guacd binaries from all versions (from /opt/guacamole/)
COPY --from=guacd-1.5.2 /opt/guacamole/sbin/guacd /opt/guacd-1.5.2/bin/guacd
COPY --from=guacd-1.5.2 /opt/guacamole/lib/ /opt/guacd-1.5.2/lib/

COPY --from=guacd-1.5.5 /opt/guacamole/sbin/guacd /opt/guacd-1.5.5/bin/guacd
COPY --from=guacd-1.5.5 /opt/guacamole/lib/ /opt/guacd-1.5.5/lib/

COPY --from=guacd-1.6.0 /opt/guacamole/sbin/guacd /opt/guacd-1.6.0/bin/guacd
COPY --from=guacd-1.6.0 /opt/guacamole/lib/ /opt/guacd-1.6.0/lib/

# Make guacd binaries executable
RUN chmod +x /opt/guacd-*/bin/guacd

# Download ALL supported Guacamole versions
RUN echo "Downloading Guacamole versions: 1.5.2, 1.5.5, 1.6.0..." && \
    wget -q https://archive.apache.org/dist/guacamole/1.5.2/binary/guacamole-1.5.2.war -O /opt/guacamole-wars/guacamole-1.5.2.war && \
    wget -q https://archive.apache.org/dist/guacamole/1.5.5/binary/guacamole-1.5.5.war -O /opt/guacamole-wars/guacamole-1.5.5.war && \
    wget -q https://archive.apache.org/dist/guacamole/1.6.0/binary/guacamole-1.6.0.war -O /opt/guacamole-wars/guacamole-1.6.0.war && \
    echo "All versions downloaded successfully!"

# Copy startup script (supervisord.conf is generated dynamically)
COPY start-guacamole.sh /opt/start-guacamole.sh
RUN chmod +x /opt/start-guacamole.sh

# Expose ports
EXPOSE 8080 4822

# Set the entrypoint
ENTRYPOINT ["/opt/start-guacamole.sh"]

