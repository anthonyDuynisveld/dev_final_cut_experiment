# frozen_string_literal: true

module DevFinalCutExperiment
  # One line of the order book. The doll is assembled from parts, each of which
  # knows its own Manual rule; the doll adds them up and applies the haunting.
  class Doll
    include ActiveModel::Model
    include ActiveModel::Attributes

    TABLE = OrderBook::TABLE
    DROP_LINES = OrderBook::DROP_LINES
    PATTERN = /\ADoll (?<number>\d+): head=(?<head>\w+), eyes=(?<eyes>\w+), hair=(?<hair>\w+), limbs=(?<limbs>\d+), outfit=(?<outfit>\w+), voice=(?<voice>\w+), haunted=(?<haunted>\w+)\z/

    attribute :number, :integer

    attr_accessor :order_book
    attr_reader :pattern, :head, :eyes, :hair, :limbs, :outfit, :voice_box, :haunting

    validates :number, numericality: { only_integer: true, greater_than: 0 }
    validates :order_book, presence: true

    def initialize(...)
      super
      @pattern = Pattern.new(doll: self)
      validate!
    end

    # The order book gives each part as a word; each becomes its part model.
    def head=(material)
      @head = Head.new(material:, doll: self)
    end

    def eyes=(kind)
      @eyes = Eyes.new(kind:, doll: self)
    end

    def hair=(style)
      @hair = Hair.new(style:, doll: self)
    end

    def limbs=(count)
      @limbs = Limbs.new(count:, doll: self)
    end

    def outfit=(style)
      @outfit = Outfit.new(style:, doll: self)
    end

    def voice=(kind)
      @voice_box = VoiceBox.new(kind:, doll: self)
    end

    def haunted=(answer)
      @haunting = Haunting.new(answer:)
    end

    def parts
      [pattern, head, eyes, hair, limbs, outfit, voice_box]
    end

    def subtotal
      parts.sum(&:minutes)
    end

    def minutes
      haunting.apply(subtotal)
    end

    # Minutes per rule, e.g. Doll 12:
    # {pattern: 10, head: 15, eyes: 2, hair: 8, limbs: 11, outfit: 4, voice_box: 4, subtotal: 54, total: 81}
    def breakdown
      parts.to_h { |part| [part.class.name.demodulize.underscore.to_sym, part.minutes] }
           .merge(subtotal:, total: minutes)
    end
  end
end
