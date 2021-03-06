# frozen_string_literal: true

module Billing
  # Represents a template of a transaction from which transactions can be created.
  class Template < ApplicationRecord
    include Transactable

    acts_as_tenant :cluster

    belongs_to :community, inverse_of: :billing_templates
    has_many :template_member_types, class_name: "Billing::TemplateMemberType",
                                     inverse_of: :template, dependent: :destroy
    has_many :member_types, class_name: "People::MemberType", through: :template_member_types

    scope :in_community, ->(c) { where(community: c) }
    scope :by_description, -> { alpha_order(:description) }

    normalize_attributes :code, :description

    def households
      member_types.map(&:households).flatten.uniq.sort_by(&:name)
    end

    def apply
      households.each do |household|
        account = Billing::AccountManager.instance.account_for(household_id: household.id,
                                                               community_id: community.id)
        Billing::Transaction.create!(account: account,
                                     code: code,
                                     value: value,
                                     description: description,
                                     incurred_on: Time.zone.today)
      end
    end
  end
end
