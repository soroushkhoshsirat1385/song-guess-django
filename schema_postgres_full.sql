-- schema_postgres_full.sql\r\n-- Generated via: manage.py sqlmigrate (Postgres backend)\r\n-- Apps: contenttypes, auth, admin, sessions, game\r\n\r\n
\r\n\r\n-- Migration: contenttypes 0001_initial\r\n
BEGIN;
--
-- Create model ContentType
--
CREATE TABLE "django_content_type" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(100) NOT NULL, "app_label" varchar(100) NOT NULL, "model" varchar(100) NOT NULL);
--
-- Alter unique_together for contenttype (1 constraint(s))
--
CREATE UNIQUE INDEX "django_content_type_app_label_model_76bd3d3b_uniq" ON "django_content_type" ("app_label", "model");
COMMIT;
\r\n\r\n-- Migration: contenttypes 0002_remove_content_type_name\r\n
BEGIN;
--
-- Change Meta options on contenttype
--
-- (no-op)
--
-- Alter field name on contenttype
--
CREATE TABLE "new__django_content_type" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(100) NULL, "app_label" varchar(100) NOT NULL, "model" varchar(100) NOT NULL);
INSERT INTO "new__django_content_type" ("id", "app_label", "model", "name") SELECT "id", "app_label", "model", "name" FROM "django_content_type";
DROP TABLE "django_content_type";
ALTER TABLE "new__django_content_type" RENAME TO "django_content_type";
CREATE UNIQUE INDEX "django_content_type_app_label_model_76bd3d3b_uniq" ON "django_content_type" ("app_label", "model");
--
-- Raw Python operation
--
-- THIS OPERATION CANNOT BE WRITTEN AS SQL
--
-- Remove field name from contenttype
--
ALTER TABLE "django_content_type" DROP COLUMN "name";
COMMIT;
\r\n\r\n-- Migration: auth 0001_initial\r\n
BEGIN;
--
-- Create model Permission
--
CREATE TABLE "auth_permission" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(50) NOT NULL, "content_type_id" integer NOT NULL REFERENCES "django_content_type" ("id") DEFERRABLE INITIALLY DEFERRED, "codename" varchar(100) NOT NULL);
--
-- Create model Group
--
CREATE TABLE "auth_group" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(80) NOT NULL UNIQUE);
CREATE TABLE "auth_group_permissions" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "group_id" integer NOT NULL REFERENCES "auth_group" ("id") DEFERRABLE INITIALLY DEFERRED, "permission_id" integer NOT NULL REFERENCES "auth_permission" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model User
--
CREATE TABLE "auth_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "password" varchar(128) NOT NULL, "last_login" datetime NOT NULL, "is_superuser" bool NOT NULL, "username" varchar(30) NOT NULL UNIQUE, "first_name" varchar(30) NOT NULL, "last_name" varchar(30) NOT NULL, "email" varchar(75) NOT NULL, "is_staff" bool NOT NULL, "is_active" bool NOT NULL, "date_joined" datetime NOT NULL);
CREATE TABLE "auth_user_groups" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "user_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "group_id" integer NOT NULL REFERENCES "auth_group" ("id") DEFERRABLE INITIALLY DEFERRED);
CREATE TABLE "auth_user_user_permissions" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "user_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "permission_id" integer NOT NULL REFERENCES "auth_permission" ("id") DEFERRABLE INITIALLY DEFERRED);
CREATE UNIQUE INDEX "auth_permission_content_type_id_codename_01ab375a_uniq" ON "auth_permission" ("content_type_id", "codename");
CREATE INDEX "auth_permission_content_type_id_2f476e4b" ON "auth_permission" ("content_type_id");
CREATE UNIQUE INDEX "auth_group_permissions_group_id_permission_id_0cd325b0_uniq" ON "auth_group_permissions" ("group_id", "permission_id");
CREATE INDEX "auth_group_permissions_group_id_b120cbf9" ON "auth_group_permissions" ("group_id");
CREATE INDEX "auth_group_permissions_permission_id_84c5c92e" ON "auth_group_permissions" ("permission_id");
CREATE UNIQUE INDEX "auth_user_groups_user_id_group_id_94350c0c_uniq" ON "auth_user_groups" ("user_id", "group_id");
CREATE INDEX "auth_user_groups_user_id_6a12ed8b" ON "auth_user_groups" ("user_id");
CREATE INDEX "auth_user_groups_group_id_97559544" ON "auth_user_groups" ("group_id");
CREATE UNIQUE INDEX "auth_user_user_permissions_user_id_permission_id_14a6b632_uniq" ON "auth_user_user_permissions" ("user_id", "permission_id");
CREATE INDEX "auth_user_user_permissions_user_id_a95ead1b" ON "auth_user_user_permissions" ("user_id");
CREATE INDEX "auth_user_user_permissions_permission_id_1fbb5f2c" ON "auth_user_user_permissions" ("permission_id");
COMMIT;
\r\n\r\n-- Migration: auth 0002_alter_permission_name_max_length\r\n
BEGIN;
--
-- Alter field name on permission
--
CREATE TABLE "new__auth_permission" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(255) NOT NULL, "content_type_id" integer NOT NULL REFERENCES "django_content_type" ("id") DEFERRABLE INITIALLY DEFERRED, "codename" varchar(100) NOT NULL);
INSERT INTO "new__auth_permission" ("id", "content_type_id", "codename", "name") SELECT "id", "content_type_id", "codename", "name" FROM "auth_permission";
DROP TABLE "auth_permission";
ALTER TABLE "new__auth_permission" RENAME TO "auth_permission";
CREATE UNIQUE INDEX "auth_permission_content_type_id_codename_01ab375a_uniq" ON "auth_permission" ("content_type_id", "codename");
CREATE INDEX "auth_permission_content_type_id_2f476e4b" ON "auth_permission" ("content_type_id");
COMMIT;
\r\n\r\n-- Migration: auth 0003_alter_user_email_max_length\r\n
BEGIN;
--
-- Alter field email on user
--
CREATE TABLE "new__auth_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "email" varchar(254) NOT NULL, "password" varchar(128) NOT NULL, "last_login" datetime NOT NULL, "is_superuser" bool NOT NULL, "username" varchar(30) NOT NULL UNIQUE, "first_name" varchar(30) NOT NULL, "last_name" varchar(30) NOT NULL, "is_staff" bool NOT NULL, "is_active" bool NOT NULL, "date_joined" datetime NOT NULL);
INSERT INTO "new__auth_user" ("id", "password", "last_login", "is_superuser", "username", "first_name", "last_name", "is_staff", "is_active", "date_joined", "email") SELECT "id", "password", "last_login", "is_superuser", "username", "first_name", "last_name", "is_staff", "is_active", "date_joined", "email" FROM "auth_user";
DROP TABLE "auth_user";
ALTER TABLE "new__auth_user" RENAME TO "auth_user";
COMMIT;
\r\n\r\n-- Migration: auth 0004_alter_user_username_opts\r\n
BEGIN;
--
-- Alter field username on user
--
-- (no-op)
COMMIT;
\r\n\r\n-- Migration: auth 0005_alter_user_last_login_null\r\n
BEGIN;
--
-- Alter field last_login on user
--
CREATE TABLE "new__auth_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "last_login" datetime NULL, "password" varchar(128) NOT NULL, "is_superuser" bool NOT NULL, "username" varchar(30) NOT NULL UNIQUE, "first_name" varchar(30) NOT NULL, "last_name" varchar(30) NOT NULL, "email" varchar(254) NOT NULL, "is_staff" bool NOT NULL, "is_active" bool NOT NULL, "date_joined" datetime NOT NULL);
INSERT INTO "new__auth_user" ("id", "password", "is_superuser", "username", "first_name", "last_name", "email", "is_staff", "is_active", "date_joined", "last_login") SELECT "id", "password", "is_superuser", "username", "first_name", "last_name", "email", "is_staff", "is_active", "date_joined", "last_login" FROM "auth_user";
DROP TABLE "auth_user";
ALTER TABLE "new__auth_user" RENAME TO "auth_user";
COMMIT;
\r\n\r\n-- Migration: auth 0006_require_contenttypes_0002\r\n
\r\n\r\n-- Migration: auth 0007_alter_validators_add_error_messages\r\n
BEGIN;
--
-- Alter field username on user
--
-- (no-op)
COMMIT;
\r\n\r\n-- Migration: auth 0008_alter_user_username_max_length\r\n
BEGIN;
--
-- Alter field username on user
--
CREATE TABLE "new__auth_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "username" varchar(150) NOT NULL UNIQUE, "password" varchar(128) NOT NULL, "last_login" datetime NULL, "is_superuser" bool NOT NULL, "first_name" varchar(30) NOT NULL, "last_name" varchar(30) NOT NULL, "email" varchar(254) NOT NULL, "is_staff" bool NOT NULL, "is_active" bool NOT NULL, "date_joined" datetime NOT NULL);
INSERT INTO "new__auth_user" ("id", "password", "last_login", "is_superuser", "first_name", "last_name", "email", "is_staff", "is_active", "date_joined", "username") SELECT "id", "password", "last_login", "is_superuser", "first_name", "last_name", "email", "is_staff", "is_active", "date_joined", "username" FROM "auth_user";
DROP TABLE "auth_user";
ALTER TABLE "new__auth_user" RENAME TO "auth_user";
COMMIT;
\r\n\r\n-- Migration: auth 0009_alter_user_last_name_max_length\r\n
BEGIN;
--
-- Alter field last_name on user
--
CREATE TABLE "new__auth_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "last_name" varchar(150) NOT NULL, "password" varchar(128) NOT NULL, "last_login" datetime NULL, "is_superuser" bool NOT NULL, "username" varchar(150) NOT NULL UNIQUE, "first_name" varchar(30) NOT NULL, "email" varchar(254) NOT NULL, "is_staff" bool NOT NULL, "is_active" bool NOT NULL, "date_joined" datetime NOT NULL);
INSERT INTO "new__auth_user" ("id", "password", "last_login", "is_superuser", "username", "first_name", "email", "is_staff", "is_active", "date_joined", "last_name") SELECT "id", "password", "last_login", "is_superuser", "username", "first_name", "email", "is_staff", "is_active", "date_joined", "last_name" FROM "auth_user";
DROP TABLE "auth_user";
ALTER TABLE "new__auth_user" RENAME TO "auth_user";
COMMIT;
\r\n\r\n-- Migration: auth 0010_alter_group_name_max_length\r\n
BEGIN;
--
-- Alter field name on group
--
CREATE TABLE "new__auth_group" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(150) NOT NULL UNIQUE);
INSERT INTO "new__auth_group" ("id", "name") SELECT "id", "name" FROM "auth_group";
DROP TABLE "auth_group";
ALTER TABLE "new__auth_group" RENAME TO "auth_group";
COMMIT;
\r\n\r\n-- Migration: auth 0011_update_proxy_permissions\r\n
BEGIN;
--
-- Raw Python operation
--
-- THIS OPERATION CANNOT BE WRITTEN AS SQL
COMMIT;
\r\n\r\n-- Migration: auth 0012_alter_user_first_name_max_length\r\n
BEGIN;
--
-- Alter field first_name on user
--
CREATE TABLE "new__auth_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "first_name" varchar(150) NOT NULL, "password" varchar(128) NOT NULL, "last_login" datetime NULL, "is_superuser" bool NOT NULL, "username" varchar(150) NOT NULL UNIQUE, "last_name" varchar(150) NOT NULL, "email" varchar(254) NOT NULL, "is_staff" bool NOT NULL, "is_active" bool NOT NULL, "date_joined" datetime NOT NULL);
INSERT INTO "new__auth_user" ("id", "password", "last_login", "is_superuser", "username", "last_name", "email", "is_staff", "is_active", "date_joined", "first_name") SELECT "id", "password", "last_login", "is_superuser", "username", "last_name", "email", "is_staff", "is_active", "date_joined", "first_name" FROM "auth_user";
DROP TABLE "auth_user";
ALTER TABLE "new__auth_user" RENAME TO "auth_user";
COMMIT;
\r\n\r\n-- Migration: admin 0001_initial\r\n
BEGIN;
--
-- Create model LogEntry
--
CREATE TABLE "django_admin_log" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "action_time" datetime NOT NULL, "object_id" text NULL, "object_repr" varchar(200) NOT NULL, "action_flag" smallint unsigned NOT NULL CHECK ("action_flag" >= 0), "change_message" text NOT NULL, "content_type_id" integer NULL REFERENCES "django_content_type" ("id") DEFERRABLE INITIALLY DEFERRED, "user_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED);
CREATE INDEX "django_admin_log_content_type_id_c4bce8eb" ON "django_admin_log" ("content_type_id");
CREATE INDEX "django_admin_log_user_id_c564eba6" ON "django_admin_log" ("user_id");
COMMIT;
\r\n\r\n-- Migration: admin 0002_logentry_remove_auto_add\r\n
BEGIN;
--
-- Alter field action_time on logentry
--
CREATE TABLE "new__django_admin_log" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "action_time" datetime NOT NULL, "object_id" text NULL, "object_repr" varchar(200) NOT NULL, "action_flag" smallint unsigned NOT NULL CHECK ("action_flag" >= 0), "change_message" text NOT NULL, "content_type_id" integer NULL REFERENCES "django_content_type" ("id") DEFERRABLE INITIALLY DEFERRED, "user_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED);
INSERT INTO "new__django_admin_log" ("id", "object_id", "object_repr", "action_flag", "change_message", "content_type_id", "user_id", "action_time") SELECT "id", "object_id", "object_repr", "action_flag", "change_message", "content_type_id", "user_id", "action_time" FROM "django_admin_log";
DROP TABLE "django_admin_log";
ALTER TABLE "new__django_admin_log" RENAME TO "django_admin_log";
CREATE INDEX "django_admin_log_content_type_id_c4bce8eb" ON "django_admin_log" ("content_type_id");
CREATE INDEX "django_admin_log_user_id_c564eba6" ON "django_admin_log" ("user_id");
COMMIT;
\r\n\r\n-- Migration: admin 0003_logentry_add_action_flag_choices\r\n
BEGIN;
--
-- Alter field action_flag on logentry
--
-- (no-op)
COMMIT;
\r\n\r\n-- Migration: sessions 0001_initial\r\n
BEGIN;
--
-- Create model Session
--
CREATE TABLE "django_session" ("session_key" varchar(40) NOT NULL PRIMARY KEY, "session_data" text NOT NULL, "expire_date" datetime NOT NULL);
CREATE INDEX "django_session_expire_date_a5c62663" ON "django_session" ("expire_date");
COMMIT;
\r\n\r\n-- Migration: game 0001_initial\r\n
BEGIN;
--
-- Create model Room
--
CREATE TABLE "game_room" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "code" varchar(12) NOT NULL UNIQUE, "name" varchar(120) NOT NULL, "created_at" datetime NOT NULL);
--
-- Create model Round
--
CREATE TABLE "game_round" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "index" integer unsigned NOT NULL CHECK ("index" >= 0), "started_at" datetime NULL, "ended_at" datetime NULL, "room_id" bigint NOT NULL REFERENCES "game_room" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model SongSubmission
--
CREATE TABLE "game_songsubmission" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "file" varchar(100) NOT NULL, "original_filename" varchar(255) NOT NULL, "created_at" datetime NOT NULL, "round_id" bigint NOT NULL REFERENCES "game_round" ("id") DEFERRABLE INITIALLY DEFERRED, "uploader_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model Guess
--
CREATE TABLE "game_guess" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "created_at" datetime NOT NULL, "guessed_uploader_id" integer NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "guesser_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "submission_id" bigint NOT NULL REFERENCES "game_songsubmission" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model RoomMember
--
CREATE TABLE "game_roommember" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "joined_at" datetime NOT NULL, "score" integer NOT NULL, "room_id" bigint NOT NULL REFERENCES "game_room" ("id") DEFERRABLE INITIALLY DEFERRED, "user_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, CONSTRAINT "uniq_room_member" UNIQUE ("room_id", "user_id"));
--
-- Create constraint uniq_room_round_index on model round
--
CREATE TABLE "new__game_round" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "index" integer unsigned NOT NULL CHECK ("index" >= 0), "started_at" datetime NULL, "ended_at" datetime NULL, "room_id" bigint NOT NULL REFERENCES "game_room" ("id") DEFERRABLE INITIALLY DEFERRED, CONSTRAINT "uniq_room_round_index" UNIQUE ("room_id", "index"));
INSERT INTO "new__game_round" ("id", "index", "started_at", "ended_at", "room_id") SELECT "id", "index", "started_at", "ended_at", "room_id" FROM "game_round";
DROP TABLE "game_round";
ALTER TABLE "new__game_round" RENAME TO "game_round";
CREATE INDEX "game_songsubmission_round_id_1cf0404a" ON "game_songsubmission" ("round_id");
CREATE INDEX "game_songsubmission_uploader_id_9ee0be59" ON "game_songsubmission" ("uploader_id");
CREATE INDEX "game_guess_guessed_uploader_id_efac032f" ON "game_guess" ("guessed_uploader_id");
CREATE INDEX "game_guess_guesser_id_81e81ffb" ON "game_guess" ("guesser_id");
CREATE INDEX "game_guess_submission_id_e29012bd" ON "game_guess" ("submission_id");
CREATE INDEX "game_roommember_room_id_ff56905a" ON "game_roommember" ("room_id");
CREATE INDEX "game_roommember_user_id_e12298c3" ON "game_roommember" ("user_id");
CREATE INDEX "game_round_room_id_060e5398" ON "game_round" ("room_id");
--
-- Create constraint uniq_round_uploader_submission on model songsubmission
--
CREATE TABLE "new__game_songsubmission" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "file" varchar(100) NOT NULL, "original_filename" varchar(255) NOT NULL, "created_at" datetime NOT NULL, "round_id" bigint NOT NULL REFERENCES "game_round" ("id") DEFERRABLE INITIALLY DEFERRED, "uploader_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, CONSTRAINT "uniq_round_uploader_submission" UNIQUE ("round_id", "uploader_id"));
INSERT INTO "new__game_songsubmission" ("id", "file", "original_filename", "created_at", "round_id", "uploader_id") SELECT "id", "file", "original_filename", "created_at", "round_id", "uploader_id" FROM "game_songsubmission";
DROP TABLE "game_songsubmission";
ALTER TABLE "new__game_songsubmission" RENAME TO "game_songsubmission";
CREATE INDEX "game_songsubmission_round_id_1cf0404a" ON "game_songsubmission" ("round_id");
CREATE INDEX "game_songsubmission_uploader_id_9ee0be59" ON "game_songsubmission" ("uploader_id");
--
-- Create constraint uniq_guess_per_submission_per_user on model guess
--
CREATE TABLE "new__game_guess" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "created_at" datetime NOT NULL, "guessed_uploader_id" integer NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "guesser_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "submission_id" bigint NOT NULL REFERENCES "game_songsubmission" ("id") DEFERRABLE INITIALLY DEFERRED, CONSTRAINT "uniq_guess_per_submission_per_user" UNIQUE ("submission_id", "guesser_id"));
INSERT INTO "new__game_guess" ("id", "created_at", "guessed_uploader_id", "guesser_id", "submission_id") SELECT "id", "created_at", "guessed_uploader_id", "guesser_id", "submission_id" FROM "game_guess";
DROP TABLE "game_guess";
ALTER TABLE "new__game_guess" RENAME TO "game_guess";
CREATE INDEX "game_guess_guessed_uploader_id_efac032f" ON "game_guess" ("guessed_uploader_id");
CREATE INDEX "game_guess_guesser_id_81e81ffb" ON "game_guess" ("guesser_id");
CREATE INDEX "game_guess_submission_id_e29012bd" ON "game_guess" ("submission_id");
COMMIT;
\r\n\r\n-- Migration: game 0002_scoreevent_roundsong\r\n
BEGIN;
--
-- Create model ScoreEvent
--
CREATE TABLE "game_scoreevent" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "event_type" varchar(32) NOT NULL, "points" integer NOT NULL, "metadata" text NOT NULL CHECK ((JSON_VALID("metadata") OR "metadata" IS NULL)), "created_at" datetime NOT NULL, "room_id" bigint NOT NULL REFERENCES "game_room" ("id") DEFERRABLE INITIALLY DEFERRED, "round_id" bigint NOT NULL REFERENCES "game_round" ("id") DEFERRABLE INITIALLY DEFERRED, "user_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED);
--
-- Create model RoundSong
--
CREATE TABLE "game_roundsong" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "order_index" integer unsigned NOT NULL CHECK ("order_index" >= 0), "played_at" datetime NULL, "round_id" bigint NOT NULL REFERENCES "game_round" ("id") DEFERRABLE INITIALLY DEFERRED, "submission_id" bigint NOT NULL UNIQUE REFERENCES "game_songsubmission" ("id") DEFERRABLE INITIALLY DEFERRED, CONSTRAINT "uniq_round_order_index" UNIQUE ("round_id", "order_index"));
CREATE INDEX "game_scoreevent_room_id_fcec4094" ON "game_scoreevent" ("room_id");
CREATE INDEX "game_scoreevent_round_id_d26eacf4" ON "game_scoreevent" ("round_id");
CREATE INDEX "game_scoreevent_user_id_307c1282" ON "game_scoreevent" ("user_id");
CREATE INDEX "game_roundsong_round_id_1ecf1e67" ON "game_roundsong" ("round_id");
COMMIT;
