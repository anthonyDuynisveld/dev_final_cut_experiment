# frozen_string_literal: true

module DevFinalCutExperiment
  class Doll
    # Rule 4: none 0, yarn 8, real 20. Real hair takes twice as long on a head
    # that has it stitched in.
    class Hair < Part
      MINUTES = { 'none' => 0, 'yarn' => 8, 'real' => 20 }.freeze
      STITCHED_MULTIPLIER = 2

      attribute :style, :string

      validates :style, inclusion: { in: MINUTES.keys }

      def minutes
        stitched? ? MINUTES.fetch(style) * STITCHED_MULTIPLIER : MINUTES.fetch(style)
      end

      def stitched?
        style == 'real' && doll.head.stitches_real_hair?
      end
    end
  end
end
