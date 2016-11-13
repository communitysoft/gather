class ApplicationPolicy
  class CommunityNotSetError < StandardError; end

  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "must be logged in" unless user.present?
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    scope.where(:id => record.id).exists?
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end

    def active_admin?
      user.active? && %i(admin cluster_admin super_admin).any? { |r| user.has_role?(r) }
    end

    def active_biller?
      user.active? && user.has_role?(:biller)
    end

    def active_admin_or_biller?
      active_admin? || active_biller?
    end
  end

  protected

  delegate :active?, to: :user

  def active_admin?
    active? && user.has_role?(:admin) && own_community_record? ||
      active_cluster_admin? || active_super_admin?
  end

  def active_cluster_admin?
    active? && user.has_role?(:cluster_admin) && own_cluster_record? || active_super_admin?
  end

  def active_super_admin?
    active? && user.has_role?(:super_admin)
  end

  def active_biller?
    active? && user.has_role?(:biller) && own_community_record?
  end

  def active_admin_or_biller?
    active_admin? || active_biller?
  end

  def own_community_record?
    return true if not_specific_record?
    ensure_community
    record.community == user.community
  end

  def own_cluster_record?
    return true if not_specific_record?
    ensure_community
    record.community.cluster == user.community.cluster
  end

  def ensure_community
    if record.community.nil?
      raise CommunityNotSetError.new("community must be set on record when checking admin role")
    end
  end

  def not_specific_record?
    record.is_a?(Class)
  end
end
