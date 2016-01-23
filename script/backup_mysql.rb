#!/usr/bin/env ruby
require 'aws/s3'
include AWS::S3

Base.establish_connection!(
  :access_key_id     => '...',
  :secret_access_key => '...'
)

filename = "mysql_db.#{Date.today.strftime('%Y%m%d')}.sql.gz"
path = "/home/ubuntu/db_backups/#{filename}"
`mysqldump --add-drop-table --ignore-table=mealfire.recipe_texts -u mealfire -"p..." mealfire | gzip > #{path}`

File.open(path, 'r') do |file|
  S3Object.store(filename, file, 'backup.mealfire.com')
end
