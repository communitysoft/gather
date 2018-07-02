# frozen_string_literal: true

module People
  class VehiclePolicy < ApplicationPolicy
    alias vehicle record

    class Scope < Scope
      def resolve
        active_cluster_admin? ? scope : scope.for_community(user.community).active
      end
    end

    def index?
      active_in_community?
    end

    # There is no show action, or any others.
    def show?
      false
    end
  end
end
