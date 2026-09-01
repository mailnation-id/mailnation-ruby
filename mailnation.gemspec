# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = "mailnation"
  s.version = "0.1.0"
  s.summary = "Official Ruby SDK for the Mailnation Email API"
  s.homepage = "https://github.com/riyanathariq/mailnation-ruby"
  s.license = "MIT"
  s.authors = ["Mailnation"]
  s.email = ["support@mailnation.id"]
  s.files = Dir["lib/**/*.rb", "LICENSE", "README.md", "openapi.yaml"]
  s.required_ruby_version = ">= 3.0"
end
