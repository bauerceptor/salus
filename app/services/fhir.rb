# frozen_string_literal: true

module Fhir
  class Error < StandardError; end
  class ValidationError < Fhir::Error; end
  class ExportError < Fhir::Error; end
  class ImportError < Fhir::Error; end

  mattr_accessor :default_code_system do
    "http://loinc.org"
  end

  def self.configure
    yield self if block_given?
  end
end
