require 'rubygems'
Gem::Specification.new { |s|
  s.name = "immutable"
  s.version = "0.0.0"
  s.date = "2012-04-03"
  s.author = "Shugo Maeda"
  s.email = "shugo@ruby-lang.org"
  s.homepage = "http://github.com/shugo/immutable"
  s.platform = Gem::Platform::RUBY
  s.summary = "Immutable data structures for Ruby"
  s.files = Dir.glob('{lib,bench,test}/**/*') # + ['README']
  s.require_path = "lib"
}
