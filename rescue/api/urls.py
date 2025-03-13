from django.urls import path
from . import views

urlpatterns = [
    path('volunteer/location/update/', views.update_volunteer_location, name='update_volunteer_location'),
    path('rescued-animals-today/', views.rescued_animals_today, name='rescued_animals_today'),  
    path('user-info/', views.get_user_info, name='get_user_info'),
    path('all-user-locations/', views.get_all_users_locations, name='get_all_users_locations'),
    path('save-location/', views.save_user_location),
    path('complete-task/<int:task_id>/', views.complete_task, name='complete_task'),
]
