# dataviewer/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('restaurants/', views.RestaurantList.as_view(), name='restaurant-list'),
    path('restaurants/<int:pk>/', views.RestaurantDetail.as_view(), name='restaurant-detail'),  # Für Detailsuche
]

#Desktop\MM0\backend\restaurant_recommender>python manage.py runserver