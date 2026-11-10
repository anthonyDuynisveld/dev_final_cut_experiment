# frozen_string_literal: true

module DevFinalCutExperiment
  class Doll
    # Rule 1: every doll takes 10 minutes to cut its pattern, whatever it's made of.
    class Pattern < Part
      MINUTES = 10

      def minutes
        MINUTES
      end
    end
  end
end
