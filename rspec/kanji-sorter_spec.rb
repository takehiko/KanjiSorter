#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "rspec"
require "./kanji-sorter.rb"

describe KanjiSorter do
  let(:kc_none) { KanjiSorter.new("") }
  let(:kc_str) { KanjiSorter.new("親馬鹿").analyze }
  let(:kc_file) { KanjiSorter.new(__FILE__, :from_file => true).analyze }

  context "#table" do
    it 'should have an appropriate Kanji table (親)' do
      kc_none.include?("親", 2).should be_true
    end

    it 'should have an appropriate Kanji table (馬)' do
      kc_none.include?("馬", 3).should be_false
    end

    it 'should have an appropriate Kanji table (鹿)' do
      kc_none.include?("鹿").should be_nil
    end
  end

  context "#word" do
    it 'should make an appropriate list (親馬鹿)' do
      kc_str.to_a[2].should =~ /親馬$/
    end

    it 'should make an appropriate list (親馬鹿)' do
      kc_str.to_a[0].should =~ /鹿$/
    end
  end

  context "#file" do
    it 'should make an appropriate list' do
      kc_file.to_a[1].should match(/学{5}/)
    end

    it 'should make an appropriate list' do
      kc_file.to_a[1].should_not match(/字{10}$/)
    end

    it 'should make an appropriate list' do
      kc_file.to_a[0].should match(/8.16/)
    end
  end
end

=begin
- 欲しいのは，「小学校で習わない漢字の検出」ですが，「各漢字の頻度分析」もさせています．
- 小学校で習う漢字は，[wikipedia:学年別漢字配当表]から切り貼りし，コードに入れました．そして出力の際，各学年についてはこの配当表の順としました．ない漢字については，UTF-8の文字コード順としました．
- デフォルトの出力は幹葉表示です．各学年+配当外に分けて，その出現個数だけ漢字が出てきます．
- いつものように，Ruby 1.8/1.9両対応です．
使用上の注意もあります：
- 入力ファイルがUTF-8以外だと実行時エラーが起こります．内部で文字コードの変換をしていません．
- 人名用漢字は配当外です．「猛彦」のうち，「彦」はこの理由でアウトです．
- 表記の揺れ（「いう」「言う」など）は検出しません．
- いわゆる静的分析なので，TeXなどマクロを定義していればその記述，すなわち展開前の内容が，分析の対象となります．
(http://d.hatena.ne.jp/takehikom/20110303/1299099469 一部改変)
=end
