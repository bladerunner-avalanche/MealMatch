from django.urls import path
from .views import register, login_view, update_profile, update_favorites, get_users, update_dietary_preferences, filter_by_dietary_preferences, get_group_dietary_preferences

urlpatterns = [
    path('register/', register, name='register'),
    path('login/', login_view, name='login'),
    path('update_profile/', update_profile, name='update_profile'),
    path('update_favorites/', update_favorites, name='update_favorites'),
    path('get_users/', get_users, name='get_users'),
    path('update_dietary_preferences/', update_dietary_preferences, name='update_dietary_preferences'),
    path('filter_by_dietary_preferences/', filter_by_dietary_preferences, name='filter_by_dietary_preferences'),
    path('get_group_dietary_preferences/', get_group_dietary_preferences, name='get_group_dietary_preferences'),
]
