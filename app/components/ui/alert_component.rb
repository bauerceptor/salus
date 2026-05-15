# frozen_string_literal: true

class Ui::AlertComponent < ViewComponent::Base
  def initialize(type: :info, dismissible: true)
    @type = type.to_sym
    @dismissible = dismissible
  end

  def call
    content_tag(:div, class: "alert alert-#{@type} shadow-lg", role: "alert") do
      concat(content_tag(:div) do
        concat(content_tag(:span, content))
      end)
      if @dismissible
        concat(content_tag(:button, class: "btn btn-ghost btn-xs", onclick: "this.parentElement.remove()") do
          concat(content_tag(:i, "", class: "ri-close-line"))
        end)
      end
    end
  end
end
