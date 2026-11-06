# frozen_string_literal: true

module DevFinalCutExperiment
  class Guess
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :code, :string
    attribute :right_place, :integer
    attribute :wrong_place, :integer
    attribute :open, :boolean
    attribute :guesses_left, :integer

    attr_accessor :lock

    validates :code, format: { with: ->(guess) { guess.lock.code_pattern } }, if: :lock
    validates :right_place, :wrong_place, :guesses_left,
              numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :lock, presence: true

    def initialize(...)
      super
      validate!
    end

    # A guess made of one repeated symbol, e.g. "SSSSSS".
    def single_symbol?
      code.chars.uniq.one?
    end
  end
end
