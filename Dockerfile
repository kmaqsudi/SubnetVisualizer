# Lightweight static build for Visual Subnet Calculator
FROM nginx:alpine

LABEL maintainer="kmaqsudi" \
      org.opencontainers.image.title="Visual Subnet Calculator" \
      org.opencontainers.image.description="Static subnet visualizer served by nginx" \
      org.opencontainers.image.source="https://github.com/kmaqsudi/SubnetVisualizer" \
      org.opencontainers.image.licenses="MIT"

# Add minimal nginx config to enable gzip and caching
RUN rm /etc/nginx/conf.d/default.conf
COPY <<'EOF' /etc/nginx/conf.d/subnets.conf
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    gzip on;
    gzip_types text/plain text/javascript application/javascript text/css application/json;
    gzip_min_length 512;

    location / {
        try_files $uri $uri/ =404;
    }

    # Cache static images for a year (they are content-addressed by build layer)
    location ~* \.(gif|png|jpg|jpeg)$ {
        add_header Cache-Control "public, max-age=31536000, immutable";
    }
}
EOF

# Copy static assets (only what is needed thanks to .dockerignore)
COPY subnets.html /usr/share/nginx/html/index.html
COPY img/ /usr/share/nginx/html/img/

EXPOSE 80
HEALTHCHECK CMD wget -q -O /dev/null http://localhost/ || exit 1

# Final image size & layer order kept minimal: config first (rarely changes), then content.
