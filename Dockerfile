FROM       ubuntu:latest

MAINTAINER James Marlowe jameskmarlowe@gmail.com

# update machine
RUN apt-get -qq update
RUN apt-get -qqy upgrade 

# install system reqs
RUN apt-get -qqy install nginx libpq-dev make wget libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl unzip

# install openresty
RUN wget http://openresty.org/download/ngx_openresty-1.5.12.1.tar.gz \
    && tar xzf ngx_openresty-1.5.12.1.tar.gz \
    && cd ngx_openresty-1.5.12.1/ \
    && ./configure --with-http_stub_status_module --with-http_postgres_module \
    && make \
    && make install

# install luarocks
RUN wget http://luarocks.org/releases/luarocks-2.0.13.tar.gz \
    && tar xzf luarocks-2.0.13.tar.gz \
    && cd luarocks-2.0.13/ \
    && ./configure --prefix=/usr/local/openresty/luajit --with-lua=/usr/local/openresty/luajit/ --lua-suffix=jit-2.1.0-alpha --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1 \
    && make \
    && make install

# install the needed rocks
RUN /usr/local/openresty/luajit/bin/luarocks install luacrypto
