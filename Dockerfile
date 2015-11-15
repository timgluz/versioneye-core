FROM alpine:3.2
MAINTAINER  Robert Reiz <reiz@versioneye.com>

ENV RAILS_ENV test
ENV BUNDLE_GEMFILE /rails/Gemfile

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

ENV BUILD_PACKAGES bash curl-dev ruby-dev build-base libxml2-dev libxslt-dev libffi-dev
ENV RUBY_PACKAGES ruby ruby-io-console ruby-bundler

# Update and install all of the required packages.
# At the end, remove the apk cache
RUN apk update && \
    apk upgrade && \
    apk add $BUILD_PACKAGES && \
    apk add $RUBY_PACKAGES && \
    rm -rf /var/cache/apk/*

RUN rm -Rf /rails; mkdir -p /rails; mkdir -p /rails/log; mkdir -p /rails/pids

COPY Gemfile Gemfile.lock /rails/

RUN bundle config build.nokogiri --use-system-libraries
RUN bundle install

COPY . /rails

WORKDIR /rails
