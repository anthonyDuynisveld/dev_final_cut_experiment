# frozen_string_literal: true

module DevFinalCutExperiment
  class Doll
    # Rule 8: after everything else is added up, a haunted doll's total is
    # multiplied by 1.5, rounded up to a whole minute. They fidget.
    class Haunting
      include ActiveModel::Model
      include ActiveModel::Attributes

      ANSWERS = %w[yes no].freeze
      MULTIPLIER = 1.5

      attribute :answer, :string

      validates :answer, inclusion: { in: ANSWERS }

      def initialize(...)
        super
        validate!
      end

      def haunted?
        answer == 'yes'
      end

      def apply(subtotal)
        haunted? ? (subtotal * MULTIPLIER).ceil : subtotal
      end
    end
  end
end
