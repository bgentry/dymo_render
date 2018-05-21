lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dymo_render/version"

Gem::Specification.new do |s|
  s.name        = "dymo_render"
  s.version     = DymoRender::VERSION
  s.date        = "2018-05-21"
  s.summary     = "Render PDFs using DYMO XML"
  s.description = "Render PDFs using the XML format from the DYMO Label Maker app"
  s.authors     = ["Blake Gentry", "Tim Morgan"]
  s.email       = "blakesgentry@gmail.com"
  s.files       = ["lib/dymo_render.rb"]
  s.homepage    = "http://github.com/bgentry/dymo_render"
  s.license     = "BSD-2-Clause"

  s.add_dependency "barby", "~> 0.6.5"
  s.add_dependency "nokogiri", "~> 1.8.2"
  s.add_dependency "prawn", "~> 2.2.2"
  s.add_dependency "rqrcode", "~> 0.10.1"
end
