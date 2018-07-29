require 'rubygems'
require 'rubygems/command.rb'
require 'rubygems/dependency_installer.rb'

begin
  Gem::Command.build_args = ARGV
  rescue NoMethodError
end

installer = Gem::DependencyInstaller.new
begin
  if RUBY_VERSION < "2.4"
    installer.install "mysql", ">=0"
  end
rescue
  exit(1)
end

f = File.open(File.join(File.dirname(__FILE__), "Rakefile"), "w")
f.write("task :default\n")
f.close
