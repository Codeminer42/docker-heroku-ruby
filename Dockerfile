FROM heroku/heroku:16
MAINTAINER Samuel Brandão <samuel@lets.events>

ARG USER_ID
ARG GROUP=users
ARG RUBY_VERSION=2.4.0
ARG NODE_VERSION=0.12.7
ARG BUNDLER_VERSION=1.15.1
ARG VENDOR_PATH=/app/vendor
ARG RUBY_TGZ_SOURCE=https://heroku-buildpack-ruby.s3.amazonaws.com/cedar-14/ruby-${RUBY_VERSION}.tgz
ARG NODE_TGZ_SOURCE=http://s3pository.heroku.com/node/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz
ARG BASE_DIR=/app
ARG RUBY_DIR=${BASE_DIR}/ruby-${RUBY_VERSION}
ARG NODE_DIR=${BASE_DIR}/node-${NODE_VERSION}
ARG GEM_ROOT_DIR=${BASE_DIR}/bundle/ruby/${RUBY_VERSION}
ARG APP_DIR=${BASE_DIR}/src

ENV GEM_HOME=${GEM_ROOT_DIR} \
    BUNDLE_PATH=${GEM_ROOT_DIR} \
    BUNDLE_APP_CONFIG=${GEM_ROOT_DIR} \
    GEM_PATH=${GEM_ROOT_DIR} \
    BUNDLE_BIN=${GEM_ROOT_DIR}/bin \
    PATH=${RUBY_DIR}/bin:${NODE_DIR}/bin:${GEM_ROOT_DIR}/bin:${PATH} \
    PG_VERSION=9.5.3 \
    PG_DOWNLOAD_SHA256=1f070a8e80ce749e687d2162e4a27107e2cc1703a471540e08111bbfb5853f9e

RUN set -ex \
  && mkdir -p ${BUNDLE_BIN} ${RUBY_DIR} ${NODE_DIR} ${APP_DIR} \
  # Install Ruby
  && curl -s --retry 3 -L ${RUBY_TGZ_SOURCE} | tar xz -C ${RUBY_DIR} \
  # Install Node
  && curl -s --retry 3 -L ${NODE_TGZ_SOURCE} | tar xz --strip-components=1 -C ${NODE_DIR} \
  # Configure rubygems
  && echo "gem: --no-rdoc --no-ri" >> /etc/gemrc \
  # Install Bundler
  && gem install bundler -v ${BUNDLER_VERSION} \
  # Add non root user
  && useradd --uid $USER_ID --groups $GROUP -m app \
  && chown -R $USER_ID.$GROUP ${BASE_DIR} /home/app

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
  # setup dependencies for bundle install - expected to be used at runtime and with a volume mounted at ${GEM_ROOT_DIR}
  && curl -sL http://ftp.postgresql.org/pub/source/v${PG_VERSION}/postgresql-${PG_VERSION}.tar.gz -o /tmp/postgresql.tar.gz \
  && echo "$PG_DOWNLOAD_SHA256 /tmp/postgresql.tar.gz" | sha256sum -c - \
  && mkdir -p /tmp/postgresql \
  && tar -xzf /tmp/postgresql.tar.gz -C /tmp/postgresql --strip-components=1 \
  && cd /tmp/postgresql \
  && CFLAGS="-O3 -pipe" ./configure --prefix=/usr/local 1>/dev/null \
  && make -j"$(getconf _NPROCESSORS_ONLN)" install 1>/dev/null 2>/dev/null \
  && cd /tmp \
  && rm -rf /tmp/postgresql*

WORKDIR $APP_DIR
USER $USER_ID
