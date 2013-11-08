# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'git_release_notes/version'

Gem::Specification.new do |gem|
  gem.name = "git_release_notes"
  gem.version = GitReleaseNotes::VERSION
  gem.authors = ["cf-devs"]
  gem.email = ["vcap-dev@googlegroups.com"]
  gem.description = %q{Extract release notes from your git log}
  gem.summary = %q{Executable that scans your git log (including submodules) for specific release tags and builds a directory of files ready for detailed editing into release notes.}
  gem.homepage = "http://github.com/cloudfoundry/git-release-notes"

  gem.files = Dir.glob("{bin,lib,release_notes}/**/*") +
      %w(LICENSE.md README.md)
  gem.executables = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "rinku"
  gem.add_dependency "thor"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "nokogiri"
  gem.add_development_dependency "capybara"
end

