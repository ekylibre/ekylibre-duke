
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

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
end
