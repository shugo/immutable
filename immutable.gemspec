require 'rubygems'
Gem::Specification.new { |s|
  s.name = "immutable"
  s.version = "0.4.0"
  s.author = "Shugo Maeda"
  s.email = "shugo@ruby-lang.org"
  s.summary = "Immutable data structures for Ruby"
  s.description = "Immutable data structures for Ruby"
  s.homepage = "http://github.com/shugo/immutable"
  s.license       = "MIT"
  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.require_path = "lib"
  s.required_ruby_version = '>= 2.7.0.dev'

  s.add_development_dependency "rake"
  s.add_development_dependency "test-unit"
  s.add_development_dependency "kramdown"
  s.add_development_dependency "yard"
}
