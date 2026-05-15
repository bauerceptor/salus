# == Schema Information
#
# Table name: karma_points
#
#  id         :uuid             not null, primary key
#  account_id :uuid             not null
#  post_id    :uuid             not null
#  reaction_type :string         not null
#  points     :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_karma_points_on_account_id (account_id)
#  index_karma_points_on_post_id    (post_id)
#  index_karma_points_on_account_id_and_post_id (account_id, post_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (post_id => posts.id)
#
FactoryBot.define do
  factory :karma_point do
    account
    post
    reaction_type { "like" }
    points { 1 }
  end
end
