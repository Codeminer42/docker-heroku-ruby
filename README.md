:warning: This image is based on `heroku/ruby` but **will not**
precompile Rails Assets to prevent the _Connection refused_
problem when using database.

:warning: Development only image!

See https://devcenter.heroku.com/articles/rails-asset-pipeline#troubleshooting.

Based on the modifications performed by Paulo Diovani (https://github.com/letsevents/docker-heroku-ruby).

# Heroku Ruby Docker Image

This image is for use with Heroku Docker CLI.

## Usage

Your project must contain a Rails application with Gemfile and Gemfile.lock and
a appropriate configuration (example with docker-compose):

```yml
version: '3.6'
services:
  web:
    image: lets/docker-heroku-ruby:0.0.1
    container_name: web
    command: bundle exec puma -C config/puma.rb
    env_file: .env
    depends_on:
      - db
      - redis
    volumes:
      - bundler:/app/bundle/ruby/2.4.0
      - user_home:/home/app
      - .:/app/src
    ports:
      - "3000:${PORT}"
    networks:
      - net
    tty: true
    stdin_open: true

volumes:
  user_home:
  bundler:
```

The required stuff are volumes for `bundler` (`/app/bundle/ruby/2.4.0`)  and
app (`/app/src`).  The `/home/app` volume is not required and are present only
for development convenience (pry history, shell history).
