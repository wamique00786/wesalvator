from django.contrib import admin
from .models import AdoptableAnimal

class AdoptableAnimalAdmin(admin.ModelAdmin):
    list_display = ('category', 'description', 'is_adoptable')  # Update this line
    search_fields = ('category', 'description')  # You can also add search fields if needed

admin.site.register(AdoptableAnimal, AdoptableAnimalAdmin)