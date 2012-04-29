module Marginalia
  module Comment
    mattr_accessor :components, :comment

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


  end

end
