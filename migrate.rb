require File.expand_path('app.rb', File.dirname(__FILE__))
require 'sequel/extensions/migration'

Sequel::MySQL.default_engine = 'InnoDB'
DB.loggers << Logger.new($stdout)

if ARGV.length > 0
  target = ARGV[0].to_i
else
  target = nil
end

Sequel::Migrator.apply(DB, 'migrations', target)