require "securerandom"

class Blade::Model < OpenStruct
  class << self
    def models
      @models ||= {}
    end

    def create(attributes)
      attributes[:id] ||= SecureRandom.hex(4)
      model = new(attributes)
      models[model.id] = model
    end

    def find(id)
      models[id]
    end

    def remove(id)
      models.delete(id)
    end

    def all
      models.values
    end

    def size
      models.size
    end
  end
end
