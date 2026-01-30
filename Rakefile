require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.libs << 'app'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

namespace :db do
  desc 'Run database migrations'
  task :migrate do
    require 'sequel'
    require 'dotenv/load'
    require 'fileutils'
    require_relative 'db/connection'
    
    Sequel.extension :migration
    db = SlackMeet::Database.connection
    
    Sequel::Migrator.run(db, 'db/migrations')
    puts 'Database migrations complete!'
  end
end

task default: :test
