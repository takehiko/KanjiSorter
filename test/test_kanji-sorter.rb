#!/usr/bin/env ruby

require "minitest/autorun"
require "./kanji-sorter.rb"

class TestKanjiYear < Minitest::Test
  def test_years
    assert_equal(2017, KanjiYear.year(use: "2020-05-01"))
    assert_equal(2017, KanjiYear.year(use: "R2sy"))
    assert_equal(1989, KanjiYear.year(use: "2020-03-31"))
    assert_equal(1989, KanjiYear.year(use: "R2-03"))
    assert_equal(1989, KanjiYear.year(use: "2020"))
    assert_equal(1989, KanjiYear.year(use: "R1 school year"))
    assert_equal(1989, KanjiYear.year(use: "H4 school year"))
    assert_equal(1977, KanjiYear.year(use: "H04-03-31"))
    assert_equal(1977, KanjiYear.year(use: "H03sy"))
    assert_equal(1977, KanjiYear.year(use: "S55sy"))
    assert_equal(1958, KanjiYear.year(use: "S55-03-31"))
    assert_equal(1958, KanjiYear.year(use: "S54sy"))
    assert_equal(1958, KanjiYear.year(use: "S36sy"))
    assert_raises(RuntimeError) { KanjiYear.year(use: "S20sy") }; puts
    assert_equal(2017, KanjiYear.year(pub: "2020-03-01"))
    assert_equal(2017, KanjiYear.year(pub: "R2-03-31"))
    assert_equal(2017, KanjiYear.year(pub: "H29-01-01"))
    assert_equal(1989, KanjiYear.year(pub: "H28-12-31"))
    assert_equal(1989, KanjiYear.year(pub: "2010"))
    assert_equal(1989, KanjiYear.year(pub: "S64-01-01"))
    assert_equal(1977, KanjiYear.year(pub: "S63-12-31"))
    assert_equal(1977, KanjiYear.year(pub: "S52-01-01"))
    assert_equal(1958, KanjiYear.year(pub: "S51-12-31"))
    assert_equal(1958, KanjiYear.year(pub: "S33-01-01"))
    assert_raises(RuntimeError) { KanjiYear.year(pub: "S32-12-31") }; puts
  end

  # 対象を切り替えて同一文字列で結果を確認する
  def test_kanji_sorter
    seq = "大阪府兵庫県京都府滋賀県奈良県和歌山県三重県香川県徳島県"

    ks2017 = KanjiSorter.new(seq, pub: "2017").analyze
    ks2017_freq_grade = ks2017.to_a
    assert_match(/三山川大/, ks2017_freq_grade[1])
    assert_match(/歌京/, ks2017_freq_grade[2])
    assert_match(/県県県県県県県庫重都島和/, ks2017_freq_grade[3])
    assert_match(/賀香滋徳奈阪府府兵良/, ks2017_freq_grade[4])
    assert_match(/0種0字/, ks2017_freq_grade[5])
    assert_match(/0種0字/, ks2017_freq_grade[6])
    assert_match(/0種0字/, ks2017_freq_grade[0])

    ks1989 = KanjiSorter.new(seq, pub: "1989").analyze
    ks1989_freq_grade = ks1989.to_a
    assert_match(/三山川大/, ks1989_freq_grade[1])
    assert_match(/歌京/, ks1989_freq_grade[2])
    assert_match(/県県県県県県県庫重都島和/, ks1989_freq_grade[3])
    assert_match(/府府兵良/, ks1989_freq_grade[4])
    assert_match(/賀徳/, ks1989_freq_grade[5])
    assert_match(/0種0字/, ks1989_freq_grade[6])
    assert_match(/奈滋阪香/, ks1989_freq_grade[0])

    ks1977 = KanjiSorter.new(seq, pub: "1977").analyze
    ks1977_freq_grade = ks1977.to_a
    assert_match(/三山川大/, ks1977_freq_grade[1])
    assert_match(/歌京/, ks1977_freq_grade[2])
    assert_match(/県県県県県県県庫重都島和/, ks1977_freq_grade[3])
    assert_match(/府府兵良/, ks1977_freq_grade[4])
    assert_match(/賀徳/, ks1977_freq_grade[5])
    assert_match(/0種0字/, ks1977_freq_grade[6])
    assert_match(/奈滋阪香/, ks1977_freq_grade[0])

    ks1958 = KanjiSorter.new(seq, pub: "1958").analyze
    ks1958_freq_grade = ks1958.to_a
    assert_match(/三山川大/, ks1958_freq_grade[1])
    assert_match(/京/, ks1958_freq_grade[2])
    assert_match(/歌県県県県県県県庫重都島和/, ks1958_freq_grade[3])
    assert_match(/府府良/, ks1958_freq_grade[4])
    assert_match(/賀兵/, ks1958_freq_grade[5])
    assert_match(/徳/, ks1958_freq_grade[6])
    assert_match(/奈滋阪香/, ks1958_freq_grade[0])
  end
end
