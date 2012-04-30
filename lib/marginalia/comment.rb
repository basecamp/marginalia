module Marginalia
  module Comment
    mattr_accessor :components, :comment, :lines_to_ignore

    def self.update!(controller = nil)
      @controller = controller
      self.comment = self.components.collect{|c| "#{c}:#{self.send(c) }" }.join(",")
    end

    def self.to_s
      self.comment
    end

    def self.clear!
      self.comment = nil
    end

    private
      def self.application
        if defined? Rails.application
          Marginalia.application_name ||= Rails.application.class.name.split("::").first
        else
          Marginalia.application_name ||= "rails"
        end

        Marginalia.application_name
      end

      def self.controller
        @controller.controller_name if @controller.respond_to? :controller_name
      end

      def self.action
        @controller.action_name if @controller.respond_to? :action_name 
      end

      def self.line
        Marginalia::Comment.lines_to_ignore ||= /\.rvm|gem|vendor|marginalia|rbenv/
        last_line = caller.detect { |line| line !~ Marginalia::Comment.lines_to_ignore }
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

  end

end
