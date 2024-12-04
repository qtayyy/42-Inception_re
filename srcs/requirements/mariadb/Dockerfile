FROM debian:bullseye
RUN apt-get update && apt-get upgrade -y && \
	apt-get install -y mariadb-server && \
	rm -rf /var/lib/apt/lists/* && \
	mkdir -p /var/run/mysqld && \
	chown -R mysql:root /var/run/mysqld /var/lib/mysql && \
	chmod 775 /var/run/mysqld && \
	sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mariadb.conf.d/50-server.cnf

COPY tools/config_mariadb.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/config_mariadb.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/config_mariadb.sh"]
CMD ["mysqld"]
