# frozen_string_literal: true

module DevFinalCutExperiment
  class Doll
    # Rule 7: none 0, giggle 4, whisper 6, lullaby 11. A head that can't hold a
    # voice box gets none, and the order is charged nothing.
    class VoiceBox < Part
      MINUTES = { 'none' => 0, 'giggle' => 4, 'whisper' => 6, 'lullaby' => 11 }.freeze

      attribute :kind, :string

      validates :kind, inclusion: { in: MINUTES.keys }

      def minutes
        ignored? ? 0 : MINUTES.fetch(kind)
      end

      def ignored?
        !doll.head.holds_voice_box?
      end
    end
  end
end
