# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'duke/version'

Gem::Specification.new do |spec|
  spec.name          = 'duke'
  spec.version       = Duke::VERSION
  spec.authors       = ['MSJarre']
  spec.email         = ['mlabous@ekylibre.com']
  spec.summary       = 'Duke assistant for Ekylibre'
  spec.homepage      = 'https://ekylibre.com'

  #  Testing
  spec.add_development_dependency 'bundler', '~> 2.2.15'
  spec.add_development_dependency 'minitest', '~> 5.8.0'
  spec.add_development_dependency 'rails'
  spec.add_development_dependency 'rake', '~> 13.0'

  spec.add_runtime_dependency 'httparty', '~> 0.17.3'
  spec.add_runtime_dependency 'ibm_watson', '~> 1.6.0'
  spec.add_runtime_dependency 'sidekiq', '~> 4.2.10'
  spec.add_runtime_dependency 'similar_text', '~> 0.0.4'
end
