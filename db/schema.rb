# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_28_160918) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "vector"

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "address"
    t.text "background_data"
    t.string "background_position", default: "center"
    t.integer "badge", default: 0, null: false
    t.text "bio", default: ""
    t.date "birthday"
    t.string "city", limit: 100
    t.string "country", limit: 100
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.string "education", limit: 50, default: ""
    t.string "email", limit: 255
    t.datetime "email_verified_at"
    t.string "first_name", limit: 100
    t.string "gender", limit: 20
    t.text "image_data"
    t.boolean "is_hidden", default: false
    t.boolean "is_verified", default: false
    t.integer "karma_score", default: 0, null: false
    t.datetime "last_login_at"
    t.string "last_name", limit: 100
    t.datetime "last_risk_assessment"
    t.datetime "last_seen_at"
    t.integer "online_status", default: 0
    t.string "password_digest", limit: 255
    t.string "phone_number", limit: 20
    t.json "preferences", default: {}
    t.integer "risk_score", default: 0
    t.string "role", limit: 50, default: "user"
    t.jsonb "settings", default: {}
    t.string "sex", limit: 20, default: ""
    t.uuid "typing_in_chatroom_id"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.string "username", limit: 50
    t.index ["badge"], name: "index_accounts_on_badge"
    t.index ["email"], name: "index_accounts_on_email", unique: true
    t.index ["karma_score"], name: "index_accounts_on_karma_score"
  end

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admins", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", limit: 255, null: false
    t.string "password_digest", limit: 255
    t.string "role", limit: 50, default: "admin"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
  end

  create_table "ai_agent_conversations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.string "title", limit: 255, default: "New Chat"
    t.datetime "updated_at", null: false
    t.index ["account_id", "updated_at"], name: "index_ai_agent_conversations_on_account_id_and_updated_at"
    t.index ["account_id"], name: "index_ai_agent_conversations_on_account_id"
  end

  create_table "ai_agent_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.json "attachments", default: {}
    t.text "content", null: false
    t.uuid "conversation_id", null: false
    t.datetime "created_at", null: false
    t.string "role", limit: 50, null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "created_at"], name: "index_ai_agent_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_ai_agent_messages_on_conversation_id"
  end

  create_table "article_tags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", default: "", null: false
    t.datetime "updated_at", null: false
  end

  create_table "article_tags_articles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "article_id", null: false
    t.uuid "article_tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id", "article_tag_id"], name: "index_article_tags_articles_on_article_id_and_article_tag_id", unique: true
    t.index ["article_id"], name: "index_article_tags_articles_on_article_id"
    t.index ["article_tag_id"], name: "index_article_tags_articles_on_article_tag_id"
  end

  create_table "articles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.text "description", default: ""
    t.string "status", limit: 50, default: "draft"
    t.string "title", limit: 255
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_articles_on_account_id"
  end

  create_table "behavior_sequences", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.integer "adherence_score", default: 100
    t.datetime "analyzed_at"
    t.datetime "created_at", null: false
    t.json "events", default: []
    t.json "metadata", default: {}
    t.string "sequence_type", limit: 50, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "adherence_score"], name: "index_behavior_sequences_on_account_id_and_adherence_score"
    t.index ["account_id", "sequence_type"], name: "index_behavior_sequences_on_account_id_and_sequence_type"
    t.index ["account_id"], name: "index_behavior_sequences_on_account_id"
  end

  create_table "caregivers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.boolean "can_view_diseases", default: true, null: false
    t.boolean "can_view_measurements", default: true, null: false
    t.boolean "can_view_medications", default: true, null: false
    t.uuid "caregiver_account_id"
    t.datetime "created_at", null: false
    t.boolean "is_accepted", default: false, null: false
    t.boolean "notify_on_abnormal_measurement", default: false, null: false
    t.boolean "notify_on_low_adherence", default: true, null: false
    t.boolean "notify_on_missed_dose", default: true, null: false
    t.string "relationship", limit: 50, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "is_accepted"], name: "index_caregivers_on_account_id_and_is_accepted"
    t.index ["account_id"], name: "index_caregivers_on_account_id"
    t.index ["caregiver_account_id", "is_accepted"], name: "index_caregivers_on_caregiver_account_id_and_is_accepted"
    t.index ["caregiver_account_id"], name: "index_caregivers_on_caregiver_account_id"
  end

  create_table "chatroom_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.text "body"
    t.uuid "chatroom_id", null: false
    t.datetime "created_at", null: false
    t.integer "message_type", default: 0
    t.json "reactions", default: {}
    t.datetime "read_at"
    t.bigint "reply_to_message_id"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_chatroom_messages_on_account_id"
    t.index ["chatroom_id"], name: "index_chatroom_messages_on_chatroom_id"
    t.index ["message_type"], name: "index_chatroom_messages_on_message_type"
    t.index ["read_at"], name: "index_chatroom_messages_on_read_at"
  end

  create_table "chatroom_participants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "chatroom_id", null: false
    t.datetime "created_at", null: false
    t.datetime "last_read_at"
    t.datetime "updated_at", null: false
    t.index ["account_id", "chatroom_id"], name: "index_chatroom_participants_on_account_id_and_chatroom_id", unique: true
    t.index ["account_id"], name: "index_chatroom_participants_on_account_id"
    t.index ["chatroom_id"], name: "index_chatroom_participants_on_chatroom_id"
  end

  create_table "chatrooms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account1_id", null: false
    t.uuid "account2_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account1_id", "account2_id"], name: "index_chatrooms_on_account1_id_and_account2_id", unique: true
    t.index ["account1_id"], name: "index_chatrooms_on_account1_id"
    t.index ["account2_id"], name: "index_chatrooms_on_account2_id"
  end

  create_table "clinical_documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.boolean "ai_processed", default: false
    t.datetime "created_at", null: false
    t.string "document_type", null: false
    t.jsonb "file_data", default: {}
    t.text "parsed_content"
    t.datetime "updated_at", null: false
    t.uuid "uploaded_by_id", null: false
    t.index ["account_id"], name: "index_clinical_documents_on_account_id"
    t.index ["ai_processed"], name: "index_clinical_documents_on_ai_processed"
    t.index ["document_type"], name: "index_clinical_documents_on_document_type"
    t.index ["uploaded_by_id"], name: "index_clinical_documents_on_uploaded_by_id"
  end

  create_table "comments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.text "body", null: false
    t.uuid "commentable_id"
    t.string "commentable_type"
    t.datetime "created_at", null: false
    t.datetime "expert_pinned_at"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_comments_on_account_id"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id"
    t.index ["expert_pinned_at"], name: "index_comments_on_expert_pinned_at"
  end

  create_table "conversation_participants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.uuid "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "last_read_at"
    t.datetime "updated_at", null: false
    t.index ["account_id", "conversation_id"], name: "index_conv_participants_on_account_conv", unique: true
    t.index ["account_id"], name: "index_conversation_participants_on_account_id"
    t.index ["conversation_id"], name: "index_conversation_participants_on_conversation_id"
  end

  create_table "conversations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "disease_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "color", limit: 20, default: "#000000"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", default: "", null: false
    t.datetime "updated_at", null: false
  end

  create_table "disease_photos", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "caption", limit: 255
    t.datetime "created_at", null: false
    t.uuid "disease_id", null: false
    t.text "image_data"
    t.datetime "updated_at", null: false
    t.index ["disease_id"], name: "index_disease_photos_on_disease_id"
  end

  create_table "disease_risk_factors", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.uuid "disease_id", null: false
    t.string "name", default: "", null: false
    t.integer "severity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["disease_id"], name: "index_disease_risk_factors_on_disease_id"
  end

  create_table "disease_statuses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "content", default: "", null: false
    t.datetime "created_at", null: false
    t.uuid "disease_id", null: false
    t.boolean "hidden", default: false, null: false
    t.datetime "hidden_at"
    t.integer "mood", default: 3, null: false
    t.text "notes"
    t.string "status", default: "", null: false
    t.datetime "updated_at", null: false
    t.index ["disease_id"], name: "index_disease_statuses_on_disease_id"
    t.index ["hidden"], name: "index_disease_statuses_on_hidden"
  end

  create_table "disease_symptom_updates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "disease_symptom_id", null: false
    t.integer "intensity", default: 1
    t.text "notes"
    t.string "status", default: ""
    t.datetime "update_date"
    t.datetime "updated_at", null: false
    t.index ["disease_symptom_id"], name: "index_disease_symptom_updates_on_disease_symptom_id"
  end

  create_table "disease_symptoms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.uuid "disease_id", null: false
    t.date "first_noticed_at"
    t.string "name", default: "", null: false
    t.uuid "predefined_symptom_id"
    t.string "severity", limit: 50, default: "mild"
    t.datetime "updated_at", null: false
    t.index ["disease_id"], name: "index_disease_symptoms_on_disease_id"
  end

  create_table "diseases", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "color", default: "", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.date "diagnosed_at"
    t.boolean "diagnosed_by_hp", default: false
    t.date "diagnosed_date"
    t.uuid "disease_category_id"
    t.string "icd10_code", default: ""
    t.string "name", limit: 255
    t.text "notes"
    t.uuid "predefined_disease_id"
    t.integer "severity", default: 1, null: false
    t.string "status", limit: 50, default: "active"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_diseases_on_account_id"
    t.index ["disease_category_id"], name: "index_diseases_on_disease_category_id"
    t.index ["predefined_disease_id"], name: "index_diseases_on_predefined_disease_id"
  end

  create_table "emergency_alerts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "acknowledged_at"
    t.string "alert_type", limit: 50, null: false
    t.datetime "created_at", null: false
    t.uuid "emergency_contact_id"
    t.text "message"
    t.json "metadata", default: {}
    t.integer "status", default: 0, null: false
    t.uuid "triggered_by_id"
    t.string "triggered_by_type"
    t.datetime "updated_at", null: false
    t.index ["account_id", "status"], name: "index_emergency_alerts_on_account_id_and_status"
    t.index ["account_id"], name: "index_emergency_alerts_on_account_id"
    t.index ["alert_type"], name: "index_emergency_alerts_on_alert_type"
    t.index ["triggered_by_type", "triggered_by_id"], name: "index_emergency_alerts_on_triggered_by"
  end

  create_table "emergency_contacts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.boolean "is_primary", default: false, null: false
    t.string "name", limit: 255, null: false
    t.boolean "notify_on_emergency", default: true, null: false
    t.string "phone_number", limit: 20, null: false
    t.string "relationship", limit: 50, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "is_primary"], name: "index_emergency_contacts_on_account_id_and_is_primary"
    t.index ["account_id"], name: "index_emergency_contacts_on_account_id"
  end

  create_table "friend_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.uuid "friend_id", null: false
    t.string "status", limit: 50, default: "pending"
    t.datetime "updated_at", null: false
    t.index ["account_id", "friend_id"], name: "index_friend_requests_on_account_id_and_friend_id", unique: true
    t.index ["account_id"], name: "index_friend_requests_on_account_id"
    t.index ["friend_id"], name: "index_friend_requests_on_friend_id"
  end

  create_table "friendships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.uuid "friend_id", null: false
    t.string "status", limit: 50, default: "pending"
    t.datetime "updated_at", null: false
    t.index ["account_id", "friend_id"], name: "index_friendships_on_account_id_and_friend_id", unique: true
    t.index ["account_id"], name: "index_friendships_on_account_id"
    t.index ["friend_id"], name: "index_friendships_on_friend_id"
  end

  create_table "group_members", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.uuid "group_id", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_group_members_on_account_id"
    t.index ["group_id", "account_id"], name: "index_group_members_on_group_id_and_account_id", unique: true
    t.index ["group_id"], name: "index_group_members_on_group_id"
    t.index ["role"], name: "index_group_members_on_role"
  end

  create_table "group_posts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.uuid "group_id", null: false
    t.string "title", limit: 255
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_group_posts_on_account_id"
    t.index ["group_id"], name: "index_group_posts_on_group_id"
  end

  create_table "groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "category", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "description", default: "", null: false
    t.string "name", default: "", null: false
    t.uuid "predefined_disease_id"
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_groups_on_category"
    t.index ["predefined_disease_id"], name: "index_groups_on_predefined_disease_id"
  end

  create_table "hashtags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "post_count", default: 0
    t.integer "trending_score", default: 0
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_hashtags_on_name", unique: true
    t.index ["trending_score"], name: "index_hashtags_on_trending_score"
  end

  create_table "health_agent_conversations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.integer "persona", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_health_agent_conversations_on_account_id"
    t.index ["persona"], name: "index_health_agent_conversations_on_persona"
    t.index ["status"], name: "index_health_agent_conversations_on_status"
  end

  create_table "health_agent_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "attachments", default: []
    t.text "content", null: false
    t.uuid "conversation_id", null: false
    t.datetime "created_at", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_health_agent_messages_on_conversation_id"
    t.index ["role"], name: "index_health_agent_messages_on_role"
  end

