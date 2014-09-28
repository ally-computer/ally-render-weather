# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ally/render/weather/version'

Gem::Specification.new do |spec|
  spec.name          = 'ally-render-weather'
  spec.version       = Ally::Render::Weather::VERSION
  spec.authors       = ['Chad Barraford']
  spec.email         = ['cbarraford@gmail.com']
  spec.description   = 'Ally render plugin that pulls weather information'
  spec.summary       = 'Ally render plugin that pulls weather info'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(/^(test|spec|features)\//)
  spec.require_paths = ['lib']

  spec.add_dependency 'ally', '~> 0.0', '>= 0.0.17'
  spec.add_dependency 'wunderground'

  # development dependencies
  spec.add_development_dependency 'bundler', '~> 1.3'
  %w( rake rspec rubocop ally-io-test ).each do |gem|
    spec.add_development_dependency gem
  end
end
