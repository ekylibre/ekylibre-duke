class String 

  def matchdel regex 
    match = self.match(regex)
    self[match[0]] = "" if match 
    return match
  end 
  
end 