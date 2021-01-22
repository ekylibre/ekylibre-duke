module Duke
  module Models
    class DukeMatchingItem < HashWithIndifferentAccess

      attr_accessor :name, :distance, :indexes, :key, :matched

      def initialize(**args) 
        super()
        args.each{|k, v| instance_variable_set("@#{k}", v)}
        args.each{|k, v| self[k] = v}
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
      
    end 
  end 
end 