# frozen_string_literal: true

class Ui::ButtonComponent < ViewComponent::Base
  def initialize(type: :primary, size: :md, href: nil, disabled: false, **options)
    @type = type.to_s
    @size = size.to_s
    @href = href
    @disabled = disabled
    @options = options
    @classes = options[:class] || ""
  end

  def call
    if @href && !@disabled
      link_to(@href, class: btn_classes, **@options) { content }
    else
      content_tag(:button, class: btn_classes, disabled: @disabled, **@options) { content }
    end
  end

  private

  def btn_classes
    type_class = case @type
                 when "secondary" then "btn-secondary"
                 when "outline" then "btn-outline"
                 when "ghost" then "btn-ghost"
                 when "link" then "btn-link"
                 when "error" then "btn-error"
                 when "success" then "btn-success"
                 else "btn-primary"
                 end

    size_class = case @size
                 when "sm" then "btn-sm"
                 when "lg" then "btn-lg"
                 when "xs" then "btn-xs"
                 else ""
                 end

    "btn #{type_class} #{size_class} #{@classes}".strip
  end
end
