class AuthenticatedConstraint
  def matches?(request)
    request.session[:user_id].present?
  end
end

class AdminAuthenticatedConstraint
  def matches?(request)
    request.session[:admin_id].present?
  end
end
