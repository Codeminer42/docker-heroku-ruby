FROM heroku/heroku:16
MAINTAINER Samuel Brandão <samuel@lets.events>

#
# build dependencies
#
ARG PG_VERSION=9.5.3
ARG PG_DOWNLOAD_SHA256=1f070a8e80ce749e687d2162e4a27107e2cc1703a471540e08111bbfb5853f9e

RUN set -ex \
  # Install ubuntu packages for development
  && DEBIAN_FRONTEND=noninteractive apt-get update -y \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    apt-transport-https \
    autoconf \
    bison \
    build-essential \
    imagemagick \
    libffi-dev \
    libgdbm3 \
    libgdbm-dev \
    libncurses5-dev \
    libreadline6-dev \
    libssl-dev \
    libyaml-dev \
    python \
    zlib1g-dev \
  # remove apt files
  && DEBIAN_FRONTEND=noninteractive apt-get -y clean \
  && rm -rf /var/lib/apt/lists/*

RUN set -ex \
  # install postgresql client
  && curl -sL http://ftp.postgresql.org/pub/source/v${PG_VERSION}/postgresql-${PG_VERSION}.tar.gz -o /tmp/postgresql.tar.gz \
  && echo "$PG_DOWNLOAD_SHA256 /tmp/postgresql.tar.gz" | sha256sum -c - \
  && mkdir -p /tmp/postgresql \
  && tar -xzf /tmp/postgresql.tar.gz -C /tmp/postgresql --strip-components=1 \
  && cd /tmp/postgresql \
  && CFLAGS="-O3 -pipe" ./configure --prefix=/usr/local 1>/dev/null \
  && make -j"$(getconf _NPROCESSORS_ONLN)" install 1>/dev/null 2>/dev/null \
  && cd /tmp \
  && rm -rf /tmp/postgresql*

#
# binary dependencies
#

ARG BASE_DIR=/app
ARG RUBY_VERSION=2.4.0
ARG NODE_VERSION=0.12.7
ARG RUBY_TGZ_SOURCE=https://heroku-buildpack-ruby.s3.amazonaws.com/cedar-14/ruby-${RUBY_VERSION}.tgz
ARG NODE_TGZ_SOURCE=http://s3pository.heroku.com/node/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz
ARG RUBY_DIR=${BASE_DIR}/ruby/${RUBY_VERSION}
ARG NODE_DIR=${BASE_DIR}/node/${NODE_VERSION}


RUN set -ex \
  && mkdir -p ${RUBY_DIR} ${NODE_DIR} \
  # Install Ruby
  && curl -s --retry 3 -L ${RUBY_TGZ_SOURCE} | tar xz -C ${RUBY_DIR} \
  # Install Node
  && curl -s --retry 3 -L ${NODE_TGZ_SOURCE} | tar xz --strip-components=1 -C ${NODE_DIR}

#
# app setup
#

ARG BUNDLER_VERSION=1.16.1
ARG GEM_ROOT_DIR=${BASE_DIR}/bundle
ARG SRC_DIR=${BASE_DIR}/src
ARG USER_ID=1000
ARG GROUP=users

ENV BUNDLE_PATH=${GEM_ROOT_DIR} \
    PATH=${RUBY_DIR}/bin:${NODE_DIR}/bin:${GEM_ROOT_DIR}/bin:${PATH}

RUN set -ex \
  # setup dependencies for bundle install - expected to be used at runtime and with a volume mounted at ${GEM_ROOT_DIR}
  && mkdir -p ${BUNDLE_PATH} ${SRC_DIR} \
  # Configure rubygems
  && echo "gem: --no-rdoc --no-ri" >> /etc/gemrc \
  # Install Bundler
  && gem install bundler -v ${BUNDLER_VERSION} \
  # Add non root user
  && useradd --uid $USER_ID --groups $GROUP -m app \
  && chown -R $USER_ID.$GROUP ${BASE_DIR} /home/app

WORKDIR $SRC_DIR
USER $USER_ID
