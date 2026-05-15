# frozen_string_literal: true

class Ui::BadgeComponent < ViewComponent::Base
  def initialize(type: :primary, size: :md)
    @type = type.to_s
    @size = size.to_s
  end

  def call
    content_tag(:span, content, class: badge_classes)
  end

  private

  def badge_classes
    size_class = case @size
                 when "sm" then "badge-sm"
                 when "lg" then "badge-lg"
                 else ""
                 end

    type_class = case @type
                 when "success" then "badge-success"
                 when "warning" then "badge-warning"
                 when "error" then "badge-error"
                 when "info" then "badge-info"
                 else "badge-primary"
                 end

    "badge #{type_class} #{size_class}".strip
  end
end
