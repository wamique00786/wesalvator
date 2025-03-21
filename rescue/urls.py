from django.urls import path, include
from . import views

urlpatterns = [
    path('', views.home, name='home'),
    path('dashboard/', views.dashboard, name='dashboard'),
    path('user-dashboard/', views.user_dashboard, name='user_dashboard'),
    path('volunteer-dashboard/', views.volunteer_dashboard, name='volunteer_dashboard'),
    path('organization-dashboard/', views.org_dashboard, name='organization_dashboard'),
    path('api/', include('rescue.api.urls'))
]