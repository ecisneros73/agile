# Uses the same Docker Hardened Image family as your existing project.
# Registry access may require: docker login dhi.io
FROM dhi.io/nginx:1-debian-dev
COPY --chown=65532:65532 nginx/nginx.conf /etc/nginx/nginx.conf
COPY --chown=65532:65532 frontend/ /usr/share/nginx/html/
EXPOSE 8080
# Inherit the upstream ENTRYPOINT and CMD.
