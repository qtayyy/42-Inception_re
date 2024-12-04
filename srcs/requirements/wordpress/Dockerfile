FROM debian:stable-backports

RUN apt-get update && apt-get -y install php7.3-fpm php-mysqli curl && \
	mkdir /run/php

COPY ./conf/www.conf /etc/php/7.3/fpm/pool.d/

COPY ./tools/install_wordpress.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/install_wordpress.sh

EXPOSE 9000

CMD ["/usr/local/bin/install_wordpress.sh"]
