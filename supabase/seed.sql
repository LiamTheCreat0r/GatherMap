SET session_replication_role = replica;

--
-- PostgreSQL database dump
--

-- \restrict 6YtmxE3iRGLVOTd5k8sbFJGBt5J3bgp3s6W62c7trnNa5tPDuSIVPwt7CBeoEyD

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

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
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: custom_oauth_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: mfa_recovery_code_sets; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: mfa_recovery_codes; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_authorizations; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_client_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: oauth_consents; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: scim_tokens; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: scim_users; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: webauthn_challenges; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: webauthn_credentials; Type: TABLE DATA; Schema: auth; Owner: supabase_auth_admin
--



--
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."user" ("id", "created_at", "birthdate", "username", "name", "surname", "city", "email", "hash_password", "profile_picture", "private_account") VALUES
	(21, '2026-10-12 06:50:36.354511+00', '1990-01-01', 'admin', 'Admin', 'User', 'Test City', 'admin@example.test', '1234', NULL, false),
	(22, '2026-10-12 06:50:36.354511+00', '1995-05-12', 'alice', 'Alice', 'Example', 'Test City', 'alice@example.test', 'test-password-alice', NULL, false),
	(23, '2026-10-12 06:50:36.354511+00', '1992-09-23', 'bob', 'Bob', 'Example', 'Test City', 'bob@example.test', 'test-password-bob', NULL, true);


--
-- Data for Name: blocked_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."blocked_user" ("id", "blocked_at", "blocked_user", "user_who_blocked") VALUES
	(1, '2026-10-12 06:50:36.354511+00', 23, 22);


--
-- Data for Name: circle; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."circle" ("id", "created_at", "owner_id") VALUES
	(1, '2026-10-12 06:50:36.354511+00', 21);


--
-- Data for Name: event; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."event" ("id", "owner_id", "scheduled_at", "location", "created_at", "name", "emoji_icon", "color", "is_public") VALUES
	(4, 21, '2026-10-19 06:50:36.354511+00', 'Central Park', '2026-10-12 06:50:36.354511+00', 'Test Meetup', '🎉', '#F26419', true),
	(5, 22, '2026-10-26 06:50:36.354511+00', 'Community Hall', '2026-10-12 06:50:36.354511+00', 'Private Gathering', '☕', '#336699', false);


--
-- Data for Name: friend; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."friend" ("id", "friends_since", "user_id_1", "user_id_2") VALUES
	(1, '2026-10-12 06:50:36.354511+00', 21, 22);


--
-- Data for Name: chat; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."chat" ("id", "circle_id", "event_id", "friend_id") VALUES
	(1, 1, NULL, NULL),
	(2, NULL, 4, NULL),
	(3, NULL, NULL, 1);


--
-- Data for Name: circle_member; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."circle_member" ("id", "user_id", "circle_id", "created_at", "user_nickname") VALUES
	(1, 21, 1, '2026-10-12 06:50:36.354511+00', 'Organizer'),
	(2, 22, 1, '2026-10-12 06:50:36.354511+00', 'Ali');


--
-- Data for Name: event_invitation; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."event_invitation" ("id", "created_at", "accepted", "user_id", "event_id") VALUES
	(1, '2026-10-12 06:50:36.354511+00', true, 22, 4);


--
-- Data for Name: message; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "public"."message" ("id", "created_at", "image", "content", "sender_id", "chat_id") VALUES
	(1, '2026-10-12 06:50:36.354511+00', NULL, 'Welcome to the circle!', 21, 1),
	(2, '2026-10-12 06:50:36.354511+00', NULL, 'Looking forward to the meetup!', 22, 2),
	(3, '2026-10-12 06:50:36.354511+00', NULL, 'Hi Alice!', 21, 3);


--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

INSERT INTO "storage"."buckets" ("id", "name", "owner", "created_at", "updated_at", "public", "avif_autodetection", "file_size_limit", "allowed_mime_types", "owner_id", "type", "versioning_status", "lifecycle_configuration", "lifecycle_configuration_generation") VALUES
	('event images', 'event images', NULL, '2026-09-25 12:55:57.416046+00', '2026-09-25 12:55:57.416046+00', false, false, NULL, NULL, NULL, 'STANDARD', 'DISABLED', NULL, NULL);


--
-- Data for Name: buckets_analytics; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: buckets_vectors; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--

INSERT INTO "storage"."objects" ("id", "bucket_id", "name", "owner", "created_at", "updated_at", "last_accessed_at", "metadata", "version", "owner_id", "user_metadata", "archived_at", "is_delete_marker", "is_versioned") VALUES
	('9c028868-1786-425a-a1e5-06eab2b4ac9c', 'event images', '.emptyFolderPlaceholder', NULL, '2026-09-25 12:56:32.226159+00', '2026-09-25 12:56:32.226159+00', '2026-09-25 12:56:32.226159+00', '{"eTag": "\"d41d8cd98f00b204e9800998ecf8427e\"", "size": 0, "mimetype": "application/octet-stream", "cacheControl": "max-age=3600", "lastModified": "2026-09-25T12:56:32.225Z", "contentLength": 0, "httpStatusCode": 200}', '760e8230-4eb1-4cef-9e70-435ee759d38e', NULL, '{}', NULL, false, false);


--
-- Data for Name: s3_multipart_uploads; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: s3_multipart_uploads_parts; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Data for Name: vector_indexes; Type: TABLE DATA; Schema: storage; Owner: supabase_storage_admin
--



--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: supabase_auth_admin
--

SELECT pg_catalog.setval('"auth"."refresh_tokens_id_seq"', 1, false);


--
-- Name: blocked_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"public"."blocked_user_id_seq"', 1, true);


--
-- Name: chat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"public"."chat_id_seq"', 3, true);


--
-- Name: circle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"public"."circle_id_seq"', 1, true);


--
-- Name: event_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"public"."event_id_seq"', 5, true);


--
-- Name: friend_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"public"."friend_id_seq"', 1, true);


--
-- Name: invitation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"public"."invitation_id_seq"', 1, true);


--
-- Name: message_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"public"."message_id_seq"', 3, true);


--
-- Name: user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"public"."user_id_seq"', 23, true);


--
-- PostgreSQL database dump complete
--

-- \unrestrict 6YtmxE3iRGLVOTd5k8sbFJGBt5J3bgp3s6W62c7trnNa5tPDuSIVPwt7CBeoEyD

RESET ALL;
