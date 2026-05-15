class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  before_create :generate_uuid

  def update_with_context(new_attributes, context)
    with_transaction_returning_status do
      assign_attributes(new_attributes)
      save(context:)
    end
  end

  private

  def generate_uuid
    self.id ||= SecureRandom.uuid
  end
end
