# == Schema Information
#
# Table name: posts
#
#  id            :uuid             not null, primary key
#  body          :string           default(""), not null
#  post_type     :integer          default: 0, not null
#  metadata      :jsonb            default: {}
#  account_id    :uuid             not null
#  group_id      :uuid             not null
#  quoted_post_id :uuid
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_posts_on_account_id     (account_id)
#  index_posts_on_group_id       (group_id)
#  index_posts_on_post_type      (post_type)
#  index_posts_on_quoted_post_id (quoted_post_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (group_id => groups.id)
#  fk_rails_...  (quoted_post_id => posts.id)
#
FactoryBot.define do
  factory :post do
    body { Faker::Lorem.sentence }
    post_type { :text }
    metadata { {} }
    group
    account

    trait :link do
      post_type { :link }
      metadata { { "link_url" => "https://example.com/article" } }
    end

    trait :image do
      post_type { :image }
      metadata { { "image_data" => "shrine_data" } }
    end

    trait :poll do
      post_type { :poll }
    end

    trait :quote do
      post_type { :quote }
    end
  end
end
