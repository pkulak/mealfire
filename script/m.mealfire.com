server {
	listen 80;
	server_name m.mealfire.com;
	
	access_log /home/ubuntu/mealfire/log/nginx_mobile_access.log;
	error_log /home/ubuntu/mealfire/log/nginx_mobile_error.log;
	
	root /home/ubuntu/mobile/;
	index index.html;

	location ~ ^/api/v2/(.*)$ {
  		proxy_pass http://127.0.0.1$request_uri;
		proxy_set_header  X-Real-IP  $remote_addr;
		proxy_set_header Host mealfire.com;
	}
}
