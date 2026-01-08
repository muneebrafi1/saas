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
# IMPORTANT: We keep NODE_ENV as 'development' initially so ALL packages install
ENV RAILS_ENV=production
ENV NODE_ENV=development 
ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true

# 4. Install Ruby Gems
COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle config set --local without 'test' && bundle install

# 5. Install Node dependencies
# We install EVERYTHING (including devDependencies like patch-package)
COPY package.json package-lock.json ./
RUN npm install

# 6. Copy application code
COPY . .

# 7. Precompile assets
# We switch to production mode here for the build
RUN NODE_ENV=production SECRET_KEY_BASE=dummy bundle exec rails assets:precompile

# 8. Final Cleanup (Switch back to production for running)
ENV NODE_ENV=production

# 9. Start Server
EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
