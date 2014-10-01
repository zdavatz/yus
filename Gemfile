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
  gem 'flexmock'
  gem 'rake'
  gem 'minitest', '>=5.0.0'
  gem 'hoe'
end

group :debugger do
  if /^2/.match(RUBY_VERSION)
    gem 'pry-byebug'
  elsif /^1\.9/.match(RUBY_VERSION)
    gem 'pry-debugger'
  end
end