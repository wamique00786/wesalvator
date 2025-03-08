from django.db import models
from django.contrib.auth.models import User

class AdoptableAnimal(models.Model):
    category = models.CharField(max_length=100)
    description = models.TextField()
    photo = models.ImageField(upload_to='animal_photos/')
    # Add this field if it doesn't exist
    is_adoptable = models.BooleanField(default=True)

    class Meta:
        permissions = [
            ("can_add_adoptable_animal", "Can add adoptable animal"),
        ]

    def __str__(self):
        return self.category