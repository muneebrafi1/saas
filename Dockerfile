# Dockerfile
FROM ruby:3.4.3-slim

# Install system dependencies required by Gumroad (PDFtk, ffmpeg, etc)
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libvips \
    libvips-dev \
    git \
    libxml2-dev \
    libxslt-dev \
    nodejs \
    npm \
    default-libmysqlclient-dev \
    ffmpeg \
    pdftk \
    wkhtmltopdf \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Set environment variables
ENV RAILS_ENV=production
ENV NODE_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true

# Install Gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && bundle install

# Install Node dependencies
COPY package.json package-lock.json ./
RUN npm install

# Copy application code
COPY . .

# Precompile assets (requires dummy secret)
RUN SECRET_KEY_BASE=dummy bundle exec rails assets:precompile

# Expose port
EXPOSE 3000

# Start the server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
