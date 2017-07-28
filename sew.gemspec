require "./lib/sew"

Gem::Specification.new do |s|
  s.name        = "sew"
  s.version     = Sew::VERSION
  s.summary     = "Static, Elegant Websites"
  s.description = "Sew stitches together static sites"
  s.authors     = ["Philip Poots"]
  s.email       = ["philip.poots@gmail.com"]
  s.homepage    = "http://github.com/pootsbook/sew"
  s.files = Dir[
    "LICENSE",
    "lib/**/*.rb",
    "*.gemspec"
  ]

  s.add_dependency "mote", "1.2.0"
  s.add_development_dependency "cutest"
end
