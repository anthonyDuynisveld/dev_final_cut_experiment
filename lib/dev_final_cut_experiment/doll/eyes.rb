# frozen_string_literal: true

module DevFinalCutExperiment
  class Doll
    # Rule 3: two eyes; button 2 each, painted 1, glass 6. Glass eyes on a head
    # that can't hold them are painted instead, at painted time.
    class Eyes < Part
      COUNT = 2
      MINUTES = { 'button' => 2, 'painted' => 1, 'glass' => 6 }.freeze

      attribute :kind, :string

      validates :kind, inclusion: { in: MINUTES.keys }

      def minutes
        COUNT * MINUTES.fetch(kind_used)
      end

      def kind_used
        kind == 'glass' && !doll.head.holds_glass_eyes? ? 'painted' : kind
      end
    end
  end
end
