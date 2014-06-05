# vim:set ft= ts=4 sw=4 et:

use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;;";
    lua_package_cpath "/usr/local/openresty-debug/lualib/?.so;/usr/local/openresty/lualib/?.so;;";
};

$ENV{TEST_NGINX_RESOLVER} = '8.8.8.8';

no_long_string();
#no_diff();

run_tests();

__DATA__

=== TEST 1: sign a message
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local hmac = require "resty.hmac"
            local hm = hmac:new("SigningKey")

            local signature, err = hm:generate_signature("sha1","Asd|zxc|qwe")
            if not signature then
                ngx.say("failed to sign message: ", err)
                return
            end
            
            ngx.say(signature)
        ';
    }
--- request
GET /t
--- response_body
Jk9+HAezinRE9cTmGVpdzcmA1WU=
--- no_error_log
[error]



=== TEST 2: check a signature
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local hmac = require "resty.hmac"
            local hm = hmac:new("SigningKey")
            local StringToSign = "Asd|zxc|qwe"

            local signature, err = hm:check_signature("sha1",StringToSign, nil, "Jk9+HAezinRE9cTmGVpdzcmA1WU=")
            if not signature then
                ngx.say("failed to sign message: ", err)
                return
            end
            
            ngx.say(err)
        ';
    }
--- request
GET /t
--- response_body
signature matches
--- no_error_log
[error]



=== TEST 3: check the auth header generation
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua '
            local hmac = require "resty.hmac"
            local hm = hmac:new("SigningKey")
            local StringToSign = "Asd|zxc|qwe"

            local headers, err = hm:generate_headers("AWS", "AccessKeyId", "sha1", StringToSign)
            if not headers then
                ngx.say("failed to sign message: ", err)
                return
            end
            
            ngx.say(headers.date)
            ngx.say(headers.auth)
        ';
    }
--- request
GET /t
--- response_body_like chop
^\S+, \d+ \S+ \d+ \d+:\d+:\d+ \+0000\nAWS AccessKeyId\:Jk9\+HAezinRE9cTmGVpdzcmA1WU\=$
--- no_error_log
[error]



=== TEST 4: generate a request and check the auth headers
--- http_config eval: $::HttpConfig
--- config
    location /v {
        content_by_lua '
            local hmac = require "resty.hmac"
            local hm, err = hmac:new("SigningKey")
            local StringToSign = "Asd|zxc|qwe"
            local ok, err = hm:check_headers("MYSERVICE", "AccessKeyId", "sha1", StringToSign)
            
            if ok then
                ngx.print("authentication complete")
            else
                ngx.print("authentication failed: ", err)
            end
        ';
    }
    location /u {
        internal;
        set_unescape_uri $date $arg_date;
        set_unescape_uri $auth $arg_auth;
        proxy_set_header Date $date;
        proxy_set_header Authorization $auth;
        proxy_pass_request_headers off;

        proxy_pass http://127.0.0.1:$server_port/v;
    }
    location /t {
        content_by_lua '
            local hmac = require "resty.hmac"
            local hm, err = hmac:new("SigningKey")
            local StringToSign = "Asd|zxc|qwe"
            local headers, err = hm:generate_headers("MYSERVICE", "AccessKeyId", "sha1", StringToSign)
        
            res = ngx.location.capture(
                "/u",
                { method = ngx.HTTP_GET, body = "Test Upload Content",
                  args = {date = headers.date, auth = headers.auth}}
            )
            
            if res.body then
                ngx.say(res.body)
            else
                ngx.say("failed: ", err)
            end
        ';
    }
--- request
GET /t
--- response_body
authentication complete
--- no_error_log
[error]
