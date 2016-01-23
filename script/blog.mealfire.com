server {
	listen 80;
	server_name blog.mealfire.com;
	
	access_log /home/rack/mealfire/log/nginx_blog_access.log;
	error_log /home/rack/mealfire/log/nginx_blog_error.log;
	
	root /home/rack/blog/_site/;
	index index.html;
}
