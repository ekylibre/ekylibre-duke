module Duke
  class DukeMatchingItem < HashWithIndifferentAccess
    include BaseDuke
    attr_accessor :name, :distance, :indexes, :key, :matched, :rate, :area, :potential

    def initialize(hash: nil, **args) 
      super()
      args = (args if hash.nil?)||hash
      args.each{|k, v| instance_variable_set("@#{k}", v)}
      args.each{|k, v| self[k.to_sym] = v}
    end 

    # @param [DukeMatchingElement] item
    # @returns true if self matches less than item
    def has_lower_match?(item)
      if item.key == @key # only compare distance when same item
        return (true if item.distance > @distance)||false
      else # apply exp(diff/70) to have item-length correction
        aDist = item.distance.to_f * Math.exp((item.matched.size - @matched.size)/120.0)
      end           
      return (true if aDist > @distance)||false 
    end

    # @param [Hash] hash : to_merge
    def merge_h hash
      hash.to_h.each do |key, val|
        instance_variable_set("@#{key}", val)
        self[key.to_sym] = val
      end  
      self
    end 
    
    # @param [DukeMatchingItem] item 
    # @returns true if item rate isn't permitted for him || false
    def needs_input_reinitialize? item 
      return false unless (item.key?(:rate) && self.key?(:rate))
      return true if ([:net_mass, :mass_area_density].include? self.rate[:unit].to_sym and Matter.find_by_id(item.key)&.net_mass.to_f == 0)
      return true if ([:net_volume, :volume_area_density].include? self.rate[:unit].to_sym and Matter.find_by_id(item.key)&.net_volume.fo_f == 0)
      return false
    end 

    # @param [String] procedure
    # @param [Measure] measure
    # @returns boolean
    def is_measure_coherent? measure, procedure
      input_param = Procedo::Procedure.find(procedure).parameters_of_type(:input).find{|param| Matter.find_by_id(@key).of_expression(param.filter)}
      dim = measure.base_dimension.to_sym
      # True If measure in mass or volume , and procedure can handle this type of indicators for its inputs and net dimension exists for specific input
      return true if ([:mass, :volume].include? dim) && (input_param.handler("net_#{dim}").present?) && (!Matter.find_by_id(key)&.send("net_#{dim}").zero?)
      return false
    end 

    def longest_substring otherstr
      substrs = clear_string(self.name.clone).substrings
      biggest = substrs.find{|sub| otherstr.include? sub[1]}
      return (biggest.last if biggest)||nil
    end 

    def has_something_more_than? otherstr
      pure = FuzzyStringMatch::JaroWinkler.create( :pure )
      common = self.longest_substring(clear_string(otherstr))
      match_rest = self.matched.clone.del(self.matched.better_match common)
      our_rest = clear_string(self.name.clone).del common
      oth_rest = clear_string(otherstr.clone).del common
      ourDist = pure.getDistance(our_rest, match_rest)
      return (true if ourDist > 0.70 && ourDist - pure.getDistance(oth_rest, match_rest) > 0.50)||false
    end 
    
  end 
end 