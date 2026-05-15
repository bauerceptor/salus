--
-- PostgreSQL database dump
--

\restrict aa2HbGJ7eejENrFsAWoAePzzOK8tad3QEULEDLk2YMNmhLLqApzHm69BqJt4rbd

-- Dumped from database version 18.3 (Debian 18.3-1.pgdg12+1)
-- Dumped by pg_dump version 18.3 (Debian 18.3-1.pgdg12+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    address text,
    background_data text,
    background_position character varying DEFAULT 'center'::character varying,
    badge integer DEFAULT 0 NOT NULL,
    bio text DEFAULT ''::text,
    birthday date,
    city character varying(100),
    country character varying(100),
    created_at timestamp(6) without time zone NOT NULL,
    date_of_birth date,
    education character varying(50) DEFAULT ''::character varying,
    email character varying(255),
    email_verified_at timestamp(6) without time zone,
    first_name character varying(100),
    gender character varying(20),
    image_data text,
    is_hidden boolean DEFAULT false,
    is_verified boolean DEFAULT false,
    karma_score integer DEFAULT 0 NOT NULL,
    last_login_at timestamp(6) without time zone,
    last_name character varying(100),
    last_risk_assessment timestamp(6) without time zone,
    last_seen_at timestamp(6) without time zone,
    online_status integer DEFAULT 0,
    password_digest character varying(255),
    phone_number character varying(20),
    preferences json DEFAULT '{}'::json,
    risk_score integer DEFAULT 0,
    role character varying(50) DEFAULT 'user'::character varying,
    settings jsonb DEFAULT '{}'::jsonb,
    sex character varying(20) DEFAULT ''::character varying,
    typing_in_chatroom_id uuid,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id uuid,
    username character varying(50)
);


