# == Schema Information
#
# Table name: poll_options
#
#  id         :uuid             not null, primary key
#  post_id    :uuid             not null
#  option_text :string           not null
#  vote_count :integer          default: 0
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_poll_options_on_post_id (post_id)
#
# Foreign Keys
#
#  fk_rails_...  (post_id => posts.id)
#
FactoryBot.define do
  factory :poll_option do
    sequence(:option_text) { |n| "Option #{n}" }
    vote_count { 0 }
    post
  end
end
