FROM debian:bullseye
RUN apt-get update && apt-get upgrade -y && \
	apt-get install -y nginx openssl && \
	mkdir /etc/nginx/ssl && \
	openssl req -newkey rsa:4096 -x509 -sha256 -days 365 -nodes \
       -out /etc/nginx/ssl/qtay.crt \
       -keyout /etc/nginx/ssl/qtay.key \
       -subj "/C=MY/ST=SELANGOR/L=PETALINGJAYA/O=42KL/OU=qtay/CN=qtay/"

COPY ./conf/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE	443

CMD ["nginx", "-g", "daemon off;"]
