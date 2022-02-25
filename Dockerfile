FROM ruby:2.7.4

ENV BUNDLER_VERSION 2.2.26

RUN gem install bundler --version "$BUNDLER_VERSION"

# CUSTOMIZED --------------------------------------------------
RUN mkdir /app
WORKDIR /app
ADD app/Gemfile /app/Gemfile
ADD app/Gemfile.lock /app/Gemfile.lock
RUN bundle install
ADD ./app /app

EXPOSE 4567
CMD ["ruby", "/app/app.rb"]
