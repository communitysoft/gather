module Reservation
  class ReservationPolicy < ApplicationPolicy
    alias_method :reservation, :record

    delegate :rule_set, :has_meal?, to: :reservation

    def index?
      # If record is a Class (not a specific reservation), can't check protocol
      active? && (reservation.is_a?(Class) || !forbidden_by_protocol?)
    end

    def show?
      active? && !forbidden_by_protocol?
    end

    def create?
      active? && !forbidden_by_protocol? && !read_only_by_protocol? && !has_meal?
    end

    def update?
      (active_reserver? || admin?) && !has_meal?
    end

    def destroy?
      (active_reserver? && (future? || recently_created?) || admin?) && !has_meal?
    end

    def permitted_attributes
      %i(name kind reserver_id resource_id sponsor_id starts_at ends_at guidelines_ok)
    end

    private

    delegate :future?, :recently_created?, to: :reservation

    def active_reserver?
      active? && reservation.reserver == user
    end

    def forbidden_by_protocol?
      rule_set.access_level == "forbidden"
    end

    def read_only_by_protocol?
      rule_set.access_level == "read_only"
    end
  end
end
