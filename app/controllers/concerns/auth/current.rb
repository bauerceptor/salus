module Auth
  module Current
    extend ActiveSupport::Concern

    included do
      helper_method :current_user, :user_signed_in?
    end

    private

    def current_user
      @current_user ||= if session[:user_id]
                          User.find_by(id: session[:user_id])
                        elsif cookies.encrypted[:user_id]
                          User.find_by(id: cookies.encrypted[:user_id])
                        end
    end

    def user_signed_in?
      current_user.present?
    end

    def authenticate_user!
      redirect_to auth_new_session_path unless user_signed_in?
    end

    def log_in(user)
      session[:user_id] = user.id
      cookies.encrypted[:user_id] = {
        value: user.id,
        expires: 2.weeks.from_now,
        httponly: true,
        secure: Rails.env.production?
      }
    end

    def log_out
      session.delete(:user_id)
      cookies.delete(:user_id)
      @current_user = nil
    end
  end
end
