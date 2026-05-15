Rails.application.routes.draw do
  get "/join/specialist/:hash", to: "public/join#specialist", as: :join_specialist
  post "/join/specialist/:hash", to: "public/join#create", as: :join_specialist_create

  namespace :admin do
    get "/sign_in", to: "sessions#new", as: :new_session
    post "/sign_in", to: "sessions#create", as: :session
    delete "/sign_out", to: "sessions#destroy", as: :destroy_session
    get "/dashboard", to: "dashboard#index", as: :dashboard

    resources :specialists, only: %i[index show new create]
    resources :assignments, only: %i[index create update] do
      collection do
        patch :bulk_reassign
      end
      member do
        patch :reassign
      end
    end
    get "/chat_health", to: "chat_health#index", as: :chat_health
    get "/referrals", to: "referrals#index", as: :referrals
  end

  get "/dashboard", to: "my_health#index", as: :authenticated_root
  get "/feed", to: "feeds#show", as: :feed

  get "/reports/patient_profile", to: "reports#patient_profile", as: :patient_profile_report

  namespace :fhir do
    get "/export/bundle", to: "export#bundle"
    get "/export/measurements", to: "export#measurements"
    get "/export/diseases", to: "export#diseases"
    get "/export/medications", to: "export#medications"
    get "/export/treatments", to: "export#treatments"
    post "/import", to: "import#create"
    get "/import/new", to: "import#new"
    post "/import/document", to: "import#import_document"
  end

  mount Avo::Engine, at: "/internal-panel"

  namespace :admin do
    resources :specialist_requests do
      member do
        post :approve
        post :reject
      end
    end
  end

  namespace :auth do
    get "/sign_in", to: "sessions#new", as: :new_session
    post "/sign_in", to: "sessions#create", as: :session
    delete "/sign_out", to: "sessions#destroy", as: :destroy_session

    get "/sign_up", to: "registrations#new", as: :new_registration
    post "/sign_up", to: "registrations#create", as: :registration

    get "/password", to: "passwords#new", as: :new_password
    post "/password", to: "passwords#create", as: :password
    get "/password/edit", to: "passwords#edit", as: :edit_password
    put "/password", to: "passwords#update", as: :update_password
  end

  scope "(:locale)", locale: /en/ do
    root to: "pages#home"

    get "/contact", to: "pages#contact", as: :contact
    get "/setup_account" => "setup_account#new"
    post "/setup_account" => "setup_account#create"

    resources :my_health, only: [:index]

    resources :medications do
      scope module: :medications do
        resources :medication_schedules, only: %i[index new create destroy]
      end
    end

    resources :notifications, only: %i[index show update destroy] do
      collection do
        post :mark_all_read
      end
    end

    resources :caregivers do
      collection do
        get :pending
        get :requests_received
        patch :accept_request
        delete :reject_request
      end
      member do
        patch :accept
        delete :reject
      end
    end

    resources :notes do
      resources :note_tag_associations, only: %i[index new create destroy]
      member do
        patch :pin
        patch :unpin
      end
    end
    resources :note_tags, except: %i[index show]

    resources :measurements, only: %i[index show edit update destroy] do
      collection do
        get "all/:measurement_type", to: "measurements#all", as: :all
        get "details/:day", to: "measurements#details", as: :details
        get "new/:measurement_type", to: "measurements#new", as: :new
        post "create/:measurement_type", to: "measurements#create", as: :create
        get "day/:day", to: "measurements#show_by_day", as: :show_by_day
      end
    end

    resources :measurement_raports, only: %i[index show destroy] do
      collection do
        post :generate_for_day
      end
    end

    resources :articles

    resources :diseases do
      resources :disease_symptoms, as: :symptoms do
        resources :disease_symptom_updates, as: :updates, except: %i[edit update]
      end
      resources :disease_risk_factors, as: :risk_factors
      resources :disease_treatments, as: :treatments, only: %i[index]
      resources :disease_photos, as: :photos, only: %i[index new create destroy]
      resources :disease_statuses, as: :statuses, path: :statuses do
        resources :disease_status_comments, as: :comments
        resources :disease_status_reactions, as: :reactions, only: %i[index] do
          collection do
            post :like
            delete :unlike
          end
        end
      end
    end

    delete "diseases/:disease_id/onboarding_nudge" => "diseases/onboarding_nudges#destroy",
           as: :disease_onboarding_nudge

    resources :treatments do
      resources :treatment_updates
      resources :treatment_diseases, only: %i[index new create destroy]
    end

    resources :accounts, only: %i[index show] do
      resources :friends, only: %i[index destroy]
      resources :posts
    end

    resources :friend_requests

    resources :groups, only: %i[index] do
      member do
        post :join_group, as: :join
        delete :leave_group, as: :leave
      end

      scope module: :groups do
        resources :disease_symptoms
        resources :disease_statuses
        resources :disease_photos
        resources :treatments
        resources :disease_risk_factors
        resources :posts do
          resources :post_comments, as: :comments, only: %i[index create]
          resources :post_reactions, as: :reactions, only: %i[index] do
            collection do
              post :like
              delete :unlike
            end
          end
        end
      end
    end

    resources :specialists, only: %i[index]
    resources :specialist_requests

    # Specialist routes (for doctors)
    namespace :specialist do
      get "/sign_in", to: "sessions#new", as: :new_session
      post "/sign_in", to: "sessions#create", as: :session
      delete "/sign_out", to: "sessions#destroy", as: :destroy_session
      get "/dashboard", to: "dashboard#index", as: :dashboard
      get "/profile", to: "profiles#show", as: :profile
      get "/profile/edit", to: "profiles#edit", as: :edit_profile
      patch "/profile", to: "profiles#update", as: nil
      resources :patients, only: %i[index show update] do
        collection do
          get :search
        end
        member do
          get :export_fhir
          post :import_fhir
          post :import_document
          get :report
          get :clinical_history
        end
      end
      resources :notes, only: %i[new create edit update destroy]
      resources :recommendations, only: %i[index new edit update destroy]
      post "recommendations/create", to: "recommendations#create", as: :create_recommendation
      resources :messages, only: %i[index new show create destroy]
      resources :notifications, only: %i[index update] do
        resource :acknowledgment, only: :create, module: :notifications
      end
      resources :medication_requests, only: %i[index update]
      resources :schedules, only: %i[index new create edit update destroy]
    end

    # Patient routes for specialist interactions
    resources :specialist_messages, only: %i[index show create destroy], as: :patient_messages
    resources :specialist_recommendations, only: %i[index show update], as: :received_recommendations,
                                           path: "/my-recommendations" do
      member do
        patch :accept
        patch :reject
        patch :dismiss
      end
    end

    # Patient requests to link with specialist
    post "/request-care", to: "specialist_patients#create", as: :request_care

    # Patient appointment requests
    post "/appointment-request", to: "specialist_patients#request_appointment", as: :appointment_request

    # Chat
    resources :chatrooms, only: %i[index show create] do
      resources :chatroom_messages, only: %i[create]
    end

    # AI Agent
    get "/ai-agent", to: "ai_agent#index", as: :ai_agent
    post "/ai-agent/messages", to: "ai_agent#create_message", as: :ai_agent_messages
    post "/ai-agent/speech", to: "ai_agent#generate_speech", as: :ai_agent_speech
    post "/ai-agent/transcribe", to: "ai_agent#transcribe", as: :ai_agent_transcribe
    post "/ai-agent/conversations", to: "ai_agent#new_conversation", as: :ai_agent_new_conversation
    delete "/ai-agent/conversations/:id", to: "ai_agent#destroy_conversation", as: :ai_agent_destroy_conversation

    get "/help", to: "help#index", as: :help

    namespace :settings do
      get "/settings", to: redirect("/settings/account")

      resource :account, only: %i[show update], controller: :account do
        delete :delete_profile_picture
      end

      resource :security, only: %i[show], controller: :security

      resource :privacy, only: %i[show update], controller: :privacy
    end

    namespace :patient do
      resources :treatment_requests, only: %i[index new create show destroy]
      resources :documents, only: %i[index show]
    end

    namespace :specialist do
      resources :treatment_requests, only: %i[index show update]
    end

    namespace :health_agent do
      resources :chat, only: %i[index create]
      get "patient_status/:patient_id", to: "patient_status#show", as: :patient_status
    end

    resources :clinical_history, only: %i[show]
    resources :clinical_documents, only: %i[index show create destroy]
  end

  mount ActionCable.server => '/cable'
end
