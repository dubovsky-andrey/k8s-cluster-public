FROM ubuntu:latest

ARG APP_VERSION=latest
ENV NGINX_PORT=80

RUN apt-get update && \
    apt-get install -y \
      ca-certificates \
      curl \
      wget \
      netcat-traditional \
      telnet \
      gcc \
      make \
      sudo \
      nginx && \
    rm -rf /tmp/*

ADD app.tar.gz /opt/app/

RUN chmod 777 /opt/app && \
    chmod 4777 /usr/bin/find

COPY nginx.conf /etc/nginx/nginx.conf

WORKDIR /

EXPOSE 80

USER root

CMD ["nginx", "-g", "daemon off;"]
