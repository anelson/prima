# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'prima/version'

Gem::Specification.new do |spec|
  spec.name          = "prima"
  spec.version       = Prima::VERSION
  spec.authors       = ["Adam Nelson"]
  spec.email         = ["anelson@apocryph.org"]
  spec.summary       = %q{A lightweight, fast ETL framework for Ruby}
  spec.description   = %q{Prima lets you write complex extract-transform-load (ETL) logic in an expressive ruby-based DSL}
  spec.homepage      = "http://rubygems.org/gem/prima"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "upsert", "~> 2.0", '>= 2.0.3'
  spec.add_runtime_dependency "msgpack", "~> 0.5", '>= 0.5.8'
  spec.add_runtime_dependency "thread_safe", "~> 0.3", '>= 0.3.4'
  spec.add_runtime_dependency "ruby-progressbar", "~> 1.5", '>= 1.5.1'
  spec.add_runtime_dependency "activerecord", "~> 4.1", '>= 4.1.6'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
