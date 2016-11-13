class UserPolicy < ApplicationPolicy

  ######### NOTE #########
  # user == the user doing the action
  # record == the user to which the action is being done

  class Scope < Scope
    def resolve
      active_admin? ? scope : scope.where("users.deactivated_at IS NULL")
    end
  end

  def index?
    active?
  end

  def show?
    active? || self?
  end

  def create?
    active_admin?
  end

  def destroy?
    active_admin? && !record.any_assignments?
  end

  def activate?
    active_admin?
  end

  def deactivate?
    active_admin?
  end

  def invite?
    active_admin?
  end

  def send_invites?
    active_admin?
  end

  def update?
    self? || active_admin?
  end

  def administer?
    active_admin?
  end

  # Basic roles are non-admin roles like biller or photographer
  def add_basic_role?
    administer?
  end

  def cluster_adminify?
    active? && user.has_role?(:cluster_admin)
  end

  def super_adminify?
    active? && user.has_role?(:super_admin)
  end

  def permitted_attributes
    [:email, :first_name, :last_name, :mobile_phone, :home_phone, :work_phone] +
      (active_admin? ? [:role_admin, :role_biller, :google_email, :alternate_id] : []) +
      (active_cluster_admin? ? [:role_cluster_admin] : []) +
      (active_super_admin? ? [:role_super_admin] : [])
  end

  private

  def self?
    record == user
  end
end