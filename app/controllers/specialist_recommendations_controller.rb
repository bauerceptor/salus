class SpecialistRecommendationsController < BaseController
  before_action :set_recommendation, only: %i[accept reject dismiss]

  def index
    @pagy, @recommendations = pagy(
      current_account.specialist_recommendations
                     .order(created_at: :desc)
    )
  end

  def accept
    @recommendation.accept!
    redirect_to received_recommendations_path, notice: "Recommendation accepted."
  end

  def reject
    @recommendation.reject!
    redirect_to received_recommendations_path, notice: "Recommendation rejected."
  end

  def dismiss
    @recommendation.dismiss!
    redirect_to received_recommendations_path, notice: "Recommendation dismissed."
  end

  private

  def set_recommendation
    @recommendation = current_account.specialist_recommendations.find(params[:id])
  end
end
