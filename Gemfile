source "http://rubygems.org"

gem 'needle'
#gem 'pg', '0.9.0'
gem 'pg'
# we have some important patches here!!
gem 'dbi', '0.4.5', :git => 'https://github.com/zdavatz/ruby-dbi'

# for running yus_add we need
# gem 'ruby-password' # but this cannot be installed on travis-ci for ruby 1.8.7
gem 'rclconf'

# for running yusd we need
gem 'odba'
gem 'dbd-pg'
gem 'deprecated', '2.0.1'

group :development, :test do
  gem 'flexmock', '~>1.3.0'
  gem 'rake'
  gem 'test-unit'
  gem 'minitest'
  gem 'hoe'
end

group :debugger do
  gem 'pry-byebug'
end