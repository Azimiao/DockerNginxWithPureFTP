#FROM指令为随后的指令设置一个Base Image
FROM alpine:3.9
#指定标签 LABEL <key>=<value> <key>=<value> <key>=<value> ...
LABEL maintainer="Yetu <admin@azimiao.com>"

ENV NGINX_VERSION 1.15.8
# 切换源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
# RUN 是构建时启动的命令，可以直接shell。与cmd语法一样
RUN apk update
RUN GPG_KEYS=B0F4253373F8F6F510D42178520A9993A1C052F8 \
	&& CONFIG="\
		--prefix=/etc/nginx \
		--sbin-path=/usr/sbin/nginx \
		--modules-path=/usr/lib/nginx/modules \
		--conf-path=/etc/nginx/nginx.conf \
		--error-log-path=/var/log/nginx/error.log \
		--http-log-path=/var/log/nginx/access.log \
		--pid-path=/var/run/nginx.pid \
		--lock-path=/var/run/nginx.lock \
		--http-client-body-temp-path=/var/cache/nginx/client_temp \
		--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
		--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
		--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
		--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
		--user=www \
		--group=www \
		--with-http_ssl_module \
		--with-http_realip_module \
		--with-http_addition_module \
		--with-http_sub_module \
		--with-http_dav_module \
		--with-http_flv_module \
		--with-http_mp4_module \
		--with-http_gunzip_module \
		--with-http_gzip_static_module \
		--with-http_random_index_module \
		--with-http_secure_link_module \
		--with-http_stub_status_module \
		--with-http_auth_request_module \
		--with-http_xslt_module=dynamic \
		--with-http_image_filter_module=dynamic \
		--with-http_geoip_module=dynamic \
		--with-threads \
		--with-stream \
		--with-stream_ssl_module \
		--with-stream_ssl_preread_module \
		--with-stream_realip_module \
		--with-stream_geoip_module=dynamic \
		--with-http_slice_module \
		--with-mail \
		--with-mail_ssl_module \
		--with-compat \
		--with-file-aio \
		--with-http_v2_module \
	" \
	&& addgroup -S nginx \
	&& adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
	&& apk add --no-cache --virtual .build-deps \
		gcc \
		libc-dev \
		make \
		openssl-dev \
		pcre-dev \
		zlib-dev \
		linux-headers \
		curl \
		gnupg1 \
		libxslt-dev \
		gd-dev \
		geoip-dev \
	&& curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
	&& curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc  -o nginx.tar.gz.asc \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& found=''; \
	for server in \
		ha.pool.sks-keyservers.net \
		hkp://keyserver.ubuntu.com:80 \
		hkp://p80.pool.sks-keyservers.net:80 \
		pgp.mit.edu \
	; do \
		echo "Fetching GPG key $GPG_KEYS from $server"; \
		gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEYS" && found=yes && break; \
	done; \
	test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPG_KEYS" && exit 1; \
	gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz \
	&& rm -rf "$GNUPGHOME" nginx.tar.gz.asc \
	&& mkdir -p /usr/src \
	&& tar -zxC /usr/src -f nginx.tar.gz \
	&& rm nginx.tar.gz \
	&& cd /usr/src/nginx-$NGINX_VERSION \
	&& ./configure $CONFIG --with-debug \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& mv objs/nginx objs/nginx-debug \
	&& mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so \
	&& mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so \
	&& mv objs/ngx_http_geoip_module.so objs/ngx_http_geoip_module-debug.so \
	&& mv objs/ngx_stream_geoip_module.so objs/ngx_stream_geoip_module-debug.so \
	&& ./configure $CONFIG \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	&& rm -rf /etc/nginx/html/ \
	&& mkdir /etc/nginx/conf.d/ \
	&& mkdir -p /usr/share/nginx/html/ \
	&& install -m644 html/index.html /usr/share/nginx/html/ \
	&& install -m644 html/50x.html /usr/share/nginx/html/ \
	&& install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
	&& install -m755 objs/ngx_http_xslt_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so \
	&& install -m755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so \
	&& install -m755 objs/ngx_http_geoip_module-debug.so /usr/lib/nginx/modules/ngx_http_geoip_module-debug.so \
	&& install -m755 objs/ngx_stream_geoip_module-debug.so /usr/lib/nginx/modules/ngx_stream_geoip_module-debug.so \
	&& ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
	&& strip /usr/sbin/nginx* \
	&& strip /usr/lib/nginx/modules/*.so \
	&& rm -rf /usr/src/nginx-$NGINX_VERSION \
	\
	# Bring in gettext so we can get `envsubst`, then throw
	# the rest away. To do this, we need to install `gettext`
	# then move `envsubst` out of the way so `gettext` can
	# be deleted completely, then move `envsubst` back.
	&& apk add --no-cache --virtual .gettext gettext \
	&& mv /usr/bin/envsubst /tmp/ \
	\
	&& runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" \
	&& apk add --no-cache --virtual .nginx-rundeps $runDeps \
	&& apk del .build-deps \
	&& apk del .gettext \
	&& mv /tmp/envsubst /usr/local/bin/ \
	\
	# Bring in tzdata so users could set the timezones through the environment
	# variables
	&& apk add --no-cache tzdata \
	\
	# forward request and error logs to docker log collector
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log


RUN echo "\r\n Finish Nginx"






# docker 容器默认会把容器内部第一个进程，也就是pid=1的程序作为docker容器
# 是否正在运行的依据，如果docker 容器pid挂了，那么docker容器便会直接退出。
# ginx默认启动是在daemon模式下，所以在使用命令docker run -d nginx /usr/
# sbin/nginx时，容器启动nginx后会立刻退出，所以需要使用nginx的前台运行模
#式，需要在配置文件中加“daemon off"指令，或在启动时加“daemon off;"参数
#。注意off后面的分号不要忽略。


#  CMD ["nginx", "-g", "daemon off;"]
# 一个dockerfile只能有一个cmd，这个会被作为运行时发送到容器内的基础容器
#的第一条命令。
#两个办法，一个是CMD不用中括号框起来，将命令用"&&"符号链接：
# 用nohup框起来，不然npm start执行了之后不会执行后面的
#CMD nohup sh -c 'npm start && node ./server/server.js'

#另一个方法是不用CMD，用ENTRYPOINT命令，指定一个执行的shell脚本，然后在entrypoint.sh文件中写上要执行的命令：

#ENTRYPOINT ["./entrypoint.sh"]
#https://segmentfault.com/q/1010000014430026/a-1020000014440879

#ftp


RUN echo "Try to Create LocalUser www" \
	&& addgroup -S www \
	&& adduser  www  -D -S -s /sbin/nologin -G www \
	&& mkdir /var/www \
	&& chown -R www:www  /var/www \
	&& chmod 755 /var/www


RUN apk add build-base libressl wget
RUN echo "Try to Download And Unzip Pureftpd" \
	&& rm -rf /build \
	&& mkdir -p /build/pureftpd \
	&& cd /build/pureftpd \
	&& wget --no-check-certificate http://download.pureftpd.org/pub/pure-ftpd/releases/pure-ftpd-1.0.47.tar.gz \
	&& tar -zxf pure-ftpd-1.0.47.tar.gz \
	&& cd /build/pureftpd/pure-ftpd-1.0.47 \
	&& ./configure --prefix=/usr \
            --with-altlog \
            --with-language=english \
            --with-rfc2640 \
            --with-ftpwho \
            --with-puredb \
            --without-ldap \
            --without-mysql \
            --without-pgsql \
	&& make \
	&& make install

RUN cd /
RUN rm -rf /build
RUN mkdir -p /conf.d/pureftpd 
# 复制配置文件
# 复制到容器 本地文件 容器内文件 只能复制本地文件
COPY docker-nginx/nginx.conf /etc/nginx/nginx.conf
COPY docker-nginx/nginx.vh.default.conf /etc/nginx/conf.d/default.conf
# 另一个复制命令，不同的是他的src可以是本地文件或url
# ADD

COPY docker-pureftpd/pure-ftpd.conf /etc/pure-ftpd.conf
COPY ftppassfile /tmp/myftppassfile
# 添加虚拟组
RUN pure-pw useradd www -u www -d /var/www  < /tmp/myftppassfile \
	&& pure-pw mkdb \
	&& rm /tmp/myftppassfile

COPY startRun.sh /bin/startRunNginxFtp.sh

RUN chmod +x /bin/startRunNginxFtp.sh

RUN mkdir -p /var/www/azimiao_com/public_html \
	&& chown -R www:www  /var/www/azimiao_com/public_html \
	&& chmod 755 /var/www/azimiao_com/public_html \
	&& mkdir -p /var/www/cert \
	&& chown -R www:www  /var/www/cert \
	&& chmod 600 /var/www/cert

VOLUME [ "/var/www" ]



STOPSIGNAL SIGTERM
# 声明要暴露的端口，随机ip时可能有用。
EXPOSE 80 443 20 21 21000-21010
ENTRYPOINT ["/bin/startRunNginxFtp.sh"]
# RUN pure-pw useradd yetu –u www –D /var/www/ < docker-pureftpd/ftppassword