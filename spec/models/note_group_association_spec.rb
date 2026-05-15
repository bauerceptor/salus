require "rails_helper"

RSpec.describe NoteGroupAssociation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:note) }
    it { is_expected.to belong_to(:note_group) }
  end
end
