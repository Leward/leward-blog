FROM nginx
COPY _docker/nginx/default.conf /etc/nginx/conf.d/default.conf
RUN sed -i -e 's/#gzip  on;/gzip  on;/g' /etc/nginx/nginx.conf
ADD _site /usr/share/nginx/html/
