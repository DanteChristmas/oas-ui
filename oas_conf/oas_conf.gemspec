$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "oas_conf/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "oas_conf"
  s.version     = OasConf::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of OasConf."
  s.description = "TODO: Description of OasConf."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.0.13"

  s.add_development_dependency "sqlite3"
end
