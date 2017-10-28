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

ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

CMD ["puma"]
