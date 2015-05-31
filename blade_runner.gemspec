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
  spec.homepage      = "https://github/javan/blade_runner"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency "faye"
  spec.add_dependency "eventmachine"
  spec.add_dependency "puma"
  spec.add_dependency "curses"
  spec.add_dependency "sprockets"
  spec.add_dependency "coffee-script"
  spec.add_dependency "coffee-script-source"
end
