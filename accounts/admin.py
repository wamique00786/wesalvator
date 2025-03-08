from django.contrib import admin
from .models import UserProfile  # Import your UserProfile model

class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'user_type', 'mobile_number')  # Fields to display in the list view
    search_fields = ('user__username', 'user__email')  # Fields to search in the admin panel

# Register the UserProfile model with the admin site
admin.site.register(UserProfile, UserProfileAdmin)