# == Schema Information
#
# Table name: disease_photos
#
#  id         :uuid             not null, primary key
#  caption    :string           default(""), not null
#  image_data :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  disease_id :uuid             not null
#
# Indexes
#
#  index_disease_photos_on_disease_id  (disease_id)
#
# Foreign Keys
#
#  fk_rails_...  (disease_id => diseases.id)
#
require "rails_helper"

RSpec.describe DiseasePhoto, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:disease) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:image) }
    it { is_expected.to validate_length_of(:caption).is_at_most(50) }
  end

  describe "Shrine attachment" do
    let(:disease) { create(:disease) }
    let(:photo_path) { Rails.root.join("spec", "assets", "photo1.jpg") }

    it "creates a photo with an attached image" do
      photo = described_class.new(
        disease: disease,
        image: Rack::Test::UploadedFile.new(photo_path, "image/jpeg"),
        caption: "Test caption"
      )
      expect(photo.save).to be true
      expect(photo.image_data).to be_present
    end

    it "stores image data in the image_data column" do
      photo = create(:disease_photo, disease: disease)
      expect(photo.image_data).to be_a(String)
      expect(photo.image_data).not_to be_empty
    end

    it "retrieves the attached image URL" do
      photo = create(:disease_photo, disease: disease)
      expect(photo.image_url).to be_a(String)
      expect(photo.image_url).not_to be_empty
    end

    it "validates presence of image" do
      photo = build(:disease_photo, disease: disease, image: nil)
      expect(photo).not_to be_valid
      expect(photo.errors[:image]).to include("can't be blank")
    end

    it "allows blank caption" do
      photo = create(:disease_photo, disease: disease, caption: "")
      expect(photo).to be_valid
    end

    it "rejects caption exceeding 50 characters" do
      photo = build(:disease_photo, disease: disease, caption: "a" * 51)
      expect(photo).not_to be_valid
      expect(photo.errors[:caption]).to include("is too long (maximum is 50 characters)")
    end

    it "destroys photos when disease is destroyed" do
      photo = create(:disease_photo, disease: disease)
      photo_id = photo.id
      disease.destroy
      expect(described_class.where(id: photo_id)).not_to exist
    end
  end
end
