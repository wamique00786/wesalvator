from django.db import models
from django.contrib.auth.models import User
from django.contrib.gis.db import models
from django.conf import settings
from django.utils import timezone

class Animal(models.Model):
    SPECIES_CHOICES = [
        ('DOG', 'Dog'),
        ('CAT', 'Cat'),
        ('BIRD', 'Bird'),
        ('OTHER', 'Other'),
    ]
    
    STATUS_CHOICES = [
        ('RESCUED', 'Rescued'),
        ('TREATMENT', 'Under Treatment'),
        ('RECOVERED', 'Recovered'),
        ('ADOPTED', 'Adopted'),
    ]

    name = models.CharField(max_length=100)
    species = models.CharField(max_length=50, choices=SPECIES_CHOICES)
    rescue_date = models.DateField()
    status = models.CharField(max_length=50, choices=STATUS_CHOICES)
    medical_needs = models.TextField()
    rescue_location = models.CharField(max_length=200)
    assigned_to = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    photo = models.ImageField(upload_to='animal_photos/', null=True, blank=True)

    def __str__(self):
        return self.name

class MedicalRecord(models.Model):
    animal = models.ForeignKey(Animal, on_delete=models.CASCADE, related_name='medical_records')
    date = models.DateField()
    treatment = models.TextField()
    notes = models.TextField()
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)

    def __str__(self):
        return f"Medical Record for {self.animal.name} on {self.date}"

class AnimalReport(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'Pending'),
        ('ASSIGNED', 'Assigned'),
        ('ADMIN_REVIEW', 'Admin Review'),
        ('COMPLETED', 'Completed'),
    )
    PRIORITY_CHOICES = (
        ('LOW', 'Low'),
        ('MEDIUM', 'Medium'),
        ('HIGH', 'High'),
    )

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    photo = models.ImageField(upload_to='animal_reports/', null=True, blank=True)  # ✅ Single image support
    description = models.TextField()
    location = models.PointField(geography=True, null=True, blank=True)  # Allow null temporarily
    timestamp = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    assigned_to = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True,
        related_name='assigned_reports'
    )
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='MEDIUM')

    def __str__(self):
        return f"Report by {self.user.username} on {self.timestamp}"

class AnimalReportImage(models.Model):
    report = models.ForeignKey(AnimalReport, on_delete=models.CASCADE, related_name='images')
    image = models.ImageField(upload_to='animal_reports/')

    def __str__(self):
        return f"Image for Report ID {self.report.id}" 

class RescueTask(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField()
    assigned_to = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='tasks')
    is_completed = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title
    
class VolunteerLocation(models.Model):
    volunteer = models.OneToOneField(User, on_delete=models.CASCADE)
    latitude = models.FloatField()
    longitude = models.FloatField()
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.volunteer.username}'s Location"
    
class UserLocationHistory(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    location = models.PointField(geography=True)
    timestamp = models.DateTimeField(default=timezone.now)
    user_type = models.CharField(max_length=20)  # To store user type at the time
    
    class Meta:
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['user', 'timestamp']),
        ]

    def __str__(self):
        return f"{self.user.username} location at {self.timestamp}"