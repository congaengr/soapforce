# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'soapforce/version'

Gem::Specification.new do |gem|
  gem.name          = "soapforce"
  gem.version       = Soapforce::VERSION
  gem.authors       = ["Joe Heth"]
  gem.email         = ["joeheth@gmail.com"]
  gem.description   = %q{A ruby client for the Salesforce SOAP API based on Savon.}
  gem.summary       = %q{A ruby client for the Salesforce SOAP API based on Savon.}
  gem.homepage      = "https://github.com/TinderBox/soapforce"

  ignores  = File.readlines('.gitignore').grep(/\S+/).map(&:chomp)
  dotfiles = %w[.gitignore .travis.yml]

  all_files_without_ignores = Dir['**/*'].reject { |f|
    File.directory?(f) || ignores.any? { |i| File.fnmatch(i, f) }
  }

  gem.files = (all_files_without_ignores + dotfiles).sort

  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency("savon", "~>2.3.0")

  gem.add_development_dependency 'rspec', '~> 2.14.0'
  gem.add_development_dependency 'webmock', '~> 1.13.0'
  gem.add_development_dependency 'simplecov', '~> 0.7.1'
end
