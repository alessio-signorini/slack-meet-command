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
    
    db_url = ENV.fetch('DATABASE_URL', 'sqlite://db/development.sqlite3')
    Sequel.extension :migration
    db = Sequel.connect(db_url)
    
    Sequel::Migrator.run(db, 'db/migrations')
    puts 'Database migrations complete!'
  end
end

task default: :test
