# Coming Elections

A simple service to alert you of upcoming elections in Canada.

## Development

    git clone git@github.com:opennorth/comingelections.git
    bundle
    bundle exec rake db:setup
    bundle exec rake scheduler:scrape
    rails s

## Deployment

    heroku apps:create --addons scheduler:standard sendgrid:starter
    heroku config:add SECRET_KEY_BASE=`bundle exec rake secret`
    git push heroku master

## Bugs? Questions?

This repository is on GitHub: [http://github.com/opennorth/comingelections](http://github.com/opennorth/comingelections), where your contributions, forks, bug reports, feature requests, and feedback are greatly welcomed.

Copyright (c) 2013 Open North Inc., released under the MIT license
