FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      nginx && \
    rm -rf /var/lib/apt/lists/*

COPY nginx.conf /etc/nginx/nginx.conf

WORKDIR /usr/share/nginx/html

EXPOSE 8080

USER root

CMD ["nginx", "-g", "daemon off;"]
