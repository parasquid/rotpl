# frozen_string_literal: true

require_relative "lib/rotpl/version"

Gem::Specification.new do |spec|
  spec.name = "rotpl"
  spec.version = Rotpl::VERSION
  spec.authors = ["parasquid"]
  spec.email = ["parasquid@gmail.com"]

  spec.summary = "Ruby OTP-Two-Factor-authentication Library"
  spec.description = "A Ruby implementation of HMAC-based One-Time Password (HOTP) and Time-based One-Time Password (TOTP) algorithms, fully compatible with Google Authenticator."
  spec.homepage = "https://github.com/parasquid/rotpl"
  spec.license = "LGPL-3.0-or-later"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}.git"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "base32", "~> 0.3"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-given", "~> 3.8"
  spec.add_development_dependency "rake", "~> 13.0"
end
