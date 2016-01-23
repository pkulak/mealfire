upstream mealfire_test {
	server 127.0.0.1:7000;
}

server {
	listen 80;
	server_name test.mealfire.com;
	
	access_log /home/rack/mealfire/log/nginx_test_access.log;
	error_log /home/rack/mealfire/log/nginx_test_error.log;
	
	root /home/rack/mealfire/public/;
	index index.html;
	
	location / {
		proxy_set_header X-Real-IP $remote_addr;
		proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
		proxy_set_header Host $http_host;
		proxy_redirect off;
		
		if (-f $request_filename/index.html) {
			rewrite (.*) $1/index.html break;
		}
		
		if (-f $request_filename.html) {
			rewrite (.*) $1.html break;
		}
		
		if (!-f $request_filename) {
			proxy_pass http://mealfire_test;
			break;
		}
	}
}
