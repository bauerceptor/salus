namespace :notifications do
  desc "Generate notifications for all accounts"
  task generate: :environment do
    puts "Generating notifications..."
    Account.find_each do |account|
      Notifications::Generator.generate_for_account(account)
    end
    puts "Done!"
  end

  desc "Generate notifications for a specific user email"
  task :for_user, [:email] => :environment do |_t, args|
    email = args[:email]
    user = User.find_by(email: email)

    if user.nil?
      puts "User not found: #{email}"
      exit 1
    end

    puts "Generating notifications for #{user.email}..."
    Notifications::Generator.generate_for_account(user.account)
    puts "Done! User now has #{user.account.notifications.count} notifications."
  end
end
