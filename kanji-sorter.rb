#!/usr/bin/env ruby
# coding: utf-8

# kanji-sorter.rb
#   引数の文字列，または引数で指定されたファイルに対して，
#   各漢字の出現頻度を求める．
#   教育漢字（学習漢字，小学漢字）でない漢字を報告する．

require "optparse"
require "date"

NAME_SHORT = "Kanji Sorter"
NAME_LONG = NAME_SHORT
VERSION_PREFIX = "0.0.2"
AUTHOR = "takehikom (takehiko@wakayama-u.ac.jp)"

class Date
  # 日付文字列からDateオブジェクトを生成する
  def self.ks_parse(str)
    d = Date.new

    if /^[rhs]/i =~ str
      s = d.resolve_wareki_year(str)
    else
      s = str
    end

    s = d.set_ymd(s)

    date = self.parse(s)
  end

  # ハッシュをもとに学年別漢字配当表の発表年
  # (1958 1977 1989 2017のいずれか)を返す
  def self.ks_year(h = {})
    # cond, date = get_cond_date(h)

    if h.key?(:use)
      cond = :use
      s = h[:use]
    else
      cond = :pub
      s = h[:pub]
    end
    if s.nil?
      raise "condition not specified."
    end
    date = self.ks_parse(s)

    if $DEBUG
      puts "DEBUG: h = #{h.inspect}"
      puts "DEBUG: cond = #{cond}"
      puts "DEBUG: date = #{date}"
    end
    y = date.get_ks_year(cond == :use)

    if $DEBUG
      puts "DEBUG: y = #{y}"
      puts
    end

    y
  end

  # 学年別漢字配当表の発表年(1958 1977 1989 2017のいずれか)を返す
  def get_ks_year(flag_use = false)
    if flag_use
      if self >= Date.parse("2020-04-01")
        return 2017
      elsif self >= Date.parse("1992-04-01")
        return 1989
      elsif self >= Date.parse("1980-04-01")
        return 1977
      elsif self >= Date.parse("1961-04-01")
        return 1958
      end
      raise "too old year in use specified"
    else
      if self >= Date.parse("2017-01-01")
        return 2017
      elsif self >= Date.parse("1989-01-01")
        return 1989
      elsif self >= Date.parse("1977-01-01")
        return 1977
      elsif self >= Date.parse("1958-01-01")
        return 1958
      end
      raise "too old year in publication specified"
    end
  end

  # 日付文字列の接頭辞（S:昭和，H:平成，R:令和）を西暦年に変換した
  # 日付文字列を返す
  def resolve_wareki_year(s)
    case s
    when /^r\D*(\d+)(.*)$/i
      s1, s2 = $1, $2
      s1_mod = (2018 + $1.to_i).to_s
    when /^h\D*(\d+)(.*)$/i
      s1, s2 = $1, $2
      s1_mod = (1988 + $1.to_i).to_s
    when /^s\D*(\d+)(.*)$/i
      s1, s2 = $1, $2
      s1_mod = (1925 + $1.to_i).to_s
    else
      raise "resolve_wareki_year failed."
    end

    s3 = s1_mod + s2
    if $DEBUG
      puts "resolve_wareki_year(#{s}) => #{s3}"
    end
    s3
  end

  # 年月日が含まれる文字列("2020-04-01", "20200401"など)を返す
  def set_ymd(s)
    s.gsub!(/\s/, "")
    if /^(\d+)s/i =~ s
      s = $1 + "-04-01"
    elsif /^\d{4}-\d{1,2}-\d{1,2}/ =~ s
      s = $&
    elsif /^(\d{4}(-?)\d{1,2})([^-\d]|$)/ =~ s
      s = $1 + $2 + "01"
    elsif /^(\d{4})(\D|$)/ =~ s
      s = $1 + "-01-01"
    end

    if $DEBUG
      puts "DEBUG: s = #{s}"
    end
    s
  end
end

