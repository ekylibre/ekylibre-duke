module Duke
  class DukeMockObject
    attr_accessor :name, :id

    def initialize(name:, id: )
      @name = name
      @id = id
    end
  end
end
