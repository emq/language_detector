# -*- encoding: utf-8 -*-


Gem::Specification.new do |s|
  s.name = "language_detector"
  s.summary = "Ruby language detection library using n-gram model"
  s.description = "Ruby language detection library using n-gram model"
  s.email = "ilya@igvita.com"
  s.homepage = "http://github.com/igrigorik/language_detector"
  s.authors = ["feedbackmine","Ilya Grigorik"]
  s.rubyforge_project = "language_detector"
  s.version = File.read('VERSION') rescue '0.0.0'
  s.files        = Dir['lib/**/*'] + %w(README.rdoc VERSION)
  s.required_rubygems_version = ">= 1.3.6"
  s.require_paths = ["lib"]
  s.rdoc_options = ["--charset=UTF-8"]
end
