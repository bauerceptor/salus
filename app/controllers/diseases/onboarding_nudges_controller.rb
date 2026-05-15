class Diseases::OnboardingNudgesController < BaseController
  def destroy
    disease = current_account.diseases.find(params[:disease_id])
    service = DiseaseOnboardingService.new(disease, current_account)
    service.dismiss!

    redirect_to disease_url(id: disease.id, locale: I18n.locale)
  end
end
