import json

from django.contrib.auth import authenticate, get_user_model, login, logout
from django.contrib.auth.decorators import login_required
from django.db import transaction
from django.http import HttpRequest, JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_GET, require_POST

from .models import Guess, Room, RoomMember, Round, SongSubmission
from .services import ensure_round_song_order, reveal_and_score_round

User = get_user_model()


def _json_body(request: HttpRequest) -> dict:
    if not request.body:
        return {}
    try:
        return json.loads(request.body.decode("utf-8"))
    except json.JSONDecodeError:
        return {}


def _ensure_member(user, room: Room) -> bool:
    return RoomMember.objects.filter(room=room, user=user).exists()


@require_GET
@login_required
def list_my_rooms(request: HttpRequest):
    rooms = list(
        Room.objects.filter(members__user=request.user)
        .distinct()
        .values('code', 'name', 'created_at')
    )
    return JsonResponse({'rooms': rooms})


@require_POST
@csrf_exempt
def register(request: HttpRequest):
    data = _json_body(request)
    username = (data.get("username") or "").strip()
    password = data.get("password") or ""

    if not username or not password:
        return JsonResponse({"error": "username_and_password_required"}, status=400)

    if User.objects.filter(username=username).exists():
        return JsonResponse({"error": "username_taken"}, status=400)

    user = User.objects.create_user(username=username, password=password)
    login(request, user)

    return JsonResponse({"user": {"id": user.id, "username": user.username}})


@require_POST
@csrf_exempt
def login_view(request: HttpRequest):
    data = _json_body(request)
    username = (data.get("username") or "").strip()
    password = data.get("password") or ""

    user = authenticate(request, username=username, password=password)
    if not user:
        return JsonResponse({"error": "invalid_credentials"}, status=401)

    login(request, user)
    return JsonResponse({"user": {"id": user.id, "username": user.username}})


@require_POST
@csrf_exempt
def logout_view(request: HttpRequest):
    logout(request)
    return JsonResponse({"ok": True})


@require_GET
@login_required
def me(request: HttpRequest):
    user = request.user
    return JsonResponse({"user": {"id": user.id, "username": user.username}})


@require_POST
@csrf_exempt
@login_required
def create_room(request: HttpRequest):
    data = _json_body(request)
    name = (data.get("name") or "").strip()

    with transaction.atomic():
        room = Room.objects.create(name=name)
        RoomMember.objects.create(room=room, user=request.user)
        Round.objects.get_or_create(room=room, index=1)

    return JsonResponse({"room": {"code": room.code, "name": room.name}})


@require_POST
@csrf_exempt
@login_required
def join_room(request: HttpRequest, room_code: str):
    room = Room.objects.filter(code=room_code).first()
    if not room:
        return JsonResponse({"error": "room_not_found"}, status=404)

    RoomMember.objects.get_or_create(room=room, user=request.user)
    return JsonResponse({"room": {"code": room.code, "name": room.name}})


@require_POST
@csrf_exempt
@login_required
def leave_room(request: HttpRequest, room_code: str):
    room = Room.objects.filter(code=room_code).first()
    if not room:
        return JsonResponse({"error": "room_not_found"}, status=404)

    RoomMember.objects.filter(room=room, user=request.user).delete()
    return JsonResponse({'ok': True})


@require_GET
@login_required
def room_state(request: HttpRequest, room_code: str):
    room = Room.objects.filter(code=room_code).first()
    if not room:
        return JsonResponse({"error": "room_not_found"}, status=404)

    if not _ensure_member(request.user, room):
        return JsonResponse({"error": "not_in_room"}, status=403)

    round_1 = Round.objects.filter(room=room, index=1).first()
    submissions = []
    if round_1:
        submissions = list(
            round_1.submissions.select_related("uploader").values(
                "id",
                "original_filename",
                "uploader__username",
                "created_at",
            )
        )

    members = list(
        room.members.select_related("user").values(
            "user__id",
            "user__username",
            "score",
            "joined_at",
        )
    )

    return JsonResponse(
        {
            "room": {"code": room.code, "name": room.name},
            "round": 1,
            "members": members,
            "submissions": submissions,
        }
    )


@require_POST
@csrf_exempt
@login_required
def submit_song(request: HttpRequest, room_code: str):
    room = Room.objects.filter(code=room_code).first()
    if not room:
        return JsonResponse({"error": "room_not_found"}, status=404)

    if not _ensure_member(request.user, room):
        return JsonResponse({"error": "not_in_room"}, status=403)

    upload = request.FILES.get("file")
    if not upload:
        return JsonResponse({"error": "missing_file"}, status=400)

    round_1, _ = Round.objects.get_or_create(room=room, index=1)

    existing = SongSubmission.objects.filter(round=round_1, uploader=request.user).first()
    if existing:
        return JsonResponse({"error": "already_submitted", "submission_id": existing.id}, status=400)

    submission = SongSubmission.objects.create(
        round=round_1,
        uploader=request.user,
        file=upload,
        original_filename=upload.name,
    )

    return JsonResponse(
        {
            "submission": {
                "id": submission.id,
                "original_filename": submission.original_filename,
            }
        }
    )


@require_POST
@csrf_exempt
@login_required
def submit_guess(request: HttpRequest, room_code: str, submission_id: int):
    room = Room.objects.filter(code=room_code).first()
    if not room:
        return JsonResponse({"error": "room_not_found"}, status=404)

    if not _ensure_member(request.user, room):
        return JsonResponse({"error": "not_in_room"}, status=403)

    submission = (
        SongSubmission.objects.select_related("round", "uploader")
        .filter(id=submission_id, round__room=room)
        .first()
    )
    if not submission:
        return JsonResponse({"error": "submission_not_found"}, status=404)

    data = _json_body(request)
    guessed_username = (data.get("guessed_username") or "").strip()

    guessed_user = None
    if guessed_username:
        guessed_user = User.objects.filter(username=guessed_username).first()
        if not guessed_user:
            return JsonResponse({"error": "guessed_user_not_found"}, status=404)

    guess, _ = Guess.objects.update_or_create(
        submission=submission,
        guesser=request.user,
        defaults={"guessed_uploader": guessed_user},
    )

    return JsonResponse({"guess": {"id": guess.id, "is_correct": guess.is_correct}})


@require_POST
@csrf_exempt
@login_required
def create_play_order(request: HttpRequest, room_code: str):
    room = Room.objects.filter(code=room_code).first()
    if not room:
        return JsonResponse({"error": "room_not_found"}, status=404)
    if not _ensure_member(request.user, room):
        return JsonResponse({"error": "not_in_room"}, status=403)

    res = ensure_round_song_order(room_code=room.code, round_index=1)
    if res.get('error'):
        return JsonResponse(res, status=400)
    return JsonResponse(res)


@require_POST
@csrf_exempt
@login_required
def reveal_round(request: HttpRequest, room_code: str):
    room = Room.objects.filter(code=room_code).first()
    if not room:
        return JsonResponse({"error": "room_not_found"}, status=404)
    if not _ensure_member(request.user, room):
        return JsonResponse({"error": "not_in_room"}, status=403)

    res = reveal_and_score_round(room_code=room.code, round_index=1)
    if res.get('error'):
        return JsonResponse(res, status=400)
    return JsonResponse(res)
