# frozen_string_literal: true

module Work
  class JobTemplateDecorator < WorkDecorator
    delegate_all

    delegate :name, to: :requester, prefix: true, allow_nil: true

    def edit_action_link_set
      ActionLinkSet.new(
        ActionLink.new(object, :destroy, icon: "trash", path: h.work_job_template_path(object),
                                         method: :delete, confirm: {title: title})
      )
    end

    def hours_formatted
      to_int_if_no_fractional_part(hours)
    end
  end
end
