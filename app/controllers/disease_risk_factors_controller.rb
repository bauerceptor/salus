class DiseaseRiskFactorsController < BaseController
  include DiseaseSettable

  before_action :set_disease_risk_factor, only: %i[show edit update destroy]
  before_action :set_breadcrumbs

  def index
    @pagy, @disease_risk_factors = pagy(
      @disease.risk_factors.order(severity: :desc)
    )
  end

  def new
    @disease_risk_factor = DiseaseRiskFactor.new
  end

  def create
    @disease_risk_factor = @disease.risk_factors.build(disease_risk_factor_params)

    respond_to do |format|
      if @disease_risk_factor.save
        format.html do
          redirect_to disease_risk_factors_path, notice: t(".success")
        end
      else
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  def update
    respond_to do |format|
      if @disease_risk_factor.update(disease_risk_factor_params)
        format.html do
          redirect_to disease_risk_factor_path(disease_id: @disease.id, id: @disease_risk_factor.id, locale: I18n.locale),
                      notice: t(".success")
        end
      else
        format.html { render :edit, status: :unprocessable_content }
      end
    end
  end

  def destroy
    @disease_risk_factor.destroy

    respond_to do |format|
      format.html do
        redirect_to disease_risk_factors_path, notice: t(".success")
      end
    end
  end

  private

  def set_disease_risk_factor
    @disease_risk_factor = @disease.risk_factors.find(params[:id])
  end

  def disease_risk_factor_params
    params.expect(disease_risk_factor: %i[name description severity])
  end

  def set_breadcrumbs
    add_breadcrumb t("diseases.breadcrumbs.home"), authenticated_root_path
    add_breadcrumb t("diseases.breadcrumbs.index"), diseases_path
    add_breadcrumb @disease.predefined_disease.name, disease_path(id: @disease.id, locale: I18n.locale)
    add_breadcrumb t(".breadcrumbs.index"), disease_risk_factors_path(disease_id: @disease.id, locale: I18n.locale)

    case action_name.to_sym
    when :new, :create
      add_breadcrumb t(".breadcrumbs.new"), new_disease_risk_factor_path(disease_id: @disease.id, locale: I18n.locale)
    when :show
      add_breadcrumb @disease_risk_factor.name,
                     disease_risk_factor_path(disease_id: @disease.id, id: @disease_risk_factor.id, locale: I18n.locale)
    when :edit, :update
      add_breadcrumb @disease_risk_factor.name,
                     disease_risk_factor_path(disease_id: @disease.id, id: @disease_risk_factor.id, locale: I18n.locale)
      add_breadcrumb t(".breadcrumbs.edit"),
                     edit_disease_risk_factor_path(disease_id: @disease.id, id: @disease_risk_factor.id,
                                                   locale: I18n.locale)
    end
  end
end
