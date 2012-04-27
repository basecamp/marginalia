require 'marginalia/railtie'

module Marginalia
  mattr_accessor :comment, :application_name

  module ActiveRecordInstrumentation
    def self.included(instrumented_class)
      if defined? Rails.application
        Marginalia.application_name = Rails.application.class.name.split("::").first
      end
      instrumented_class.class_eval do
        if defined? :execute
          alias_method :execute_without_marginalia, :execute
          alias_method :execute, :execute_with_marginalia
        end
      end
    end

    def execute_with_marginalia(sql, name = nil)
      last_line = caller.detect { |line| line !~ /\.rvm|gem|vendor/ }
      
      root = if defined?(Rails) && Rails.respond_to?(:root)
        Rails.root.to_s
      elsif defined?(RAILS_ROOT)
        RAILS_ROOT
      else
        ""
      end
      
      if last_line.starts_with? root
        last_line = last_line[root.length..-1]
      end

      execute_without_marginalia("#{sql} /* #{ last_line } -- #{ Marginalia.comment } */", name)
    end
  end

end
