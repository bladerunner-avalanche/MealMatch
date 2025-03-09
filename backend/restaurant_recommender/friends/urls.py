from django.urls import path
from .views import get_friends, add_friend, remove_friend, get_all_users

urlpatterns = [
    path('get_friends/', get_friends, name='get_friends'),
    path('add_friend/', add_friend, name='add_friend'),
    path('remove_friend/', remove_friend, name='remove_friend'),
    path('get_all_users/', get_all_users, name='get_all_users'),
]
