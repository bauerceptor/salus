require "rails_helper"

RSpec.describe SpecialistReferralClick, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:specialist_request) }
  end

  describe "scopes" do
    let(:specialist_request) { create(:specialist_request) }

    it "returns clicks in clicked_at desc order" do
      create(:specialist_referral_click, specialist_request: specialist_request, clicked_at: 2.days.ago)
      create(:specialist_referral_click, specialist_request: specialist_request, clicked_at: 1.day.ago)
      click3 = create(:specialist_referral_click, specialist_request: specialist_request, clicked_at: Time.current)

      expect(described_class.order(clicked_at: :desc).first).to eq(click3)
    end
  end

  describe "#hash_code" do
    it "returns the specialist request hash code" do
      sr = create(:specialist_request)
      create(:specialist_referral_click, specialist_request: sr)
      click = described_class.last
      expect(click.hash_code).to eq(sr.hash_code)
    end
  end

  describe "creation" do
    it "is created with valid attributes" do
      sr = create(:specialist_request)
      click = described_class.create!(
        specialist_request: sr,
        ip_address: "192.168.1.1",
        user_agent: "Mozilla/5.0",
        clicked_at: Time.current
      )
      expect(click.id).to be_present
      expect(click.clicked_at).to be_present
    end

    it "records the timestamp when created" do
      sr = create(:specialist_request)
      click = described_class.create!(
        specialist_request: sr,
        ip_address: "192.168.1.1",
        user_agent: "Mozilla/5.0"
      )
      expect(click.clicked_at).to be_present
    end
  end

  describe "uniqueness" do
    it "allows multiple clicks for the same specialist request" do
      sr = create(:specialist_request)
      create(:specialist_referral_click, specialist_request: sr)
      expect do
        create(:specialist_referral_click, specialist_request: sr)
      end.not_to raise_error
    end
  end
end
