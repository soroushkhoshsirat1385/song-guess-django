from django.contrib import admin

from .models import Guess, Room, RoomMember, Round, RoundSong, ScoreEvent, SongSubmission


@admin.register(Room)
class RoomAdmin(admin.ModelAdmin):
    list_display = ("code", "name", "created_at")
    search_fields = ("code", "name")


@admin.register(RoomMember)
class RoomMemberAdmin(admin.ModelAdmin):
    list_display = ("room", "user", "score", "joined_at")
    list_select_related = ("room", "user")


@admin.register(Round)
class RoundAdmin(admin.ModelAdmin):
    list_display = ("room", "index", "started_at", "ended_at")
    list_select_related = ("room",)


@admin.register(SongSubmission)
class SongSubmissionAdmin(admin.ModelAdmin):
    list_display = ("round", "uploader", "original_filename", "created_at")
    list_select_related = ("round", "uploader")


@admin.register(Guess)
class GuessAdmin(admin.ModelAdmin):
    list_display = ("submission", "guesser", "guessed_uploader", "created_at")
    list_select_related = ("submission", "guesser", "guessed_uploader")


@admin.register(RoundSong)
class RoundSongAdmin(admin.ModelAdmin):
    list_display = ("round", "order_index", "submission", "played_at")
    list_select_related = ("round", "submission")


@admin.register(ScoreEvent)
class ScoreEventAdmin(admin.ModelAdmin):
    list_display = ("room", "round", "user", "event_type", "points", "created_at")
    list_select_related = ("room", "round", "user")
