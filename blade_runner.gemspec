# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'blade_runner/version'

Gem::Specification.new do |spec|
  spec.name          = "blade_runner"
  spec.version       = BladeRunner::VERSION
  spec.authors       = ["Javan Makhmali"]
  spec.email         = ["javan@javan.us"]

  spec.summary       = %q{Blade Runner}
  spec.description   = %q{A Sprockets-friendly JavaScript test runner}
  spec.homepage      = "https://github.com/javan/blade_runner"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency "blade_runner-qunit_adapter"
  spec.add_dependency "activesupport", ">= 3.0.0"
  spec.add_dependency "coffee-script", "~> 2.4.0"
  spec.add_dependency "coffee-script-source", "~> 1.9.0"
  spec.add_dependency "curses", "~> 1.0.0"
  spec.add_dependency "eventmachine", "~> 1.0.0"
  # Lock to 1.1.1 to avoid Promise error in 1.1.2 with Chrome 43
  # "Uncaught TypeError: Cannot read property '_state' of undefined"
  spec.add_dependency "faye", "1.1.1"
  spec.add_dependency "sprockets", "~> 3.2.0"
  spec.add_dependency "thin", "~> 1.6.0"
  spec.add_dependency "useragent", "~> 0.13.0"
  spec.add_dependency "thor", "~> 0.19.1"
end
