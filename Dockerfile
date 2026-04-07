FROM node:20-slim AS nodejs

FROM ruby:3.3.0-slim

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    libpq-dev \
    libyaml-dev \
    vim \
    && rm -rf /var/lib/apt/lists/*

COPY --from=nodejs /usr/local /usr/local

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json yarn.lock* ./
RUN npm install

COPY . .

CMD ["bin/rails", "server", "-b", "0.0.0.0"]
