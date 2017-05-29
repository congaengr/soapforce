# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'soapforce/version'

Gem::Specification.new do |spec|
  spec.name          = "soapforce"
  spec.version       = Soapforce::VERSION
  spec.authors       = ["Joe Heth"]
  spec.email         = ["joeheth@gmail.com"]
  spec.description   = %q{A ruby client for the Salesforce SOAP API based on Savon.}
  spec.summary       = %q{Wraps Savon with helper methods and custom types for interacting with the Salesforce SOAP API.}
  spec.homepage      = "https://github.com/TinderBox/soapforce"
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "savon", ">= 2.3.0", '< 3.0.0'

  spec.add_development_dependency 'rspec', '>= 2.14.0', '< 4.0.0'
  spec.add_development_dependency 'webmock', '>= 1.17.0', '< 3.0.0'
  spec.add_development_dependency 'simplecov', '>= 0.9.0', '< 1.0.0'
end
