FROM nginx:1.27-alpine

COPY public/ /usr/share/nginx/html/
RUN addgroup -S app && adduser -S app -G app

USER app
