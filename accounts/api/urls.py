from django.urls import path
from . import views
from ..views import SignUpView, LoginView, PasswordResetRequestView


urlpatterns =[
    path('accounts/login/', LoginView.as_view(), name='login_api'),
    path('accounts/signup/', SignUpView.as_view(), name='signup_api'),
    path('accounts/password_reset/', PasswordResetRequestView.as_view(), name='password_reset_api'),
    path('user_report/', views.UserReportView.as_view(), name='user_report'),
    path('animal_reports/', views.AnimalReportListView.as_view()),
    path('volunteers/nearby/', views.NearbyVolunteersView.as_view(), name='nearby_volunteers'),

]