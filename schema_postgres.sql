-- schema_postgres.sql\r\n-- Generated via: manage.py sqlmigrate (Postgres backend)\r\n
-- Migration: game 0001_initial\r\n
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
\r\n
