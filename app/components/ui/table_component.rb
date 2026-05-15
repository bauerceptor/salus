# frozen_string_literal: true

class Ui::TableComponent < ViewComponent::Base
  def initialize(columns: [], **options)
    @columns = columns
    @options = options
    @classes = options[:class] || ""
  end

  def call
    content_tag(:div, class: "overflow-x-auto #{@classes}") do
      content_tag(:table, class: "table") do
        concat(table_header) if @columns.any?
        concat(content_tag(:tbody) { content })
      end
    end
  end

  private

  def table_header
    content_tag(:thead) do
      content_tag(:tr) do
        @columns.each do |col|
          concat(content_tag(:th, col[:label] || col[:field].to_s.humanize))
        end
      end
    end
  end
end
