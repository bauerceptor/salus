class GenerateNotificationsJob < ApplicationJob
  queue_as :default

  def perform
    Account.find_each do |account|
      Notifications::Generator.generate_for_account(account)
    end
  end
end
