# frozen_string_literal: true

require 'socket'

module Marginalia
  class ThreadState
    attr_accessor :controller, :job
    attr_writer :inline_annotations

    def inline_annotations
      @inline_annotations ||= []
    end
  end

  module Comment
    mattr_accessor :components, :lines_to_ignore, :prepend_comment
    Marginalia::Comment.components ||= [:application, :controller, :action]

    ADAPTER_COMPONENTS = [:socket, :db_host, :database]

    def self.update!(controller = nil)
      self.state.controller = controller
    end

    def self.update_job!(job)
      self.state.job = job
    end

    def self.construct_comment(adapter)
      ret = String.new
      self.components.each do |c|
        component_value = if ADAPTER_COMPONENTS.include?(c)
          self.send(c, adapter)
        else
          self.send(c)
        end
        if component_value.present?
          ret << "#{c}:#{component_value},"
        end
      end
      ret.chop!
      ret = self.escape_sql_comment(ret)
      ret
    end

    def self.construct_inline_comment
      return nil if inline_annotations.none?
      escape_sql_comment(inline_annotations.join)
    end

    def self.escape_sql_comment(str)
      while str.include?('/*') || str.include?('*/')
        str = str.gsub('/*', '').gsub('*/', '')
      end
      str
    end

    def self.clear!
      self.marginalia_controller = nil
    end

    def self.clear_job!
      self.marginalia_job = nil
    end

    private
      def self.marginalia_controller=(controller)
        state.controller = controller
      end

      def self.marginalia_controller
        state.controller
      end

      def self.marginalia_job=(job)
        state.job = job
      end

      def self.marginalia_job
        state.job
      end

      def self.application
        if defined?(Rails.application)
          Marginalia.application_name ||= Rails.application.class.name.split("::").first
        else
          Marginalia.application_name ||= "rails"
        end

        Marginalia.application_name
      end

      def self.job
        marginalia_job.class.name if marginalia_job
      end

      def self.controller
        marginalia_controller.controller_name if marginalia_controller.respond_to? :controller_name
      end

      def self.controller_with_namespace
        marginalia_controller.class.name if marginalia_controller
      end

      def self.action
        marginalia_controller.action_name if marginalia_controller.respond_to? :action_name
      end

      def self.sidekiq_job
        marginalia_job["class"] if marginalia_job && marginalia_job.respond_to?(:[])
      end

      DEFAULT_LINES_TO_IGNORE_REGEX = %r{\.rvm|/ruby/gems/|vendor/|marginalia|rbenv|monitor\.rb.*mon_synchronize}

      def self.line
        Marginalia::Comment.lines_to_ignore ||= DEFAULT_LINES_TO_IGNORE_REGEX

        last_line = caller.detect do |line|
          line !~ Marginalia::Comment.lines_to_ignore
        end
        if last_line
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
          last_line
        end
      end

      def self.hostname
        @cached_hostname ||= Socket.gethostname
      end

      def self.pid
        Process.pid
      end

      def self.request_id
        if marginalia_controller.respond_to?(:request) && marginalia_controller.request.respond_to?(:uuid)
          marginalia_controller.request.uuid
        end
      end

      if Gem::Version.new(ActiveRecord::VERSION::STRING) >= Gem::Version.new('3.2.19')
        def self.socket(adapter)
          connection_config(adapter)[:socket]
        end

        def self.db_host(adapter)
          connection_config(adapter)[:host]
        end

        def self.database(adapter)
          connection_config(adapter)[:database]
        end

        def self.connection_config(adapter)
          return {} if adapter.pool.nil?
          adapter.pool.spec.config
        end
      end

      def self.state
        Thread.current[:marginalia] ||= ThreadState.new
      end

      def self.inline_annotations
        state.inline_annotations
      end
  end

end
