module Duke
  class DukeMatchingItem < HashWithIndifferentAccess
    include Utils::BaseDuke
    using Duke::Utils::DukeRefinements

    attr_accessor :name, :distance, :indexes, :key, :matched, :rate, :area

    def initialize(hash: nil, **args)
      super()
      args = (args if hash.nil?) || hash
      args.each{|k, v| instance_variable_set("@#{k}", v)}
      args.each{|k, v| self[k.to_sym] = v}
    end

    # @param [DukeMatchingElement] item
    # @returns true if self matches less than item
    def lower_match?(item)
      # byebug
      if item.key == @key # only compare distance when same item
        item.distance > @distance
      else # apply exp(diff/70) to have item-length correction
        dist = item.distance.to_f * Math.exp((item.matched.size - @matched.size)/120.0)
        dist > @distance
      end
    end

    # @param [Hash] hash : to_merge
    def merge_h(hash)
      hash.to_h.each do |key, val|
        instance_variable_set("@#{key}", val)
        self[key.to_sym] = val
      end
      self
    end

    # @param [DukeMatchingItem] item
    # @returns true if item rate isn't permitted for him || false
    def conflicting_rate?(item)
      # byebug
      item.key?(:rate) && self.key?(:rate) &&
      ((%i[net_mass mass_area_density].include?(self.rate[:unit].to_sym) && (Matter.find_by_id(item.key)&.net_mass.to_f == 0)) ||
      (%i[net_volume volume_area_density].include?(self.rate[:unit].to_sym) && (Matter.find_by_id(item.key)&.net_volume&.to_f == 0)))
    end

    # @param [String] procedure
    # @param [Measure] measure
    # @returns boolean
    def measure_coherent?(measure, procedure)
      # byebug
      input_param = Procedo::Procedure.find(procedure).parameters_of_type(:input).find do |param|
        Matter.find_by_id(@key).of_expression(param.filter)
      end
      dim = measure.base_dimension.to_sym
      # True If measure in mass or volume , and procedure can handle this type of indicators for its inputs and net dimension exists
      %i[mass volume].include?(dim) && input_param.handler("net_#{dim}").present? && !Matter.find_by_id(key)&.send("net_#{dim}")&.zero?
    end

  end
end
