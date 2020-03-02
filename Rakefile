require "bundler/gem_tasks"

task :default => ['test:all']

namespace :test do
  desc "test all drivers"
  task :all => [:mysql2, :postgresql, :sqlite]

  desc "test mysql driver"
  task :mysql do
    sh "DRIVER=mysql bundle exec ruby -Ilib -Itest test/*_test.rb"
  end

  desc "test mysql2 driver"
  task :mysql2 do
    sh "DRIVER=mysql2 bundle exec ruby -Ilib -Itest test/*_test.rb"
  end

  desc "test PostgreSQL driver"
  task :postgresql do
    sh "DRIVER=postgresql DB_USERNAME=postgres bundle exec ruby -Ilib -Itest test/*_test.rb"
  end

  desc "test sqlite3 driver"
  task :sqlite do
    sh "DRIVER=sqlite3 bundle exec ruby -Ilib -Itest test/*_test.rb"
  end
end

namespace :db do

  desc "reset all databases"
  task :reset => [:"mysql:reset", :"postgresql:reset"]

  namespace :mysql do
    desc "reset MySQL database"
    task :reset => [:drop, :create]

    desc "create MySQL database"
    task :create do
      sh 'mysql -u root -e "create database marginalia_test;"'
    end

    desc "drop MySQL database"
    task :drop do
      sh 'mysql -u root -e "drop database if exists marginalia_test;"'
    end
  end

  namespace :postgresql do
    desc "reset PostgreSQL database"
    task :reset => [:drop, :create]

    desc "create PostgreSQL database"
    task :create do
      sh 'createdb -U postgres marginalia_test'
    end

    desc "drop PostgreSQL database"
    task :drop do
      sh 'psql -d postgres -U postgres -c "DROP DATABASE IF EXISTS marginalia_test"'
    end
  end
end
