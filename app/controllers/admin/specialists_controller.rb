class Admin::SpecialistsController < Admin::BaseController
  FIELDS_OF_EXPERTISE = [
    "Allergy", "Angiology", "Audiology", "Balneology", "Surgery",
    "Respiratory diseases", "Internal medicine", "Infectious diseases",
    "Dermatology", "Diabetes", "Endocrinology", "Epidemiology", "Pharmacology",
    "Gastroenterology", "Geriatrics", "Gynecology", "Hematology", "Hypertension",
    "Immunology", "Cardiosurgery", "Cardiology", "Sports medicine", "Microbiology",
    "Nephrology", "Neonatology", "Neurosurgery", "Neurology", "Neuropathology",
    "Ophthalmology", "Oncology", "Orthopedics", "Otorhinolaryngology", "Pathomorphology",
    "Pediatrics", "Perinatology", "Obstetrics", "Psychiatry", "Radiology",
    "Radiotherapy", "Rheumatology", "Toxicology", "Transfusion medicine",
    "Transplantation", "Urology"
  ].freeze

  def index
    specialists = User.joins(:roles).where(roles: { name: "specialist" })

    if params[:search].present?
      specialists = specialists.joins(:account).where(
        "accounts.first_name ILIKE :search OR accounts.last_name ILIKE :search OR users.email ILIKE :search",
        search: "%#{params[:search]}%"
      )
    end

    @pagy, @specialists = pagy(specialists.order(created_at: :desc), items: 20)
  end

  def show
    @specialist = User.find(params[:id])
  end

  def new
    @specialist = User.new
    @specialist.build_account
    @specialist.build_specialist
  end

  def create
    @specialist = User.new(specialist_params)

    unless @specialist.valid?
      render :new, status: :unprocessable_content
      return
    end

    ActiveRecord::Base.transaction do
      @specialist.password = specialist_params[:password] || SecureRandom.hex(8)
      @specialist.password_confirmation = specialist_params[:password_confirmation] || @specialist.password
      @specialist.tos_agreement = true
      @specialist.skip_confirmation!

      @specialist.build_account(account_params) if account_params.present?

      @specialist.build_specialist(specialist_profile_params)
      @specialist.set_specialist_role!
      @specialist.save!
    end

    redirect_to admin_specialist_path(@specialist), notice: "Specialist created successfully."
  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = e.message
    render :new, status: :unprocessable_content
  end

  private

  def specialist_params
    params.expect(user: [:email, :password, :password_confirmation])
  end

  def account_params
    params.expect(user: { account_attributes: [:first_name, :last_name, :username] }).dig(:account_attributes).presence
  end

  def specialist_profile_params
    profile = params.expect(user: { specialist_attributes: [:field_of_expertise, :specialization, :specialization_description] }).dig(:specialist_attributes)
    return {} if profile.blank?

    profile.permit!
  end
end
