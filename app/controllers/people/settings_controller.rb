# frozen_string_literal: true

module People
  class SettingsController < ::SettingsController
    before_action -> { nav_context(:people, :settings, :general) }

    protected

    def sub_settings
      current_community.settings.people
    end

    def edit_path
      edit_people_settings_path
    end
  end
end
