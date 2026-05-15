require "rails_helper"

RSpec.describe NoteGroup, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:note_group_associations).dependent(:destroy) }
    it { is_expected.to have_many(:notes).through(:note_group_associations) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end
end
