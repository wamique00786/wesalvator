from django.db import models
from django.contrib.auth.models import User
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.gis.db import models as geomodels
from phonenumber_field.modelfields import PhoneNumberField

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    user_type = models.CharField(max_length=20, choices=[('USER', 'User'), ('VOLUNTEER', 'Volunteer'), ('ORGANIZATION', 'Organization')])
    mobile_number = PhoneNumberField(region='IN', blank=True, null=True)
    location = geomodels.PointField(null=True, blank=True, srid=4326)  # Use PointField for geographic data
    last_location_update = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"{self.user.username} - {self.get_user_type_display()}"

# Signal to create user profile
@receiver(post_save, sender=User)
def create_or_update_user_profile(sender, instance, created, **kwargs):
    """Create UserProfile only if it doesn't exist (no updates)."""
    if created:
        # Use get_or_create to avoid duplicates
        UserProfile.objects.get_or_create(user=instance)