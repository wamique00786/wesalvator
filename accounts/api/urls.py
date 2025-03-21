from django.urls import path
from . import views


urlpatterns =[
    path('accounts/signup/', views.SignUpView.as_view(), name='signup_api'),
    path('accounts/login/', views.LoginView.as_view(), name='login_api'),
    path('accounts/password_reset/', views.PasswordResetRequestView.as_view(), name='password_reset_api'),
    path('user_report/', views.UserReportView.as_view(), name='user_report'),
    path('animal_reports/', views.AnimalReportListView.as_view()),
    path('user_report2/', views.UserReportV2View.as_view()),
    path('save-org-location/', views.save_org_location),
    path('organizations/', views.OrgListView.as_view()),
    path('volunteers/nearby/', views.NearbyVolunteersView.as_view(), name='nearby_volunteers'),
    path('volunteers/all/', views.AllVolunteersView.as_view(), name='all_volunteers'),
    path('volunteers/active/', views.ActiveVolunteersView.as_view(), name='all_volunteers'),
    path('volunteer/location/<int:volunteer_id>/', views.get_volunteer_location, name='get_volunteer_location'),

]