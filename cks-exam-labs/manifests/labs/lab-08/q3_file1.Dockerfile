FROM alpine:3.20

WORKDIR /app
COPY register.sh /etc/register.sh
COPY secret-token .
RUN /etc/register.sh ./secret-token
RUN rm ./secret-token

CMD ["sh", "-c", "sleep 1d"]
