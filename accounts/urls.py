from django.urls import path, include
from . import views
from .views import password_reset_request
from django.contrib.auth import views as auth_views  # Import Django's auth views

urlpatterns = [
    path('signup/', views.signup, name='signup'),
    #path('verify-firebase-token/', views.verify_firebase_token_view, name='verify_firebase_token'),
    path('get-admins/', views.get_admins, name='get_admins'),
    path('login/', views.custom_login, name='login'),
    path('password_reset/', password_reset_request, name='password_reset'), 
    path('password_reset/done/', auth_views.PasswordResetDoneView.as_view(), name='password_reset_done'), 
    path('reset/<uidb64>/<token>/', auth_views.PasswordResetConfirmView.as_view(), name='password_reset_confirm'), 
    path('reset/done/', auth_views.PasswordResetCompleteView.as_view(), name='password_reset_complete'), 
    path('api/', include('accounts.api.urls')) 

]
