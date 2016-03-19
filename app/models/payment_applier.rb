# Applies payments to accounts.
class PaymentApplier
  attr_accessor :data

  # Takes a hash of form { "123" => "11.99", "456" => "22.40"},
  # where keys are account IDs and values are amounts.
  def initialize(data)
    self.data = data
  end

  def apply!
    data.each do |account_id, amount|
      next if amount.to_f <= 0
      Transaction.create!(
        account_id: account_id,
        code: "payment",
        description: "Payment - Thank You!",
        incurred_on: Date.today,
        amount: -amount.to_f.round(2)
      )
    end
  end
end
