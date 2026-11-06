# frozen_string_literal: true

module DevFinalCutExperiment
  class LibraryExecutor
    attr_reader :library

    def self.from_file
      new(InstructionParser.new)
    end

    def initialize(parser)
      @parser = parser
      @library = build_library
    end

    def run
      library.genuine_shelf_sum
    end

    private

    attr_reader :parser

    def build_library
      library = Library.new
      library.books.concat(parser.parse_rows(Book, library:))
      library
    end
  end
end
