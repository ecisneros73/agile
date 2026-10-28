# Use the Docker Hardened NGINX image that you have already pulled.
# For production, pin to an approved version/digest.
FROM dhi.io/nginx:1-debian-dev

# Copy only static web assets into the NGINX document root.
COPY --chown=65532:65532 html/ /usr/share/nginx/html/

# Preserve the vendor-provided ENTRYPOINT/CMD configuration.
EXPOSE 8080
