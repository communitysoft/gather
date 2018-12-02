module FormHelper
  # Gather forms are setup with a nested grid.
  # Outer Grid:
  #   - The form defaults to 9 columns in the outer grid, leaving 3 for e.g.
  #     an image upload widget or info box.
  #   - Setting width: :full makes it 12 columns.
  # Inner Grid:
  #   - The inner grid is for the label and field (together called the "control").
  #   - The inner grid defaults to 3 columns for the label and 9 for the field (layout: :narrow_label).
  #   - The :narrower_label layout is 2/10.
  #   - The :equal_width layout is 6/6.
  #   - Layouts are achieved using CSS in the global/forms/bootstrap.scss file.
  #
  # Other options:
  # - top_error_notification: Whether or not to include the f.error_notification at the top of the form.
  #     Defaults to true.
  def gather_form_for(obj, options = {})
    width = options.delete(:width) || :normal
    name = options.delete(:name) || Array.wrap(obj).last.model_name.name.underscore.dasherize.gsub("/", "--")
    layout = options.delete(:layout) || :narrow_label

    options[:html] ||= {}

    classes = options[:html][:class].present? ? [options[:html][:class]] : []
    classes << "gather-form"
    classes << (layout == :vertical ? "form-vertical" : "form-horizontal") # Used by Bootstrap
    classes << (layout.to_s.tr("_", "-") << "-layout") # Layout
    classes << (width == :full ? "full-width" : "normal-width")
    classes << "#{name}-form" # Object class name

    options[:html][:class] = classes.join(" ")

    # We need to wrap form in a row because it has a col-sm-x class.
    content_tag(:div, class: "row") do
      simple_form_for(obj, options) do |form|
        top_errors = []
        if options[:top_error_notification] != false
          # We include the full error messages for debugging purposes in case the attribute on which
          # they are set is not included in the form. This shouldn't happen but does occasionally
          # and is hard to debug when it does.
          top_errors << form.error_notification(title: obj.errors.full_messages.join(", "))
        end
        top_errors << form.error(:base) if obj.errors[:base].present?
        safe_join(top_errors.push(capture { yield(form) }))
      end
    end
  end

  def form_actions(align: :right, classes: "")
    content_tag(:div, class: "row") do
      content_tag(:div, class: "form-actions col-sm-12 text-#{align} #{classes}") do
        capture { yield }
      end
    end
  end

  # Renders a set of nested fields handled by cocoon. Assumes:
  # - Partial at parentmodels/_childmodel_fields.html.erb
  # - Parent model has accepts_nested_attributes_for :childmodels
  def nested_field_set(f, assoc, options = {})
    wrapper_partial = "shared/nested_fields_wrapper"
    options[:inner_partial] ||= "#{f.object.class.model_name.collection}/#{assoc.to_s.singularize}_fields"
    options[:multiple] = true unless options.has_key?(:multiple)

    wrapper_classes = %w[nested-fields subfields]
    wrapper_classes << "no-inner-labels" if options[:inner_labels] == false
    wrapper_classes << "multiple" if options[:multiple]

    f.input(assoc, options.slice(:required, :label)) do
      content_tag(:div, class: "nested-field-set") do
        f.simple_fields_for(assoc, wrapper: :nested_fields) do |f2|
          render(wrapper_partial, f: f2, options: options, classes: wrapper_classes)
        end <<
          if options[:multiple]
            content_tag(:span, class: "add-link-wrapper") do
              link_to_add_association_with_icon(t("cocoon.add_links.#{assoc}"), f, assoc,
                partial: wrapper_partial,
                render_options: {
                  wrapper: :nested_fields, # Simple form wrapper
                  locals: {options: options, classes: wrapper_classes}
                })
            end
          end
      end
    end
  end

  def link_to_add_association_with_icon(label, *args)
    link_to_add_association(icon_tag("plus") << " " << label, *args)
  end
end
