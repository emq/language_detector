require 'yaml'

if RUBY_VERSION < '1.9'
  require 'jcode'
  $KCODE = 'u' if RUBY_VERSION < '1.9'
end

class LanguageDetector

  # Supports two ngram databases:
  # - fm - built from scratch texts included with gem
  # - tc - textcat ngram database
  def initialize(type='tc')
    @profiles = load_model(type)
  end

  def detect text
    p = Profile.new(:text => text)
    best_profile = nil
    best_distance = nil

    @profiles.each do |profile|
      distance = profile.compute_distance(p)

      if !best_distance or distance < best_distance
        best_distance = distance
        best_profile = profile
      end
    end

    best_profile.name
  end

  def self.train_tc
    profiles = []
    languages = Dir.glob("textcat_ngrams/*.lm").collect {|l| l.gsub(/\.lm$/,'')}.sort

    languages.each do |language|
      ngram = {}
      rang = 1

      lang = File.open("#{language}.lm", "r")
      lang.each_line do |line|

        line = line.chomp
        if line =~ /^[^0-9\s]+/o
          ngram[line.chomp.split(/\t/).first] = rang
          rang += 1
        end

      end
      lang.close

      p = Profile.new(:name => language.split('/').last.split('-').first)
      p.ngrams = ngram

      profiles.push p
    end

    puts 'saving model...'
    filename = File.expand_path(File.join(File.dirname(__FILE__), "model-tc.yml"))
    File.open(filename, 'w') {|f| YAML.dump(profiles, f)}
  end

  def self.train_fm
    # For a full list of ISO 639 language tags visit:
    # http:#www.loc.gov/standards/iso639-2/englangn.html

    #LARGE profiles follow:

    #NOTE: These profiles taken from the "World War II" node on wikipedia
    #with the 'lang' and ?action=raw URI which results in a UTF8 encoded
    #file.  If we need to get more profile data for a language this is
    #always a good source of data.
    #
    # http:#en.wikipedia.org/wiki/World_War_II

    training_data = [
      # af (afrikaans)
      [ "ar", "ar-utf8.txt", "utf8", "arabic" ],
      [ "bg", "bg-utf8.txt", "utf8", "bulgarian" ],
      # bs (bosnian )
      # ca (catalan)
      [ "cs", "cs-utf8.txt", "utf8", "czech" ],
      # cy (welsh)
      [ "da", "da-iso-8859-1.txt", "iso-8859-1", "danish" ],
      [ "de", "de-utf8.txt", "utf8", "german" ],
      [ "el", "el-utf8.txt", "utf8", "greek" ],
      [ "en", "en-iso-8859-1.txt", "iso-8859-1", "english" ],
      [ "et", "et-utf8.txt", "utf8", "estonian" ],
      [ "es", "es-utf8.txt", "utf8", "spanish" ],
      [ "fa", "fa-utf8.txt", "utf8", "farsi" ],
      [ "fi", "fi-utf8.txt", "utf8", "finnish" ],
      [ "fr", "fr-utf8.txt", "utf8", "french" ],
      [ "fy", "fy-utf8.txt", "utf8", "frisian" ],
      [ "ga", "ga-utf8.txt", "utf8", "irish" ],
      #gd (gaelic)
      #haw (hawaiian)
      [ "he", "he-utf8.txt", "utf8", "hebrew" ],
      [ "hi", "hi-utf8.txt", "utf8", "hindi" ],
      [ "hr", "hr-utf8.txt", "utf8", "croatian" ],
      #id (indonesian)
      [ "io", "io-utf8.txt", "utf8", "ido" ],
      [ "is", "is-utf8.txt", "utf8", "icelandic" ],
      [ "it", "it-utf8.txt", "utf8", "italian" ],
      [ "ja", "ja-utf8.txt", "utf8", "japanese" ],
      [ "ko", "ko-utf8.txt", "utf8", "korean" ],
      #ku (kurdish)
      #la ?
      #lb ?
      #lt (lithuanian)
      #lv (latvian)
      [ "hu", "hu-utf8.txt", "utf8", "hungarian" ],
      #mk (macedonian)
      #ms (malay)
      #my (burmese)
      [ "nl", "nl-iso-8859-1.txt", "iso-8859-1", "dutch" ],
      [ "no", "no-utf8.txt", "utf8", "norwegian" ],
      [ "pl", "pl-utf8.txt", "utf8", "polish" ],
      [ "pt", "pt-utf8.txt", "utf8", "portuguese" ],
      [ "ro", "ro-utf8.txt", "utf8", "romanian" ],
      [ "ru", "ru-utf8.txt", "utf8", "russian" ],
      [ "sl", "sl-utf8.txt", "utf8", "slovenian" ],
      #sr (serbian)
      [ "sv", "sv-iso-8859-1.txt", "iso-8859-1", "swedish" ],
      #[ "sv", "sv-utf8.txt", "utf8", "swedish" ],
      [ "th", "th-utf8.txt", "utf8", "thai" ],
      #tl (tagalog)
      #ty (tahitian)
      [ "uk", "uk-utf8.txt", "utf8", "ukraninan" ],
      [ "vi", "vi-utf8.txt", "utf8", "vietnamese" ],
      #wa (walloon)
      #yi (yidisih)
      [ "zh", "zh-utf8.txt", "utf8", "chinese" ]
    ]

    profiles = []
    training_data.each do |data|
      p = Profile.new(:name => data.last, :file => data[1])
      profiles.push p
    end
    puts 'saving model...'
    filename = File.expand_path(File.join(File.dirname(__FILE__), "model-fm.yml"))
    File.open(filename, 'w') {|f| YAML.dump(profiles, f)}
  end

  def load_model(name)
    filename = File.expand_path(File.join(File.dirname(__FILE__), "model-#{name}.yml"))
    @profiles = YAML.load_file(filename)
  end
