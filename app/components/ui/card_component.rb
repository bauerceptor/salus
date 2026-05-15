# frozen_string_literal: true

class Ui::CardComponent < ViewComponent::Base
  def initialize(title: nil, options: {})
    @title = title
    @options = options
    @classes = options[:class] || ""
  end

  def call
    content_tag(:div, class: "card-component #{@classes}") do
      if @title
        concat(content_tag(:div, class: "card-component__header") do
          content_tag(:h3, @title, class: "card-component__title")
        end)
      end
      concat(content_tag(:div, class: "card-component__body") { content })
    end
  end
end
