# frozen_string_literal: true

module Calendars
  # A group of calendars.
  class Group < Node
    has_many :calendars, class_name: "Calendars::Calendar", inverse_of: :group, dependent: :nullify

    def photo?
      false
    end

    def group?
      true
    end
  end
end
