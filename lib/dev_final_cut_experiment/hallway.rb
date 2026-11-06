# frozen_string_literal: true

module DevFinalCutExperiment
  class Hallway
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :size, :integer

    validates :size, numericality: { only_integer: true, greater_than: 0 }

    def lights
      @lights ||= Array.new(size, false)
    end

    def turn_on(from, to)
      (from..to).each { |index| lights[index] = true }
    end

    def turn_off(from, to)
      (from..to).each { |index| lights[index] = false }
    end

    def toggle(from, to)
      (from..to).each { |index| lights[index] = !lights[index] }
    end

    def lit_count
      lights.count(true)
    end
  end
end
