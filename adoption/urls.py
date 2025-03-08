from django.urls import path
from . import views
from .views import adopt_view

urlpatterns = [
    path('adopt/', adopt_view, name='adopt'),
    path('adopt-animal/', views.adopt_animal, name='adopt_animal'),
    path('add-animal/', views.add_adoptable_animal, name='add_adoptable_animal'),
    path('adoptable-animals/', views.adoptable_animals_list, name='adoptable_animals_list'),  # Ensure this line is present
    path('adoptable-animal/<int:pk>/', views.adoptable_animal_detail, name='adoptable_animal_detail'),
    path('edit-adoptable-animal/<int:pk>/', views.edit_adoptable_animal, name='edit_adoptable_animal'),
    path('not-authorized/', views.not_authorized, name='not_authorized'),
]