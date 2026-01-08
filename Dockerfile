# Dockerfile
FROM ruby:3.4.3-slim

# 1. Install System Dependencies & Node.js 20
# We use 'curl' to fetch the specific Node 20 source list first
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

# -----------------------------------------------------------------------------
# THE "DEEP RESEARCH" FIX
# This block completely bypasses the "KeyError" crashes by swapping the config 
# files for dummy ones during the build process.
# -----------------------------------------------------------------------------
RUN \
    # A. Backup the strict database config
    mv config/database.yml config/database.yml.bak && \
    # B. Create a dummy database config that asks for NOTHING
    echo "production:\n  adapter: mysql2\n  database: dummy\n  username: dummy\n  password: dummy\n  host: 127.0.0.1" > config/database.yml && \
    # C. Create a 'Monkey Patch' that forces Rails to accept "dummy" for ANY missing key
    echo 'module BuildEnvFallback; def fetch(key, *args); super rescue "dummy"; end; end; ENV.singleton_class.prepend(BuildEnvFallback)' > config/initializers/00_build_bypass.rb && \
    # D. Run the build (It will now SUCCEED because we disabled the checks)
    NODE_ENV=production SECRET_KEY_BASE=dummy bundle exec rails assets:precompile && \
    # E. Restore the original files so the app works when deployed
    rm config/database.yml && \
    mv config/database.yml.bak config/database.yml && \
    rm config/initializers/00_build_bypass.rb

# -----------------------------------------------------------------------------

# 8. Final Cleanup
ENV NODE_ENV=production

# 9. Start Server
EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
