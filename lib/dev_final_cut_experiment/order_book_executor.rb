# frozen_string_literal: true

module DevFinalCutExperiment
  class OrderBookExecutor
    attr_reader :order_book

    def self.from_file
      new(InstructionParser.new)
    end

    def initialize(parser)
      @parser = parser
      @order_book = build_order_book
    end

    def run
      order_book.minutes
    end

    private

    attr_reader :parser

    def build_order_book
      order_book = OrderBook.new
      order_book.dolls.concat(parser.parse_rows(Doll, order_book:))
      order_book
    end
  end
end
