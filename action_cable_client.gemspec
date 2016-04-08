# -*- encoding: utf-8 -*-

# allows bundler to use the gemspec for dependencies
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)


require 'action_cable_client/version'

Gem::Specification.new do |s|
  s.name        = 'action_cable_client'
  s.version     = ActionCableClient::VERSION
  s.platform    = Gem::Platform::RUBY
  s.license     = 'MIT'
  s.authors     = ['L. Preston Sego III']
  s.email       = 'LPSego3+dev@gmail.com'
  s.homepage    = 'https://github.com/NullVoxPopuli/action_cable_client'
  s.summary     = "ActionCableClient-#{ActionCableClient::VERSION}"
  s.description = ''

  s.files        = Dir['CHANGELOG.md', 'LICENSE' 'MIT-LICENSE', 'README.md', 'lib/**/*']
  s.require_path = 'lib'

  s.test_files    = s.files.grep(%r{^(test|spec|features)/})

  s.required_ruby_version = '>= 2.3.0'

  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'websocket-eventmachine-client'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'pry-byebug'
  s.add_development_dependency 'codeclimate-test-reporter'
  s.add_development_dependency 'rubocop'
end
