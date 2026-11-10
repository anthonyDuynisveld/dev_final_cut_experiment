# frozen_string_literal: true

module DevFinalCutExperiment
  class Doll
    # Rule 5: a complete doll has 4 limbs. Each attached limb takes 5 minutes;
    # each missing limb still takes 2, to sew the stump closed.
    class Limbs < Part
      COMPLETE = 4
      ATTACH_MINUTES = 5
      SEW_CLOSED_MINUTES = 2

      attribute :count, :integer

      validates :count, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: COMPLETE }

      def minutes
        (count * ATTACH_MINUTES) + (missing * SEW_CLOSED_MINUTES)
      end

      def missing
        COMPLETE - count
      end
    end
  end
end
