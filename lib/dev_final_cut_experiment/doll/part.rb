# frozen_string_literal: true

module DevFinalCutExperiment
  class Doll
    # Shared by every doll part: belongs to a doll, validates as it's built,
    # and answers how many minutes it takes.
    class Part
      include ActiveModel::Model
      include ActiveModel::Attributes

      attr_accessor :doll

      validates :doll, presence: true

      def initialize(...)
        super
        validate!
      end

      def minutes
        raise NotImplementedError, "#{self.class.name} must define #minutes"
      end
    end
  end
end
