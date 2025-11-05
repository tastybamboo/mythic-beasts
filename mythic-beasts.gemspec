require_relative "lib/mythic_beasts/version"

Gem::Specification.new do |spec|
  spec.name = "mythic-beasts"
  spec.version = MythicBeasts::VERSION
  spec.authors = ["James Inman"]
  spec.email = ["james@otaina.co.uk"]

  spec.summary = "Ruby client for Mythic Beasts API"
  spec.description = "A Ruby gem for interacting with Mythic Beasts APIs including DNS, VPS provisioning, and domain management"
  spec.homepage = "https://github.com/tastybamboo/mythic-beasts"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/tastybamboo/mythic-beasts"
  spec.metadata["changelog_uri"] = "https://github.com/tastybamboo/mythic-beasts/blob/main/CHANGELOG.md"

  spec.files = Dir["lib/**/*", "README.md", "LICENSE", "CHANGELOG.md"]
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-retry", "~> 2.0"
  spec.add_dependency "tty-prompt", "~> 0.23"

  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "vcr", "~> 6.1"
  spec.add_development_dependency "standard", "~> 1.35"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "pry", "~> 0.14"
  spec.add_development_dependency "lefthook", "~> 1.5"
  spec.add_development_dependency "bundler-audit", "~> 0.9"
end
