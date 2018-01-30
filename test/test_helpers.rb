class TestHelpers
  def self.create_db(db_name:, db_port:, log_file:)
    PgInstance.create(db_name, db_port, log_file)
  end

  def self.drop_db(instance:)
    PgInstance.drop_db(instance.port, instance.db_name)
  end

  def self.copy_pid(instance:, to_file:)
    pidfile = "#{instance.directory}/postmaster.pid"
    pid = File.open(pidfile) {|f| f.readline }
    File.open(to_file, "a") { |f| f.puts pid }
  end

  def self.file_contains_string(file, string, debug=false)
    File.foreach(file) do |line|
      puts line if debug
      return true if line.include?(string)
    end
    false
  end

  def self.truncate_file(file)
    File.truncate(file, 0)
  end
end

class PgInstance
  attr_reader :directory, :port, :db_name, :db_log_file

  def initialize(directory, name, port, log_file)
    @directory = directory
    @port = port
    @db_name = name
    @db_log_file = log_file
  end

  def self.create(name, port, log_file)
    dir = "tmp"
    self.initialize_pg_cluster(dir)
    self.start_cluster(port, dir, log_file)
    self.create_db(port, name)
    new(dir, name, port, log_file)
  end

  def self.initialize_pg_cluster(dir)
    %x[mkdir -p "tmp"]
    %x[initdb -A trust -D#{dir}]
  end

  def self.start_cluster(port, dir, log_file)
    %x[pg_ctl -o"-p #{port}" -D#{dir} -l#{log_file} start]
  end

  def self.create_db(port, name)
    %x[createdb -p#{port} #{name}]
  end

  def self.destroy(instance:)
    self.drop_db(instance.port, instance.db_name)
    self.stop_cluster(instance.port, instance.directory)
    self.remove_logfile(instance.db_log_file)
  end

  def self.drop_db(port, name)
    system("dropdb -p#{port} #{name}")
  end

  def self.stop_cluster(port, directory)
    system("pg_ctl -o'-p #{port}' -D#{directory} stop")
  end

  def self.remove_logfile(logfile)
    system("rm #{logfile}")
  end
end
