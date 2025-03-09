from django.urls import path
from .recommender import create_group, list_groups, recommend_for_group, leave_group, delete_group  

urlpatterns = [
    path('create_group/', create_group, name='create_group'),
    path('list_groups/', list_groups, name='list_groups'),
    path('recommend/', recommend_for_group, name='recommend_for_group'),
    path('leave_group/', leave_group, name='leave_group'),
    path('delete_group/', delete_group, name='delete_group'),
]
