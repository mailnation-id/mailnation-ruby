# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = "mailnation"
  s.version = "0.1.0"
  s.summary = "Official Ruby SDK for the Mailnation Email API"
  s.homepage = "https://github.com/mailnation-id/mailnation-ruby"
  s.license = "MIT"
  s.authors = ["Mailnation"]
  s.email = ["support@mailnation.id"]
  s.files = Dir["lib/**/*.rb", "LICENSE", "README.md", "openapi.yaml"]
  s.required_ruby_version = ">= 3.0"
  s.metadata = {
    "homepage_uri" => s.homepage,
    "source_code_uri" => "https://github.com/mailnation-id/mailnation-ruby",
    "documentation_uri" => "https://docs.mailnation.id/docs/sdks"
  }
end
