# Dockerfile
FROM ruby:3.4.3-slim

# 1. Install System Dependencies & Node.js 20
RUN apt-get update -qq && apt-get install -y curl gnupg && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y \
    build-essential \
    pkg-config \
    libvips \
    libvips-dev \
    git \
    libxml2-dev \
    libxslt-dev \
    libyaml-dev \
    nodejs \
    default-libmysqlclient-dev \
    ffmpeg \
    pdftk \
    wkhtmltopdf \
    && rm -rf /var/lib/apt/lists/*

# 2. Set working directory
WORKDIR /app

# 3. Set Environment Variables
ENV RAILS_ENV=production
ENV NODE_ENV=development 
ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true

# 4. Install Ruby Gems
COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle config set --local without 'test' && bundle install

# 5. Install Node dependencies
COPY package.json package-lock.json ./
RUN npm install

# 6. Copy application code
COPY . .

# 7. Precompile assets (WITH ALL DUMMY VARIABLES)
# We added DATABASE_PORT, REDIS_URL, and ELASTICSEARCH_URL to prevent future crashes
RUN NODE_ENV=production \
    SECRET_KEY_BASE=dummy \
    DATABASE_NAME=dummy \
    DATABASE_USERNAME=dummy \
    DATABASE_PASSWORD=dummy \
    DATABASE_HOST=dummy \
    DATABASE_PORT=3306 \
    REDIS_URL=redis://dummy:6379/1 \
    ELASTICSEARCH_URL=http://dummy:9200 \
    bundle exec rails assets:precompile

# 8. Final Cleanup
ENV NODE_ENV=production

# 9. Start Server
EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
