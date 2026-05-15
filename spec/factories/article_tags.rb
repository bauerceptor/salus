FactoryBot.define do
  factory :article_tag do
    article
    tag factory: :note_tag
  end
end
