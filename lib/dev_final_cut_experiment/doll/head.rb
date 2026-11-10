# frozen_string_literal: true

module DevFinalCutExperiment
  class Doll
    # Rule 2: porcelain 25, wax 15, cloth 10. Also the only place that knows
    # what each material can hold, for the rules on eyes, hair and voice.
    class Head < Part
      MINUTES = { 'porcelain' => 25, 'wax' => 15, 'cloth' => 10 }.freeze

      attribute :material, :string

      validates :material, inclusion: { in: MINUTES.keys }

      def minutes
        MINUTES.fetch(material)
      end

      # Rule 3: wax melts glass-eye sockets.
      def holds_glass_eyes?
        material != 'wax'
      end

      # Rule 4: real hair on cloth is stitched strand by strand.
      def stitches_real_hair?
        material == 'cloth'
      end

      # Rule 7: only porcelain and wax can hold a voice box.
      def holds_voice_box?
        material != 'cloth'
      end
    end
  end
end
