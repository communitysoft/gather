# frozen_string_literal: true

module People
  # Decorates User for CSV export
  class UserCsvDecorator < ::UserDecorator
    include CsvDecorable

    delegate :unit_num, :unit_suffix, :garage_nums, :keyholders, to: :household

    def birthdate
      object.birthday&.date&.to_s(object.birthday&.full? ? :iso8601 : :iso8601_month_day)
    end

    def guardian_names
      return nil if guardians.none?
      guardians.active.decorate.map(&:full_name).sort.join(", ")
    end

    def joined_on
      csv_localize(object.joined_on)
    end

    def child
      csv_bool(object.child?)
    end

    def vehicles
      adult? && household.vehicles.any? ? household.vehicles.map(&:to_s).sort.join("; ") : nil
    end

    def emergency_contacts
      return nil if household.emergency_contacts.none?
      chunks = household.emergency_contacts.map do |contact|
        ["#{contact.name} (#{contact.relationship})", contact.location, contact.phone(:main).formatted,
         contact.phone(:alt).formatted, contact.email].compact.join(", ")
      end
      chunks.sort.join("; ")
    end

    def pets
      return nil if household.pets.none?
      chunks = household.pets.map do |pet|
        "#{pet.name} (#{pet.color} #{pet.species})"
      end
      chunks.sort.join("; ")
    end
  end
end
