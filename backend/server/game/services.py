from __future__ import annotations

from dataclasses import asdict, dataclass

from django.contrib.auth import get_user_model
from django.db import transaction

import random

from .models import Guess, Room, RoomMember, Round, RoundSong, ScoreEvent, SongSubmission

User = get_user_model()


@dataclass(frozen=True)
class LeaderboardEntry:
    username: str
    score: int


def _get_room_or_none(room_code: str) -> Room | None:
    return Room.objects.filter(code=room_code).first()


def require_member(room: Room, user) -> RoomMember | None:
    return RoomMember.objects.select_related('user').filter(room=room, user=user).first()


def build_room_state(room_code: str) -> dict:
    room = _get_room_or_none(room_code)
    if not room:
        return {"error": "room_not_found"}

    round_1 = Round.objects.filter(room=room, index=1).first()

    members = list(
        room.members.select_related('user').values(
            'user__id',
            'user__username',
            'score',
            'joined_at',
        )
    )

    submissions = []
    play_order = []
    if round_1:
        submissions = list(
            round_1.submissions.select_related('uploader').values(
                'id',
                'original_filename',
                'uploader__username',
                'created_at',
            )
        )
        play_order = list(
            round_1.round_songs.select_related('submission')
            .order_by('order_index')
            .values('order_index', 'submission_id', 'played_at')
        )

    return {
        'room': {'code': room.code, 'name': room.name},
        'round': 1,
        'members': members,
        'submissions': submissions,
        'play_order': play_order,
    }


def ensure_round_song_order(room_code: str, round_index: int = 1) -> dict:
    room = _get_room_or_none(room_code)
    if not room:
        return {"error": "room_not_found"}

    round_obj = Round.objects.filter(room=room, index=round_index).first()
    if not round_obj:
        return {"error": "round_not_found"}

    if RoundSong.objects.filter(round=round_obj).exists():
        return {"ok": True, "already_exists": True}

    submissions = list(SongSubmission.objects.filter(round=round_obj).all())
    rng = random.Random()
    rng.shuffle(submissions)

    RoundSong.objects.bulk_create(
        [
            RoundSong(round=round_obj, submission=s, order_index=i)
            for i, s in enumerate(submissions)
        ]
    )
    return {"ok": True, "count": len(submissions)}


def submit_guess(room_code: str, guesser, submission_id: int, guessed_username: str | None) -> dict:
    room = _get_room_or_none(room_code)
    if not room:
        return {"error": "room_not_found"}

    if not require_member(room, guesser):
        return {"error": "not_in_room"}

    submission = (
        SongSubmission.objects.select_related('round', 'uploader')
        .filter(id=submission_id, round__room=room)
        .first()
    )
    if not submission:
        return {"error": "submission_not_found"}

    guessed_user = None
    if guessed_username:
        guessed_user = User.objects.filter(username=guessed_username).first()
        if not guessed_user:
            return {"error": "guessed_user_not_found"}

    guess, _ = Guess.objects.update_or_create(
        submission=submission,
        guesser=guesser,
        defaults={'guessed_uploader': guessed_user},
    )

    return {
        'guess': {
            'id': guess.id,
            'submission_id': submission.id,
            'guesser': guesser.username,
            'guessed_uploader': guessed_user.username if guessed_user else None,
            'is_correct': guess.is_correct,
        }
    }


def reveal_and_score_round(room_code: str, round_index: int = 1) -> dict:
    room = _get_room_or_none(room_code)
    if not room:
        return {"error": "room_not_found"}

    round_obj = Round.objects.filter(room=room, index=round_index).first()
    if not round_obj:
        return {"error": "round_not_found"}

    # Scoring rules (MVP):
    # - +2 for each correct guess (to the guesser)
    # - +3 to the uploader if nobody guessed their song correctly
    CORRECT_GUESS_POINTS = 2
    UNGUESSED_SONG_POINTS = 3

    with transaction.atomic():
        ensure_round_song_order(room_code, round_index=round_index)

        submissions = list(
            SongSubmission.objects.select_related('uploader')
            .filter(round=round_obj)
            .all()
        )

        # Preload members for score updates.
        members = {
            m.user_id: m
            for m in RoomMember.objects.select_for_update().filter(room=room).all()
        }

        score_events: list[ScoreEvent] = []

        for submission in submissions:
            guesses = list(
                Guess.objects.select_related('guesser', 'guessed_uploader')
                .filter(submission=submission)
                .all()
            )

            any_correct = False
            for g in guesses:
                if g.is_correct:
                    any_correct = True
                    member = members.get(g.guesser_id)
                    if member:
                        member.score += CORRECT_GUESS_POINTS

                    score_events.append(
                        ScoreEvent(
                            room=room,
                            round=round_obj,
                            user_id=g.guesser_id,
                            event_type=ScoreEvent.EVENT_CORRECT_GUESS,
                            points=CORRECT_GUESS_POINTS,
                            metadata={
                                'submission_id': submission.id,
                                'uploader_id': submission.uploader_id,
                            },
                        )
                    )

            if not any_correct:
                uploader_member = members.get(submission.uploader_id)
                if uploader_member:
                    uploader_member.score += UNGUESSED_SONG_POINTS

                score_events.append(
                    ScoreEvent(
                        room=room,
                        round=round_obj,
                        user_id=submission.uploader_id,
                        event_type=ScoreEvent.EVENT_UNGUESSED_SONG,
                        points=UNGUESSED_SONG_POINTS,
                        metadata={'submission_id': submission.id},
                    )
                )

        RoomMember.objects.bulk_update(list(members.values()), ['score'])

        if score_events:
            ScoreEvent.objects.bulk_create(score_events)

    leaderboard = sorted(
        (LeaderboardEntry(username=m.user.username, score=m.score) for m in members.values()),
        key=lambda e: (-e.score, e.username.lower()),
    )

    return {
        'room': {'code': room.code, 'name': room.name},
        'round': round_index,
        'leaderboard': [asdict(e) for e in leaderboard],
        'scoring': {
            'correct_guess_points': CORRECT_GUESS_POINTS,
            'unguessed_song_points': UNGUESSED_SONG_POINTS,
        },
    }
