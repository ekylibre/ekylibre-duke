class String 

  def matchdel regex 
    match = self.match(regex)
    self[match[0]] = '' if match.present?
    return match
  end 

  def del substr 
    self.gsub!(substr, '')  if substr.present? && self.include?(substr)
    self
  end 

  def duke_clear 
    return " " if self.blank? 
    str = self.strip.downcase.split(" | ").first
    [/\bnum(e|é)ro\b/, /n ?°/,/\b(le|la|les)\b/, /(#|-|_|\\)/, /(?<=\s)\s/].each{|rgx| str.gsub!(rgx, '')}
    str = (I18n.transliterate(str) unless str.blank?)||" "
    str
  end 

  def substrings 
    idx_cb = (0..self.size).to_a.combination(2)
    return idx_cb.map{|i1, i2| [i2-i1, self[i1..i2-1]] if i2-i1 > 3}.compact.sort_by{|e|-e[0]}
  end

  def partial_similar ostr 
    return 0 if self.length > ostr.length||ostr.split.first.eql?(ostr)
    return ostr.words_combinations.map{|word| word.length > 3 ? word.similar(self) : 0}.max
  end 

  def words_combinations
    return (0..self.duke_words.size).to_a.combination(2).map{|i1, i2| self.duke_words[i1..i2-1].join(" ")}
  end

  def duke_words
    return self.split /\s+|\'/
  end 
  
  def better_match ostr 
    return nil if ostr.nil?
    level, val = 0, nil
    self.substrings.each do |key, value|
      if (dist=value.similar(ostr)) > level
        val = value
        level = dist
      end 
    end
    return val
  end   

end 