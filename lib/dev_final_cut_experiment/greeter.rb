# frozen_string_literal: true

module DevFinalCutExperiment
  class Greeter
    def initialize(name)
      @name = name
    end

    def greet
      "Hello, #{@name}!"
    end
  end
end
