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
to automate identification of controllers and actions that are hotspots for slow queries.

This gem was created at 37signals. You can read more about how we use it [on
our blog](http://37signals.com/svn/posts/3130-tech-note-mysql-query-comments-in-rails).

This has been tested and used in production with both the mysql and mysql2 gems, 
tested on Rails 2.3.5 through 4.1.x. It has also been tested for sqlite3 and postgres.

Patches are welcome for other database adapters. 

## Installation

### For Rails 3.x and 4.x:

    # Gemfile
    gem 'marginalia'

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

#### Components

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
  * `:controller_with_namespace` to include the full classname (including namespace)
    of the controller.
  * `:job` to include the classname of the ActiveJob being performed.
  * `:hostname` to include ```Socket.gethostname```.
  * `:pid` to include current process id. 

With ActiveRecord >= 3.2.19:
  * `:db_host` to include the configured database hostname.
  * `:socket` to include the configured database socket.
  * `:database` to include the configured database name.

Pull requests for other included comment components are welcome.

#### Prepend comments

By default marginalia appends the comments at the end of the query. Certain databases, such as MySQL will truncate
the query text. This is the case for slow query logs and the results of querying some InnoDB internal tables where the
length of the query is more than 1024 bytes.

In order to not lose the marginalia comments from your logs, you can prepend the comments using this option:

    Marginalia::Comment.prepend_comment = true

#### Inline query annotations

In addition to the request or job-level component-based annotations,
Marginalia may be used to add inline annotations to specific queries using a
block-based API.

For example, the following code:

    Marginalia.with_annotation("foo") do
      Account.where(queenbee_id: 1234567890).first
    end

will issue this query:

    Account Load (0.3ms)  SELECT `accounts`.* FROM `accounts`
    WHERE `accounts`.`queenbee_id` = 1234567890
    LIMIT 1
    /*application:BCX,controller:project_imports,action:show*/ /*foo*/

Nesting `with_annotation` blocks will concatenate the comment strings.

#### Customizing key-value formatting

To change the default key-value separator (from `,`), set `Marginalia::Comment.key_value_separator`.
To surround all values with single quotes (`'`) and escape internal quotes as `\'`,
set `Marginalia::Comment.quote_values = :single`.

## Contributing

Start by bundling and creating the test database:

    bundle
    rake db:mysql:create
    rake db:postgresql:create

Then, running `rake` will run the tests on all the database adapters (`mysql`, `mysql2`, `postgresql` and `sqlite`):

    rake

