class PagesController < ApplicationController
  def home
    redirect_to my_health_index_path if current_user
  end

  def contact; end
end
