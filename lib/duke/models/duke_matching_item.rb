module Duke
  module Models
    class DukeMatchingItem < HashWithIndifferentAccess

      attr_accessor :name, :distance, :indexes, :key, :matched, :rate

      def initialize(hash: nil, **args) 
        super()
        args = (args if hash.nil?)||hash
        args.each{|k, v| instance_variable_set("@#{k}", v)}
        args.each{|k, v| self[k.to_sym] = v}
      end 

      def has_lower_match?(a)
        # When user says "Bouleytreau Verrier", should we match "Bouleytreau" or "Bouleytreau-Verrier" ? Correcting distance with length of item found
        if a.key == @key
          return (true if a.distance >= @distance) || false
        else
          aDist = a.distance.to_f * Math.exp((a.matched.size - @matched.size)/70.0)
        end           
        return (true if aDist > @distance)|| false
      end

      def merge_h hash
        return self if hash.blank?
        if hash.kind_of?(Hash)  
          hash.each do |key, val|
            instance_variable_set("@#{key}", val)
            self[key.to_sym] = val
          end 
        end 
        self
      end 
      
      def needs_input_reinitialize? item 
        return false unless (item.key?(:rate) && self.key?(:rate))
        return true if ([:net_mass, :mass_area_density].include? self.rate[:unit].to_sym and Matter.find_by_id(item.key)&.net_mass.to_f == 0)
        return true if ([:net_volume, :volume_area_density].include? self.rate[:unit].to_sym and Matter.find_by_id(item.key)&.net_volume.fo_f == 0)
        return false
      end 
      
    end 
  end 
end 