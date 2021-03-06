# frozen_string_literal: true

module Meals
  # Calculates meal cost according to the fixed cost model.
  class FixedCostCalculator < CostCalculator
    def type
      :fixed
    end

    # Calculates the maximum the cook can spend on ingredients to stay within the
    # fixed maximum meal cost per person.
    def max_ingredient_cost
      sum_product
    end

    protected

    def base_price_for(type)
      formula.parts_by_type[type]&.share
    end
  end
end
