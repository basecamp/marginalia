# marginalia [![Build Status](https://travis-ci.org/basecamp/marginalia.svg?branch=master)](https://travis-ci.org/basecamp/marginalia)

Attach comments to your ActiveRecord queries. By default, it adds the application, controller, and action names as a
comment at the end of each query.

This helps when searching log files for queries, and seeing where slow queries came from.

For example, once enabled, your logs will look like:

    Account Load (0.3ms)  SELECT `accounts`.* FROM `accounts` 
    WHERE `accounts`.`queenbee_id` = 1234567890 
    LIMIT 1 
    /*application:BCX,controller:project_imports,action:show*/

You can also use these query comments along with a tool like [pt-query-digest](http://www.percona.com/doc/percona-toolkit/2.1/pt-query-digest.html#query-reviews) 
to automate identification of controllers and actions that are hotspots forslow queries.

This gem was created at 37signals. You can read more about how we use it [on
our blog](http://37signals.com/svn/posts/3130-tech-note-mysql-query-comments-in-rails).

This has been tested and used in production with both the mysql and mysql2 gems, 
tested on Rails 2.3.5 through 4.0-stable. It has also been tested for sqlite3 and postgres.

Patches are welcome for other database adapters. 

## Installation

### For Rails 3.x and 4.0:

    # Gemfile
    gem 'marginalia'
    
    # config/application.rb
    require 'marginalia/railtie'


### For Rails 2.x:

If using cached externals, add to your `config/externals.yml` file.

Or, if your prefer using `config.gem`, you can use:

    config.gem 'marginalia'

Finally, if bundled, you'll need to manually run the initialization step in an
initializer, e.g.:
    
    # Gemfile
    gem 'marginalia', :require => false

    #config/initializers/marginalia.rb
    require 'marginalia'
    Marginalia::Railtie.insert

### Customization
Optionally, you can set the application name shown in the log like so in an initializer (e.g. `config/initializers/marginalia.rb`):

    Marginalia.application_name = "BCX"

For Rails 3 applications, the name will default to your Rails application name.
For Rails 2 applications, "rails" is used as the default application name.

You can also configure the components of the comment that will be appended,
by setting `Marginalia::Comment.components`. By default, this is set to:

    Marginalia::Comment.components = [:application, :controller, :action]

Which results in a comment of
`application:#{application_name},controller:#{controller.name},action:#{action_name}`.

You can re-order or remove these components. You can also add additional
comment components of your desire by defining new module methods for
`Marginalia::Comment` which return a string. For example:

    module Marginalia
      module Comment
        def self.mycommentcomponent
          "TEST"
        end
      end
    end

    Marginalia::Comment.components = [:application, :mycommentcomponent]

Which will result in a comment like
`application:#{application_name},mycommentcomponent:TEST`
The calling controller is available to these methods via `@controller`.

Marginalia ships with `:application`, `:controller`, and `:action` enabled by
default. In addition, implementation is provided for:
  * `:line` (for file and line number calling query). :line supports
    a configuration by setting a regexp in `Marginalia::Comment.lines_to_ignore`
    to exclude parts of the stacktrace from inclusion in the line comment.

Pull requests for other included comment components are welcome.

## Contributing

Start by bundling and creating the test database:

    bundle
    rake db:create

Then, running `rake` will run the tests on both the `mysql` and `mysql2` adapters:

    rake

