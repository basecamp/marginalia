# query_comments

Attach comments to your ActiveRecord queries. By default, it adds the application, controller, and action to each query.

This gem helps immensely when searching log files for queries, and seeing where slow queries came from.

For example:

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

## Support

MySQL only, currently. Tested with mysql and mysql2 gems. Patches are welcome for other database adapters (with tests, of course).

## License

MIT. Please see `LICENSE`.
