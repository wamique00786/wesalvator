from django.urls import path
from . import views


urlpatterns =[
    path('user/', views.UserReportView.as_view(), name='user_report'),
    path('animal_reports/', views.AnimalReportListView.as_view()),
    path('volunteers/nearby/', views.NearbyVolunteersView.as_view(), name='nearby_volunteers'),

]