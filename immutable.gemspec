require 'rubygems'
Gem::Specification.new { |s|
  s.name = "immutable"
  s.version = "0.3.2"
  s.date = "2016-07-08"
  s.author = "Shugo Maeda"
  s.email = "shugo@ruby-lang.org"
  s.homepage = "http://github.com/shugo/immutable"
  s.platform = Gem::Platform::RUBY
  s.summary = "Immutable data structures for Ruby"
  s.files = Dir.glob('{lib,benchmark,test}/**/*') + ['README.md']
  s.require_path = "lib"
}
