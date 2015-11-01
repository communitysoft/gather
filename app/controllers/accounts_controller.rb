class AccountsController < ApplicationController
  skip_load_resource only: :index
  load_and_authorize_resource

  def index
    @households = Household.joins(:account).includes(account: :last_invoice).
      in_community(current_user.community).
      where("deactivated_at IS NULL OR
        COALESCE(accounts.due_last_invoice,0) - total_new_credits + total_new_charges > 0.01").
      by_name.page(params[:page]).per(20)

    @grand_total_due = Household.joins(:account).in_community(current_user.community).
      sum("current_balance")
    @nonzero_accounts = Household.joins(:account).in_community(current_user.community).
      where("current_balance >= 0.01").count
  end

  def show
  end
end
