
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "duke/version"

Gem::Specification.new do |spec|
  spec.name          = "duke"
  spec.version       = Duke::VERSION
  spec.authors       = ["MSJarre"]
  spec.email         = ["mlabous@ekylibre.com"]

  spec.summary       = %q{Duke assistant for Ekylibre}
  spec.homepage      = "https://ekylibre.com"

  spec.add_development_dependency "bundler", "~> 2.1.4"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_runtime_dependency 'ibm_watson', "~> 1.6.0"
  spec.add_runtime_dependency 'sidekiq', "~> 4.2.10"
  spec.add_runtime_dependency 'httparty', "~> 0.17.3"
  spec.add_runtime_dependency 'pusher', "~> 1.4.2"
  spec.add_runtime_dependency 'similar_text', "~> 0.0.4"

end