--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    blob_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying NOT NULL,
    record_id uuid NOT NULL,
    record_type character varying NOT NULL
);


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    content_type character varying,
    created_at timestamp(6) without time zone NOT NULL,
    filename character varying NOT NULL,
    key character varying NOT NULL,
    metadata text,
    service_name character varying NOT NULL
);


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    blob_id uuid NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: admins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    email character varying(255) NOT NULL,
    password_digest character varying(255),
    role character varying(50) DEFAULT 'admin'::character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ai_agent_conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_agent_conversations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    title character varying(255) DEFAULT 'New Chat'::character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ai_agent_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_agent_messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    attachments json DEFAULT '{}'::json,
    content text NOT NULL,
    conversation_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    role character varying(50) NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: article_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.article_tags (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: article_tags_articles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.article_tags_articles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    article_id uuid NOT NULL,
    article_tag_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: articles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.articles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    body text,
    created_at timestamp(6) without time zone NOT NULL,
    description text DEFAULT ''::text,
    status character varying(50) DEFAULT 'draft'::character varying,
    title character varying(255),
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: behavior_sequences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.behavior_sequences (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    adherence_score integer DEFAULT 100,
    analyzed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    events json DEFAULT '[]'::json,
    metadata json DEFAULT '{}'::json,
    sequence_type character varying(50) NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: caregivers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.caregivers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    can_view_diseases boolean DEFAULT true NOT NULL,
    can_view_measurements boolean DEFAULT true NOT NULL,
    can_view_medications boolean DEFAULT true NOT NULL,
    caregiver_account_id uuid,
    created_at timestamp(6) without time zone NOT NULL,
    is_accepted boolean DEFAULT false NOT NULL,
    notify_on_abnormal_measurement boolean DEFAULT false NOT NULL,
    notify_on_low_adherence boolean DEFAULT true NOT NULL,
    notify_on_missed_dose boolean DEFAULT true NOT NULL,
    relationship character varying(50) NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: chatroom_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chatroom_messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    body text,
    chatroom_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    message_type integer DEFAULT 0,
    reactions json DEFAULT '{}'::json,
    read_at timestamp(6) without time zone,
    reply_to_message_id bigint,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: chatroom_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chatroom_participants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    chatroom_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    last_read_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: chatrooms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chatrooms (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account1_id uuid NOT NULL,
    account2_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: clinical_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clinical_documents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    ai_processed boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    document_type character varying NOT NULL,
    file_data jsonb DEFAULT '{}'::jsonb,
    parsed_content text,
    updated_at timestamp(6) without time zone NOT NULL,
    uploaded_by_id uuid NOT NULL
);


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    body text NOT NULL,
    commentable_id uuid,
    commentable_type character varying,
    created_at timestamp(6) without time zone NOT NULL,
    expert_pinned_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: conversation_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversation_participants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    conversation_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    last_read_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: disease_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.disease_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    color character varying(20) DEFAULT '#000000'::character varying,
    created_at timestamp(6) without time zone NOT NULL,
    description text,
    name character varying DEFAULT ''::character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: disease_photos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.disease_photos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    caption character varying(255),
    created_at timestamp(6) without time zone NOT NULL,
    disease_id uuid NOT NULL,
    image_data text,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: disease_risk_factors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.disease_risk_factors (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    description text,
    disease_id uuid NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    severity integer DEFAULT 1 NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: disease_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.disease_statuses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    content text DEFAULT ''::text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    disease_id uuid NOT NULL,
    hidden boolean DEFAULT false NOT NULL,
    hidden_at timestamp(6) without time zone,
    mood integer DEFAULT 3 NOT NULL,
    notes text,
    status character varying DEFAULT ''::character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: disease_symptom_updates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.disease_symptom_updates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    disease_symptom_id uuid NOT NULL,
    intensity integer DEFAULT 1,
    notes text,
    status character varying DEFAULT ''::character varying,
    update_date timestamp(6) without time zone,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: disease_symptoms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.disease_symptoms (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    description text,
    disease_id uuid NOT NULL,
    first_noticed_at date,
    name character varying DEFAULT ''::character varying NOT NULL,
    predefined_symptom_id uuid,
    severity character varying(50) DEFAULT 'mild'::character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: diseases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.diseases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    color character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    description text,
    diagnosed_at date,
    diagnosed_by_hp boolean DEFAULT false,
    diagnosed_date date,
    disease_category_id uuid,
    icd10_code character varying DEFAULT ''::character varying,
    name character varying(255),
    notes text,
    predefined_disease_id uuid,
    severity integer DEFAULT 1 NOT NULL,
    status character varying(50) DEFAULT 'active'::character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: emergency_alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.emergency_alerts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    acknowledged_at timestamp(6) without time zone,
    alert_type character varying(50) NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    emergency_contact_id uuid,
    message text,
    metadata json DEFAULT '{}'::json,
    status integer DEFAULT 0 NOT NULL,
    triggered_by_id uuid,
    triggered_by_type character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: emergency_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.emergency_contacts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    name character varying(255) NOT NULL,
    notify_on_emergency boolean DEFAULT true NOT NULL,
    phone_number character varying(20) NOT NULL,
    relationship character varying(50) NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: friend_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.friend_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    friend_id uuid NOT NULL,
    status character varying(50) DEFAULT 'pending'::character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: friendships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.friendships (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    friend_id uuid NOT NULL,
    status character varying(50) DEFAULT 'pending'::character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: group_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_members (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    group_id uuid NOT NULL,
    role integer DEFAULT 0 NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: group_posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_posts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    body text,
    created_at timestamp(6) without time zone NOT NULL,
    group_id uuid NOT NULL,
    title character varying(255),
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    category integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    description character varying DEFAULT ''::character varying NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    predefined_disease_id uuid,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: hashtags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hashtags (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying NOT NULL,
    post_count integer DEFAULT 0,
    trending_score integer DEFAULT 0,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: health_agent_conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.health_agent_conversations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    persona integer DEFAULT 0 NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: health_agent_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.health_agent_messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    attachments jsonb DEFAULT '[]'::jsonb,
    content text NOT NULL,
    conversation_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    role integer DEFAULT 0 NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: health_embeddings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.health_embeddings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    embedding_type character varying NOT NULL,
    content text NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    confidence_score integer DEFAULT 0,
    validated boolean DEFAULT false,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    embedding public.vector(1536)
);


--
-- Name: health_observation_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.health_observation_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    confidence_level integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    evidence jsonb DEFAULT '[]'::jsonb,
    observation_count integer DEFAULT 1,
    observation_type character varying NOT NULL,
    specialist_id uuid,
    status integer DEFAULT 0,
    triggered_by character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: karma_points; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.karma_points (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    points integer NOT NULL,
    post_id uuid NOT NULL,
    reaction_type character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: measurement_raports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.measurement_raports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    attachment_data jsonb,
    content text,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    raport_type character varying(50) DEFAULT 'weekly'::character varying,
    title character varying(255),
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: measurement_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.measurement_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    critical_lower_limit numeric(10,2),
    critical_upper_limit numeric(10,2),
    is_active boolean DEFAULT true,
    lower_limit numeric(10,2),
    name character varying DEFAULT ''::character varying NOT NULL,
    unit character varying DEFAULT ''::character varying NOT NULL,
    unit_id uuid DEFAULT gen_random_uuid(),
    updated_at timestamp(6) without time zone NOT NULL,
    upper_limit numeric(10,2)
);


--
-- Name: measurements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.measurements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    is_within_limits boolean DEFAULT true,
    measurement_date timestamp(6) without time zone,
    measurement_type_id uuid NOT NULL,
    notes text,
    updated_at timestamp(6) without time zone NOT NULL,
    value character varying
);


--
-- Name: medication_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.medication_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    medication_id uuid NOT NULL,
    medication_schedule_id uuid,
    notes text,
    scheduled_for timestamp(6) without time zone,
    status character varying(50) DEFAULT 'pending'::character varying,
    taken_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: medication_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.medication_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    dosage character varying,
    frequency character varying,
    medication_name character varying NOT NULL,
    reason text,
    rejection_reason text,
    requested_at timestamp(6) without time zone NOT NULL,
    reviewed_at timestamp(6) without time zone,
    specialist_id uuid NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: medication_schedules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.medication_schedules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    day_of_week character varying(20),
    is_active boolean DEFAULT true NOT NULL,
    medication_id uuid NOT NULL,
    scheduled_time time without time zone NOT NULL,
    time_of_day character varying(50),
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: medications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.medications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    disease_id uuid,
    dosage character varying(255) NOT NULL,
    email_reminder_enabled boolean DEFAULT false NOT NULL,
    end_date date,
    frequency character varying(255) NOT NULL,
    instructions text,
    is_active boolean DEFAULT true NOT NULL,
    medication_request_id uuid,
    name character varying(255) NOT NULL,
    notes text,
    reminder_enabled boolean DEFAULT true NOT NULL,
    reminder_minutes_before integer DEFAULT 15,
    source character varying,
    specialist_recommendation_id uuid,
    start_date date,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: message_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message_attachments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    content_type character varying(100),
    created_at timestamp(6) without time zone NOT NULL,
    file_data text,
    file_type character varying(100),
    filename character varying(255),
    message_id uuid NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    attachment_type character varying(100),
    attachment_url text,
    body text,
    conversation_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    duration integer,
    message_type character varying(50) DEFAULT 'text'::character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: note_disease_associations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.note_disease_associations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    disease_id uuid NOT NULL,
    note_id uuid NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: note_group_associations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.note_group_associations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    note_group_id uuid NOT NULL,
    note_id uuid NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: note_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.note_groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying(255),
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: note_tag_associations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.note_tag_associations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    note_id uuid NOT NULL,
    note_tag_id uuid NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: note_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.note_tags (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying(100),
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    background_color character varying DEFAULT ''::character varying,
    content text,
    created_at timestamp(6) without time zone NOT NULL,
    is_pinned boolean DEFAULT false,
    note_type character varying(50) DEFAULT 'general'::character varying,
    title character varying(255),
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    body text,
    created_at timestamp(6) without time zone NOT NULL,
    data json DEFAULT '{}'::json,
    notifiable_id uuid,
    notifiable_type character varying,
    notification_type character varying(50) NOT NULL,
    read_at timestamp(6) without time zone,
    title character varying(255) NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: poll_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.poll_options (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    option_text character varying NOT NULL,
    post_id uuid NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    vote_count integer DEFAULT 0
);


--
-- Name: poll_votes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.poll_votes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    poll_option_id uuid NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: post_bookmarks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_bookmarks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    post_id uuid NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: post_hashtags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_hashtags (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    hashtag_id uuid NOT NULL,
    post_id uuid NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    body character varying DEFAULT ''::character varying NOT NULL,
    bookmark_count integer DEFAULT 0,
    created_at timestamp(6) without time zone NOT NULL,
    group_id uuid NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    pinned_at timestamp(6) without time zone,
    poll_votes_count integer DEFAULT 0,
    post_type integer DEFAULT 0 NOT NULL,
    quote_count integer DEFAULT 0,
    quoted_post_id uuid,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: predefined_diseases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.predefined_diseases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    creates_group boolean DEFAULT true NOT NULL,
    description text NOT NULL,
    icd10_code character varying(50) NOT NULL,
    name character varying(255) NOT NULL,
    related_names character varying[] DEFAULT '{}'::character varying[],
    special boolean DEFAULT false NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: predefined_symptoms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.predefined_symptoms (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    description text NOT NULL,
    name character varying(255) NOT NULL,
    predefined_disease_id uuid,
    related_names character varying[] DEFAULT '{}'::character varying[],
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: reactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    reactable_id uuid,
    reactable_type character varying,
    reaction_type character varying(50) NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: shared_accesses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shared_accesses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    expires_at timestamp(6) without time zone,
    permission_level integer DEFAULT 0 NOT NULL,
    shareable_id uuid,
    shareable_type character varying,
    shared_with_account_id uuid,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_blocked_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_blocked_executions (
    id bigint NOT NULL,
    concurrency_key character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    job_id bigint NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    queue_name character varying NOT NULL
);


--
-- Name: solid_queue_blocked_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_blocked_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_blocked_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_blocked_executions_id_seq OWNED BY public.solid_queue_blocked_executions.id;


--
-- Name: solid_queue_claimed_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_claimed_executions (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    job_id bigint NOT NULL,
    process_id bigint
);


--
-- Name: solid_queue_claimed_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_claimed_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_claimed_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_claimed_executions_id_seq OWNED BY public.solid_queue_claimed_executions.id;


--
-- Name: solid_queue_failed_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_failed_executions (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    error text,
    job_id bigint NOT NULL
);


--
-- Name: solid_queue_failed_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_failed_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_failed_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_failed_executions_id_seq OWNED BY public.solid_queue_failed_executions.id;


--
-- Name: solid_queue_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_jobs (
    id bigint NOT NULL,
    active_job_id character varying,
    arguments text,
    class_name character varying NOT NULL,
    concurrency_key character varying,
    created_at timestamp(6) without time zone NOT NULL,
    finished_at timestamp(6) without time zone,
    priority integer DEFAULT 0 NOT NULL,
    queue_name character varying NOT NULL,
    scheduled_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_jobs_id_seq OWNED BY public.solid_queue_jobs.id;


--
-- Name: solid_queue_pauses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_pauses (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    queue_name character varying NOT NULL
);


--
-- Name: solid_queue_pauses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_pauses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_pauses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_pauses_id_seq OWNED BY public.solid_queue_pauses.id;


--
-- Name: solid_queue_processes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_processes (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    hostname character varying,
    kind character varying NOT NULL,
    last_heartbeat_at timestamp(6) without time zone NOT NULL,
    metadata text,
    name character varying NOT NULL,
    pid integer NOT NULL,
    supervisor_id bigint
);


--
-- Name: solid_queue_processes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_processes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_processes_id_seq OWNED BY public.solid_queue_processes.id;


--
-- Name: solid_queue_ready_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_ready_executions (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    job_id bigint NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    queue_name character varying NOT NULL
);


--
-- Name: solid_queue_ready_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_ready_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_ready_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_ready_executions_id_seq OWNED BY public.solid_queue_ready_executions.id;


--
-- Name: solid_queue_recurring_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_recurring_executions (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    job_id bigint NOT NULL,
    run_at timestamp(6) without time zone NOT NULL,
    task_key character varying NOT NULL
);


--
-- Name: solid_queue_recurring_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_recurring_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_recurring_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_recurring_executions_id_seq OWNED BY public.solid_queue_recurring_executions.id;


--
-- Name: solid_queue_recurring_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_recurring_tasks (
    id bigint NOT NULL,
    arguments text,
    class_name character varying,
    command character varying(2048),
    created_at timestamp(6) without time zone NOT NULL,
    description text,
    key character varying NOT NULL,
    priority integer DEFAULT 0,
    queue_name character varying,
    schedule character varying NOT NULL,
    static boolean DEFAULT true NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_recurring_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_recurring_tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_recurring_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_recurring_tasks_id_seq OWNED BY public.solid_queue_recurring_tasks.id;


--
-- Name: solid_queue_scheduled_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_scheduled_executions (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    job_id bigint NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    queue_name character varying NOT NULL,
    scheduled_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_scheduled_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_scheduled_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_scheduled_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_scheduled_executions_id_seq OWNED BY public.solid_queue_scheduled_executions.id;


--
-- Name: solid_queue_semaphores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.solid_queue_semaphores (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    key character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    value integer DEFAULT 1 NOT NULL
);


--
-- Name: solid_queue_semaphores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.solid_queue_semaphores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: solid_queue_semaphores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.solid_queue_semaphores_id_seq OWNED BY public.solid_queue_semaphores.id;


--
-- Name: specialist_appointments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.specialist_appointments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    appointment_date date,
    created_at timestamp(6) without time zone NOT NULL,
    end_time character varying(5),
    notes text,
    patient_id uuid NOT NULL,
    schedule_id uuid NOT NULL,
    specialist_id uuid NOT NULL,
    start_time character varying(5),
    status character varying(50) DEFAULT 'scheduled'::character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: specialist_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.specialist_messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    body text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    parent_id uuid,
    sender_type character varying(50) NOT NULL,
    specialist_id uuid NOT NULL,
    specialist_recommendation_id uuid,
    subject character varying(255) NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: specialist_note_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.specialist_note_attachments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    file_type character varying(100),
    file_url character varying(500),
    filename character varying(255),
    specialist_note_id uuid NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: specialist_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.specialist_notes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    content text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    note_type character varying(50) DEFAULT 'observation'::character varying NOT NULL,
    specialist_id uuid NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: specialist_notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.specialist_notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid,
    acknowledged_at timestamp(6) without time zone,
    acknowledgment_note text,
    created_at timestamp(6) without time zone NOT NULL,
    deferred_until timestamp(6) without time zone,
    is_read boolean DEFAULT false NOT NULL,
    message text,
    notifiable_id uuid,
    notifiable_type character varying,
    notification_type character varying(50) NOT NULL,
    patient_id uuid NOT NULL,
    specialist_id uuid NOT NULL,
    title character varying(255) NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: specialist_patients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.specialist_patients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    notes text,
    relationship_type character varying(50) DEFAULT 'consulting'::character varying NOT NULL,
    specialist_id uuid NOT NULL,
    status character varying(50) DEFAULT 'pending'::character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: specialist_recommendations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.specialist_recommendations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    dosage character varying(255),
    medication_id uuid,
    name character varying(255) NOT NULL,
    notes text,
    recommendation_type character varying(50) NOT NULL,
    specialist_id uuid NOT NULL,
    status character varying(50) DEFAULT 'pending'::character varying NOT NULL,
    treatment_id uuid,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: specialist_referral_clicks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.specialist_referral_clicks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    clicked_at timestamp(6) without time zone NOT NULL,
    ip_address character varying(45),
    specialist_request_id uuid NOT NULL,
    user_agent character varying(512)
);


--
-- Name: specialist_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.specialist_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    field_of_expertise character varying,
    hash_code character varying(20),
    message text,
    specialist_id uuid NOT NULL,
    specialization character varying,
    specialization_description character varying,
    status character varying(50) DEFAULT 'pending'::character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: specialist_schedules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.specialist_schedules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    appointment_type character varying(50),
    created_at timestamp(6) without time zone NOT NULL,
    day_of_week integer,
    duration_minutes integer,
    end_time character varying(5),
    is_active boolean DEFAULT true,
    specialist_id uuid NOT NULL,
    start_time character varying(5),
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: specialists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.specialists (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bio text,
    created_at timestamp(6) without time zone NOT NULL,
    field_of_expertise character varying(255),
    license_number character varying(100),
    qualifications json DEFAULT '{}'::json,
    specialization character varying,
    specialization_description character varying,
    status character varying(50) DEFAULT 'active'::character varying,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id uuid NOT NULL
);


--
-- Name: treatment_diseases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.treatment_diseases (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    disease_id uuid NOT NULL,
    treatment_id uuid NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: treatment_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.treatment_requests (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    description text,
    rejection_reason text,
    requested_at timestamp(6) without time zone NOT NULL,
    reviewed_at timestamp(6) without time zone,
    specialist_id uuid,
    start_date date,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    title character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: treatment_updates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.treatment_updates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    notes text,
    status character varying(50),
    treatment_id uuid NOT NULL,
    update_date timestamp(6) without time zone,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: treatments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.treatments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    account_id uuid NOT NULL,
    approval_status character varying DEFAULT 'pending'::character varying NOT NULL,
    approved_at timestamp(6) without time zone,
    approved_by_id uuid,
    created_at timestamp(6) without time zone NOT NULL,
    description text,
    effectiveness integer DEFAULT 0 NOT NULL,
    end_date date,
    hidden_at timestamp(6) without time zone,
    is_finished boolean DEFAULT false NOT NULL,
    is_hidden boolean DEFAULT false NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    requested_at timestamp(6) without time zone,
    source character varying,
    specialist_recommendation_id uuid,
    start_date date,
    status character varying DEFAULT 'active'::character varying,
    title character varying DEFAULT ''::character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: units; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.units (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    description text,
    name character varying DEFAULT ''::character varying NOT NULL,
    symbol character varying DEFAULT ''::character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    role_id uuid NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id uuid NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    avatar_url character varying(500),
    bio text,
    created_at timestamp(6) without time zone NOT NULL,
    email character varying(255) NOT NULL,
    field_of_expertise character varying(255),
    first_name character varying(100),
    last_name character varying(100),
    license_number character varying(100),
    otp_backup_codes text,
    otp_required_for_login boolean DEFAULT false NOT NULL,
    otp_secret character varying,
    password_digest character varying(255),
    phone_number character varying(20),
    qualifications json DEFAULT '{}'::json,
    specialty character varying(100),
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: solid_queue_blocked_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_blocked_executions_id_seq'::regclass);


--
-- Name: solid_queue_claimed_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_claimed_executions_id_seq'::regclass);


--
-- Name: solid_queue_failed_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_failed_executions_id_seq'::regclass);


--
-- Name: solid_queue_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_jobs ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_jobs_id_seq'::regclass);


--
-- Name: solid_queue_pauses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_pauses ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_pauses_id_seq'::regclass);


--
-- Name: solid_queue_processes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_processes ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_processes_id_seq'::regclass);


--
-- Name: solid_queue_ready_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_ready_executions_id_seq'::regclass);


--
-- Name: solid_queue_recurring_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_recurring_executions_id_seq'::regclass);


--
-- Name: solid_queue_recurring_tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_tasks ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_recurring_tasks_id_seq'::regclass);


--
-- Name: solid_queue_scheduled_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_scheduled_executions_id_seq'::regclass);


--
-- Name: solid_queue_semaphores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_semaphores ALTER COLUMN id SET DEFAULT nextval('public.solid_queue_semaphores_id_seq'::regclass);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: ai_agent_conversations ai_agent_conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_agent_conversations
    ADD CONSTRAINT ai_agent_conversations_pkey PRIMARY KEY (id);


--
-- Name: ai_agent_messages ai_agent_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_agent_messages
    ADD CONSTRAINT ai_agent_messages_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: article_tags_articles article_tags_articles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.article_tags_articles
    ADD CONSTRAINT article_tags_articles_pkey PRIMARY KEY (id);


--
-- Name: article_tags article_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.article_tags
    ADD CONSTRAINT article_tags_pkey PRIMARY KEY (id);


--
-- Name: articles articles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.articles
    ADD CONSTRAINT articles_pkey PRIMARY KEY (id);


--
-- Name: behavior_sequences behavior_sequences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.behavior_sequences
    ADD CONSTRAINT behavior_sequences_pkey PRIMARY KEY (id);


--
-- Name: caregivers caregivers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caregivers
    ADD CONSTRAINT caregivers_pkey PRIMARY KEY (id);


--
-- Name: chatroom_messages chatroom_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chatroom_messages
    ADD CONSTRAINT chatroom_messages_pkey PRIMARY KEY (id);


--
-- Name: chatroom_participants chatroom_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chatroom_participants
    ADD CONSTRAINT chatroom_participants_pkey PRIMARY KEY (id);


--
-- Name: chatrooms chatrooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chatrooms
    ADD CONSTRAINT chatrooms_pkey PRIMARY KEY (id);


--
-- Name: clinical_documents clinical_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clinical_documents
    ADD CONSTRAINT clinical_documents_pkey PRIMARY KEY (id);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: conversation_participants conversation_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_participants
    ADD CONSTRAINT conversation_participants_pkey PRIMARY KEY (id);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- Name: disease_categories disease_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disease_categories
    ADD CONSTRAINT disease_categories_pkey PRIMARY KEY (id);


--
-- Name: disease_photos disease_photos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disease_photos
    ADD CONSTRAINT disease_photos_pkey PRIMARY KEY (id);


--
-- Name: disease_risk_factors disease_risk_factors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disease_risk_factors
    ADD CONSTRAINT disease_risk_factors_pkey PRIMARY KEY (id);


--
-- Name: disease_statuses disease_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disease_statuses
    ADD CONSTRAINT disease_statuses_pkey PRIMARY KEY (id);


--
-- Name: disease_symptom_updates disease_symptom_updates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disease_symptom_updates
    ADD CONSTRAINT disease_symptom_updates_pkey PRIMARY KEY (id);


--
-- Name: disease_symptoms disease_symptoms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disease_symptoms
    ADD CONSTRAINT disease_symptoms_pkey PRIMARY KEY (id);


--
-- Name: diseases diseases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diseases
    ADD CONSTRAINT diseases_pkey PRIMARY KEY (id);


--
-- Name: emergency_alerts emergency_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emergency_alerts
    ADD CONSTRAINT emergency_alerts_pkey PRIMARY KEY (id);


--
-- Name: emergency_contacts emergency_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.emergency_contacts
    ADD CONSTRAINT emergency_contacts_pkey PRIMARY KEY (id);


--
-- Name: friend_requests friend_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friend_requests
    ADD CONSTRAINT friend_requests_pkey PRIMARY KEY (id);


--
-- Name: friendships friendships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friendships
    ADD CONSTRAINT friendships_pkey PRIMARY KEY (id);


--
-- Name: group_members group_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_members
    ADD CONSTRAINT group_members_pkey PRIMARY KEY (id);


--
-- Name: group_posts group_posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_posts
    ADD CONSTRAINT group_posts_pkey PRIMARY KEY (id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: hashtags hashtags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hashtags
    ADD CONSTRAINT hashtags_pkey PRIMARY KEY (id);


--
-- Name: health_agent_conversations health_agent_conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_agent_conversations
    ADD CONSTRAINT health_agent_conversations_pkey PRIMARY KEY (id);


--
-- Name: health_agent_messages health_agent_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_agent_messages
    ADD CONSTRAINT health_agent_messages_pkey PRIMARY KEY (id);


--
-- Name: health_embeddings health_embeddings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_embeddings
    ADD CONSTRAINT health_embeddings_pkey PRIMARY KEY (id);


--
-- Name: health_observation_logs health_observation_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_observation_logs
    ADD CONSTRAINT health_observation_logs_pkey PRIMARY KEY (id);


--
-- Name: karma_points karma_points_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.karma_points
    ADD CONSTRAINT karma_points_pkey PRIMARY KEY (id);


--
-- Name: measurement_raports measurement_raports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurement_raports
    ADD CONSTRAINT measurement_raports_pkey PRIMARY KEY (id);


--
-- Name: measurement_types measurement_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurement_types
    ADD CONSTRAINT measurement_types_pkey PRIMARY KEY (id);


--
-- Name: measurements measurements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.measurements
    ADD CONSTRAINT measurements_pkey PRIMARY KEY (id);


--
-- Name: medication_logs medication_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medication_logs
    ADD CONSTRAINT medication_logs_pkey PRIMARY KEY (id);


--
-- Name: medication_requests medication_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medication_requests
    ADD CONSTRAINT medication_requests_pkey PRIMARY KEY (id);


--
-- Name: medication_schedules medication_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medication_schedules
    ADD CONSTRAINT medication_schedules_pkey PRIMARY KEY (id);


--
-- Name: medications medications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medications
    ADD CONSTRAINT medications_pkey PRIMARY KEY (id);


--
-- Name: message_attachments message_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_attachments
    ADD CONSTRAINT message_attachments_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: note_disease_associations note_disease_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.note_disease_associations
    ADD CONSTRAINT note_disease_associations_pkey PRIMARY KEY (id);


--
-- Name: note_group_associations note_group_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.note_group_associations
    ADD CONSTRAINT note_group_associations_pkey PRIMARY KEY (id);


--
-- Name: note_groups note_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.note_groups
    ADD CONSTRAINT note_groups_pkey PRIMARY KEY (id);


--
-- Name: note_tag_associations note_tag_associations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.note_tag_associations
    ADD CONSTRAINT note_tag_associations_pkey PRIMARY KEY (id);


--
-- Name: note_tags note_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.note_tags
    ADD CONSTRAINT note_tags_pkey PRIMARY KEY (id);


--
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: poll_options poll_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_options
    ADD CONSTRAINT poll_options_pkey PRIMARY KEY (id);


--
-- Name: poll_votes poll_votes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.poll_votes
    ADD CONSTRAINT poll_votes_pkey PRIMARY KEY (id);


--
-- Name: post_bookmarks post_bookmarks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_bookmarks
    ADD CONSTRAINT post_bookmarks_pkey PRIMARY KEY (id);


--
-- Name: post_hashtags post_hashtags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_hashtags
    ADD CONSTRAINT post_hashtags_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: predefined_diseases predefined_diseases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.predefined_diseases
    ADD CONSTRAINT predefined_diseases_pkey PRIMARY KEY (id);


--
-- Name: predefined_symptoms predefined_symptoms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.predefined_symptoms
    ADD CONSTRAINT predefined_symptoms_pkey PRIMARY KEY (id);


--
-- Name: reactions reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reactions
    ADD CONSTRAINT reactions_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: shared_accesses shared_accesses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shared_accesses
    ADD CONSTRAINT shared_accesses_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_blocked_executions solid_queue_blocked_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_blocked_executions
    ADD CONSTRAINT solid_queue_blocked_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_claimed_executions solid_queue_claimed_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_claimed_executions
    ADD CONSTRAINT solid_queue_claimed_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_failed_executions solid_queue_failed_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_failed_executions
    ADD CONSTRAINT solid_queue_failed_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_jobs solid_queue_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_jobs
    ADD CONSTRAINT solid_queue_jobs_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_pauses solid_queue_pauses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_pauses
    ADD CONSTRAINT solid_queue_pauses_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_processes solid_queue_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_processes
    ADD CONSTRAINT solid_queue_processes_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_ready_executions solid_queue_ready_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_ready_executions
    ADD CONSTRAINT solid_queue_ready_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_recurring_executions solid_queue_recurring_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_executions
    ADD CONSTRAINT solid_queue_recurring_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_recurring_tasks solid_queue_recurring_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_recurring_tasks
    ADD CONSTRAINT solid_queue_recurring_tasks_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_scheduled_executions solid_queue_scheduled_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_scheduled_executions
    ADD CONSTRAINT solid_queue_scheduled_executions_pkey PRIMARY KEY (id);


--
-- Name: solid_queue_semaphores solid_queue_semaphores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.solid_queue_semaphores
    ADD CONSTRAINT solid_queue_semaphores_pkey PRIMARY KEY (id);


--
-- Name: specialist_appointments specialist_appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialist_appointments
    ADD CONSTRAINT specialist_appointments_pkey PRIMARY KEY (id);


--
-- Name: specialist_messages specialist_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialist_messages
    ADD CONSTRAINT specialist_messages_pkey PRIMARY KEY (id);


--
-- Name: specialist_note_attachments specialist_note_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialist_note_attachments
    ADD CONSTRAINT specialist_note_attachments_pkey PRIMARY KEY (id);


--
-- Name: specialist_notes specialist_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialist_notes
    ADD CONSTRAINT specialist_notes_pkey PRIMARY KEY (id);


--
-- Name: specialist_notifications specialist_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialist_notifications
    ADD CONSTRAINT specialist_notifications_pkey PRIMARY KEY (id);


--
-- Name: specialist_patients specialist_patients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialist_patients
    ADD CONSTRAINT specialist_patients_pkey PRIMARY KEY (id);


--
-- Name: specialist_recommendations specialist_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialist_recommendations
    ADD CONSTRAINT specialist_recommendations_pkey PRIMARY KEY (id);


--
-- Name: specialist_referral_clicks specialist_referral_clicks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialist_referral_clicks
    ADD CONSTRAINT specialist_referral_clicks_pkey PRIMARY KEY (id);


--
-- Name: specialist_requests specialist_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialist_requests
    ADD CONSTRAINT specialist_requests_pkey PRIMARY KEY (id);


--
-- Name: specialist_schedules specialist_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialist_schedules
    ADD CONSTRAINT specialist_schedules_pkey PRIMARY KEY (id);


--
-- Name: specialists specialists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialists
    ADD CONSTRAINT specialists_pkey PRIMARY KEY (id);


--
-- Name: treatment_diseases treatment_diseases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.treatment_diseases
    ADD CONSTRAINT treatment_diseases_pkey PRIMARY KEY (id);


--
-- Name: treatment_requests treatment_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.treatment_requests
    ADD CONSTRAINT treatment_requests_pkey PRIMARY KEY (id);


--
-- Name: treatment_updates treatment_updates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.treatment_updates
    ADD CONSTRAINT treatment_updates_pkey PRIMARY KEY (id);


--
-- Name: treatments treatments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.treatments
    ADD CONSTRAINT treatments_pkey PRIMARY KEY (id);


--
-- Name: units units_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.units
    ADD CONSTRAINT units_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_on_account_id_reactable_type_reactable_id_d54a0ed989; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_account_id_reactable_type_reactable_id_d54a0ed989 ON public.reactions USING btree (account_id, reactable_type, reactable_id);


--
-- Name: idx_on_specialist_request_id_clicked_at_1fae2c9a75; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_specialist_request_id_clicked_at_1fae2c9a75 ON public.specialist_referral_clicks USING btree (specialist_request_id, clicked_at);


--
-- Name: index_accounts_on_badge; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_badge ON public.accounts USING btree (badge);


--
-- Name: index_accounts_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accounts_on_email ON public.accounts USING btree (email);


--
-- Name: index_accounts_on_karma_score; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_karma_score ON public.accounts USING btree (karma_score);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_admins_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_admins_on_email ON public.admins USING btree (email);


--
-- Name: index_ai_agent_conversations_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ai_agent_conversations_on_account_id ON public.ai_agent_conversations USING btree (account_id);


--
-- Name: index_ai_agent_conversations_on_account_id_and_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ai_agent_conversations_on_account_id_and_updated_at ON public.ai_agent_conversations USING btree (account_id, updated_at);


--
-- Name: index_ai_agent_messages_on_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ai_agent_messages_on_conversation_id ON public.ai_agent_messages USING btree (conversation_id);


--
-- Name: index_ai_agent_messages_on_conversation_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ai_agent_messages_on_conversation_id_and_created_at ON public.ai_agent_messages USING btree (conversation_id, created_at);


--
-- Name: index_article_tags_articles_on_article_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_article_tags_articles_on_article_id ON public.article_tags_articles USING btree (article_id);


--
-- Name: index_article_tags_articles_on_article_id_and_article_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_article_tags_articles_on_article_id_and_article_tag_id ON public.article_tags_articles USING btree (article_id, article_tag_id);


--
-- Name: index_article_tags_articles_on_article_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_article_tags_articles_on_article_tag_id ON public.article_tags_articles USING btree (article_tag_id);


--
-- Name: index_articles_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_articles_on_account_id ON public.articles USING btree (account_id);


--
-- Name: index_behavior_sequences_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_behavior_sequences_on_account_id ON public.behavior_sequences USING btree (account_id);


--
-- Name: index_behavior_sequences_on_account_id_and_adherence_score; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_behavior_sequences_on_account_id_and_adherence_score ON public.behavior_sequences USING btree (account_id, adherence_score);


--
-- Name: index_behavior_sequences_on_account_id_and_sequence_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_behavior_sequences_on_account_id_and_sequence_type ON public.behavior_sequences USING btree (account_id, sequence_type);


--
-- Name: index_caregivers_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_caregivers_on_account_id ON public.caregivers USING btree (account_id);


--
-- Name: index_caregivers_on_account_id_and_is_accepted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_caregivers_on_account_id_and_is_accepted ON public.caregivers USING btree (account_id, is_accepted);


--
-- Name: index_caregivers_on_caregiver_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_caregivers_on_caregiver_account_id ON public.caregivers USING btree (caregiver_account_id);


--
-- Name: index_caregivers_on_caregiver_account_id_and_is_accepted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_caregivers_on_caregiver_account_id_and_is_accepted ON public.caregivers USING btree (caregiver_account_id, is_accepted);


--
-- Name: index_chatroom_messages_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chatroom_messages_on_account_id ON public.chatroom_messages USING btree (account_id);


--
-- Name: index_chatroom_messages_on_chatroom_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chatroom_messages_on_chatroom_id ON public.chatroom_messages USING btree (chatroom_id);


--
-- Name: index_chatroom_messages_on_message_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chatroom_messages_on_message_type ON public.chatroom_messages USING btree (message_type);


--
-- Name: index_chatroom_messages_on_read_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chatroom_messages_on_read_at ON public.chatroom_messages USING btree (read_at);


--
-- Name: index_chatroom_participants_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chatroom_participants_on_account_id ON public.chatroom_participants USING btree (account_id);


--
-- Name: index_chatroom_participants_on_account_id_and_chatroom_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_chatroom_participants_on_account_id_and_chatroom_id ON public.chatroom_participants USING btree (account_id, chatroom_id);


--
-- Name: index_chatroom_participants_on_chatroom_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chatroom_participants_on_chatroom_id ON public.chatroom_participants USING btree (chatroom_id);


--
-- Name: index_chatrooms_on_account1_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chatrooms_on_account1_id ON public.chatrooms USING btree (account1_id);


--
-- Name: index_chatrooms_on_account1_id_and_account2_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_chatrooms_on_account1_id_and_account2_id ON public.chatrooms USING btree (account1_id, account2_id);


--
-- Name: index_chatrooms_on_account2_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chatrooms_on_account2_id ON public.chatrooms USING btree (account2_id);


--
-- Name: index_clinical_documents_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_clinical_documents_on_account_id ON public.clinical_documents USING btree (account_id);


--
-- Name: index_clinical_documents_on_ai_processed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_clinical_documents_on_ai_processed ON public.clinical_documents USING btree (ai_processed);


--
-- Name: index_clinical_documents_on_document_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_clinical_documents_on_document_type ON public.clinical_documents USING btree (document_type);


--
-- Name: index_clinical_documents_on_uploaded_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_clinical_documents_on_uploaded_by_id ON public.clinical_documents USING btree (uploaded_by_id);


--
-- Name: index_comments_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_account_id ON public.comments USING btree (account_id);


--
-- Name: index_comments_on_commentable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_commentable ON public.comments USING btree (commentable_type, commentable_id);


--
-- Name: index_comments_on_commentable_type_and_commentable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_commentable_type_and_commentable_id ON public.comments USING btree (commentable_type, commentable_id);


--
-- Name: index_comments_on_expert_pinned_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_expert_pinned_at ON public.comments USING btree (expert_pinned_at);


--
-- Name: index_conv_participants_on_account_conv; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_conv_participants_on_account_conv ON public.conversation_participants USING btree (account_id, conversation_id);


--
-- Name: index_conversation_participants_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversation_participants_on_account_id ON public.conversation_participants USING btree (account_id);


--
-- Name: index_conversation_participants_on_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversation_participants_on_conversation_id ON public.conversation_participants USING btree (conversation_id);


--
-- Name: index_disease_photos_on_disease_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_disease_photos_on_disease_id ON public.disease_photos USING btree (disease_id);


--
-- Name: index_disease_risk_factors_on_disease_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_disease_risk_factors_on_disease_id ON public.disease_risk_factors USING btree (disease_id);


--
-- Name: index_disease_statuses_on_disease_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_disease_statuses_on_disease_id ON public.disease_statuses USING btree (disease_id);


--
-- Name: index_disease_statuses_on_hidden; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_disease_statuses_on_hidden ON public.disease_statuses USING btree (hidden);


--
-- Name: index_disease_symptom_updates_on_disease_symptom_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_disease_symptom_updates_on_disease_symptom_id ON public.disease_symptom_updates USING btree (disease_symptom_id);


--
-- Name: index_disease_symptoms_on_disease_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_disease_symptoms_on_disease_id ON public.disease_symptoms USING btree (disease_id);


--
-- Name: index_diseases_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_diseases_on_account_id ON public.diseases USING btree (account_id);


--
-- Name: index_diseases_on_disease_category_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_diseases_on_disease_category_id ON public.diseases USING btree (disease_category_id);


--
-- Name: index_diseases_on_predefined_disease_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_diseases_on_predefined_disease_id ON public.diseases USING btree (predefined_disease_id);


--
-- Name: index_emergency_alerts_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_emergency_alerts_on_account_id ON public.emergency_alerts USING btree (account_id);


--
-- Name: index_emergency_alerts_on_account_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_emergency_alerts_on_account_id_and_status ON public.emergency_alerts USING btree (account_id, status);


--
-- Name: index_emergency_alerts_on_alert_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_emergency_alerts_on_alert_type ON public.emergency_alerts USING btree (alert_type);


--
-- Name: index_emergency_alerts_on_triggered_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_emergency_alerts_on_triggered_by ON public.emergency_alerts USING btree (triggered_by_type, triggered_by_id);


--
-- Name: index_emergency_contacts_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_emergency_contacts_on_account_id ON public.emergency_contacts USING btree (account_id);


--
-- Name: index_emergency_contacts_on_account_id_and_is_primary; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_emergency_contacts_on_account_id_and_is_primary ON public.emergency_contacts USING btree (account_id, is_primary);


--
-- Name: index_friend_requests_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_friend_requests_on_account_id ON public.friend_requests USING btree (account_id);


--
-- Name: index_friend_requests_on_account_id_and_friend_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_friend_requests_on_account_id_and_friend_id ON public.friend_requests USING btree (account_id, friend_id);


--
-- Name: index_friend_requests_on_friend_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_friend_requests_on_friend_id ON public.friend_requests USING btree (friend_id);


--
-- Name: index_friendships_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_friendships_on_account_id ON public.friendships USING btree (account_id);


--
-- Name: index_friendships_on_account_id_and_friend_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_friendships_on_account_id_and_friend_id ON public.friendships USING btree (account_id, friend_id);


--
-- Name: index_friendships_on_friend_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_friendships_on_friend_id ON public.friendships USING btree (friend_id);


--
-- Name: index_group_members_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_members_on_account_id ON public.group_members USING btree (account_id);


--
-- Name: index_group_members_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_members_on_group_id ON public.group_members USING btree (group_id);


--
-- Name: index_group_members_on_group_id_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_group_members_on_group_id_and_account_id ON public.group_members USING btree (group_id, account_id);


--
-- Name: index_group_members_on_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_members_on_role ON public.group_members USING btree (role);


--
-- Name: index_group_posts_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_posts_on_account_id ON public.group_posts USING btree (account_id);


--
-- Name: index_group_posts_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_posts_on_group_id ON public.group_posts USING btree (group_id);


--
-- Name: index_groups_on_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_on_category ON public.groups USING btree (category);


--
-- Name: index_groups_on_predefined_disease_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_on_predefined_disease_id ON public.groups USING btree (predefined_disease_id);


--
-- Name: index_hashtags_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_hashtags_on_name ON public.hashtags USING btree (name);


--
-- Name: index_hashtags_on_trending_score; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hashtags_on_trending_score ON public.hashtags USING btree (trending_score);


--
-- Name: index_health_agent_conversations_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_agent_conversations_on_account_id ON public.health_agent_conversations USING btree (account_id);


--
-- Name: index_health_agent_conversations_on_persona; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_agent_conversations_on_persona ON public.health_agent_conversations USING btree (persona);


--
-- Name: index_health_agent_conversations_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_agent_conversations_on_status ON public.health_agent_conversations USING btree (status);


--
-- Name: index_health_agent_messages_on_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_agent_messages_on_conversation_id ON public.health_agent_messages USING btree (conversation_id);


--
-- Name: index_health_agent_messages_on_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_agent_messages_on_role ON public.health_agent_messages USING btree (role);


--
-- Name: index_health_embeddings_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_embeddings_on_account_id ON public.health_embeddings USING btree (account_id);


--
-- Name: index_health_embeddings_on_embedding_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_embeddings_on_embedding_type ON public.health_embeddings USING btree (embedding_type);


--
-- Name: index_health_embeddings_on_validated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_embeddings_on_validated ON public.health_embeddings USING btree (validated);


--
-- Name: index_health_observation_logs_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_observation_logs_on_account_id ON public.health_observation_logs USING btree (account_id);


--
-- Name: index_health_observation_logs_on_observation_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_observation_logs_on_observation_type ON public.health_observation_logs USING btree (observation_type);


--
-- Name: index_health_observation_logs_on_specialist_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_observation_logs_on_specialist_id ON public.health_observation_logs USING btree (specialist_id);


--
-- Name: index_health_observation_logs_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_observation_logs_on_status ON public.health_observation_logs USING btree (status);


--
-- Name: index_karma_points_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_karma_points_on_account_id ON public.karma_points USING btree (account_id);


--
-- Name: index_karma_points_on_account_id_and_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_karma_points_on_account_id_and_post_id ON public.karma_points USING btree (account_id, post_id);


--
-- Name: index_karma_points_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_karma_points_on_post_id ON public.karma_points USING btree (post_id);


--
-- Name: index_measurement_raports_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_measurement_raports_on_account_id ON public.measurement_raports USING btree (account_id);


--
-- Name: index_measurements_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_measurements_on_account_id ON public.measurements USING btree (account_id);


--
-- Name: index_measurements_on_measurement_type_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_measurements_on_measurement_type_id ON public.measurements USING btree (measurement_type_id);


--
-- Name: index_med_schedules_on_med_id_and_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_med_schedules_on_med_id_and_is_active ON public.medication_schedules USING btree (medication_id, is_active, scheduled_time);


--
-- Name: index_medication_logs_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_medication_logs_on_account_id ON public.medication_logs USING btree (account_id);


--
-- Name: index_medication_logs_on_medication_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_medication_logs_on_medication_id ON public.medication_logs USING btree (medication_id);


--
-- Name: index_medication_logs_on_medication_schedule_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_medication_logs_on_medication_schedule_id ON public.medication_logs USING btree (medication_schedule_id);


--
-- Name: index_medication_logs_on_scheduled_for; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_medication_logs_on_scheduled_for ON public.medication_logs USING btree (scheduled_for);


--
-- Name: index_medication_requests_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_medication_requests_on_account_id ON public.medication_requests USING btree (account_id);


--
-- Name: index_medication_requests_on_specialist_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_medication_requests_on_specialist_id_and_status ON public.medication_requests USING btree (specialist_id, status);


--
-- Name: index_medication_schedules_on_medication_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_medication_schedules_on_medication_id ON public.medication_schedules USING btree (medication_id);


--
-- Name: index_medications_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_medications_on_account_id ON public.medications USING btree (account_id);


--
-- Name: index_medications_on_account_id_and_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_medications_on_account_id_and_is_active ON public.medications USING btree (account_id, is_active);


--
-- Name: index_medications_on_medication_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_medications_on_medication_request_id ON public.medications USING btree (medication_request_id);


--
-- Name: index_medications_on_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_medications_on_source ON public.medications USING btree (source);


--
-- Name: index_medications_on_specialist_recommendation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_medications_on_specialist_recommendation_id ON public.medications USING btree (specialist_recommendation_id);


--
-- Name: index_message_attachments_on_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_message_attachments_on_message_id ON public.message_attachments USING btree (message_id);


--
-- Name: index_messages_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_account_id ON public.messages USING btree (account_id);


--
-- Name: index_messages_on_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_conversation_id ON public.messages USING btree (conversation_id);


--
-- Name: index_messages_on_conversation_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_conversation_id_and_created_at ON public.messages USING btree (conversation_id, created_at);


--
-- Name: index_note_disease_associations_on_disease_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_note_disease_associations_on_disease_id ON public.note_disease_associations USING btree (disease_id);


--
-- Name: index_note_disease_associations_on_note_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_note_disease_associations_on_note_id ON public.note_disease_associations USING btree (note_id);


--
-- Name: index_note_disease_associations_on_note_id_and_disease_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_note_disease_associations_on_note_id_and_disease_id ON public.note_disease_associations USING btree (note_id, disease_id);


--
-- Name: index_note_group_associations_on_note_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_note_group_associations_on_note_group_id ON public.note_group_associations USING btree (note_group_id);


--
-- Name: index_note_group_associations_on_note_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_note_group_associations_on_note_id ON public.note_group_associations USING btree (note_id);


--
-- Name: index_note_group_associations_on_note_id_and_note_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_note_group_associations_on_note_id_and_note_group_id ON public.note_group_associations USING btree (note_id, note_group_id);


--
-- Name: index_note_groups_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_note_groups_on_account_id ON public.note_groups USING btree (account_id);


--
-- Name: index_note_tag_associations_on_note_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_note_tag_associations_on_note_id ON public.note_tag_associations USING btree (note_id);


--
-- Name: index_note_tag_associations_on_note_id_and_note_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_note_tag_associations_on_note_id_and_note_tag_id ON public.note_tag_associations USING btree (note_id, note_tag_id);


--
-- Name: index_note_tag_associations_on_note_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_note_tag_associations_on_note_tag_id ON public.note_tag_associations USING btree (note_tag_id);


--
-- Name: index_note_tags_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_note_tags_on_account_id ON public.note_tags USING btree (account_id);


--
-- Name: index_notes_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notes_on_account_id ON public.notes USING btree (account_id);


--
-- Name: index_notifications_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_account_id ON public.notifications USING btree (account_id);


--
-- Name: index_notifications_on_account_id_and_notification_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_account_id_and_notification_type ON public.notifications USING btree (account_id, notification_type);


--
-- Name: index_notifications_on_account_id_and_read_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_account_id_and_read_at ON public.notifications USING btree (account_id, read_at);


--
-- Name: index_notifications_on_notifiable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_notifications_on_notifiable ON public.notifications USING btree (notifiable_type, notifiable_id);


--
-- Name: index_poll_options_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_poll_options_on_post_id ON public.poll_options USING btree (post_id);


--
-- Name: index_poll_votes_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_poll_votes_on_account_id ON public.poll_votes USING btree (account_id);


--
-- Name: index_poll_votes_on_poll_option_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_poll_votes_on_poll_option_id ON public.poll_votes USING btree (poll_option_id);


--
-- Name: index_poll_votes_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_poll_votes_unique ON public.poll_votes USING btree (account_id, poll_option_id);


--
-- Name: index_post_bookmarks_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_bookmarks_on_account_id ON public.post_bookmarks USING btree (account_id);


--
-- Name: index_post_bookmarks_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_bookmarks_on_post_id ON public.post_bookmarks USING btree (post_id);


--
-- Name: index_post_bookmarks_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_post_bookmarks_unique ON public.post_bookmarks USING btree (account_id, post_id);


--
-- Name: index_post_hashtags_on_hashtag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_hashtags_on_hashtag_id ON public.post_hashtags USING btree (hashtag_id);


--
-- Name: index_post_hashtags_on_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_post_hashtags_on_post_id ON public.post_hashtags USING btree (post_id);


--
-- Name: index_post_hashtags_on_post_id_and_hashtag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_post_hashtags_on_post_id_and_hashtag_id ON public.post_hashtags USING btree (post_id, hashtag_id);


--
-- Name: index_posts_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_account_id ON public.posts USING btree (account_id);


--
-- Name: index_posts_on_bookmark_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_bookmark_count ON public.posts USING btree (bookmark_count);


--
-- Name: index_posts_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_group_id ON public.posts USING btree (group_id);


--
-- Name: index_posts_on_pinned_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_pinned_at ON public.posts USING btree (pinned_at);


--
-- Name: index_posts_on_poll_votes_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_poll_votes_count ON public.posts USING btree (poll_votes_count);


--
-- Name: index_posts_on_post_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_post_type ON public.posts USING btree (post_type);


--
-- Name: index_posts_on_quote_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_quote_count ON public.posts USING btree (quote_count);


--
-- Name: index_posts_on_quoted_post_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_posts_on_quoted_post_id ON public.posts USING btree (quoted_post_id);


--
-- Name: index_predefined_diseases_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_predefined_diseases_on_name ON public.predefined_diseases USING btree (name);


--
-- Name: index_predefined_diseases_on_special; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_predefined_diseases_on_special ON public.predefined_diseases USING btree (special);


--
-- Name: index_predefined_symptoms_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_predefined_symptoms_on_name ON public.predefined_symptoms USING btree (name);


--
-- Name: index_reactions_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reactions_on_account_id ON public.reactions USING btree (account_id);


--
-- Name: index_reactions_on_reactable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reactions_on_reactable ON public.reactions USING btree (reactable_type, reactable_id);


--
-- Name: index_roles_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_roles_on_name ON public.roles USING btree (name);


--
-- Name: index_shared_accesses_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shared_accesses_on_account_id ON public.shared_accesses USING btree (account_id);


--
-- Name: index_shared_accesses_on_account_share; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shared_accesses_on_account_share ON public.shared_accesses USING btree (account_id, shareable_type, shareable_id);


--
-- Name: index_shared_accesses_on_shareable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shared_accesses_on_shareable ON public.shared_accesses USING btree (shareable_type, shareable_id);


--
-- Name: index_shared_accesses_on_shared_with; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shared_accesses_on_shared_with ON public.shared_accesses USING btree (shared_with_account_id);


--
-- Name: index_solid_queue_blocked_executions_for_maintenance; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_blocked_executions_for_maintenance ON public.solid_queue_blocked_executions USING btree (expires_at, concurrency_key);


--
-- Name: index_solid_queue_blocked_executions_for_release; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_blocked_executions_for_release ON public.solid_queue_blocked_executions USING btree (concurrency_key, priority, job_id);


--
-- Name: index_solid_queue_blocked_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_blocked_executions_on_job_id ON public.solid_queue_blocked_executions USING btree (job_id);


--
-- Name: index_solid_queue_claimed_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_claimed_executions_on_job_id ON public.solid_queue_claimed_executions USING btree (job_id);


--
-- Name: index_solid_queue_claimed_executions_on_process_id_and_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_claimed_executions_on_process_id_and_job_id ON public.solid_queue_claimed_executions USING btree (process_id, job_id);


--
-- Name: index_solid_queue_dispatch_all; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_dispatch_all ON public.solid_queue_scheduled_executions USING btree (scheduled_at, priority, job_id);


--
-- Name: index_solid_queue_failed_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_failed_executions_on_job_id ON public.solid_queue_failed_executions USING btree (job_id);


--
-- Name: index_solid_queue_jobs_for_alerting; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_for_alerting ON public.solid_queue_jobs USING btree (scheduled_at, finished_at);


--
-- Name: index_solid_queue_jobs_for_filtering; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_for_filtering ON public.solid_queue_jobs USING btree (queue_name, finished_at);


--
-- Name: index_solid_queue_jobs_on_active_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_active_job_id ON public.solid_queue_jobs USING btree (active_job_id);


--
-- Name: index_solid_queue_jobs_on_class_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_class_name ON public.solid_queue_jobs USING btree (class_name);


--
-- Name: index_solid_queue_jobs_on_finished_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_jobs_on_finished_at ON public.solid_queue_jobs USING btree (finished_at);


--
-- Name: index_solid_queue_pauses_on_queue_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_pauses_on_queue_name ON public.solid_queue_pauses USING btree (queue_name);


--
-- Name: index_solid_queue_poll_all; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_poll_all ON public.solid_queue_ready_executions USING btree (priority, job_id);


--
-- Name: index_solid_queue_poll_by_queue; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_poll_by_queue ON public.solid_queue_ready_executions USING btree (queue_name, priority, job_id);


--
-- Name: index_solid_queue_processes_on_last_heartbeat_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_processes_on_last_heartbeat_at ON public.solid_queue_processes USING btree (last_heartbeat_at);


--
-- Name: index_solid_queue_processes_on_name_and_supervisor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_processes_on_name_and_supervisor_id ON public.solid_queue_processes USING btree (name, supervisor_id);


--
-- Name: index_solid_queue_processes_on_supervisor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_processes_on_supervisor_id ON public.solid_queue_processes USING btree (supervisor_id);


--
-- Name: index_solid_queue_ready_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_ready_executions_on_job_id ON public.solid_queue_ready_executions USING btree (job_id);


--
-- Name: index_solid_queue_recurring_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_executions_on_job_id ON public.solid_queue_recurring_executions USING btree (job_id);


--
-- Name: index_solid_queue_recurring_executions_on_task_key_and_run_at; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_executions_on_task_key_and_run_at ON public.solid_queue_recurring_executions USING btree (task_key, run_at);


--
-- Name: index_solid_queue_recurring_tasks_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_recurring_tasks_on_key ON public.solid_queue_recurring_tasks USING btree (key);


--
-- Name: index_solid_queue_recurring_tasks_on_static; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_recurring_tasks_on_static ON public.solid_queue_recurring_tasks USING btree (static);


--
-- Name: index_solid_queue_scheduled_executions_on_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_scheduled_executions_on_job_id ON public.solid_queue_scheduled_executions USING btree (job_id);


--
-- Name: index_solid_queue_semaphores_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_semaphores_on_expires_at ON public.solid_queue_semaphores USING btree (expires_at);


--
-- Name: index_solid_queue_semaphores_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_solid_queue_semaphores_on_key ON public.solid_queue_semaphores USING btree (key);


--
-- Name: index_solid_queue_semaphores_on_key_and_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_solid_queue_semaphores_on_key_and_value ON public.solid_queue_semaphores USING btree (key, value);


--
-- Name: index_spec_recommendations_on_spec_id_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_spec_recommendations_on_spec_id_and_account_id ON public.specialist_recommendations USING btree (specialist_id, account_id);


--
-- Name: index_specialist_appointments_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_appointments_on_patient_id ON public.specialist_appointments USING btree (patient_id);


--
-- Name: index_specialist_appointments_on_schedule_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_appointments_on_schedule_id ON public.specialist_appointments USING btree (schedule_id);


--
-- Name: index_specialist_appointments_on_specialist_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_appointments_on_specialist_id ON public.specialist_appointments USING btree (specialist_id);


--
-- Name: index_specialist_messages_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_messages_on_account_id ON public.specialist_messages USING btree (account_id);


--
-- Name: index_specialist_messages_on_is_read; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_messages_on_is_read ON public.specialist_messages USING btree (is_read);


--
-- Name: index_specialist_messages_on_sender_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_messages_on_sender_type ON public.specialist_messages USING btree (sender_type);


--
-- Name: index_specialist_messages_on_specialist_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_messages_on_specialist_id ON public.specialist_messages USING btree (specialist_id);


--
-- Name: index_specialist_messages_on_specialist_id_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_messages_on_specialist_id_and_account_id ON public.specialist_messages USING btree (specialist_id, account_id);


--
-- Name: index_specialist_note_attachments_on_specialist_note_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_note_attachments_on_specialist_note_id ON public.specialist_note_attachments USING btree (specialist_note_id);


--
-- Name: index_specialist_notes_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_notes_on_account_id ON public.specialist_notes USING btree (account_id);


--
-- Name: index_specialist_notes_on_specialist_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_notes_on_specialist_id ON public.specialist_notes USING btree (specialist_id);


--
-- Name: index_specialist_notes_on_specialist_id_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_notes_on_specialist_id_and_account_id ON public.specialist_notes USING btree (specialist_id, account_id);


--
-- Name: index_specialist_notifications_on_notifiable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_notifications_on_notifiable ON public.specialist_notifications USING btree (notifiable_type, notifiable_id);


--
-- Name: index_specialist_notifications_on_notification_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_notifications_on_notification_type ON public.specialist_notifications USING btree (notification_type);


--
-- Name: index_specialist_notifications_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_notifications_on_patient_id ON public.specialist_notifications USING btree (patient_id);


--
-- Name: index_specialist_notifications_on_specialist_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_notifications_on_specialist_id ON public.specialist_notifications USING btree (specialist_id);


--
-- Name: index_specialist_notifications_on_specialist_id_and_is_read; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_notifications_on_specialist_id_and_is_read ON public.specialist_notifications USING btree (specialist_id, is_read);


--
-- Name: index_specialist_patients_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_patients_on_account_id ON public.specialist_patients USING btree (account_id);


--
-- Name: index_specialist_patients_on_specialist_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_patients_on_specialist_id ON public.specialist_patients USING btree (specialist_id);


--
-- Name: index_specialist_patients_on_specialist_id_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_specialist_patients_on_specialist_id_and_account_id ON public.specialist_patients USING btree (specialist_id, account_id);


--
-- Name: index_specialist_patients_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_patients_on_status ON public.specialist_patients USING btree (status);


--
-- Name: index_specialist_recommendations_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_recommendations_on_account_id ON public.specialist_recommendations USING btree (account_id);


--
-- Name: index_specialist_recommendations_on_specialist_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_recommendations_on_specialist_id ON public.specialist_recommendations USING btree (specialist_id);


--
-- Name: index_specialist_recommendations_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_recommendations_on_status ON public.specialist_recommendations USING btree (status);


--
-- Name: index_specialist_referral_clicks_on_specialist_request_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_referral_clicks_on_specialist_request_id ON public.specialist_referral_clicks USING btree (specialist_request_id);


--
-- Name: index_specialist_requests_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_requests_on_account_id ON public.specialist_requests USING btree (account_id);


--
-- Name: index_specialist_requests_on_hash_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_specialist_requests_on_hash_code ON public.specialist_requests USING btree (hash_code);


--
-- Name: index_specialist_requests_on_specialist_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_requests_on_specialist_id ON public.specialist_requests USING btree (specialist_id);


--
-- Name: index_specialist_requests_on_specialist_id_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_specialist_requests_on_specialist_id_and_account_id ON public.specialist_requests USING btree (specialist_id, account_id);


--
-- Name: index_specialist_schedules_on_specialist_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialist_schedules_on_specialist_id ON public.specialist_schedules USING btree (specialist_id);


--
-- Name: index_specialists_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_specialists_on_user_id ON public.specialists USING btree (user_id);


--
-- Name: index_treatment_diseases_on_disease_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_treatment_diseases_on_disease_id ON public.treatment_diseases USING btree (disease_id);


--
-- Name: index_treatment_diseases_on_treatment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_treatment_diseases_on_treatment_id ON public.treatment_diseases USING btree (treatment_id);


--
-- Name: index_treatment_diseases_on_treatment_id_and_disease_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_treatment_diseases_on_treatment_id_and_disease_id ON public.treatment_diseases USING btree (treatment_id, disease_id);


--
-- Name: index_treatment_requests_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_treatment_requests_on_account_id ON public.treatment_requests USING btree (account_id);


--
-- Name: index_treatment_requests_on_account_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_treatment_requests_on_account_id_and_status ON public.treatment_requests USING btree (account_id, status);


--
-- Name: index_treatment_requests_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_treatment_requests_on_status ON public.treatment_requests USING btree (status);


--
-- Name: index_treatment_updates_on_treatment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_treatment_updates_on_treatment_id ON public.treatment_updates USING btree (treatment_id);


--
-- Name: index_treatments_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_treatments_on_account_id ON public.treatments USING btree (account_id);


--
-- Name: index_treatments_on_account_id_and_approval_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_treatments_on_account_id_and_approval_status ON public.treatments USING btree (account_id, approval_status);


--
-- Name: index_treatments_on_approval_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_treatments_on_approval_status ON public.treatments USING btree (approval_status);


--
-- Name: index_treatments_on_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_treatments_on_source ON public.treatments USING btree (source);


--
-- Name: index_treatments_on_specialist_recommendation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_treatments_on_specialist_recommendation_id ON public.treatments USING btree (specialist_recommendation_id);


--
-- Name: index_user_roles_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_roles_on_role_id ON public.user_roles USING btree (role_id);


--
-- Name: index_user_roles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_roles_on_user_id ON public.user_roles USING btree (user_id);


--
-- Name: index_user_roles_on_user_id_and_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_roles_on_user_id_and_role_id ON public.user_roles USING btree (user_id, role_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: accounts accounts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: chatrooms fk_rails_0de4cd98ec; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chatrooms
    ADD CONSTRAINT fk_rails_0de4cd98ec FOREIGN KEY (account1_id) REFERENCES public.accounts(id);


--
-- Name: health_agent_messages fk_rails_10f12580e3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_agent_messages
    ADD CONSTRAINT fk_rails_10f12580e3 FOREIGN KEY (conversation_id) REFERENCES public.health_agent_conversations(id);


--
-- Name: conversation_participants fk_rails_16e436cb91; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_participants
    ADD CONSTRAINT fk_rails_16e436cb91 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: health_agent_conversations fk_rails_215af2d6e1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_agent_conversations
    ADD CONSTRAINT fk_rails_215af2d6e1 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: chatroom_messages fk_rails_2319e79597; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chatroom_messages
    ADD CONSTRAINT fk_rails_2319e79597 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: chatrooms fk_rails_2464bc771b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chatrooms
    ADD CONSTRAINT fk_rails_2464bc771b FOREIGN KEY (account2_id) REFERENCES public.accounts(id);


--
-- Name: health_observation_logs fk_rails_2b04c905a4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_observation_logs
    ADD CONSTRAINT fk_rails_2b04c905a4 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: behavior_sequences fk_rails_3056937f5c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.behavior_sequences
    ADD CONSTRAINT fk_rails_3056937f5c FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: medications fk_rails_4689b8b800; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medications
    ADD CONSTRAINT fk_rails_4689b8b800 FOREIGN KEY (medication_request_id) REFERENCES public.medication_requests(id) NOT VALID;


--
-- Name: health_embeddings fk_rails_59356af1e9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_embeddings
    ADD CONSTRAINT fk_rails_59356af1e9 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: chatroom_messages fk_rails_5bf1498e71; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chatroom_messages
    ADD CONSTRAINT fk_rails_5bf1498e71 FOREIGN KEY (chatroom_id) REFERENCES public.chatrooms(id);


--
-- Name: clinical_documents fk_rails_5c2eae50ad; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clinical_documents
    ADD CONSTRAINT fk_rails_5c2eae50ad FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: ai_agent_conversations fk_rails_757f0cc016; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_agent_conversations
    ADD CONSTRAINT fk_rails_757f0cc016 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: karma_points fk_rails_8babb3064c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.karma_points
    ADD CONSTRAINT fk_rails_8babb3064c FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: caregivers fk_rails_9b396db440; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caregivers
    ADD CONSTRAINT fk_rails_9b396db440 FOREIGN KEY (caregiver_account_id) REFERENCES public.accounts(id);


--
-- Name: caregivers fk_rails_a9cc1d3918; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caregivers
    ADD CONSTRAINT fk_rails_a9cc1d3918 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: chatroom_participants fk_rails_b2dda0fa76; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chatroom_participants
    ADD CONSTRAINT fk_rails_b2dda0fa76 FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: chatroom_participants fk_rails_b917650d55; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chatroom_participants
    ADD CONSTRAINT fk_rails_b917650d55 FOREIGN KEY (chatroom_id) REFERENCES public.chatrooms(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: diseases fk_rails_c7fa4b9806; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diseases
    ADD CONSTRAINT fk_rails_c7fa4b9806 FOREIGN KEY (disease_category_id) REFERENCES public.disease_categories(id);


--
-- Name: ai_agent_messages fk_rails_d409325e96; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_agent_messages
    ADD CONSTRAINT fk_rails_d409325e96 FOREIGN KEY (conversation_id) REFERENCES public.ai_agent_conversations(id);


--
-- Name: conversation_participants fk_rails_d4fdd4cae0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_participants
    ADD CONSTRAINT fk_rails_d4fdd4cae0 FOREIGN KEY (conversation_id) REFERENCES public.conversations(id);


--
-- Name: diseases fk_rails_e3c3bb4e1b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.diseases
    ADD CONSTRAINT fk_rails_e3c3bb4e1b FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- PostgreSQL database dump complete
--

\unrestrict aa2HbGJ7eejENrFsAWoAePzzOK8tad3QEULEDLk2YMNmhLLqApzHm69BqJt4rbd

