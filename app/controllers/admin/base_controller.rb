class Admin::BaseController < ApplicationController
  include Auth::AdminCurrent

  before_action :authenticate_admin!
  layout "admin_dashboard"
end
