lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dymo_render/version"

Gem::Specification.new do |gem|
  gem.name        = "dymo_render"
  gem.version     = DymoRender::VERSION
  gem.date        = "2018-05-21"
  gem.summary     = "Render PDFs using DYMO XML"
  gem.description = "Render PDFs using the XML format from the DYMO Label Maker app"
  gem.authors     = ["Blake Gentry", "Tim Morgan"]
  gem.email       = "blakesgentry@gmail.com"
  gem.files       = `git ls-files`.split($/)
  gem.homepage    = "http://github.com/bgentry/dymo_render"
  gem.license     = "BSD-2-Clause"

  gem.test_files    = gem.files.grep(%r{^(test|spec)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "barby", "~> 0.6"
  gem.add_dependency "nokogiri", "~> 1.8"
  gem.add_dependency "prawn", "~> 2.2"
  gem.add_dependency "rqrcode", "~> 0.10"
end
