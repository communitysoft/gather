# frozen_string_literal: true

# For calendars.
module Calendars
  class EventSerializer < ApplicationSerializer
    include Rails.application.routes.url_helpers

    attributes :id, :url, :title, :start, :end, :editable, :class_name, :calendar_allows_overlap, :calendar_id

    def url
      calendars_event_path(object)
    end

    def title
      object.name
    end

    def start
      # We don't include timezone in the format because the calendar doesn't have timezone
      # set either so we want everything to be ambiguously zoned and let the server
      # assume all incoming events are in the community's zone. The only reason we'd need
      # zone is if we someday wanted to mix times from several zones on the calendar but
      # we don't and can't foresee needing to.
      object.starts_at.to_s
    end

    # end is a reserved word
    define_method("end") do
      object.ends_at.to_s
    end

    def editable
      # scope == current_user
      Calendars::EventPolicy.new(scope, object).edit?
    end

    def class_name
      if object.meal
        "has-meal"
      elsif object.creator == scope
        "own-event"
      else
        ""
      end
    end

    def calendar_allows_overlap
      object.calendar_allows_overlap?
    end
  end
end
