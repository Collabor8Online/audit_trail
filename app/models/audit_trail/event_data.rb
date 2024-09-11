module AuditTrail
  class EventData
    def initialize event
      @event = event
    end

    def [] key
      value_for(key) || model_for(key)
    end

    def []= key, value
      value.is_a?(ActiveRecord::Base) ? set_model(key, value) : set_value(key, value)
    end

    private

    def value_for key
      @event.internal_data[key]
    end

    def set_value key, value
      @event.internal_data[key] = value
    end

    def model_for key
      @event.links.find_by(name: key)&.model
    end

    def set_model key, model
      @event.links.where(name: key).first_or_initialize.update! model: model
    end
  end
end
