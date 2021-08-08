# marginalia [![Build Status](https://github.com/basecamp/marginalia/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/basecamp/marginalia/actions/workflows/ci.yml)

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

This has been tested and used in production with the mysql2 and pg gems, and is
tested on Rails 5.2 through 6.1, and Ruby 2.6 through 3.0. It is also tested
for sqlite3.

Rails version support will follow supported versions in the [Ruby on Rails maintenance policy](https://guides.rubyonrails.org/maintenance_policy.html)
and Ruby support will follow maintained versions in the [Ruby maintenance policy](https://www.ruby-lang.org/en/downloads/branches/).

Patches are welcome for other database adapters. 

## Installation

    # Gemfile
    gem 'marginalia'

### Customization
Optionally, you can set the application name shown in the log like so in an initializer (e.g. `config/initializers/marginalia.rb`):

    Marginalia.application_name = "BCX"

The name will default to your Rails application name.

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

### Caveats

#### Prepared statements

Be careful when using Marginalia with prepared statements. If you use a component
like `request_id` then every query will be unique and so ActiveRecord will create
a new prepared statement for each potentially exhausting system resources.
[Disable prepared statements](https://guides.rubyonrails.org/configuring.html#configuring-a-postgresql-database)
if you wish to use components with high cardinality values.

## Contributing

Start by bundling and creating the test database:

    bundle
    rake db:mysql:create
    rake db:postgresql:create

Then, running `rake` will run the tests on all the database adapters (`mysql`, `mysql2`, `postgresql` and `sqlite`):

    rake

