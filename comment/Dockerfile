FROM alpine:latest
ENV APP_HOME /app
WORKDIR $APP_HOME
COPY Gemfile* $APP_HOME/

RUN apk update && apk add ruby ruby-json tzdata \
    && apk add --virtual .build_deps ruby-dev g++ make ruby-bundler \
    && bundle install \
    && apk del .build_deps \
    && gem cleanup \
    && rm -rf /root/.bundle /usr/lib/ruby/gems/*/cache/* /var/cache/apk/*

COPY . $APP_HOME/

ENV COMMENT_DATABASE_HOST comment_db
ENV COMMENT_DATABASE comments

CMD ["puma"]
