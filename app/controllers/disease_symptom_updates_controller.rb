class DiseaseSymptomUpdatesController < BaseController
  include DiseaseSettable

  before_action :set_disease_symptom
  before_action :set_disease_symptom_update, only: %i[destroy]

  def index
    load_disease_symptom_updates
  end

  def new
    @disease_symptom_update = DiseaseSymptomUpdate.new
  end

  def create
    @disease_symptom_update = @disease_symptom.updates.build(disease_symptom_update_params)

    respond_to do |format|
      if @disease_symptom_update.save
        format.turbo_stream { load_disease_symptom_updates }
        format.html do
          redirect_to disease_symptom_update_path(
            disease_id: @disease.id,
            symptom_id: @disease_symptom.id,
            id: @disease_symptom_update.id,
            locale: I18n.locale
          ), notice: t(".success")
        end
      else
        format.html { render :new, status: :unprocessable_content }
      end
    end
  end

  def destroy
    @disease_symptom_update.destroy

    respond_to do |format|
      format.turbo_stream { load_disease_symptom_updates }
      format.html do
        redirect_to disease_symptom_updates_path(disease_id: @disease.id, symptom_id: @disease_symptom.id, locale: I18n.locale),
                    notice: t(".success")
      end
    end
  end

  private

  def set_disease_symptom
    @disease_symptom = @disease.symptoms.find(params[:symptom_id])
  end

  def set_disease_symptom_update
    @disease_symptom_update = @disease_symptom.updates.find(params[:id])
  end

  def load_disease_symptom_updates
    @pagy, @disease_symptom_updates = pagy(
      @disease_symptom.updates.all
    )
  end

  def disease_symptom_update_params
    params.expect(disease_symptom_update: %i[intensity update_date])
  end
end
