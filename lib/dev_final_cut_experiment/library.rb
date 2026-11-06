# frozen_string_literal: true

module DevFinalCutExperiment
  class Library
    include ActiveModel::Model

    TABLE = File.expand_path('../../data/scene-2-input.txt', __dir__)
    DROP_LINES = 0

    attr_reader :books

    def initialize(...)
      super
      validate!
      @books = []
    end

    def genuine_books
      books.select(&:genuine?)
    end

    def genuine_shelf_sum
      genuine_books.sum(&:shelf)
    end
  end
end
