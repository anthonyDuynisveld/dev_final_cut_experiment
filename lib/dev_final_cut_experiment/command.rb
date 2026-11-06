# frozen_string_literal: true

module DevFinalCutExperiment
  class Command
    include ActiveModel::Model
    include ActiveModel::Attributes

    TABLE = Hallway::TABLE
    DROP_LINES = Hallway::DROP_LINES
    PATTERN = /\A(?<action>turn on|turn off|toggle) (?<from>\d+) through (?<to>\d+)\z/
    ACTIONS = %w[turn_on turn_off toggle].freeze

    attribute :action, :string
    attribute :from, :integer
    attribute :to, :integer

    attr_accessor :hallway

    validates :action, inclusion: { in: ACTIONS }
    validates :from, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :to, numericality: { only_integer: true, greater_than_or_equal_to: :from }, if: :from
    validates :hallway, presence: true
    validates :to, numericality: { less_than: ->(command) { command.hallway.size } }, if: :hallway

    def initialize(...)
      super
      validate!
    end

    # The file says "turn on"; the Hallway method is turn_on.
    def action=(value)
      super(value.to_s.tr(' ', '_'))
    end

    def apply
      hallway.public_send(action, from, to)
    end
  end
end
