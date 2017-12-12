require 'marginalia'

module Marginalia
  class Setup
    def self.install
      if defined? ActiveRecord::ConnectionAdapters::Mysql2Adapter
        ActiveRecord::ConnectionAdapters::Mysql2Adapter.module_eval do
          include Marginalia::ActiveRecordInstrumentation
        end
      end

      if defined? ActiveRecord::ConnectionAdapters::MysqlAdapter
        ActiveRecord::ConnectionAdapters::MysqlAdapter.module_eval do
          include Marginalia::ActiveRecordInstrumentation
        end
      end

      if defined? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
        ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.module_eval do
          include Marginalia::ActiveRecordInstrumentation
        end
      end

      if defined? ActiveRecord::ConnectionAdapters::SQLite3Adapter
        ActiveRecord::ConnectionAdapters::SQLite3Adapter.module_eval do
          include Marginalia::ActiveRecordInstrumentation
        end
      end
    end
  end
end
