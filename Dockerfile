FROM       ubuntu:latest

MAINTAINER James Marlowe <jameskmarlowe@gmail.com>

# update machine
RUN apt-get -qq update
RUN apt-get -qqy upgrade

# install system reqs
RUN apt-get -y install nginx libpq-dev make wget

# install openresty
RUN wget http://openresty.org/download/ngx_openresty-1.5.12.1.tar.gz
RUN tar xzvf ngx_openresty-1.5.12.1.tar.gz 
RUN cd ngx_openresty-1.5.12.1/
RUN ./configure --with-http_stub_status_module --with-http_postgres_module
RUN make
RUN make install
RUN cd

# install luarocks
RUN wget http://luarocks.org/releases/luarocks-2.0.13.tar.gz
RUN tar xzvf luarocks-2.0.13.tar.gz
RUN cd luarocks-2.0.13/
RUN ./configure --prefix=/usr/local/openresty/luajit --with-lua=/usr/local/openresty/luajit/ --lua-suffix=jit-2.1.0-alpha --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1
RUN make
RUN make install
RUN cd

# install the needed rocks
RUN /usr/local/openresty/luajit/bin/luarocks install luacrypto
