+++
date = "2015-11-15T13:10:41-08:00"
draft = false
title = "letsencrypt yay"
author = "Richard Genthner"
comments = true
image = ""
menu = ""
share = true
slug = "letsencrypt yay"
tags = ["technology", "encryption"]

+++

### letsencrypt
This is a amazing product that is opensource. I recently decided that this was going to be the way I get my ssl certificates for everything I do. I was
lucky to get into the beta invitation only. It works great. Every 90 days you have regen your certificates but thats not a big deal because they give you
tools to do it.

#### Setup
So you get this going to your going to need to check out their repo.

```
git clone https://github.com/letsencrypt/letsencrypt
  cd letsencrypt
  ./letsencrypt-auto --server \
      https://acme-v01.api.letsencrypt.org/directory --help
```

Next after you get your domains submitted for the beta and registered you will want to do the following commands. Heres how for apache:
```
./letsencrypt-auto --apache --server https://acme-v01.api.letsencrypt.org/directory --agree-dev-preview
```

For standalone Apache you would do the following:
```
./letsencrypt-auto certonly -a standalone \
  -d example.com -d www.example.com \
  --server https://acme-v01.api.letsencrypt.org/directory --agree-dev-preview
  ```

If your like me and use nginx for your server you will need to do the following to get it working:
```
./letsencrypt-auto certonly -a manual -d www.stbtx.com -d example.com -d blog.example.com --webroot-path /var/www/html --server https://acme-v01.api.letsencrypt.org/directory --agree-dev-preview
```
Then you will need to do the following openssl command:
```
openssl dhparam -out dhparam.pem 4096
```

Then in the Nginx server block add the following SSL configuration:
```
# SSL configuration
	listen 443 ssl default_server;
	listen [::]:443 ssl default_server;
	ssl_certificate /etc/letsencrypt/live/{domain}/fullchain.pem;
    	ssl_certificate_key /etc/letsencrypt/live/{domain}/privkey.pem;
    	ssl_session_timeout 1d;
    	ssl_session_cache shared:SSL:10m;
    	ssl_session_tickets off;
	    # openssl dhparam -out dhparam.pem 2048
    	ssl_dhparam /etc/nginx/dhparam.pem;

    	ssl_protocols TLSv1.1 TLSv1.2;
    	ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK';
    	ssl_prefer_server_ciphers on;

    	add_header Strict-Transport-Security max-age=15768000;

    	ssl_stapling on;
    	ssl_stapling_verify on;

    	## verify chain of trust of OCSP response using Root CA and Intermediate certs
    	#ssl_trusted_certificate /path/to/root_CA_cert_plus_intermediates; ## Addition CA certs
    	ssl_trusted_certificate /etc/letsencrypt/live/{domain}/chain.pem;
    	resolver 8.8.8.8 8.8.4.4 valid=86400;
	resolver_timeout 10;
```

Restart your nginx server and you will be golden. This will support HSTS, SPDY and SSL.

There you have deployed letencrypt certificates to your server woot! :) Great job!
