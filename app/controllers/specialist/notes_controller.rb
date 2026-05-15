class Specialist::NotesController < Specialist::BaseController
  before_action :set_patient, only: %i[new create]
  before_action :set_note, only: %i[edit update destroy]

  def new
    @note = SpecialistNote.new
  end

  def edit; end

  def create
    @note = current_user.specialist_notes.build(note_params)
    @note.account_id = @patient.id

    if @note.save
      save_attachments(@note) if params[:attachments]
      redirect_to specialist_patient_path(id: @patient.id, locale: I18n.locale), notice: t(".success")
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @note.update(note_params)
      save_attachments(@note) if params[:attachments]
      redirect_to specialist_patient_path(id: @note.account.id, locale: I18n.locale), notice: t(".update_success")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @note.destroy
    redirect_to specialist_patient_path(id: @note.account.id, locale: I18n.locale), notice: t(".destroy_success")
  end

  private

  def set_patient
    @patient = Account.find(params[:patient_id])
  end

  def set_note
    @note = current_user.specialist_notes.find(params[:id])
  end

  def note_params
    params.expect(specialist_note: %i[content note_type])
  end

  def save_attachments(note)
    return unless params[:attachments]

    params[:attachments].each do |attachment|
      next if attachment.blank?

      file_type = case attachment.content_type
                  when %r{\Aimage/}
                    "image"
                  when %r{\Avideo/}
                    "video"
                  when %r{\Aaudio/}
                    "audio"
                  else
                    "document"
                  end

      note.attachments.create!(
        file_type: file_type,
        file_url: attachment,
        filename: attachment.original_filename
      )
    end
  end
end
