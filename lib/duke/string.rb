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

  def better_match ostr 
    return nil if ostr.nil?
    level, val, pure = [0.0, nil, FuzzyStringMatch::JaroWinkler.create( :pure )]
    self.substrings.each do |key, value|
      if (dist=pure.getDistance(value, ostr)) > level
        val = value
        level=dist
      end 
    end
    return val
  end   

end 