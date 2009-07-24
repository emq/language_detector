# -*- coding: utf-8 -*-
require 'test/unit'
require File.dirname(__FILE__) + '/../lib/language_detector'

class ProfileTest < Test::Unit::TestCase
  def test_is_punctuation
    p = Profile.new(:name => "test")
    assert p.is_punctuation?(',')
    assert p.is_punctuation?('.')
    assert !p.is_punctuation?('A')
    assert !p.is_punctuation?('a')
  end

  def test_tokenize
    p = Profile.new(:name => "test")
    assert_equal ["this", "is", "A", "test"], p.tokenize("this is ,+_  A \t 123 test")
  end

  def test_count_ngram
    p = Profile.new(:name => "test")
    assert_equal({"w"=>1, "o"=>1, "r"=>1, "d"=>1, "s"=>1}, p.count_ngram('words', 1, {}))
    assert_equal({"wo"=>1, "or"=>1, "rd"=>1, "ds"=>1, "_w" => 1, "s_" => 1}, p.count_ngram('words', 2, {}))
    assert_equal({"wor"=>1, "ord"=>1, "rds"=>1, "_wo" => 1, "ds_" => 1, "s__" => 1}, p.count_ngram('words', 3, {}))
    assert_equal({"word"=>1, "ords"=>1, "_wor" => 1, "rds_" => 1, "ds__" => 1, "s___" => 1}, p.count_ngram('words', 4, {}))
    assert_equal({"words"=>1, "_word" => 1, "ords_" => 1, "rds__" => 1, "ds___" => 1, "s____" => 1}, p.count_ngram('words', 5, {}))
    assert_equal({}, p.count_ngram('words', 6, {}))
  end

  def test_init_with_string
    # ruby 1.8 / 1.9 sort has slightly different semantics, hence test the presence of each ngram instead
    p = Profile.new(:text => "this is ,+_  A \t 123 test")
    [
      ["t_", 30], ["st__", 29], ["st", 16], ["hi", 8], ["_tes", 7], ["is__", 6], ["s___", 5], ["s_", 3], ["his_", 11],
      ["tes", 10], ["t___", 9], ["es", 12], ["_te", 14], ["est_", 13], ["est", 15], ["te", 4], ["his", 17], ["_th", 20],
      ["s__", 19], ["st_", 18], ["th", 24], ["_thi", 23], ["t__", 22], ["test", 21], ["thi", 28], ["is_", 27], ["this", 26],
      ["_i", 25], ["is", 2], ["_t", 1]
    ].each do |ngram|
      assert p.ngrams.has_key?(ngram.first)
    end
  end

  def test_init_with_file
    p = Profile.new(:file => "bg-utf8.txt")
    assert !p.ngrams.empty?
  end

  def test_compute_distance
    p1 = Profile.new(:name => "test", :text => "this is ,+_  A \t 123 test")
    p2 = Profile.new(:name => "test", :text => "this is ,+_  A \t 123 test")
    assert_equal 0, p1.compute_distance(p2)

    p3 = Profile.new(:name => "test", :text => "xxxx")
    assert_equal 18000, p1.compute_distance(p3)
  end
end

class LanguageDetectorTest < Test::Unit::TestCase
  def test_detect
    d = LanguageDetector.new

    assert_equal "spanish", d.detect("para poner este importante proyecto en práctica")
    assert_equal "english", d.detect("this is a test of the Emergency text categorizing system.")
    assert_equal "french", d.detect("serait désigné peu après PDG d'Antenne 2 et de FR 3. Pas même lui ! Le")
    assert_equal "italian", d.detect("studio dell'uomo interiore? La scienza del cuore umano, che")
    assert_equal "romanian", d.detect("taiate pe din doua, in care vezi stralucind brun  sau violet cristalele interioare")
    assert_equal "polish", d.detect("na porozumieniu, na ³±czeniu si³ i ¶rodków. Dlatego szukam ludzi, którzy")
    assert_equal "german", d.detect("sagt Hühsam das war bei Über eine Annonce in einem Frankfurter der Töpfer ein. Anhand von gefundenen gut kennt, hatte ihm die wahren Tatsachen Sechzehn Adorno-Schüler erinnern und daß ein Weiterdenken der Theorie für ihre Festlegung sind drei Jahre Erschütterung Einblick in die Abhängigkeit der Bauarbeiten sei")
    assert_equal "hungarian", d.detect("esôzéseket egy kissé túlméretezte, ebbôl kifolyólag a Földet egy hatalmas árvíz mosta el")
    assert_equal "finnish", d.detect("koulun arkistoihin pölyttymään, vaan nuoret saavat itse vaikuttaa ajatustensa eteenpäinviemiseen esimerkiksi")
    assert_equal "dutch", d.detect("tegen de kabinetsplannen. Een speciaal in het leven geroepen Landelijk")
    assert_equal "danish", d.detect("viksomhed, 58 pct. har et arbejde eller er under uddannelse, 76 pct. forsørges ikke længere af Kolding")
    assert_equal "czech", d.detect("datují rokem 1862.  Naprosto zakázán byl v pocitech smutku, beznadìje èi jiné")
    #    assert_equal "norwegian", d.detect("hånd på den enda hvitere restaurant-duken med en bevegelse så forfinet bevegelse")
    assert_equal "portuguese", d.detect("popular. Segundo o seu biógrafo, a Maria Adelaide auxiliava muita gente")
    assert_equal "english", d.detect("TaffyDB finders looking nice so far! Testing this long sentence.")
  end
end
