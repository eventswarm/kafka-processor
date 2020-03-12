FROM jruby:9.2

# need git for eventswarm bundle dependencies
RUN apt-get update && apt-get upgrade && apt-get install -y git && apt-get install -y maven

RUN bundle config --global frozen 1

WORKDIR /usr/src/app

# get dependencies installed
COPY Gemfile Gemfile.lock Jarfile Jarfile.lock app.rb ./
RUN bundle install
RUN jruby -S jbundle install

CMD ["bundle", "exec", "jruby", "./app.rb"]
