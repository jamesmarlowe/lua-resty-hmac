Name
====

lua-resty-hmac - Lua library for making and receiving hmac signed requests

Table of Contents
=================

* [Name](#name)
* [Status](#status)
* [Description](#description)
* [Synopsis](#synopsis)
* [Methods](#methods)
    * [new](#new)
    * [generate_signature](#generate_signature)
    * [check_signature](#check_signature)
    * [generate_headers](#generate_headers)
    * [check_headers](#check_headers)
* [Limitations](#limitations)
* [Installation](#installation)
* [TODO](#todo)
* [Community](#community)
    * [English Mailing List](#english-mailing-list)
    * [Chinese Mailing List](#chinese-mailing-list)
* [Testing](#testing)
* [Bugs and Patches](#bugs-and-patches)
* [Author](#author)
* [Copyright and License](#copyright-and-license)
* [See Also](#see-also)

Status
======

This library is still under early development and considered experimental.

Description
===========

This Lua library is a hmac utility for the ngx_lua nginx module:

Synopsis
========

```lua
    lua_package_path "/path/to/lua-resty-hmac/lib/?.lua;;";

    server {
        location /test {
            content_by_lua '
                local hmac = require "resty.hmac"
                local hm, err = hmac:new("SigningKey")
                
                local date = os.date("!%a, %d %b %Y %H:%M:%S +0000")
                local destination = "/path/to/new/file.txt"
                local StringToSign = "PUT"..string.char(10)..string.char(10)..string.char(10)..date..string.char(10)..destination
                
                local headers, err = hm:generate_headers("AWS", "AccessKeyId", "sha1", StringToSign)
                
                if headers then
                    ngx.say("headers generated")
                else
                    ngx.say(err)
                end
                
                res = ngx.location.capture(
                    "/upload/to/s3/",
                    { method = ngx.HTTP_PUT, body = "Test Upload Content",
                      args = {date = headers.date, auth = headers.auth, file = destination}}
                )
                
                if res.status == 200 then
                    ngx.say("uploaded successfully")
                else
                    ngx.say("upload failed")
                end
            ';
        }
        
        location /upload/to/s3/ {
            internal;
            resolver 8.8.8.8;
            set_unescape_uri $date $arg_date;
            set_unescape_uri $auth $arg_auth;
            set_unescape_uri $file $arg_file;

            proxy_pass_request_headers off;
            more_clear_headers 'Host';
            more_clear_headers 'Connection';
            more_clear_headers 'Content-Length';
            more_clear_headers 'User-Agent';
            more_clear_headers 'Accept';

            proxy_set_header Date $date;
            proxy_set_header Authorization $auth;
            proxy_set_header content-type '';
            proxy_set_header Content-MD5 '';

            proxy_pass http://s3.amazonaws.com$file;
        }
    }
```

[Back to TOC](#table-of-contents)

Methods
=======

All of the commands return either something that evaluates to true on success, or `nil` and an error message on failure.

new
---
`syntax: hm, err = hmac:new("SigningKey")`

Creates a signing object. In case of failures, returns `nil` and a string describing the error.

[Back to TOC](#table-of-contents)

generate_signature
------------------
`syntax: sig, err = hm:generate_signature(dtype, message, delimiter)`

`syntax: sig, err = hm:generate_signature("sha1", "StringToSign")`

Attempts to sign a message using the algorithm set by dtype and the key set with new(). It can also be called using a table as the message with a delimiter used when concatenating the arguments which defaults to a newline (char 10).

```
local args = {"PUT","/path/to/file/","Wed, 19 Mar 2014 21:45:06 +0000"}
local sig, err = hm:generate_signature("sha1", args)
```

In case of success, returns the signature. In case of errors, returns `nil` with a string describing the error.

[Back to TOC](#table-of-contents)

check_signature
------------------
`syntax: ok, err = hm:check_signature(dtype, message, delimiter, signature)`

`syntax: ok, err = hm:check_signature("sha1", "StringToSign", nil, "bo1h3498v3")`

Attempts to sign a message and compare it with a precomputed signature.

```
local args = {"PUT","/path/to/file/","Wed, 19 Mar 2014 21:45:06 +0000"}
local ok, err = hm:check_signature("sha1", args, nil, "bo1h3498v3")
```

In case of success, returns `true`. In case of errors, returns `false` with a string describing the error.

[Back to TOC](#table-of-contents)

generate_headers
------------------
`syntax: headers, err = hm:generate_headers(service, id, dtype, message, delimiter)`

`syntax: headers, err = hm:generate_headers("AWS", "AccessKeyId", "sha1", "StringToSign")`

Attempts to generate the date and an authentication string for use in an auth header.

In case of success, returns a table `{date = date, auth = auth}`. In case of errors, returns `nil` with a string describing the error.

[Back to TOC](#table-of-contents)

check_headers
------------------
`syntax: ok, err = hm:check_headers(service, id, dtype, message, delimiter, max_time_diff)`

`syntax: ok, err = hm:check_headers("AWS", "AccessKeyId", "sha1", "StringToSign")`

Attempts to sign a message and compare request headers to computed headers.

In case of success, returns `true`. In case of errors, returns `nil` with a string describing the error.

[Back to TOC](#table-of-contents)

Limitations
===========

* Doesn't support setting which headers to compare against

[Back to TOC](#table-of-contents)

Installation
============
You can install it with luarocks `luarocks install lua-resty-hmac`

Otherwise you need to configure the lua_package_path directive to add the path of your lua-resty-hmac source tree to ngx_lua's LUA_PATH search path, as in

```nginx
    # nginx.conf
    http {
        lua_package_path "/path/to/lua-resty-hmac/lib/?.lua;;";
        ...
    }
```

This package also requires the luacrypto package to be installed http://luarocks.org/repositories/rocks/#luacrypto

Ensure that the system account running your Nginx ''worker'' proceses have
enough permission to read the `.lua` file.

Docker
------
I've also made a docker image to make setup of the nginx environment easier. View details here: https://registry.hub.docker.com/u/jamesmarlowe/lua-resty-hmac/
```
# install docker according to http://docs.docker.com/installation/

# pull image
sudo docker pull jamesmarlowe/lua-resty-hmac

# make sure it is there
sudo docker images

# run the image
sudo docker run -t -i jamesmarlowe/lua-resty-hmac
```

[Back to TOC](#table-of-contents)

TODO
====

[Back to TOC](#table-of-contents)

Community
=========

[Back to TOC](#table-of-contents)

English Mailing List
--------------------

The [openresty-en](https://groups.google.com/group/openresty-en) mailing list is for English speakers.

[Back to TOC](#table-of-contents)

Chinese Mailing List
--------------------

The [openresty](https://groups.google.com/group/openresty) mailing list is for Chinese speakers.

[Back to TOC](#table-of-contents)

Testing
=======

Running the tests in t/ is simple once you know whats happening. They use perl's prove and agentzh's test-nginx.

```
sudo apt-get install perl build-essential curl
sudo cpan Test::Nginx
mkdir -p ~/work 
cd ~/work 
git clone https://github.com/agentzh/test-nginx.git 
cd /path/to/lua-resty-hmac/
make test #assumes openresty installed to /usr/bin/openresty/
```

[Back to TOC](#table-of-contents)

Bugs and Patches
================

Please report bugs or submit patches by

1. creating a ticket on the [GitHub Issue Tracker](http://github.com/jamesmarlowe/lua-resty-hmac/issues),

[Back to TOC](#table-of-contents)

Author
======

James Marlowe "jamesmarlowe" <jameskmarlowe@gmail.com>, Lumate LLC.

[Back to TOC](#table-of-contents)

Copyright and License
=====================

This module is licensed under the BSD license.

Copyright (C) 2012-2014, by James Marlowe (jamesmarlowe) <jameskmarlowe@gmail.com>, Lumate LLC.

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

[Back to TOC](#table-of-contents)

See Also
========
* the ngx_lua module: http://wiki.nginx.org/HttpLuaModule

[Back to TOC](#table-of-contents)
