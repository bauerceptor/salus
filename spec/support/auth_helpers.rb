module AuthHelpers
  def sign_in(user)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(user.account)
  end

  def sign_out(user)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
    allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(false)
    allow_any_instance_of(ApplicationController).to receive(:current_account).and_return(nil)
  end

  def sign_in_user(user, account: nil)
    sign_in user
  end

  def sign_in_specialist(specialist_user)
    sign_in specialist_user
  end

  def sign_in_admin(admin_user)
    sign_in admin_user
  end

  def current_account_for(user)
    user.account
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
  config.include AuthHelpers, type: :controller
  config.include AuthHelpers, type: :system
  config.include AuthHelpers, type: :feature
end
