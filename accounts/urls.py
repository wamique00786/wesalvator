from django.urls import path
from . import views
from .views import SignUpView, LoginView, PasswordResetRequestView, password_reset_request
from django.contrib.auth import views as auth_views  # Import Django's auth views

urlpatterns = [
    path('signup/', views.signup, name='signup'),
    path('login/', views.custom_login, name='login'),
    path('password_reset/', password_reset_request, name='password_reset'),  # Add this line
    path('password_reset/done/', auth_views.PasswordResetDoneView.as_view(), name='password_reset_done'),  # Password reset done
    path('reset/<uidb64>/<token>/', auth_views.PasswordResetConfirmView.as_view(), name='password_reset_confirm'),  # Password reset confirm
    path('reset/done/', auth_views.PasswordResetCompleteView.as_view(), name='password_reset_complete'),  # Password reset complete
    path('api/accounts/signup/', SignUpView.as_view(), name='signup_api'),
    path('api/accounts/login/', LoginView.as_view(), name='login_api'),
    path('api/accounts/password_reset/', PasswordResetRequestView.as_view(), name='password_reset_api'),
    path('api/accounts/animal_reports/', views.AnimalReportListView.as_view()),
    path('api/accounts/user/', views.UserReportView.as_view(), name='user_report'),
    path('volunteers/nearby/', views.NearbyVolunteersView.as_view(), name='nearby_volunteers'),

]