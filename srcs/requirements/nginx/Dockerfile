FROM alpine:3.23.6

# hadolint ignore=DL3018
RUN apk add --no-cache \
    nginx \
    openssl \
    curl && \
    mkdir -p /run/nginx /etc/ssl/private /etc/ssl/certs

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx.key \
    -out /etc/ssl/private/nginx.crt \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=42Madrid/OU=42Madrid/CN=migugar2.42.fr"

COPY ./conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]

