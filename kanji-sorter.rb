#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# kanji-sorter.rb
#   引数の文字列，または引数で指定されたファイルに対して，
#   各漢字を小学校で学習する学年（および配当外）に振り分け，
#   出現回数を出力する．

if RUBY_VERSION < "1.9"
  $KCODE = "utf8"
end

require "optparse"

NAME_SHORT = "Kanji Sorter"
NAME_LONG = NAME_SHORT
VERSION_PREFIX = "0.0.1"
AUTHOR = "takehikom (takehiko@sys.wakayama-u.ac.jp)"

class KanjiSorter
  def initialize(str, opt = {})
    @body = str # 入力文字列
    if opt[:from_file]
      @body = open(str).read
    end
    @pattern_result = opt[:pattern] || 0 # kanji_and_freq_to_sで使用

    @kanji_grade = {}         # '一' => 1, ...
    @kanji_freq = Hash.new(0) # @bodyにおける文字の頻度
    @freq_grade = []          # 各学年および配当外の出力内容(0:配当外，1:1年, ..., 6:6年)

    setup_kanji
  end
  attr_reader :body

  def start
    analyze
    report
  end

  def analyze
    get_kanji_freq
    get_freq_grade
  end

  def get_kanji_freq
    @body.each_line do |line0|
      line = line0.gsub(/[^一-龠]/, '')
      line.split(//).each do |c|
        @kanji_freq[c] += 1
      end
    end

    self # for method chain
  end

  def get_freq_grade
    @kanji_array.each_with_index do |kanji_grade_array, i|
      grade = i + 1
      line = ""
      freq = 0
      sort = 0

      kanji_grade_array.each do |c|
        if @kanji_freq[c] > 0
          line += kanji_and_freq_to_s(c)
          sort += 1
          freq += @kanji_freq[c]
          @kanji_freq.delete(c)
        end
      end
      line = "#{grade}年(#{sort}種#{freq}字): " + line
      @freq_grade.push(line)
    end

    line = ""
    freq = 0
    sort = 0
    kanji_outside = @kanji_freq.keys.sort
    kanji_outside.each do |c|
      line += kanji_and_freq_to_s(c)
      sort += 1
      freq += @kanji_freq[c]
      @kanji_freq.delete(c)
    end
    # この時点で@kanji_freqは空になる
    line = "配当外(#{sort}種#{freq}字): " + line
    @freq_grade.unshift(line)

    self # for method chain
  end

  def to_a
    @freq_grade
  end

  def to_s
    if @freq_grade.empty?
      ""
    else
      (@freq_grade[1, 6] + [@freq_grade[0]]).join("\n") + "\n"
    end
  end

  def report
    print to_s
  end

  def include?(c, grade = nil)
    if grade
      @kanji_grade[c] == grade
    else
      @kanji_grade[c]
    end
  end

  private

  def setup_kanji
    # 学年別漢字配当表 http://ja.wikipedia.org/wiki/%E5%AD%A6%E5%B9%B4%E5%88%A5%E6%BC%A2%E5%AD%97%E9%85%8D%E5%BD%93%E8%A1%A8
    kanji1 = '一右雨円王音下火花貝学気九休玉金空月犬見五口校左三山子四糸字耳七車手十出女小上森人水正生青夕石赤千川先早草足村大男竹中虫町天田土二日入年白八百文木本名目立力林六'
    kanji2 = '引羽雲園遠何科夏家歌画回会海絵外角楽活間丸岩顔汽記帰弓牛魚京強教近兄形計元言原戸古午後語工公広交光考行高黄合谷国黒今才細作算止市矢姉思紙寺自時室社弱首秋週春書少場色食心新親図数西声星晴切雪船線前組走多太体台地池知茶昼長鳥朝直通弟店点電刀冬当東答頭同道読内南肉馬売買麦半番父風分聞米歩母方北毎妹万明鳴毛門夜野友用曜来里理話'
    kanji3 = '悪安暗医委意育員院飲運泳駅央横屋温化荷開界階寒感漢館岸起期客究急級宮球去橋業曲局銀区苦具君係軽血決研県庫湖向幸港号根祭皿仕死使始指歯詩次事持式実写者主守取酒受州拾終習集住重宿所暑助昭消商章勝乗植申身神真深進世整昔全相送想息速族他打対待代第題炭短談着注柱丁帳調追定庭笛鉄転都度投豆島湯登等動童農波配倍箱畑発反坂板皮悲美鼻筆氷表秒病品負部服福物平返勉放味命面問役薬由油有遊予羊洋葉陽様落流旅両緑礼列練路和'
    kanji4 = '愛案以衣位囲胃印英栄塩億加果貨課芽改械害各覚街完官管関観願希季紀喜旗器機議求泣救給挙漁共協鏡競極訓軍郡径型景芸欠結建健験固功好候航康告差菜最材昨札刷殺察参産散残士氏史司試児治辞失借種周祝順初松笑唱焼象照賞臣信成省清静席積折節説浅戦選然争倉巣束側続卒孫帯隊達単置仲貯兆腸低底停的典伝徒努灯堂働特得毒熱念敗梅博飯飛費必票標不夫付府副粉兵別辺変便包法望牧末満未脈民無約勇要養浴利陸良料量輪類令冷例歴連老労録'
    kanji5 = '圧移因永営衛易益液演応往桜恩可仮価河過快賀解格確額刊幹慣眼基寄規技義逆久旧居許境均禁句群経潔件券険検限現減故個護効厚耕鉱構興講混査再災妻採際在財罪雑酸賛支志枝師資飼示似識質舎謝授修述術準序招承証条状常情織職制性政勢精製税責績接設舌絶銭祖素総造像増則測属率損退貸態団断築張提程適敵統銅導徳独任燃能破犯判版比肥非備俵評貧布婦富武復複仏編弁保墓報豊防貿暴務夢迷綿輸余預容略留領'
    kanji6 = '異遺域宇映延沿我灰拡革閣割株干巻看簡危机貴揮疑吸供胸郷勤筋系敬警劇激穴絹権憲源厳己呼誤后孝皇紅降鋼刻穀骨困砂座済裁策冊蚕至私姿視詞誌磁射捨尺若樹収宗就衆従縦縮熟純処署諸除将傷障城蒸針仁垂推寸盛聖誠宣専泉洗染善奏窓創装層操蔵臓存尊宅担探誕段暖値宙忠著庁頂潮賃痛展討党糖届難乳認納脳派拝背肺俳班晩否批秘腹奮並陛閉片補暮宝訪亡忘棒枚幕密盟模訳郵優幼欲翌乱卵覧裏律臨朗論'

    add_grade(1, kanji1)
    add_grade(2, kanji2)
    add_grade(3, kanji3)
    add_grade(4, kanji4)
    add_grade(5, kanji5)
    add_grade(6, kanji6)

    @kanji_array = [kanji1, kanji2, kanji3, kanji4, kanji5, kanji6].map {|str| str.split(//)}
  end

  def add_grade(grade, str)
    str.split(//).each do |c|
      @kanji_grade[c] = grade
    end
  end

  def kanji_and_freq_to_s(c)
    freq = @kanji_freq[c]
    case @pattern_result
    when 1
      "\n\t%s(%d)" % [c, freq]
    when 2
      "%s(%d) " % [c, freq]
    else
      c * freq
    end
  end
end

if __FILE__ == $0
  opt = OptionParser.new
  h = {}
  opt.on("-i", "--input=VAL", "input from file") {|v|
    h[:from_file] = true
    h[:filename] = v
  }
  opt.on("-p", "--pattern=VAL", "output pattern of kanji characters") {|v|
    h[:pattern] = v.to_i
  }
  opt.parse!(ARGV)
  if h.key?(:from_file)
    KanjiSorter.new(h[:filename], h).start
  else
    KanjiSorter.new(ARGV.join(" "), h).start
  end
end
