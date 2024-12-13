#!/bin/sh

if [ -d /var/lib/mysql/$MYSQL_DATABASE ]; then
	echo "Database already exists"
else
	touch /usr/local/bin/init.sql
	echo "FLUSH PRIVILEGES;
		CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;
		CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQLPASSWORD';
		GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
		FLUSH PRIVILEGES;" > /usr/local/bin/init.sql
	mysqld --user=mysql --bootstrap < /usr/local/bin/init.sql
fi

exec "$@"
