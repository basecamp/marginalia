# query_comments

Attach comments to your ActiveRecord queries. By default, it adds the application, controller, and action names to each query.

This gem helps immensely when searching log files for queries, and seeing where slow queries came from.

For example, once enabled, your logs will look like:

    Account Load (0.3ms)  SELECT `accounts`.* FROM `accounts` 
    WHERE `accounts`.`queenbee_id` = 1234567890 
    LIMIT 1 
    /*application:BCX,controller:project_imports,action:show*/

## Install

For Rails 3.x:

    gem 'query_comments'

Then `bundle`, and that's it!

For Rails 2.x:

    config.gem 'query_comments'

Set the application name shown in the log like so, perhaps in `config/initializers/query_comments.rb`:

    QueryComments.application_name = "BCX"

## Support

MySQL only, currently. Tested with mysql and mysql2 gems. Patches are welcome for other database adapters (with tests, of course).

## Contributing

Start by bundling and creating the test database:

    bundle
    rake db:create

Then, running `rake` will run the tests just on the original MySQL adapter:

    rake

To run the test suite against both `mysql2` and the original adapter:

    rake test:all

## Thanks

Big thanks to @thoughtbot's Paperclip gem, which inspired the Rails 2 and 3 style supported Railtie code.

## License

MIT. Please see `LICENSE`.
