from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.contrib.auth import views as auth_views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('accounts/', include('accounts.urls')),  # Ensure this line is present
    path('donation/', include('donation.urls')),
    path('adoption/', include('adoption.urls')),
    path('subscription/', include('subscription.urls')),
    path('base/', include('base.urls')),
    path('', include('chatbot.urls')),
    path('', include('rescue.urls')),
    # Authentication URLs
    path('accounts/login/', auth_views.LoginView.as_view(template_name='registration/login.html'), name='login'),
    path('accounts/logout/', auth_views.LogoutView.as_view(next_page='/'), name='logout'),
    path('', include('accounts.urls')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)