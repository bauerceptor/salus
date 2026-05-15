class Specialist::RecommendationsController < Specialist::BaseController
  before_action :set_patient, only: %i[new create]
  before_action :set_recommendation, only: %i[edit update destroy]

  def index
    @pagy, @recommendations = pagy(
      current_user.specialist_recommendations
                  .order(created_at: :desc)
                  .includes(:account)
    )
  end

  def new
    @recommendation = SpecialistRecommendation.new
    @recommendation.recommendation_type = params[:type] || "medication"
  end

  def edit; end

  def create
    @recommendation = current_user.specialist_recommendations.build(recommendation_params)
    @recommendation.account_id = @patient.id

    if @recommendation.save
      redirect_to specialist_patient_path(id: @patient.id, locale: I18n.locale),
                  notice: "#{@recommendation.recommendation_type.titleize} recommendation sent."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @recommendation.update(recommendation_params)
      redirect_to specialist_patient_path(id: @recommendation.account.id, locale: I18n.locale), notice: "Recommendation updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @recommendation.destroy
    redirect_to specialist_patient_path(id: @recommendation.account.id, locale: I18n.locale), notice: "Recommendation deleted."
  end

  private

  def set_patient
    @patient = Account.find(params[:patient_id])
  end

  def set_recommendation
    @recommendation = current_user.specialist_recommendations.find(params[:id])
  end

  def recommendation_params
    params.expect(specialist_recommendation: %i[recommendation_type name dosage notes medication_id
                                                treatment_id])
  end
end
