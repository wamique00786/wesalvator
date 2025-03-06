from django.contrib import admin
from .models import *

# Register your models here.
admin.site.register([Animal, MedicalRecord, AnimalReport, RescueTask, VolunteerLocation, UserLocationHistory])