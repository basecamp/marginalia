# marginalia

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
tested on Rails 2.3.5 through 3.2-stable. Patches are welcome for other database adapters. 

## Installation

### For Rails 3.x:

    gem 'marginalia'

Then `bundle`, and that's it!

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

## Contributing

Start by bundling and creating the test database:

    bundle
    rake db:create

Then, running `rake` will run the tests on both the `mysql` and `mysql2` adapters:

    rake

