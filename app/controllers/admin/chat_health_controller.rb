class Admin::ChatHealthController < Admin::BaseController
  def index
    @chat_health_service = Admin::ChatHealthService.new
    @specialist_stats = @chat_health_service.health_stats
  end
end
