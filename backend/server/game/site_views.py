from __future__ import annotations

from django.contrib import messages
from django.contrib.auth import authenticate, get_user_model, login, logout
from django.contrib.auth.decorators import login_required
from django.http import HttpRequest, HttpResponse
from django.shortcuts import redirect, render
from django.urls import reverse
from django.views.decorators.http import require_http_methods

from .models import Room

User = get_user_model()


def index(_request: HttpRequest) -> HttpResponse:
    return redirect("site_rooms")


@require_http_methods(["GET", "POST"])
def login_page(request: HttpRequest) -> HttpResponse:
    if request.method == "POST":
        username = (request.POST.get("username") or "").strip()
        password = request.POST.get("password") or ""

        user = authenticate(request, username=username, password=password)
        if not user:
            messages.error(request, "Invalid username/password")
            return redirect("site_login")

        login(request, user)
        return redirect("site_rooms")

    return render(request, "game/login.html")


@require_http_methods(["GET", "POST"])
def register_page(request: HttpRequest) -> HttpResponse:
    if request.method == "POST":
        username = (request.POST.get("username") or "").strip()
        password = request.POST.get("password") or ""

        if not username or not password:
            messages.error(request, "Username and password are required")
            return redirect("site_register")

        if User.objects.filter(username=username).exists():
            messages.error(request, "Username already taken")
            return redirect("site_register")

        user = User.objects.create_user(username=username, password=password)
        login(request, user)
        return redirect("site_rooms")

    return render(request, "game/register.html")


@login_required
def logout_page(request: HttpRequest) -> HttpResponse:
    logout(request)
    return redirect("site_login")


@login_required
@require_http_methods(["GET", "POST"])
def rooms_page(request: HttpRequest) -> HttpResponse:
    if request.method == "POST":
        action = request.POST.get("action")
        if action == "create":
            name = (request.POST.get("name") or "").strip()
            room = Room.objects.create(name=name)
            # join the room via API logic is handled elsewhere; keep it simple here:
            room.members.create(user=request.user)
            room.rounds.get_or_create(index=1)
            return redirect("site_room", room_code=room.code)

        if action == "join":
            code = (request.POST.get("code") or "").strip().upper()
            room = Room.objects.filter(code=code).first()
            if not room:
                messages.error(request, "Room not found")
                return redirect("site_rooms")
            room.members.get_or_create(user=request.user)
            room.rounds.get_or_create(index=1)
            return redirect("site_room", room_code=room.code)

    rooms = Room.objects.filter(members__user=request.user).distinct().order_by("created_at")
    return render(request, "game/rooms.html", {"rooms": rooms})


@login_required
@require_http_methods(["GET", "POST"])
def room_page(request: HttpRequest, room_code: str) -> HttpResponse:
    room = Room.objects.filter(code=room_code).first()
    if not room:
        messages.error(request, "Room not found")
        return redirect("site_rooms")

    if not room.members.filter(user=request.user).exists():
        messages.error(request, "You are not a member of this room")
        return redirect("site_rooms")

    # Minimal actions that call the same model/services logic as the API.
    if request.method == "POST":
        action = request.POST.get("action")
        if action == "create_order":
            from .services import ensure_round_song_order

            ensure_round_song_order(room_code=room.code, round_index=1)
            return redirect("site_room", room_code=room.code)

        if action == "reveal":
            from .services import reveal_and_score_round

            reveal_and_score_round(room_code=room.code, round_index=1)
            return redirect("site_room", room_code=room.code)

    round_1 = room.rounds.filter(index=1).first()
    submissions = []
    play_order = []
    leaderboard = list(room.members.select_related("user").order_by("-score", "user__username"))

    if round_1:
        submissions = list(round_1.submissions.select_related("uploader").all())
        play_order = list(round_1.round_songs.order_by("order_index").all())

    return render(
        request,
        "game/room.html",
        {
            "room": room,
            "round": round_1,
            "submissions": submissions,
            "play_order": play_order,
            "leaderboard": leaderboard,
        },
    )
