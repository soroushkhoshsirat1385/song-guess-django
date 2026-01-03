import secrets
import string

from django.conf import settings
from django.db import models
from django.utils import timezone


def generate_room_code(length: int = 6) -> str:
    alphabet = string.ascii_uppercase + string.digits
    return ''.join(secrets.choice(alphabet) for _ in range(length))


class Room(models.Model):
    code = models.CharField(max_length=12, unique=True, default=generate_room_code)
    name = models.CharField(max_length=120, blank=True)
    created_at = models.DateTimeField(default=timezone.now)

    def __str__(self) -> str:
        return self.code


class RoomMember(models.Model):
    room = models.ForeignKey(Room, on_delete=models.CASCADE, related_name='members')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    joined_at = models.DateTimeField(default=timezone.now)
    score = models.IntegerField(default=0)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['room', 'user'], name='uniq_room_member'),
        ]


class Round(models.Model):
    room = models.ForeignKey(Room, on_delete=models.CASCADE, related_name='rounds')
    index = models.PositiveIntegerField(default=1)
    started_at = models.DateTimeField(null=True, blank=True)
    ended_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['room', 'index'], name='uniq_room_round_index'),
        ]


def song_upload_path(instance: 'SongSubmission', filename: str) -> str:
    # Store only inside MEDIA_ROOT and keep it room-scoped.
    safe_name = filename.replace('\\', '_').replace('/', '_')
    return f"rooms/{instance.round.room.code}/rounds/{instance.round.index}/{safe_name}"


class SongSubmission(models.Model):
    round = models.ForeignKey(Round, on_delete=models.CASCADE, related_name='submissions')
    uploader = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    file = models.FileField(upload_to=song_upload_path)
    original_filename = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['round', 'uploader'], name='uniq_round_uploader_submission'),
        ]


class Guess(models.Model):
    submission = models.ForeignKey(SongSubmission, on_delete=models.CASCADE, related_name='guesses')
    guesser = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='guesses_made')
    guessed_uploader = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='guesses_received',
    )
    created_at = models.DateTimeField(default=timezone.now)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['submission', 'guesser'], name='uniq_guess_per_submission_per_user'),
        ]

    @property
    def is_correct(self) -> bool:
        return self.guessed_uploader_id is not None and self.guessed_uploader_id == self.submission.uploader_id


class RoundSong(models.Model):
    """Persisted randomized play order for a round."""

    round = models.ForeignKey(Round, on_delete=models.CASCADE, related_name='round_songs')
    submission = models.OneToOneField(SongSubmission, on_delete=models.CASCADE, related_name='round_song')
    order_index = models.PositiveIntegerField()
    played_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=['round', 'order_index'], name='uniq_round_order_index'),
        ]


class ScoreEvent(models.Model):
    """Append-only scoring ledger for audit/premium logs."""

    EVENT_CORRECT_GUESS = 'correct_guess'
    EVENT_UNGUESSED_SONG = 'unguessed_song'

    EVENT_TYPE_CHOICES = [
        (EVENT_CORRECT_GUESS, 'Correct guess'),
        (EVENT_UNGUESSED_SONG, 'Unguessed song'),
    ]

    room = models.ForeignKey(Room, on_delete=models.CASCADE, related_name='score_events')
    round = models.ForeignKey(Round, on_delete=models.CASCADE, related_name='score_events')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='score_events')
    event_type = models.CharField(max_length=32, choices=EVENT_TYPE_CHOICES)
    points = models.IntegerField()
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(default=timezone.now)
