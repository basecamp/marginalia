require 'marginalia'
require 'pg'

module Marginalia
  module PgConnectionMonkeyPatch
    def exec(sql, *args)
      comment = Marginalia.construct_comment
      if comment && comment != "" && !sql.include?(comment)
        super "#{sql} #{comment}", *args
      else
        super sql, *args
      end
    end

    def query(sql, *args)
      comment = Marginalia.construct_comment
      if comment && comment != "" && !sql.include?(comment)
        super "#{sql} #{comment}", *args
      else
        super sql, *args
      end
    end

    def async_exec(sql, *args)
      comment = Marginalia.construct_comment
      if comment && comment != "" && !sql.include?(comment)
        super "#{sql} #{comment}", *args
      else
        super sql, *args
      end
    end

    def async_query(sql, *args)
      comment = Marginalia.construct_comment
      if comment && comment != "" && !sql.include?(comment)
        super "#{sql} #{comment}", *args
      else
        super sql, *args
      end
    end
  end
end

module Marginalia
  module PgInstrumentation
    def self.install
      PG::Connection.prepend(Marginalia::PgConnectionMonkeyPatch)
    end
  end
end
