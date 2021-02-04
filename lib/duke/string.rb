class String 

  def matchdel regex 
    match = self.match(regex)
    self[match[0]] = "" if match 
    return match
  end 

  def del substr 
    self[substr] = ""  if substr.present? && self.include?(substr)
    return self
  end 

end 