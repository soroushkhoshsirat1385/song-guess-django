from django.urls import path

from . import views

urlpatterns = [
    # Auth (session-based)
    path("auth/register/", views.register, name="register"),
    path("auth/login/", views.login_view, name="login"),
    path("auth/logout/", views.logout_view, name="logout"),
    path("auth/me/", views.me, name="me"),

    # Convenience: list rooms for current user
    path("rooms/", views.list_my_rooms, name="list_my_rooms"),

    # Rooms
    path("rooms/create/", views.create_room, name="create_room"),
    path("rooms/<str:room_code>/join/", views.join_room, name="join_room"),
    path("rooms/<str:room_code>/leave/", views.leave_room, name="leave_room"),
    path("rooms/<str:room_code>/state/", views.room_state, name="room_state"),

    # Gameplay
    path("rooms/<str:room_code>/submit/", views.submit_song, name="submit_song"),
    path(
        "rooms/<str:room_code>/submissions/<int:submission_id>/guess/",
        views.submit_guess,
        name="submit_guess",
    ),

    # Round utilities (round 1 for now)
    path("rooms/<str:room_code>/order/create/", views.create_play_order, name="create_play_order"),
    path("rooms/<str:room_code>/reveal/", views.reveal_round, name="reveal_round"),
]
