Rails.logger.debug "Seeding random users ..."

100.times do |i|
  first_name = Faker::Name.first_name
  last_name = Faker::Name.last_name
  username = "#{first_name}#{last_name}#{i}".downcase

  user = User.new(
    email: "#{first_name}.#{last_name}#{i}@gmail.com",
    password: "password",
    password_confirmation: "password",
    tos_agreement: true
  )
  user.save!

  account = user.build_account(
    first_name:,
    last_name:,
    username:,
    email: "#{username}@example.com",
    is_hidden: [true, false].sample
  )

  predefined_disease_ids = []

  def get_random_unused_predefined_disease(used_ids)
    unused_diseases = PredefinedDisease.where.not(id: used_ids)
    unused_diseases.sample
  end

  5.times do
    predefined_disease = get_random_unused_predefined_disease(predefined_disease_ids)
    next unless predefined_disease

    Disease.find_or_create_by!(
      account:,
      predefined_disease:
    ) do |d|
      d.name = predefined_disease.name.titleize
      d.diagnosed_at = Date.new(2023, 5, 15)
      d.diagnosed_by_hp = false
      d.severity = rand(1..5)
      d.color = "#FF0000"
    end

    group = Group.find_or_create_by(predefined_disease:) do |g|
      g.name = "#{predefined_disease.name.titleize} Support Group"
      g.description = "Community for people with #{predefined_disease.name.titleize}"
      g.category = :general
    end
    GroupMember.find_or_create_by(group: group, account: account)

    predefined_disease_ids.push(predefined_disease.id)
  end
end

Rails.logger.debug "Seeding random users completed."
