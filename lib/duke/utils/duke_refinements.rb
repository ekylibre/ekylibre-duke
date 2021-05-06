module Duke
  module Utils
    module DukeRefinements

      refine String do
        # @params [Regex] regex, what we try to match
        # @return [MatchElement] match,
        def matchdel(regex)
          match = self.match(regex)
          self[match[0]] = '' if match
          match
        end

        # @params [String] substr
        # rm -f substr from self
        def duke_del(substr)
          self.gsub!(substr, '') if substr.present? && self.include?(substr)
          self
        end

        # downcase & split at first (" | ") & remove useless words & remove multiple whitespaces & removes accents
        # @return [String]cleared_string
        def duke_clear
          if self.blank?
            ' '
          else
            str = self.strip.downcase.split(' | ').first
            [
              Regex.numeroes,
              Regex.useless_words,
              Regex.useless_characters,
              Regex.multiple_whitespaces
            ].each{|regex| str.gsub!(regex, '')}
            str.blank? ? ' ' : I18n.transliterate(str)
          end
        end

        # Creates substrings for string
        # @return all [sizes, substrings] sorted by size
        def substrings
          idx_cb = (0..self.size).to_a.combination(2)
          idx_cb.map{|i1, i2| [i2-i1, self[i1..i2-1]] if i2-i1 > 3}.compact.sort_by{|e| -e[0]}
        end

        # Match every Duke_word, add alogarithmic regression according to partial match size, to adjust matching level
        # @param [String|Array] item - String or Array of strings
        # @return [Float] biggest partial_match between self & item
        def partial_similar(item)
          if self.length < 4 || item.blank?
            0
          else
            item = item.words_combinations if item.is_a?(String)
            item.map{|word| word.length > 3 ? (0.64 + 0.14 * Math.log(word.size)) * word.similar(self) : 0}.max
          end
        end

        # Creates all words combinations for a sentence
        # @return [Array] all words combinations from a string
        def words_combinations
          (0..self.duke_words.size).to_a.combination(2).map do |i1, i2|
            self.duke_words[i1..i2-1].join(' ')
          end
        end

        # Splits every words from a sentence on \s & \'
        # @return [Array] of all words from a string (splits at whitespaces and "'")
        def duke_words
          self.split(/\s+|\'/)
        end
      end

    end
  end
end
