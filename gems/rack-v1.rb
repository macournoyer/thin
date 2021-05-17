# frozen_string_literal: true

source 'https://rubygems.org'

gemspec path: "../"

gem 'rack', '~> 1.0'

group :development do
  gem "rake-compiler"
end

group :test do
  gem "rake", ">= 12.3.3"
  gem "rspec", "~> 3.5"
end

