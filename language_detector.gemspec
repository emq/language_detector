Gem::Specification.new do |s|
  s.name = %q{language_detector}
  s.version = "0.1.2"

  s.authors = ["feedbackmine", "igrigorik"]
  s.description = %q{n-gram based language detector, written in ruby}
  s.email = %q{feedbackmine@feedbackmine.com}
  s.files = ["README.rdoc", 
            "lib/language_detector.rb",  
            "lib/model-fm.yml",
            "lib/model-tc.yml",
            "test/language_detector_test.rb"]
  s.homepage = %q{http://www.tweetjobsearch.com}
  s.require_paths = ["lib"]
  s.summary = %q{n-gram based language detector, written in ruby}
end
