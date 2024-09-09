module AuditTrail
  def self.record event_name, partition: "event", user: nil, **params
    models = params.select { |key, value| value.is_a? ActiveRecord::Base }
    data = params.select { |key, value| !value.is_a? ActiveRecord::Base }
    Event.create!(name: event_name, partition: partition, user: user, data: data, status: "completed").tap do |event|
      models.each { |key, model| event.links.create! name: key, model: model }
    end
  end
end
