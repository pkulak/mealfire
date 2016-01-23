upstream mealfire {
	server 127.0.0.1:3000;
	server 127.0.0.1:3001;
	server 127.0.0.1:3002;
}

server {
	listen 80;
	server_name www.mealfire.com;
	rewrite ^/(.*) http://mealfire.com/$1 permanent;
}

server {
	listen 80;
	server_name mealfire.com;
	
	access_log /home/ubuntu/mealfire/log/nginx_access.log;
	error_log /home/ubuntu/mealfire/log/nginx_error.log;
	
	root /home/ubuntu/mealfire/public/;
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
			proxy_pass http://mealfire;
			break;
		}
	}
}
