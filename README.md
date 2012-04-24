# query_comments

Attach comments to your ActiveRecord queries. By default, it adds the application, controller, and action names as a
comment at the end of each query.

This helps when searching log files for queries, and seeing where slow queries came from.

For example, once enabled, your logs will look like:

    Account Load (0.3ms)  SELECT `accounts`.* FROM `accounts` 
    WHERE `accounts`.`queenbee_id` = 1234567890 
    LIMIT 1 
    /*application:BCX,controller:project_imports,action:show*/

You can also these query comments with a tool like [pt-query-digest](http://www.percona.com/doc/percona-toolkit/2.1/pt-query-digest.html#query-reviews) 
to automate identification of controllers and actions that are hotspots forslow queries.

This gem was created at 37signals. You can read more about how we use it [on
our blog](http://37signals.com/svn/posts/3130-tech-note-mysql-query-comments-in-rails).

## Installation

### For Rails 3.x:

    gem 'query_comments'

Then `bundle`, and that's it!

### For Rails 2.x:

If using cached externals, add to your `config/externals.yml` file.

Or, if your prefer using `config.gem`, you can use:

    config.gem 'query_comments'

Finally, if bundled, you'll need to manually run the initialization step in an
initializer, e.g.:
    
    # Gemfile
    gem 'query_comments', :require => false

    #config/initializers/query_comments.rb
    require 'query_comments'
    QueryComments::Railtie.insert

### Customization
Optionally, you can set the application name shown in the log like so in an initializer (e.g. `config/initializers/query_comments.rb`):

    QueryComments.application_name = "BCX"

For Rails 3 applications, the name will default to your Rails application name.
For Rails 2 applications, "rails" is used as the default application name.

## Support

mysql and mysql2 gems, tested on Rails 2.3.5 through 3.2-stable. Patches are welcome for other database adapters. 

## Contributing

Start by bundling and creating the test database:

    bundle
    rake db:create

Then, running `rake` will run the tests just on the original MySQL adapter:

    rake

To run the test suite against both `mysql2` and the original adapter:

    rake test:all

