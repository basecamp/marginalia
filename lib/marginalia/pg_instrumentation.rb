require 'marginalia'
require 'pg'

module Marginalia
  module PgMonkeyPatch
    def exec(sql)
      comment = Marginalia.construct_comment
      if comment && comment != "" && !sql.include?(comment)
        super "#{sql} #{comment}"
      else
        super sql
      end
    end

    def async_exec(sql, params=nil)
      comment = Marginalia.construct_comment
      if comment && comment != "" && !sql.include?(comment)
        super "#{sql} #{comment}"
      else
        super sql
      end
    end
  end
end

module Marginalia
  module PgInstrumentation
    def self.install
      PG::Connection.prepend(Marginalia::PgMonkeyPatch)
    end
  end
end
