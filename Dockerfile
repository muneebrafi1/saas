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

# -----------------------------------------------------------------------------
# THE "BOOT HACK" (Solves the load-order issue)
# We inject the bypass code directly into boot.rb so it loads FIRST.
# -----------------------------------------------------------------------------
RUN \
    # A. Backup the original boot file
    cp config/boot.rb config/boot.rb.bak && \
    # B. Append the "Monkey Patch" to the END of boot.rb
    # This forces Rails to return "dummy" for ANY missing variable (Memcache, Stripe, etc.)
    echo '\nmodule BuildEnvFallback; def fetch(key, *args); super rescue "dummy"; end; end; ENV.singleton_class.prepend(BuildEnvFallback)' >> config/boot.rb && \
    # C. Run the build (It will now SUCCEED because boot.rb intercepts the errors)
    NODE_ENV=production SECRET_KEY_BASE=dummy bundle exec rails assets:precompile && \
    # D. Restore the original boot file so the app runs normally on deployment
    mv config/boot.rb.bak config/boot.rb

# -----------------------------------------------------------------------------

# 8. Final Cleanup
ENV NODE_ENV=production

# 9. Start Server
EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
