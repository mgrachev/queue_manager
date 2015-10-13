# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'queue_manager/version'

Gem::Specification.new do |spec|
  spec.name          = 'queue_manager'
  spec.version       = QueueManager::Version::STRING
  spec.authors       = ['Mikhail Grachev']
  spec.email         = ['work@mgrachev.com']
  spec.summary       = %q{Queue manager based on Redis (Sorted Set)}
  spec.description   = %q{Queue manager for Rails application. Based on Redis (Sorted Set)}
  spec.homepage      = 'https://github.com/mgrachev/queue_manager'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 1.9.3'

  spec.add_dependency 'redis', '>= 3.2'
  spec.add_dependency 'rails', '>= 3.1'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.1'
  spec.add_development_dependency 'mock_redis', '~> 0.14'
  spec.add_development_dependency 'yard', '~> 0.8.7'
  spec.add_development_dependency 'redcarpet', '~> 3.2' # Markdown implementation (for yard)
end
