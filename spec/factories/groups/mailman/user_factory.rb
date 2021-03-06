# frozen_string_literal: true

FactoryBot.define do
  factory :group_mailman_user, class: "Groups::Mailman::User" do
    user
    sequence(:remote_id) { |i| "abcd#{i}" }
  end
end
