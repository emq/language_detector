# -*- coding: utf-8 -*-
require 'test/unit'
require File.dirname(__FILE__) + '/../lib/language_detector'

class LanguageDetector::ProfileTest < Test::Unit::TestCase
  def test_is_punctuation
    p = LanguageDetector::Profile.new(:name => "test")
    assert p.is_punctuation?(',')
    assert p.is_punctuation?('.')
    assert !p.is_punctuation?('A')
    assert !p.is_punctuation?('a')
  end

  def test_tokenize
    p = LanguageDetector::Profile.new(:name => "test")
    assert_equal ["this", "is", "A", "test"], p.tokenize("this is ,+_  A \t 123 test")
  end

  def test_count_ngram
    p = LanguageDetector::Profile.new(:name => "test")
    assert_equal({"w"=>1, "o"=>1, "r"=>1, "d"=>1, "s"=>1}, p.count_ngram('words', 1, {}))
    assert_equal({"wo"=>1, "or"=>1, "rd"=>1, "ds"=>1, "_w" => 1, "s_" => 1}, p.count_ngram('words', 2, {}))
    assert_equal({"wor"=>1, "ord"=>1, "rds"=>1, "_wo" => 1, "ds_" => 1, "s__" => 1}, p.count_ngram('words', 3, {}))
    assert_equal({"word"=>1, "ords"=>1, "_wor" => 1, "rds_" => 1, "ds__" => 1, "s___" => 1}, p.count_ngram('words', 4, {}))
    assert_equal({"words"=>1, "_word" => 1, "ords_" => 1, "rds__" => 1, "ds___" => 1, "s____" => 1}, p.count_ngram('words', 5, {}))
    assert_equal({}, p.count_ngram('words', 6, {}))
  end

  def test_init_with_string
    # ruby 1.8 / 1.9 sort has slightly different semantics, hence test the presence of each ngram instead
    p = LanguageDetector::Profile.new(:text => "this is ,+_  A \t 123 test")
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
    p = LanguageDetector::Profile.new(:file => "bg-utf8.txt")
    assert !p.ngrams.empty?
  end

  def test_compute_distance
    p1 = LanguageDetector::Profile.new(:name => "test", :text => "this is ,+_  A \t 123 test")
    p2 = LanguageDetector::Profile.new(:name => "test", :text => "this is ,+_  A \t 123 test")
    assert_equal 0, p1.compute_distance(p2)

    p3 = LanguageDetector::Profile.new(:name => "test", :text => "xxxx")
    assert_equal 18000, p1.compute_distance(p3)
  end
end

class LanguageDetectorTest < Test::Unit::TestCase
  def test_detect
    d = LanguageDetector.new('fm')

    assert_equal "spanish",   d.detect("para poner este importante proyecto en práctica")
    assert_equal "english",   d.detect("this is a test of the Emergency text categorizing system.")
    assert_equal "french",    d.detect("serait désigné peu après PDG d'Antenne 2 et de FR 3. Pas même lui ! Le")
    assert_equal "italian",   d.detect("studio dell'uomo interiore? La scienza del cuore umano, che")
    assert_equal "romanian",  d.detect("taiate pe din doua, in care vezi stralucind brun  sau violet cristalele interioare")
    assert_equal "polish",    d.detect("na porozumieniu, na ³±czeniu si³ i ¶rodków. Dlatego szukam ludzi, którzy")
    assert_equal "german",    d.detect("sagt Hühsam das war bei Über eine Annonce in einem Frankfurter der Töpfer ein. Anhand von gefundenen gut kennt, hatte ihm die wahren Tatsachen Sechzehn Adorno-Schüler erinnern und daß ein Weiterdenken der Theorie für ihre Festlegung sind drei Jahre Erschütterung Einblick in die Abhängigkeit der Bauarbeiten sei")
    assert_equal "hungarian", d.detect("esôzéseket egy kissé túlméretezte, ebbôl kifolyólag a Földet egy hatalmas árvíz mosta el")
    assert_equal "finnish",   d.detect("koulun arkistoihin pölyttymään, vaan nuoret saavat itse vaikuttaa ajatustensa eteenpäinviemiseen esimerkiksi")
    assert_equal "dutch",     d.detect("tegen de kabinetsplannen. Een speciaal in het leven geroepen Landelijk")
    assert_equal "danish",    d.detect("viksomhed, 58 pct. har et arbejde eller er under uddannelse, 76 pct. forsørges ikke længere af Kolding")
    assert_equal "czech",     d.detect("datují rokem 1862.  Naprosto zakázán byl v pocitech smutku, beznadìje èi jiné")
    assert_equal "norwegian", d.detect("hovedstaden Nanjings fall i desember ble byens innbyggere utsatt for et seks")
    assert_equal "portuguese",d.detect("popular. Segundo o seu biógrafo, a Maria Adelaide auxiliava muita gente")
    assert_equal "english",   d.detect("TaffyDB finders looking nice so far! Testing this long sentence.")
    assert_equal "japanese",  d.detect("ブッシュ前大統領、「再登板」の厚顔無恥")
    assert_equal "russian",   d.detect("105-мм самоходная гаубица M7, широко известная также под её британским названием «Прист» — самоходная артиллерийская установка (САУ) США периода Второй мировой войны, класса самоходных гаубиц. Создана в 1942 году на шасси среднего танка M3. Серийно выпускалась с апреля 1942 по март 1945 года, всего было выпущено 4316 САУ этого типа. M7 являлась основной САУ США во Второй мировой войне, являясь стандартной артиллерией танковых дивизий и в меньших масштабах используясь также пехотными частями и корпусной артиллерией. M7 применялась войсками США на всех театрах военных действий, помимо этого, более 1000 из выпущенных САУ было передано Великобритании и Франции по программе ленд-лиза. В послевоенный период M7 оставалась на вооружении США до середины 1950-х годов и в ограниченных масштабах применялась в Корейской войне.")
    assert_equal "chinese",   d.detect("南北朝是中国历史上的一段时期，由420年刘裕篡东晋建立南朝宋开始，至589年隋灭南朝陈为止。")
    assert_equal "arabic",    d.detect("الأُرْخُص نوع ضخم جدا من الماشية كان يعيش في معظم أوروبة، الشرق الأوسط، شمال إفريقيا، آسيا الوسطى، و الهند قبل أن ينقرض في الربع الأول من القرن السابع عشر عام 1627، ويشتق اسم الأرخص في العربيّة من اسمه اللاتينيّ المترجم عن الألمانيّة ")
  end
end
