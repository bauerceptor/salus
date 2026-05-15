require "rails_helper"

RSpec.describe NotesController, type: :request do
  let(:user) { create(:user) }
  let(:account) { user.account }

  describe "GET #index" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get notes_path
        expect(response).to be_successful
      end

      it "assigns @notes" do
        note = create(:note, account: account)
        get notes_path
        expect(assigns(:notes)).to include(note)
      end

      it "orders notes by pinned first, then by created_at" do
        pinned = create(:note, account: account, is_pinned: true)
        unpinned = create(:note, account: account, is_pinned: false)
        get notes_path
        expect(assigns(:notes_pinned).first).to eq(pinned)
        expect(assigns(:notes).first).to eq(unpinned)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get notes_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "GET #new" do
    context "when authenticated" do
      before { sign_in user }

      it "returns a successful response" do
        get new_note_path
        expect(response).to be_successful
      end

      it "assigns a new note" do
        get new_note_path
        expect(assigns(:note)).to be_a_new(Note)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get new_note_path
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        note: {
          title: "Doctor Appointment",
          content: "Annual checkup scheduled"
        }
      }
    end

    context "when authenticated with valid params" do
      before { sign_in user }

      it "creates a new note" do
        expect do
          post notes_path, params: valid_params
        end.to change(Note, :count).by(1)
      end

      it "redirects to index after creation" do
        post notes_path, params: valid_params
        expect(response).to redirect_to(notes_path)
      end
    end

    context "when authenticated with invalid params" do
      before { sign_in user }

      it "does not create a new note" do
        expect do
          post notes_path, params: { note: { title: "" } }
        end.not_to change(Note, :count)
      end

      it "renders new template with error" do
        post notes_path, params: { note: { title: "" } }
        expect(response).to render_template(:new)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        post notes_path, params: valid_params
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "GET #show" do
    let(:note) { create(:note, account: account) }

    context "when authenticated as owner" do
      before { sign_in user }

      it "returns a successful response" do
        get note_path(id: note.id)
        expect(response).to be_successful
      end

      it "assigns @note" do
        get note_path(id: note.id)
        expect(assigns(:note)).to eq(note)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get note_path(id: note.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "PATCH #update" do
    let(:note) { create(:note, account: account) }
    let(:valid_params) do
      {
        note: {
          content: "Updated content"
        }
      }
    end

    context "when authenticated as owner with valid params" do
      before { sign_in user }

      it "updates the note" do
        patch note_path(id: note.id), params: valid_params
        note.reload
        expect(note.content).to eq("Updated content")
      end

      it "redirects to show after update" do
        patch note_path(id: note.id), params: valid_params
        expect(response).to redirect_to(note_path(note))
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch note_path(id: note.id), params: valid_params
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "PATCH #pin" do
    let(:note) { create(:note, account: account, is_pinned: false) }

    context "when authenticated as owner" do
      before { sign_in user }

      it "pins the note" do
        patch pin_note_path(id: note.id)
        note.reload
        expect(note.is_pinned).to be true
      end

      it "redirects to notes" do
        patch pin_note_path(id: note.id)
        expect(response).to redirect_to(notes_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch pin_note_path(id: note.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "PATCH #unpin" do
    let(:note) { create(:note, account: account, is_pinned: true) }

    context "when authenticated as owner" do
      before { sign_in user }

      it "unpins the note" do
        patch unpin_note_path(id: note.id)
        note.reload
        expect(note.is_pinned).to be false
      end

      it "redirects to notes" do
        patch unpin_note_path(id: note.id)
        expect(response).to redirect_to(notes_path)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        patch unpin_note_path(id: note.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end

  describe "DELETE #destroy" do
    let(:note) { create(:note, account: account) }

    context "when authenticated as owner" do
      before { sign_in user }

      it "destroys the note" do
        delete note_path(id: note.id)
        expect do
          note.reload
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "redirects to index after destruction" do
        delete note_path(id: note.id)
        expect(response).to redirect_to(notes_url)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        delete note_path(id: note.id)
        expect(response).to redirect_to(auth_new_session_path)
      end
    end
  end
end
