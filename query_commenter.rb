# Sample query commenter for MySQL in Rails 2.3.x or 3.x.x applications
# 
# Copyright (c) 2012 37signals, LLC
# Maintained by noah@37signals.com
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Could run in an initializer, or place in lib/query_commenter.rb or in a gem
module QueryComments

  module ActiveRecordInstrumentation
    def self.included(instrumented_class)
      instrumented_class.class_eval do
        alias_method :execute_without_instrumentation, :execute
        alias_method :execute, :execute_with_instrumentation
      end
    end

    def execute_with_instrumentation(sql, name = nil)
      sql = "#{sql} /*#{ActiveRecord::Base.query_comment}*/"
      execute_without_instrumentation(sql, name)
    end
  end

  class ActiveRecord::Base
    cattr_accessor :query_comment
  end

  def self.initialize!

    ActionController::Base.class_eval do
      def record_query_comment
        ActiveRecord::Base.query_comment = "application:BCX,controller:#{controller_name},action:#{action_name}"
        yield
      ensure
        ActiveRecord::Base.query_comment = nil
      end
      around_filter :record_query_comment
    end

    if defined? ActiveRecord::ConnectionAdapters::Mysql2Adapter
      ActiveRecord::ConnectionAdapters::Mysql2Adapter.module_eval do
         include QueryComments::ActiveRecordInstrumentation 
      end
    end
    
    if defined? ActiveRecord::ConnectionAdapters::MysqlAdapter
      ActiveRecord::ConnectionAdapters::MysqlAdapter.module_eval do
         include QueryComments::ActiveRecordInstrumentation 
      end
    end
  end
end

# Via an initializer or railtie in a gem, call:
QueryComments.initialize!