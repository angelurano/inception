FROM alpine:3.23.6

# hadolint ignore=DL3018
RUN apk update && apk add --no-cache mariadb mariadb-client

RUN mkdir -p /run/mysqld && \ 
  chown -R mysql:mysql /run/mysqld

COPY conf/mariadb.cnf /etc/my.cnf.d/mariadb-server.cnf

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3306

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
CMD ["mysqld", "--user=mysql", "--console"]

