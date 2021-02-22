module Duke 
  module DukeRefinements 

    refine String do 
      # @params [Regex] regex, what we try to match 
      # @return [MatchElement] match, 
      def matchdel regex 
        match = self.match(regex)
        self[match[0]] = '' if match.present?
        return match
      end 

      # @params [String] substr 
      # rm -f from self
      def duke_del substr 
        self.gsub!(substr, '')  if substr.present? && self.include?(substr)
        self
      end 

      # downcase & split at first (" | ") & remove useless words & remove multiple whitespaces & removes accents
      def duke_clear 
        return " " if self.blank? 
        str = self.strip.downcase.split(" | ").first
        [/\bnum(e|é)ro\b/, /n ?°/,/\b(le|la|les)\b/, /(#|-|_|\\)/, /(?<=\s)\s/].each{|rgx| str.gsub!(rgx, '')}
        str = (I18n.transliterate(str) unless str.blank?)||" "
        str
      end 

      # @return all [sizes, substrings] sorted by size 
      def substrings 
        idx_cb = (0..self.size).to_a.combination(2)
        return idx_cb.map{|i1, i2| [i2-i1, self[i1..i2-1]] if i2-i1 > 3}.compact.sort_by{|e|-e[0]}
      end

      # @param [String|Array] item - String or words combinations
      # Match every Duke_word, add a logarithmic regression according to partial match size, to adjust matching level
      # @return [Float] biggest partial_match between self & ostr
      def partial_similar item 
        return 0 if self.length < 4
        items = item.words_combinations if item.kind_of?(String)
        return item.map{|wrd| wrd.length > 3 ? (0.64 + 0.14 * Math.log([wrd.size, 20].min)) * wrd.similar(self) : 0}.max
      end 

      # @return [Array] all words combinations from a string
      def words_combinations
        return (0..self.duke_words.size).to_a.combination(2).map{|i1, i2| self.duke_words[i1..i2-1].join(" ")}
      end

      # @return [Array] of all words from a string (splits at whitespaces and "'")
      def duke_words
        return self.split /\s+|\'/
      end
    end 

  end 
end 