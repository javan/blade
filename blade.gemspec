# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'blade/version'

Gem::Specification.new do |spec|
  spec.name          = "blade"
  spec.version       = Blade::VERSION
  spec.authors       = ["Javan Makhmali"]
  spec.email         = ["javan@javan.us"]

  spec.summary       = %q{Blade}
  spec.description   = %q{Sprockets test runner and toolkit}
  spec.homepage      = "https://github.com/javan/blade"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency "blade-qunit_adapter", "~> 2.0.1"
  spec.add_dependency "activesupport", ">= 3.0.0"
  spec.add_dependency "coffee-script"
  spec.add_dependency "coffee-script-source"
  spec.add_dependency "curses", "~> 1.0.0"
  spec.add_dependency "eventmachine"
  spec.add_dependency "faye"
  spec.add_dependency "sprockets", ">= 3.0"
  spec.add_dependency "thin", ">= 1.6.0"
  spec.add_dependency "useragent", "~> 0.16.7"
  spec.add_dependency "thor", "~> 0.19.1"
end
