> Note: This is a fork of marginalia with the rails-specific stuff thrown out.

# marginalia [![Build Status](https://travis-ci.org/travis-ci/marginalia.svg?branch=master)](https://travis-ci.org/travis-ci/marginalia)

Attach comments to your ActiveRecord queries. By default, it adds the application, controller, and action names as a
comment at the end of each query.

This helps when searching log files for queries, and seeing where slow queries came from.

For example, once enabled, your logs will look like:

    Account Load (0.3ms)  SELECT `accounts`.* FROM `accounts`
    WHERE `accounts`.`queenbee_id` = 1234567890
    LIMIT 1
    /*app=api,endpoint=Travis::API::V3::Services::Repositories::ForCurrentUser,request_id=123e4567-e89b-12d3-a456-426655440000*/

You can also use these query comments along with a tool like [pt-query-digest](http://www.percona.com/doc/percona-toolkit/2.1/pt-query-digest.html#query-reviews)
to automate identification of controllers and actions that are hotspots for slow queries.

This gem was created at 37signals. You can read more about how we use it [on
our blog](http://37signals.com/svn/posts/3130-tech-note-mysql-query-comments-in-rails).

This has been tested and used in production with both the mysql and mysql2 gems,
tested on Rails 2.3.5 through 4.1.x. It has also been tested for sqlite3 and postgres.

Patches are welcome for other database adapters.

## Installation

Add the gem to your Gemfile:

    # Gemfile
    gem 'marginalia', git: 'https://github.com/travis-ci/marginalia'

Then in your code, register install the monkey patches:

    require 'active_record/connection_adapters/postgresql_adapter'
    require 'marginalia'

    # once on app boot
    Marginalia.install

    # for every request
    Marginalia.set('app', 'api')
    Marginalia.set('request_id', '123e4567-e89b-12d3-a456-426655440000')
    ...
    Marginalia.clear!

## Contributing

Start by bundling and creating the test database:

    bundle
    rake db:mysql:create
    rake db:postgresql:create

Then, running `rake` will run the tests on all the database adapters (`mysql`, `mysql2`, `postgresql` and `sqlite`):

    rake
