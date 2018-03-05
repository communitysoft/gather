module Work
  class Share < ApplicationRecord
    acts_as_tenant :cluster

    belongs_to :period, inverse_of: :shares
    belongs_to :user

    scope :for_community, ->(c) { joins(:period).where("work_periods.community_id": c.id) }
    scope :for_period, ->(p) { joins(:user).where(period_id: p.id, "users.deactivated_at": nil) }

    delegate :community, to: :period
  end
end