# Could not dump table "health_embeddings" because of following StandardError
#   Unknown type 'vector(1536)' for column 'embedding'


  create_table "health_observation_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.integer "confidence_level", default: 0
    t.datetime "created_at", null: false
    t.jsonb "evidence", default: []
    t.integer "observation_count", default: 1
    t.string "observation_type", null: false
    t.uuid "specialist_id"
    t.integer "status", default: 0
    t.string "triggered_by"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_health_observation_logs_on_account_id"
    t.index ["observation_type"], name: "index_health_observation_logs_on_observation_type"
    t.index ["specialist_id"], name: "index_health_observation_logs_on_specialist_id"
    t.index ["status"], name: "index_health_observation_logs_on_status"
  end

  create_table "karma_points", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.integer "points", null: false
    t.uuid "post_id", null: false
    t.string "reaction_type", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "post_id"], name: "index_karma_points_on_account_id_and_post_id"
    t.index ["account_id"], name: "index_karma_points_on_account_id"
    t.index ["post_id"], name: "index_karma_points_on_post_id"
  end

  create_table "measurement_raports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.jsonb "attachment_data"
    t.text "content"
    t.datetime "created_at", null: false
    t.string "name", default: "", null: false
    t.string "raport_type", limit: 50, default: "weekly"
    t.string "title", limit: 255
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_measurement_raports_on_account_id"
  end

  create_table "measurement_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "critical_lower_limit", precision: 10, scale: 2
    t.decimal "critical_upper_limit", precision: 10, scale: 2
    t.boolean "is_active", default: true
    t.decimal "lower_limit", precision: 10, scale: 2
    t.string "name", default: "", null: false
    t.string "unit", default: "", null: false
    t.uuid "unit_id", default: -> { "gen_random_uuid()" }
    t.datetime "updated_at", null: false
    t.decimal "upper_limit", precision: 10, scale: 2
  end

  create_table "measurements", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.boolean "is_within_limits", default: true
    t.datetime "measurement_date"
    t.uuid "measurement_type_id", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["account_id"], name: "index_measurements_on_account_id"
    t.index ["measurement_type_id"], name: "index_measurements_on_measurement_type_id"
  end

  create_table "medication_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.uuid "medication_id", null: false
    t.uuid "medication_schedule_id"
    t.text "notes"
    t.datetime "scheduled_for"
    t.string "status", limit: 50, default: "pending"
    t.datetime "taken_at"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_medication_logs_on_account_id"
    t.index ["medication_id"], name: "index_medication_logs_on_medication_id"
    t.index ["medication_schedule_id"], name: "index_medication_logs_on_medication_schedule_id"
    t.index ["scheduled_for"], name: "index_medication_logs_on_scheduled_for"
  end

  create_table "medication_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.string "dosage"
    t.string "frequency"
    t.string "medication_name", null: false
    t.text "reason"
    t.text "rejection_reason"
    t.datetime "requested_at", null: false
    t.datetime "reviewed_at"
    t.uuid "specialist_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_medication_requests_on_account_id"
    t.index ["specialist_id", "status"], name: "index_medication_requests_on_specialist_id_and_status"
  end

  create_table "medication_schedules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "day_of_week", limit: 20
    t.boolean "is_active", default: true, null: false
    t.uuid "medication_id", null: false
    t.time "scheduled_time", null: false
    t.string "time_of_day", limit: 50
    t.datetime "updated_at", null: false
    t.index ["medication_id", "is_active", "scheduled_time"], name: "index_med_schedules_on_med_id_and_is_active"
    t.index ["medication_id"], name: "index_medication_schedules_on_medication_id"
  end

  create_table "medications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.uuid "disease_id"
    t.string "dosage", limit: 255, null: false
    t.boolean "email_reminder_enabled", default: false, null: false
    t.date "end_date"
    t.string "frequency", limit: 255, null: false
    t.text "instructions"
    t.boolean "is_active", default: true, null: false
    t.uuid "medication_request_id"
    t.string "name", limit: 255, null: false
    t.text "notes"
    t.boolean "reminder_enabled", default: true, null: false
    t.integer "reminder_minutes_before", default: 15
    t.string "source"
    t.uuid "specialist_recommendation_id"
    t.date "start_date"
    t.datetime "updated_at", null: false
    t.index ["account_id", "is_active"], name: "index_medications_on_account_id_and_is_active"
    t.index ["account_id"], name: "index_medications_on_account_id"
    t.index ["medication_request_id"], name: "index_medications_on_medication_request_id"
    t.index ["source"], name: "index_medications_on_source"
    t.index ["specialist_recommendation_id"], name: "index_medications_on_specialist_recommendation_id"
  end

  create_table "message_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "content_type", limit: 100
    t.datetime "created_at", null: false
    t.text "file_data"
    t.string "file_type", limit: 100
    t.string "filename", limit: 255
    t.uuid "message_id", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_message_attachments_on_message_id"
  end

  create_table "messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "attachment_type", limit: 100
    t.text "attachment_url"
    t.text "body"
    t.uuid "conversation_id", null: false
    t.datetime "created_at", null: false
    t.integer "duration"
    t.string "message_type", limit: 50, default: "text", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_messages_on_account_id"
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
  end

  create_table "note_disease_associations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "disease_id", null: false
    t.uuid "note_id", null: false
    t.datetime "updated_at", null: false
    t.index ["disease_id"], name: "index_note_disease_associations_on_disease_id"
    t.index ["note_id", "disease_id"], name: "index_note_disease_associations_on_note_id_and_disease_id", unique: true
    t.index ["note_id"], name: "index_note_disease_associations_on_note_id"
  end

  create_table "note_group_associations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "note_group_id", null: false
    t.uuid "note_id", null: false
    t.datetime "updated_at", null: false
    t.index ["note_group_id"], name: "index_note_group_associations_on_note_group_id"
    t.index ["note_id", "note_group_id"], name: "index_note_group_associations_on_note_id_and_note_group_id", unique: true
    t.index ["note_id"], name: "index_note_group_associations_on_note_id"
  end

  create_table "note_groups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.string "name", limit: 255
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_note_groups_on_account_id"
  end

  create_table "note_tag_associations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "note_id", null: false
    t.uuid "note_tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["note_id", "note_tag_id"], name: "index_note_tag_associations_on_note_id_and_note_tag_id", unique: true
    t.index ["note_id"], name: "index_note_tag_associations_on_note_id"
    t.index ["note_tag_id"], name: "index_note_tag_associations_on_note_tag_id"
  end

  create_table "note_tags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.string "name", limit: 100
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_note_tags_on_account_id"
  end

  create_table "notes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "background_color", default: ""
    t.text "content"
    t.datetime "created_at", null: false
    t.boolean "is_pinned", default: false
    t.string "note_type", limit: 50, default: "general"
    t.string "title", limit: 255
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_notes_on_account_id"
  end

  create_table "notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.json "data", default: {}
    t.uuid "notifiable_id"
    t.string "notifiable_type"
    t.string "notification_type", limit: 50, null: false
    t.datetime "read_at"
    t.string "title", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "notification_type"], name: "index_notifications_on_account_id_and_notification_type"
    t.index ["account_id", "read_at"], name: "index_notifications_on_account_id_and_read_at"
    t.index ["account_id"], name: "index_notifications_on_account_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
  end

  create_table "poll_options", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "option_text", null: false
    t.uuid "post_id", null: false
    t.datetime "updated_at", null: false
    t.integer "vote_count", default: 0
    t.index ["post_id"], name: "index_poll_options_on_post_id"
  end

  create_table "poll_votes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.uuid "poll_option_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "poll_option_id"], name: "index_poll_votes_unique", unique: true
    t.index ["account_id"], name: "index_poll_votes_on_account_id"
    t.index ["poll_option_id"], name: "index_poll_votes_on_poll_option_id"
  end

  create_table "post_bookmarks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.uuid "post_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "post_id"], name: "index_post_bookmarks_unique", unique: true
    t.index ["account_id"], name: "index_post_bookmarks_on_account_id"
    t.index ["post_id"], name: "index_post_bookmarks_on_post_id"
  end

  create_table "post_hashtags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "hashtag_id", null: false
    t.uuid "post_id", null: false
    t.datetime "updated_at", null: false
    t.index ["hashtag_id"], name: "index_post_hashtags_on_hashtag_id"
    t.index ["post_id", "hashtag_id"], name: "index_post_hashtags_on_post_id_and_hashtag_id", unique: true
    t.index ["post_id"], name: "index_post_hashtags_on_post_id"
  end

  create_table "posts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "body", default: "", null: false
    t.integer "bookmark_count", default: 0
    t.datetime "created_at", null: false
    t.uuid "group_id", null: false
    t.jsonb "metadata", default: {}
    t.datetime "pinned_at"
    t.integer "poll_votes_count", default: 0
    t.integer "post_type", default: 0, null: false
    t.integer "quote_count", default: 0
    t.uuid "quoted_post_id"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_posts_on_account_id"
    t.index ["bookmark_count"], name: "index_posts_on_bookmark_count"
    t.index ["group_id"], name: "index_posts_on_group_id"
    t.index ["pinned_at"], name: "index_posts_on_pinned_at"
    t.index ["poll_votes_count"], name: "index_posts_on_poll_votes_count"
    t.index ["post_type"], name: "index_posts_on_post_type"
    t.index ["quote_count"], name: "index_posts_on_quote_count"
    t.index ["quoted_post_id"], name: "index_posts_on_quoted_post_id"
  end

  create_table "predefined_diseases", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "creates_group", default: true, null: false
    t.text "description", null: false
    t.string "icd10_code", limit: 50, null: false
    t.string "name", limit: 255, null: false
    t.string "related_names", default: [], array: true
    t.boolean "special", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_predefined_diseases_on_name", unique: true
    t.index ["special"], name: "index_predefined_diseases_on_special"
  end

  create_table "predefined_symptoms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "name", limit: 255, null: false
    t.uuid "predefined_disease_id"
    t.string "related_names", default: [], array: true
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_predefined_symptoms_on_name", unique: true
  end

  create_table "reactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.uuid "reactable_id"
    t.string "reactable_type"
    t.string "reaction_type", limit: 50, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "reactable_type", "reactable_id"], name: "idx_on_account_id_reactable_type_reactable_id_d54a0ed989"
    t.index ["account_id"], name: "index_reactions_on_account_id"
    t.index ["reactable_type", "reactable_id"], name: "index_reactions_on_reactable"
  end

  create_table "roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", default: "", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "shared_accesses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.integer "permission_level", default: 0, null: false
    t.uuid "shareable_id"
    t.string "shareable_type"
    t.uuid "shared_with_account_id"
    t.datetime "updated_at", null: false
    t.index ["account_id", "shareable_type", "shareable_id"], name: "index_shared_accesses_on_account_share"
    t.index ["account_id"], name: "index_shared_accesses_on_account_id"
    t.index ["shareable_type", "shareable_id"], name: "index_shared_accesses_on_shareable"
    t.index ["shared_with_account_id"], name: "index_shared_accesses_on_shared_with"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "specialist_appointments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.date "appointment_date"
    t.datetime "created_at", null: false
    t.string "end_time", limit: 5
    t.text "notes"
    t.uuid "patient_id", null: false
    t.uuid "schedule_id", null: false
    t.uuid "specialist_id", null: false
    t.string "start_time", limit: 5
    t.string "status", limit: 50, default: "scheduled"
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_specialist_appointments_on_patient_id"
    t.index ["schedule_id"], name: "index_specialist_appointments_on_schedule_id"
    t.index ["specialist_id"], name: "index_specialist_appointments_on_specialist_id"
  end

  create_table "specialist_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.boolean "is_read", default: false, null: false
    t.uuid "parent_id"
    t.string "sender_type", limit: 50, null: false
    t.uuid "specialist_id", null: false
    t.uuid "specialist_recommendation_id"
    t.string "subject", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_specialist_messages_on_account_id"
    t.index ["is_read"], name: "index_specialist_messages_on_is_read"
    t.index ["sender_type"], name: "index_specialist_messages_on_sender_type"
    t.index ["specialist_id", "account_id"], name: "index_specialist_messages_on_specialist_id_and_account_id"
    t.index ["specialist_id"], name: "index_specialist_messages_on_specialist_id"
  end

  create_table "specialist_note_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "file_type", limit: 100
    t.string "file_url", limit: 500
    t.string "filename", limit: 255
    t.uuid "specialist_note_id", null: false
    t.datetime "updated_at", null: false
    t.index ["specialist_note_id"], name: "index_specialist_note_attachments_on_specialist_note_id"
  end

  create_table "specialist_notes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "note_type", limit: 50, default: "observation", null: false
    t.uuid "specialist_id", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_specialist_notes_on_account_id"
    t.index ["specialist_id", "account_id"], name: "index_specialist_notes_on_specialist_id_and_account_id"
    t.index ["specialist_id"], name: "index_specialist_notes_on_specialist_id"
  end

  create_table "specialist_notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id"
    t.datetime "acknowledged_at"
    t.text "acknowledgment_note"
    t.datetime "created_at", null: false
    t.datetime "deferred_until"
    t.boolean "is_read", default: false, null: false
    t.text "message"
    t.uuid "notifiable_id"
    t.string "notifiable_type"
    t.string "notification_type", limit: 50, null: false
    t.uuid "patient_id", null: false
    t.uuid "specialist_id", null: false
    t.string "title", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_specialist_notifications_on_notifiable"
    t.index ["notification_type"], name: "index_specialist_notifications_on_notification_type"
    t.index ["patient_id"], name: "index_specialist_notifications_on_patient_id"
    t.index ["specialist_id", "is_read"], name: "index_specialist_notifications_on_specialist_id_and_is_read"
    t.index ["specialist_id"], name: "index_specialist_notifications_on_specialist_id"
  end

  create_table "specialist_patients", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.text "notes"
    t.string "relationship_type", limit: 50, default: "consulting", null: false
    t.uuid "specialist_id", null: false
    t.string "status", limit: 50, default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_specialist_patients_on_account_id"
    t.index ["specialist_id", "account_id"], name: "index_specialist_patients_on_specialist_id_and_account_id", unique: true
    t.index ["specialist_id"], name: "index_specialist_patients_on_specialist_id"
    t.index ["status"], name: "index_specialist_patients_on_status"
  end

  create_table "specialist_recommendations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.string "dosage", limit: 255
    t.uuid "medication_id"
    t.string "name", limit: 255, null: false
    t.text "notes"
    t.string "recommendation_type", limit: 50, null: false
    t.uuid "specialist_id", null: false
    t.string "status", limit: 50, default: "pending", null: false
    t.uuid "treatment_id"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_specialist_recommendations_on_account_id"
    t.index ["specialist_id", "account_id"], name: "index_spec_recommendations_on_spec_id_and_account_id"
    t.index ["specialist_id"], name: "index_specialist_recommendations_on_specialist_id"
    t.index ["status"], name: "index_specialist_recommendations_on_status"
  end

  create_table "specialist_referral_clicks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "clicked_at", null: false
    t.string "ip_address", limit: 45
    t.uuid "specialist_request_id", null: false
    t.string "user_agent", limit: 512
    t.index ["specialist_request_id", "clicked_at"], name: "idx_on_specialist_request_id_clicked_at_1fae2c9a75"
    t.index ["specialist_request_id"], name: "index_specialist_referral_clicks_on_specialist_request_id"
  end

  create_table "specialist_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.string "field_of_expertise"
    t.string "hash_code", limit: 20
    t.text "message"
    t.uuid "specialist_id", null: false
    t.string "specialization"
    t.string "specialization_description"
    t.string "status", limit: 50, default: "pending"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_specialist_requests_on_account_id"
    t.index ["hash_code"], name: "index_specialist_requests_on_hash_code", unique: true
    t.index ["specialist_id", "account_id"], name: "index_specialist_requests_on_specialist_id_and_account_id", unique: true
    t.index ["specialist_id"], name: "index_specialist_requests_on_specialist_id"
  end

  create_table "specialist_schedules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "appointment_type", limit: 50
    t.datetime "created_at", null: false
    t.integer "day_of_week"
    t.integer "duration_minutes"
    t.string "end_time", limit: 5
    t.boolean "is_active", default: true
    t.uuid "specialist_id", null: false
    t.string "start_time", limit: 5
    t.datetime "updated_at", null: false
    t.index ["specialist_id"], name: "index_specialist_schedules_on_specialist_id"
  end

  create_table "specialists", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "field_of_expertise", limit: 255
    t.string "license_number", limit: 100
    t.json "qualifications", default: {}
    t.string "specialization"
    t.string "specialization_description"
    t.string "status", limit: 50, default: "active"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_specialists_on_user_id"
  end

  create_table "treatment_diseases", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "disease_id", null: false
    t.uuid "treatment_id", null: false
    t.datetime "updated_at", null: false
    t.index ["disease_id"], name: "index_treatment_diseases_on_disease_id"
    t.index ["treatment_id", "disease_id"], name: "index_treatment_diseases_on_treatment_id_and_disease_id", unique: true
    t.index ["treatment_id"], name: "index_treatment_diseases_on_treatment_id"
  end

  create_table "treatment_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.text "rejection_reason"
    t.datetime "requested_at", null: false
    t.datetime "reviewed_at"
    t.uuid "specialist_id"
    t.date "start_date"
    t.string "status", default: "pending", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "status"], name: "index_treatment_requests_on_account_id_and_status"
    t.index ["account_id"], name: "index_treatment_requests_on_account_id"
    t.index ["status"], name: "index_treatment_requests_on_status"
  end

  create_table "treatment_updates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", default: "", null: false
    t.string "name", default: "", null: false
    t.text "notes"
    t.string "status", limit: 50
    t.uuid "treatment_id", null: false
    t.datetime "update_date"
    t.datetime "updated_at", null: false
    t.index ["treatment_id"], name: "index_treatment_updates_on_treatment_id"
  end

  create_table "treatments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "account_id", null: false
    t.string "approval_status", default: "pending", null: false
    t.datetime "approved_at"
    t.uuid "approved_by_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "effectiveness", default: 0, null: false
    t.date "end_date"
    t.datetime "hidden_at"
    t.boolean "is_finished", default: false, null: false
    t.boolean "is_hidden", default: false, null: false
    t.string "name", default: "", null: false
    t.datetime "requested_at"
    t.string "source"
    t.uuid "specialist_recommendation_id"
    t.date "start_date"
    t.string "status", default: "active"
    t.string "title", default: ""
    t.datetime "updated_at", null: false
    t.index ["account_id", "approval_status"], name: "index_treatments_on_account_id_and_approval_status"
    t.index ["account_id"], name: "index_treatments_on_account_id"
    t.index ["approval_status"], name: "index_treatments_on_approval_status"
    t.index ["source"], name: "index_treatments_on_source"
    t.index ["specialist_recommendation_id"], name: "index_treatments_on_specialist_recommendation_id"
  end

  create_table "units", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", default: "", null: false
    t.string "symbol", default: "", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "role_id", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "avatar_url", limit: 500
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "email", limit: 255, null: false
    t.string "field_of_expertise", limit: 255
    t.string "first_name", limit: 100
    t.string "last_name", limit: 100
    t.string "license_number", limit: 100
    t.text "otp_backup_codes"
    t.boolean "otp_required_for_login", default: false, null: false
    t.string "otp_secret"
    t.string "password_digest", limit: 255
    t.string "phone_number", limit: 20
    t.json "qualifications", default: {}
    t.string "specialty", limit: 100
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "accounts", "users", name: "accounts_user_id_fkey"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ai_agent_conversations", "accounts"
  add_foreign_key "ai_agent_messages", "ai_agent_conversations", column: "conversation_id"
  add_foreign_key "behavior_sequences", "accounts"
  add_foreign_key "caregivers", "accounts"
  add_foreign_key "caregivers", "accounts", column: "caregiver_account_id"
  add_foreign_key "chatroom_messages", "accounts"
  add_foreign_key "chatroom_messages", "chatrooms"
  add_foreign_key "chatroom_participants", "accounts"
  add_foreign_key "chatroom_participants", "chatrooms"
  add_foreign_key "chatrooms", "accounts", column: "account1_id"
  add_foreign_key "chatrooms", "accounts", column: "account2_id"
  add_foreign_key "clinical_documents", "accounts"
  add_foreign_key "conversation_participants", "accounts"
  add_foreign_key "conversation_participants", "conversations"
  add_foreign_key "diseases", "accounts"
  add_foreign_key "diseases", "disease_categories"
  add_foreign_key "health_agent_conversations", "accounts"
  add_foreign_key "health_agent_messages", "health_agent_conversations", column: "conversation_id"
  add_foreign_key "health_embeddings", "accounts"
  add_foreign_key "health_observation_logs", "accounts"
  add_foreign_key "karma_points", "accounts"
  add_foreign_key "medications", "medication_requests", validate: false
end
