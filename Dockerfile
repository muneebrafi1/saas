# Dockerfile
FROM ruby:3.4.3-slim

# 1. Install system dependencies
# We added 'libyaml-dev' to fix the "yaml.h not found" error
# We added 'pkg-config' to help finding libraries
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    pkg-config \
    libvips \
    libvips-dev \
    git \
    libxml2-dev \
    libxslt-dev \
    libyaml-dev \
    nodejs \
    npm \
    default-libmysqlclient-dev \
    ffmpeg \
    pdftk \
    wkhtmltopdf \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 2. Set working directory
WORKDIR /app

# 3. Set environment variables
ENV RAILS_ENV=production
ENV NODE_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true

# 4. Install Ruby Gems
# We added .ruby-version here to fix the "No such file" error
COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle config set --local without 'development test' && bundle install

# 5. Install Node dependencies
COPY package.json package-lock.json ./
RUN npm install

# 6. Copy the rest of the application code
COPY . .

# 7. Precompile assets
# We use a dummy secret key just for this step so it doesn't crash during build
RUN SECRET_KEY_BASE=dummy bundle exec rails assets:precompile

# 8. Open port 3000
EXPOSE 3000

# 9. Start the server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
