:warning: Development only image!

# Heroku Ruby Docker Image

This image is for use with Heroku Docker CLI.

## Build

Generate a new test image in development environment with:

```sh
bin/build-local.sh
```

A new image will be generated locally with the name
`lets/docker-heroku-ruby-local:latest`. Test the changes you want with this
image and make sure they are all good.

The automated build will generate a new image in dockerhub after the merge to
the master branch.

## Usage

Your project must contain a Rails application with Gemfile and Gemfile.lock and
a appropriate configuration (example with docker-compose):

```yml
version: '3.6'
services:
  web:
    image: lets/docker-heroku-ruby:0.0.2
    container_name: web
    command: bundle exec puma -C config/puma.rb
    env_file: .env
    depends_on:
      - db
      - redis
    volumes:
      - bundler:/app/bundle
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

The required stuff are volumes for `bundler` (`/app/bundle`)  and app
(`/app/src`).  The `/home/app` volume is not required and are present only for
development convenience (pry history, shell history).
