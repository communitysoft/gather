# frozen_string_literal: true

module Meals
  class CostDecorator < ApplicationDecorator
    delegate_all

    (Signup::SIGNUP_TYPES + %i[ingredient_cost pantry_cost]).each do |attrib|
      define_method("#{attrib}_nice") do
        (num = self[attrib]).blank? ? "?" : h.number_to_currency(num)
      end
    end

    %i[ingredient_cost pantry_cost].each do |attrib|
      define_method("#{attrib}_decimals") do
        (num = self[attrib]).blank? ? nil : h.number_with_precision(num, precision: 2)
      end
    end

    def payment_method_nice
      t("simple_form.options.meal.cost.payment_method.#{payment_method}")
    end
  end
end
