from django import forms
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth.models import User
from .models import UserProfile
from phonenumber_field.formfields import PhoneNumberField
from django.core.exceptions import ValidationError
import phonenumbers


class SignUpForm(UserCreationForm):
    USER_TYPES = [
        ('USER', 'Regular User'),
        ('VOLUNTEER', 'Volunteer'),
        ('ORGANIZATION', 'Organization')
    ]

    user_type = forms.ChoiceField(
        choices=USER_TYPES,
        required=True,
        widget=forms.Select(attrs={'class': 'form-control'}),
        label='User Type'
    )
    email = forms.EmailField(
        required=True,
        widget=forms.EmailInput(attrs={'class': 'form-control'}),
        label='Email Address'
    )
    mobile_number = forms.CharField(
        required=True,
        widget=forms.TextInput(attrs={
            'class': 'form-control',
            'placeholder': 'Enter your phone number (e.g., 9876543210)',
            'id': 'mobile_number'
        }),
        help_text='Enter your phone number without the country code.',
        label='Mobile Number'
    )
    country_code = forms.CharField(
        required=True,
        widget=forms.HiddenInput(attrs={'id': 'country_code'})
    )
    username = forms.CharField(
        widget=forms.TextInput(attrs={'class': 'form-control'}),
        label='Username'
    )
    password1 = forms.CharField(
        widget=forms.PasswordInput(attrs={'class': 'form-control'}),
        label='Password'
    )
    password2 = forms.CharField(
        widget=forms.PasswordInput(attrs={'class': 'form-control'}),
        label='Confirm Password'
    )

    class Meta:
        model = User
        fields = ('username', 'email', 'mobile_number', 'country_code', 'password1', 'password2', 'user_type')

    def clean_mobile_number(self):
        """
        Validates and combines country code and mobile number into a full E.164 format.
        """
        country_code = self.data.get("country_code", "").strip()
        mobile_number = self.cleaned_data.get("mobile_number", "").strip()

        if not country_code or not mobile_number:
            raise ValidationError("Please enter a valid mobile number and country code.")

        full_number = f"{country_code}{mobile_number}"

        try:
            parsed_number = phonenumbers.parse(full_number, None)

            if not phonenumbers.is_valid_number(parsed_number):
                raise ValidationError("Enter a valid phone number.")

            return phonenumbers.format_number(parsed_number, phonenumbers.PhoneNumberFormat.E164)

        except phonenumbers.NumberParseException:
            raise ValidationError("Invalid phone number format. Please check your input.")

    def save(self, commit=True):
        user = super().save(commit=False)
        user.email = self.cleaned_data['email']
        if commit:
            user.save()
            # Create or update UserProfile
            UserProfile.objects.update_or_create(
                user=user,
                defaults={
                    'user_type': self.cleaned_data['user_type'],
                    'mobile_number': self.cleaned_data['mobile_number']
                }
            )
        return user


class PasswordResetForm(forms.Form):
    email = forms.EmailField(
        label="Email",
        max_length=254,
        widget=forms.EmailInput(attrs={'class': 'form-control'})
    )