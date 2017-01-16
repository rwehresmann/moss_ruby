# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'moss_ruby/version'

Gem::Specification.new do |spec|
  spec.name        = 'moss_ruby'
  spec.version     = MossRuby::VERSION
  spec.date        = '2016-07-07'
  spec.summary     = "Moss gem to access system for Detecting Software Plagiarism"
  spec.description = "Moss-ruby is an unofficial ruby gem for the Moss system for Detecting Software Plagiarism (http://theory.stanford.edu/~aiken/moss/)"
  spec.authors     = ["Andrew Cain"]
  spec.email       = 'acain@swin.edu.au'
  spec.files       = ["lib/moss_ruby.rb"]
  spec.homepage    = 'https://bitbucket.org/macite/moss-ruby'
  spec.license     = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
