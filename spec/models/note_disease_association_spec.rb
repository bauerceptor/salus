require "rails_helper"

RSpec.describe NoteDiseaseAssociation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:note) }
    it { is_expected.to belong_to(:disease) }
  end
end