end

class Profile
  LIMIT = 1500
  PUNCTUATIONS = [
    ?\n, ?\r, ?\t, ?\s, ?!, ?", ?#, ?$, ?%, ?&, ?', ?(, ?), ?*, ?+, ?,, ?-, ?., ?/,
    ?0, ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?:, ?;, ?<, ?=, ?>, ??, ?@, ?[, ?\\, ?], ?^, ?_, ?`, ?{, ?|, ?}, ?~
  ]

  attr_accessor :ngrams, :name

  def initialize(*args)
    args = args.first

    @punctuations = Hash[*PUNCTUATIONS.map{|k| [k,1]}.flatten]
    @name = args[:name] || ""
    @ngrams = {}

    init_with_string(args[:text]) if args[:text]
    init_with_file(args[:file]) if args[:file]
  end

  def compute_distance(other_profile)
    distance = 0
    other_profile.ngrams.each do |k, v|
      n = @ngrams[k]
      if n = @ngrams[k]
        distance += (v - n).abs
      else
        distance += LIMIT
      end
    end

    distance
  end

  def init_with_file(filename)
    ngram_count = Hash.new(0)

    path = File.expand_path(File.join(File.dirname(__FILE__), "training_data/" + filename))
    File.open(path).each_line {|line| generate_ngrams(line, ngram_count) }
    puts "training with " + path

    ngram_count.sort {|a,b| b[1] <=> a[1]}.each_with_index do |t, i|
      ngrams[t[0]] = (i+1)
      break if i > LIMIT
    end
  end

  def init_with_string(str)
    ngram_count = {}
    generate_ngrams(str, ngram_count)

    ngram_count.sort {|a,b| b[1] <=> a[1]}.each_with_index do |t, i|
      @ngrams[t[0]] = (i+1)
      break if i > LIMIT
    end
  end
  
  def generate_ngrams(str, ngram_count)
    tokens = tokenize(str)
    tokens.each do |token|
      count_ngram(token, 2, ngram_count)
      count_ngram(token, 3, ngram_count)
      count_ngram(token, 4, ngram_count)
      count_ngram(token, 5, ngram_count)
    end
  end

  def tokenize str
    tokens = []
    s = ''
    str.each_byte do |b|
      if is_punctuation?(b)
        tokens.push s unless s.empty?
        s = ''
      else
        s << b
      end
    end

    tokens.push s unless s.empty?
    tokens
  end

  def is_punctuation?(b); @punctuations.has_key?(b); end

  def count_ngram(token, n, counts)
    token = "_#{token}#{'_' * (n-1)}" if n > 1 && token.length >= n
    i = 0
    while i + n <= token.length
      s = ''
      j = 0
      while j < n
        s << token[i+j]
        j += 1
      end
      counts[s] = counts[s] ? counts[s] +=1 : 1
      i += 1
    end

    counts
  end

end

if $0 == __FILE__
  if ARGV.length == 1
    if 'train-fm' == ARGV[0]
      LanguageDetector.train_fm
    elsif 'train-tc' == ARGV[0]
      LanguageDetector.train_tc
    end
  else
    d = LanguageDetector.new
    p d.detect("what language is it is?")
  end
end