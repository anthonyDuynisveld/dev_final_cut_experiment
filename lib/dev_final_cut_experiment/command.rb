# frozen_string_literal: true

module DevFinalCutExperiment
  class Command
    include ActiveModel::Model
    include ActiveModel::Attributes

    ACTIONS = %w[turn_on turn_off toggle].freeze

    attribute :action, :string
    attribute :from, :integer
    attribute :to, :integer

    validates :action, inclusion: { in: ACTIONS }
    validates :from, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :to, numericality: { only_integer: true, greater_than_or_equal_to: :from }, if: :from

    def apply(hallway)
      hallway.public_send(action, from, to)
    end
  end
end
