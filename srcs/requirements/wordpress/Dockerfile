FROM debian:bullseye

RUN apt-get update && apt-get upgrade -y && \
	apt-get install -y php7.4-fpm php-mysqli curl && \
	mkdir /run/php

COPY ./conf/www.conf /etc/php/7.4/fpm/pool.d/

COPY ./tools/install_wordpress.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/install_wordpress.sh

EXPOSE 9000

CMD ["/usr/local/bin/install_wordpress.sh"]
