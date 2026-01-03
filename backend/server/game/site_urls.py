from django.urls import path

from . import site_views

urlpatterns = [
    path("", site_views.index, name="site_index"),
    path("login/", site_views.login_page, name="site_login"),
    path("register/", site_views.register_page, name="site_register"),
    path("logout/", site_views.logout_page, name="site_logout"),
    path("rooms/", site_views.rooms_page, name="site_rooms"),
    path("rooms/<str:room_code>/", site_views.room_page, name="site_room"),
]
