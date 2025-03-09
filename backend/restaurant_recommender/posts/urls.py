from django.urls import path
from .views import create_post, list_posts, delete_post

urlpatterns = [
    path('create_post/', create_post, name='create_post'),
    path('list_posts/', list_posts, name='list_posts'),
    path('delete_post/', delete_post, name='delete_post'),
]
