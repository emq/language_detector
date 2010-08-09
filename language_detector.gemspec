# -*- encoding: utf-8 -*-

require './VERSION'

Gem::Specification.new do |s|
  s.name = "language_detector"
  s.summary = "Ruby language detection library using n-gram model"
  s.description = "Ruby language detection library using n-gram model"
  s.email = "ilya@igvita.com"
  s.homepage = "http://github.com/igrigorik/language_detector"
  s.authors = ["Ilya Grigorik"]
  s.rubyforge_project = "language_detector"
  s.version = VERSION
  s.files        = Dir['lib/**/*'] + %w(README.rdoc)
  s.required_rubygems_version = ">= 1.3.6"
  s.require_paths = ["lib"]
  s.rdoc_options = ["--charset=UTF-8"]
end

