# frozen_string_literal: true

module DevFinalCutExperiment
  class OrderBook
    include ActiveModel::Model

    TABLE = File.expand_path('../../data/scene-4-input.txt', __dir__)
    DROP_LINES = 0
    # Rule 9: dolls whose number is a multiple of 13 are never built.
    UNLUCKY_MULTIPLE = 13

    attr_reader :dolls

    def initialize(...)
      super
      validate!
      @dolls = []
    end

    def built_dolls
      dolls.reject { |doll| (doll.number % UNLUCKY_MULTIPLE).zero? }
    end

    def torn_out_dolls
      dolls - built_dolls
    end

    def minutes
      built_dolls.sum(&:minutes)
    end
  end
end
