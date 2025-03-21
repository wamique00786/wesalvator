from django.urls import path
from . import views
from .views import career_view

urlpatterns = [
    path('career/', career_view, name='career'),
    path('team/', views.team, name='team'),
    path('contact-us/', views.contact_us, name='contact_us'),
    path('about/', views.about, name='about'),
    path('notify/', views.send_notification_email, name='send_notification_email'),
]