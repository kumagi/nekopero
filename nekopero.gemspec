# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nekopero/version'

Gem::Specification.new do |gem|
  gem.name          = "nekopero"
  gem.version       = Nekopero::VERSION
  gem.authors       = ["KUMAZAKI Hiroki"]
  gem.email         = ["hiroki.kumazaki@gmail.com"]
  gem.description   = %q{Jubatus terminal client}
  gem.summary       = %q{You can use Jubatus through terminal with naive query}
  gem.homepage      = "http://github.com/kumagi/nekopero"

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{|f| File.basename(f)}
  gem.require_paths = ["lib"]
  gem.add_dependency 'jubatus', '>= 0.1.0'
  gem.add_dependency 'amatch', '>= 0.2.10'
end
