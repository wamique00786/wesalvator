from django import forms
from .models import AdoptableAnimal

class AdoptableAnimalForm(forms.ModelForm):
    class Meta:
        model = AdoptableAnimal
        fields = ['category', 'description', 'photo', 'is_adoptable']
        widgets = {
            'description': forms.Textarea(attrs={'rows': 4}),
        }

        labels = {
            'category': 'Animal Category',
            'description': 'Description',
            'photo': 'Photo',
            'is_adoptable': 'Is Adoptable',
        }