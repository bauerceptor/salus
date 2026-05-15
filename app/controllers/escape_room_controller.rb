class EscapeRoomController < ApplicationController
  skip_before_action :authenticate!, raise: false

  def index; end
end
