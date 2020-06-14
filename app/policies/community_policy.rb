# frozen_string_literal: true

class CommunityPolicy < ApplicationPolicy
  def index?
    active_super_admin?
  end

  def show?
    record_tied_to_user_cluster? || active_super_admin?
  end

  def update?
    active_admin?
  end
end
