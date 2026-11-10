# frozen_string_literal: true

module DevFinalCutExperiment
  class Doll
    # Rule 6: none 0, overalls 7, sailor 9, gown 12. With fewer than 2 limbs the
    # outfit takes half the time, rounded down (fewer sleeves).
    class Outfit < Part
      MINUTES = { 'none' => 0, 'overalls' => 7, 'sailor' => 9, 'gown' => 12 }.freeze
      HALF_TIME_BELOW_LIMBS = 2

      attribute :style, :string

      validates :style, inclusion: { in: MINUTES.keys }

      def minutes
        half_time? ? MINUTES.fetch(style) / 2 : MINUTES.fetch(style)
      end

      def half_time?
        doll.limbs.count < HALF_TIME_BELOW_LIMBS
      end
    end
  end
end
