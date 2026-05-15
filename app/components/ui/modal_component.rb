# frozen_string_literal: true

class Ui::ModalComponent < ViewComponent::Base
  def initialize(id:, title: nil, **options)
    @id = id
    @title = title
    @options = options
  end

  def call
    content_tag(:div, class: "modal modal-bottom sm:modal-middle") do
      concat(content_tag(:div, class: "modal-box bg-base-100") do
        concat(content_tag(:h3, @title, class: "font-bold text-lg mb-4")) if @title
        concat(content)
      end)
      concat(content_tag(:form, "", method: "post", action: "#", class: "modal-action") do
        concat(content_tag(:button, I18n.t("common.close"), type: "button", class: "btn",
                                                            onclick: "document.getElementById('#{@id}').close()"))
      end)
      concat(content_tag(:div, "", class: "modal-backdrop", onclick: "document.getElementById('#{@id}').close()"))
    end
  end
end
