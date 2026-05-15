RSpec.describe "Routes", type: :routing do
  describe "Treatment Requests" do
    describe "Patient Treatment Requests" do
      it "GET /patient/treatment_requests routes to patient/treatment_requests#index" do
        expect(get: "/patient/treatment_requests")
          .to route_to(controller: "patient/treatment_requests", action: "index")
      end

      it "GET /patient/treatment_requests/new routes to patient/treatment_requests#new" do
        expect(get: "/patient/treatment_requests/new")
          .to route_to(controller: "patient/treatment_requests", action: "new")
      end

      it "POST /patient/treatment_requests routes to patient/treatment_requests#create" do
        expect(post: "/patient/treatment_requests")
          .to route_to(controller: "patient/treatment_requests", action: "create")
      end

      it "GET /patient/treatment_requests/:id routes to patient/treatment_requests#show" do
        expect(get: "/patient/treatment_requests/123")
          .to route_to(controller: "patient/treatment_requests", action: "show", id: "123")
      end

      it "DELETE /patient/treatment_requests/:id routes to patient/treatment_requests#destroy" do
        expect(delete: "/patient/treatment_requests/123")
          .to route_to(controller: "patient/treatment_requests", action: "destroy", id: "123")
      end
    end

    describe "Specialist Treatment Requests" do
      it "GET /specialist/treatment_requests routes to specialist/treatment_requests#index" do
        expect(get: "/specialist/treatment_requests")
          .to route_to(controller: "specialist/treatment_requests", action: "index")
      end

      it "GET /specialist/treatment_requests/:id routes to specialist/treatment_requests#show" do
        expect(get: "/specialist/treatment_requests/123")
          .to route_to(controller: "specialist/treatment_requests", action: "show", id: "123")
      end

      it "PATCH /specialist/treatment_requests/:id routes to specialist/treatment_requests#update" do
        expect(patch: "/specialist/treatment_requests/123")
          .to route_to(controller: "specialist/treatment_requests", action: "update", id: "123")
      end
    end
  end

  describe "Authentication Routes" do
    describe "Auth Sessions" do
      it "GET /auth/sign_in routes to auth/sessions#new" do
        expect(get: "/auth/sign_in")
          .to route_to(controller: "auth/sessions", action: "new")
      end

      it "POST /auth/sign_in routes to auth/sessions#create" do
        expect(post: "/auth/sign_in")
          .to route_to(controller: "auth/sessions", action: "create")
      end

      it "DELETE /auth/sign_out routes to auth/sessions#destroy" do
        expect(delete: "/auth/sign_out")
          .to route_to(controller: "auth/sessions", action: "destroy")
      end
    end

    describe "Auth Registrations" do
      it "GET /auth/sign_up routes to auth/registrations#new" do
        expect(get: "/auth/sign_up")
          .to route_to(controller: "auth/registrations", action: "new")
      end

      it "POST /auth/sign_up routes to auth/registrations#create" do
        expect(post: "/auth/sign_up")
          .to route_to(controller: "auth/registrations", action: "create")
      end
    end

    describe "Auth Passwords" do
      it "GET /auth/password routes to auth/passwords#new" do
        expect(get: "/auth/password")
          .to route_to(controller: "auth/passwords", action: "new")
      end

      it "POST /auth/password routes to auth/passwords#create" do
        expect(post: "/auth/password")
          .to route_to(controller: "auth/passwords", action: "create")
      end

      it "GET /auth/password/edit routes to auth/passwords#edit" do
        expect(get: "/auth/password/edit")
          .to route_to(controller: "auth/passwords", action: "edit")
      end

      it "PUT /auth/password routes to auth/passwords#update" do
        expect(put: "/auth/password")
          .to route_to(controller: "auth/passwords", action: "update")
      end
    end
  end

  describe "Specialist Namespace" do
    it "GET /specialist/sign_in routes to specialist/sessions#new" do
      expect(get: "/specialist/sign_in")
        .to route_to(controller: "specialist/sessions", action: "new")
    end

    it "GET /specialist/dashboard routes to specialist/dashboard#index" do
      expect(get: "/specialist/dashboard")
        .to route_to(controller: "specialist/dashboard", action: "index")
    end

    it "GET /specialist/patients routes to specialist/patients#index" do
      expect(get: "/specialist/patients")
        .to route_to(controller: "specialist/patients", action: "index")
    end

    it "GET /specialist/patients/:id routes to specialist/patients#show" do
      expect(get: "/specialist/patients/123")
        .to route_to(controller: "specialist/patients", action: "show", id: "123")
    end
  end

  describe "Settings Namespace" do
    it "GET /settings/account routes to settings/account#show" do
      expect(get: "/settings/account")
        .to route_to(controller: "settings/account", action: "show")
    end

    it "GET /settings/privacy routes to settings/privacy#show" do
      expect(get: "/settings/privacy")
        .to route_to(controller: "settings/privacy", action: "show")
    end

    it "PATCH /settings/privacy routes to settings/privacy#update" do
      expect(patch: "/settings/privacy")
        .to route_to(controller: "settings/privacy", action: "update")
    end
  end

  describe "Main Resources" do
    it "GET /dashboard routes to my_health#index" do
      expect(get: "/dashboard")
        .to route_to(controller: "my_health", action: "index")
    end

    it "GET /medications routes to medications#index" do
      expect(get: "/medications")
        .to route_to(controller: "medications", action: "index")
    end

    it "GET /treatments routes to treatments#index" do
      expect(get: "/treatments")
        .to route_to(controller: "treatments", action: "index")
    end

    it "GET /measurements routes to measurements#index" do
      expect(get: "/measurements")
        .to route_to(controller: "measurements", action: "index")
    end

    it "GET /diseases routes to diseases#index" do
      expect(get: "/diseases")
        .to route_to(controller: "diseases", action: "index")
    end

    it "GET /notes routes to notes#index" do
      expect(get: "/notes")
        .to route_to(controller: "notes", action: "index")
    end
  end

  describe "FHIR Namespace" do
    it "GET /fhir/export/bundle routes to fhir/export#bundle" do
      expect(get: "/fhir/export/bundle")
        .to route_to(controller: "fhir/export", action: "bundle")
    end

    it "GET /fhir/export/measurements routes to fhir/export#measurements" do
      expect(get: "/fhir/export/measurements")
        .to route_to(controller: "fhir/export", action: "measurements")
    end

    it "GET /fhir/import/new routes to fhir/import#new" do
      expect(get: "/fhir/import/new")
        .to route_to(controller: "fhir/import", action: "new")
    end

    it "POST /fhir/import routes to fhir/import#create" do
      expect(post: "/fhir/import")
        .to route_to(controller: "fhir/import", action: "create")
    end
  end

  describe "AI Agent" do
    it "GET /ai-agent routes to ai_agent#index" do
      expect(get: "/ai-agent")
        .to route_to(controller: "ai_agent", action: "index")
    end

    it "POST /ai-agent/messages routes to ai_agent#create_message" do
      expect(post: "/ai-agent/messages")
        .to route_to(controller: "ai_agent", action: "create_message")
    end

    it "DELETE /ai-agent/conversations/:id routes to ai_agent#destroy_conversation" do
      expect(delete: "/ai-agent/conversations/123")
        .to route_to(controller: "ai_agent", action: "destroy_conversation", id: "123")
    end
  end
end