class KanjiSorter
  def initialize(str, opt = {})
    @body = str # 入力文字列
    if opt[:from_file]
      @body = open(str).read
    end
    @pattern_result = opt[:pattern] || 0 # kanji_and_freq_to_sで使用

    begin
      @kanjiset_year = Date.ks_year(opt)
    rescue
      @kanjiset_year = 2017
    end

    @kanji_grade = {}         # '一' => 1, ...
    @kanji_freq = Hash.new(0) # @bodyにおける文字の頻度
    @freq_grade = []          # 各学年および配当外の出力内容
                              # (0:配当外，1:1年, ..., 6:6年)

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
    case @kanjiset_year
    when 1958
      # 1958年公表，1961年4月1日より使用
      # https://ja.wikipedia.org/wiki/%E5%AD%A6%E5%B9%B4%E5%88%A5%E6%BC%A2%E5%AD%97%E9%85%8D%E5%BD%93%E8%A1%A8_(1958-1967)
      kanji1 = '一右雨下火花九金月五口左三山子四耳七手十女小上森人水正生青石赤川先足大中田土二日白八木本目六'
      kanji2 = '雲円王音何夏家会海外学間気汽休牛京玉空犬見元古戸光工校考行高合谷国黒今作思糸紙字時車秋出春書少色心声西夕切雪千前組早草走村多男知地池竹虫朝町長鳥天冬東道読南入年馬麦半百父風分文米歩母方北名明毛門夜友用来立力林話'
      kanji3 = '悪安暗意引運駅園遠黄屋温化科歌荷画回界絵開貝角楽活寒感岸岩顔期帰記起客急球究級去魚強教橋局近銀苦君兄形計決研県原庫午後語交公向広号根才細算仕使始市指止死事寺持次自室実社者弱主取首受終週集住重所暑助勝昭乗場食新深申神親身進図数世星晴船全送太体待台第炭茶着昼柱注追通弟鉄店点電都度刀島投当答頭動同肉波配買売畑発坂板番皮美表病品負物聞平返勉妹毎万鳴面野役由遊曜様葉落理里流旅両礼和'
      kanji4 = '愛案以位囲委衣医育印員飲院泳英塩横加貨芽改械階害覚官観関館願喜器旗機季宮挙競共協鏡業曲極具郡係景軽芸結血建言固湖幸港航告差最祭菜材昨刷察散産残司史士姉詩試歯治式失写借守種酒州拾習順初商唱消焼照章植信真臣勢成整清静席積節戦線選然争相息速族続卒孫他打対隊代題達短談置丁帳調直停定底庭的転徒登努湯燈等働堂童内熱農反悲費飛鼻必氷秒不付夫府部服福粉別変便包放法望末味脈民命問薬油勇有予洋陽利陸料良緑輪類冷歴列練連路労老録'
      kanji5 = '圧易移胃因栄永衛液演央往応億恩仮価果河課過賀解快各格確完慣漢管寄希紀規技義議久救求給居許漁興均句区群軍型経欠件健験現限個護候功厚康講鉱査際在殺雑参蚕賛酸師志支氏似示辞質識舎謝収周修宿祝術準序承省象賞常情織性政精製績責接折設説浅銭祖素倉想総像増造側則測帯貸単団築貯張腸低敵適典伝統導銅特毒独任念燃能破敗倍博飯比肥非備筆俵標票貧婦布武副復仏兵編辺弁保報貿防牧満務無迷綿約輸余容要養浴留量領令例'
      kanji6 = '異遺壱営益延可我拡革額株刊勧幹歓眼基貴疑逆旧供境勤禁訓敬系潔兼券憲検権絹険厳減己故誤効后孝構皇耕穀混再妻採済災罪財策私至視詞資児釈授需宗就衆従述純処諸除招証称条状職仁推是制聖誠税絶舌宣専善創蔵俗属存尊損態退断忠著賃提程展党討得徳届難弐認納派拝判版犯否評富複奮陛補墓豊暴未盟訳預欲律率略臨論'
    when 1977
      # 1977年公表，1980年4月1日より使用
      # https://ja.wikipedia.org/wiki/%E5%AD%A6%E5%B9%B4%E5%88%A5%E6%BC%A2%E5%AD%97%E9%85%8D%E5%BD%93%E8%A1%A8_(1977-1988)
      kanji1 = '一右雨円王音下火花学気九休金空月犬見五口校左三山子四糸字耳七車手十出女小上森人水正生青夕石赤千川先早足村大男中虫町天田土二日入年白八百文木本名目立力林六'
      kanji2 = '引雲遠何科夏家歌画回会海絵貝外間顔汽記帰牛魚京教強玉近形計元原戸古午後語工広交光行考高黄合谷国黒今才作算止市思紙寺自時室社弱首秋春書少場色食心新親図数西声星晴切雪船前組走草多太体台池地知竹茶昼長鳥朝通弟店点電冬刀当東答頭同道読南馬買売麦半番父風分聞米歩母方北毎妹明鳴毛門夜野友用曜来楽里理話'
      kanji3 = '悪安暗医意育員院飲運泳駅園横屋温化荷界開階角活寒感館岸岩起期客究急級宮球去橋業曲局銀苦具君兄係軽血決県研言庫湖公向幸港号根祭細仕死使始指歯詩次事持式実写者主守取酒受州拾終習週集住重所暑助昭消商章勝乗植申身神深進世整線全送息族他打対待代第題炭短着注柱帳調直追丁定庭鉄転都度投島湯登等動童内肉農波配畑発反坂板皮悲美鼻氷表秒病品負部服福物平返勉放万味命面問役薬由油有遊予洋葉陽様落流旅両緑礼列路和'
      kanji4 = '愛案衣以囲位委胃印英栄塩央億加貨課芽改械害各覚完官漢管関観願希季紀喜旗器機議求救給挙漁共協鏡競極区軍郡型景芸欠結建健験固功候航康告差菜最材昨刷殺察参散産残士氏史司姉試辞失借種周宿順初省唱照賞焼臣信真成清勢静席積折節説浅戦選然争相倉想象速側続卒孫帯隊達単談治置貯腸低底停的典伝徒努灯堂働毒熱念敗倍博飯飛費必筆票標不夫付府副粉兵別辺変便包法望牧末満脈民約勇要養浴利陸良料量輪類令冷例歴連練老労録'
      kanji5 = '圧易移因営永衛液益演往応恩仮価果河過賀解快格確額刊幹慣歓眼基寄規技義逆久旧居許境興均禁句訓群経潔件券検絹険減現限個故護効厚構耕講鉱混査再妻採災際在罪財雑蚕賛酸師志支資似児示識質舎謝授収修衆祝述術準序除招承称証常条状情織職制性政精製税責績接設舌絶銭善祖素総造像増則測属損退貸態団断築張提程敵適統導銅得徳特独任燃能破犯判版比非肥備俵評貧婦布富武復複仏編弁保墓報豊防貿暴未務無迷綿輸余預容率略留領'
      kanji6 = '異遺域壱宇羽映延沿可我灰街革拡閣割株干巻看勧簡丸危机揮貴疑弓吸泣供胸郷勤筋系径敬警劇穴兼憲権源厳己呼誤后好孝皇紅降鋼刻穀骨困砂座済裁策冊至私姿視詞誌矢磁射捨尺釈若需樹宗就従縦縮熟純処署諸将笑傷障城蒸針仁垂推寸是聖誠宣専染泉洗奏窓創層操蔵臓俗存尊宅担探段暖値仲宙忠著庁兆頂潮賃痛展党討糖届難弐乳認納脳派拝肺背俳班晩否批秘腹奮陛閉片補宝訪亡忘棒枚幕密盟模訳郵優幼羊欲翌乱卵覧裏律臨朗論'
    when 1989
      # 1989年公表，1992年から使用
      # https://ja.wikipedia.org/wiki/%E5%AD%A6%E5%B9%B4%E5%88%A5%E6%BC%A2%E5%AD%97%E9%85%8D%E5%BD%93%E8%A1%A8_(1989-2016)
      kanji1 = '一右雨円王音下火花貝学気九休玉金空月犬見五口校左三山子四糸字耳七車手十出女小上森人水正生青夕石赤千川先早草足村大男竹中虫町天田土二日入年白八百文木本名目立力林六'
      kanji2 = '引羽雲園遠何科夏家歌画回会海絵外角楽活間丸岩顔汽記帰弓牛魚京強教近兄形計元言原戸古午後語工公広交光考行高黄合谷国黒今才細作算止市矢姉思紙寺自時室社弱首秋週春書少場色食心新親図数西声星晴切雪船線前組走多太体台地池知茶昼長鳥朝直通弟店点電刀冬当東答頭同道読内南肉馬売買麦半番父風分聞米歩母方北毎妹万明鳴毛門夜野友用曜来里理話'
      kanji3 = '悪安暗医委意育員院飲運泳駅央横屋温化荷開界階寒感漢館岸起期客究急級宮球去橋業曲局銀区苦具君係軽血決研県庫湖向幸港号根祭皿仕死使始指歯詩次事持式実写者主守取酒受州拾終習集住重宿所暑助昭消商章勝乗植申身神真深進世整昔全相送想息速族他打対待代第題炭短談着注柱丁帳調追定庭笛鉄転都度投豆島湯登等動童農波配倍箱畑発反坂板皮悲美鼻筆氷表秒病品負部服福物平返勉放味命面問役薬由油有遊予羊洋葉陽様落流旅両緑礼列練路和'
      kanji4 = '愛案以衣位囲胃印英栄塩億加果貨課芽改械害各覚街完官管関観願希季紀喜旗器機議求泣救給挙漁共協鏡競極訓軍郡径型景芸欠結建健験固功好候航康告差菜最材昨札刷殺察参産散残士氏史司試児治辞失借種周祝順初松笑唱焼象照賞臣信成省清静席積折節説浅戦選然争倉巣束側続卒孫帯隊達単置仲貯兆腸低底停的典伝徒努灯堂働特得毒熱念敗梅博飯飛費必票標不夫付府副粉兵別辺変便包法望牧末満未脈民無約勇要養浴利陸良料量輪類令冷例歴連老労録'
      kanji5 = '圧移因永営衛易益液演応往桜恩可仮価河過快賀解格確額刊幹慣眼基寄規技義逆久旧居許境均禁句群経潔件券険検限現減故個護効厚耕鉱構興講混査再災妻採際在財罪雑酸賛支志枝師資飼示似識質舎謝授修述術準序招承証条状常情織職制性政勢精製税責績接設舌絶銭祖素総造像増則測属率損退貸態団断築張提程適敵統銅導徳独任燃能破犯判版比肥非備俵評貧布婦富武復複仏編弁保墓報豊防貿暴務夢迷綿輸余預容略留領'
      kanji6 = '異遺域宇映延沿我灰拡革閣割株干巻看簡危机貴揮疑吸供胸郷勤筋系敬警劇激穴絹権憲源厳己呼誤后孝皇紅降鋼刻穀骨困砂座済裁策冊蚕至私姿視詞誌磁射捨尺若樹収宗就衆従縦縮熟純処署諸除将傷障城蒸針仁垂推寸盛聖誠宣専泉洗染善奏窓創装層操蔵臓存尊宅担探誕段暖値宙忠著庁頂潮賃痛展討党糖届難乳認納脳派拝背肺俳班晩否批秘腹奮並陛閉片補暮宝訪亡忘棒枚幕密盟模訳郵優幼欲翌乱卵覧裏律臨朗論'
    else
      # 2017年公表，2020年から使用
      # https://ja.wikipedia.org/wiki/%E5%AD%A6%E5%B9%B4%E5%88%A5%E6%BC%A2%E5%AD%97%E9%85%8D%E5%BD%93%E8%A1%A8
      kanji1 = '一右雨円王音下火花貝学気九休玉金空月犬見五口校左三山子四糸字耳七車手十出女小上森人水正生青夕石赤千川先早草足村大男竹中虫町天田土二日入年白八百文木本名目立力林六'
      kanji2 = '引羽雲園遠何科夏家歌画回会海絵外角楽活間丸岩顔汽記帰弓牛魚京強教近兄形計元言原戸古午後語工公広交光考行高黄合谷国黒今才細作算止市矢姉思紙寺自時室社弱首秋週春書少場色食心新親図数西声星晴切雪船線前組走多太体台地池知茶昼長鳥朝直通弟店点電刀冬当東答頭同道読内南肉馬売買麦半番父風分聞米歩母方北毎妹万明鳴毛門夜野友用曜来里理話'
      kanji3 = '悪安暗医委意育員院飲運泳駅央横屋温化荷開界階寒感漢館岸起期客究急級宮球去橋業曲局銀区苦具君係軽血決研県庫湖向幸港号根祭皿仕死使始指歯詩次事持式実写者主守取酒受州拾終習集住重宿所暑助昭消商章勝乗植申身神真深進世整昔全相送想息速族他打対待代第題炭短談着注柱丁帳調追定庭笛鉄転都度投豆島湯登等動童農波配倍箱畑発反坂板皮悲美鼻筆氷表秒病品負部服福物平返勉放味命面問役薬由油有遊予羊洋葉陽様落流旅両緑礼列練路和'
      kanji4 = '愛案以衣位茨印英栄媛塩岡億加果貨課芽賀改械害街各覚潟完官管関観願岐希季旗器機議求泣給挙漁共協鏡競極熊訓軍郡群径景芸欠結建健験固功好香候康佐差菜最埼材崎昨札刷察参産散残氏司試児治滋辞鹿失借種周祝順初松笑唱焼照城縄臣信井成省清静席積折節説浅戦選然争倉巣束側続卒孫帯隊達単置仲沖兆低底的典伝徒努灯働特徳栃奈梨熱念敗梅博阪飯飛必票標不夫付府阜富副兵別辺変便包法望牧末満未民無約勇要養浴利陸良料量輪類令冷例連老労録'
      kanji5 = '圧囲移因永営衛易益液演応往桜可仮価河過快解格確額刊幹慣眼紀基寄規喜技義逆久旧救居許境均禁句型経潔件険検限現減故個護効厚耕航鉱構興講告混査再災妻採際在財罪殺雑酸賛士支史志枝師資飼示似識質舎謝授修述術準序招証象賞条状常情織職制性政勢精製税責績接設絶祖素総造像増則測属率損貸態団断築貯張停提程適統堂銅導得毒独任燃能破犯判版比肥非費備評貧布婦武復複仏粉編弁保墓報豊防貿暴脈務夢迷綿輸余容略留領歴'
      kanji6 = '胃異遺域宇映延沿恩我灰拡革閣割株干巻看簡危机揮貴疑吸供胸郷勤筋系敬警劇激穴券絹権憲源厳己呼誤后孝皇紅降鋼刻穀骨困砂座済裁策冊蚕至私姿視詞誌磁射捨尺若樹収宗就衆従縦縮熟純処署諸除承将傷障蒸針仁垂推寸盛聖誠舌宣専泉洗染銭善奏窓創装層操蔵臓存尊退宅担探誕段暖値宙忠著庁頂腸潮賃痛敵展討党糖届難乳認納脳派拝背肺俳班晩否批秘俵腹奮並陛閉片補暮宝訪亡忘棒枚幕密盟模訳郵優預幼欲翌乱卵覧裏律臨朗論'
    end

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
  opt.on("-u", "--use=VAL", "date in use") {|v|
    h[:use] = v
  }
  opt.on("-p", "--pub=VAL", "date in publication") {|v|
    h[:pub] = v
  }
  opt.parse!(ARGV)
  if h.key?(:from_file)
    KanjiSorter.new(h[:filename], h).start
  else
    KanjiSorter.new(ARGV.join(" "), h).start
  end
end
