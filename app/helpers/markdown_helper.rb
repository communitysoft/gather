# frozen_string_literal: true

# Markdown is a minimalistic markup syntax
module MarkdownHelper
  def safe_render_markdown(str, extra_allowed_tags: [])
    return "" if str.blank?
    tags = Rails::Html::WhiteListSanitizer.allowed_tags.merge(extra_allowed_tags)
    attributes = Rails::Html::WhiteListSanitizer.allowed_attributes.merge(%w[target])
    renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, space_after_headers: true,
                                                                tables: true)
    sanitize(renderer.render(str), tags: tags, attributes: attributes)
  end
end
