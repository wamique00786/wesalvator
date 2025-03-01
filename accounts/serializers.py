# rescue/serializers.py
from django.contrib.auth.models import User
from rest_framework import serializers
from .models import UserProfile
from rescue.models import AnimalReport
from phonenumber_field.serializerfields import PhoneNumberField
from django.contrib.gis.geos import Point

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name']

class UserProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    location = serializers.SerializerMethodField()
    distance = serializers.SerializerMethodField()

    class Meta:
        model = UserProfile
        fields = ['id', 'user', 'user_type', 'location', 'distance']

    def get_location(self, obj):
        """
        Custom method to serialize the GeoDjango Point field
        """
        if obj.location:
            return {
                'type': 'Point',
                'coordinates': [
                    obj.location.x,  # longitude
                    obj.location.y   # latitude
                ]
            }
        return None

    def get_distance(self, obj):
        """
        Include distance if it was annotated in the queryset
        """
        if hasattr(obj, 'distance'):
            return {
                'km': round(obj.distance.km, 2),
                'text': f"{round(obj.distance.km, 2)} km away"
            }
        return None
    
    def create(self, validated_data):
        user = validated_data.pop('user')
        user_profile = UserProfile.objects.create(user=user, **validated_data)
        return user_profile

class LoginSerializer(serializers.Serializer):
    username = serializers.CharField(required=True)
    password = serializers.CharField(required=True)
    user_type = serializers.ChoiceField(choices=[
        ('USER', 'Regular User'),
        ('VOLUNTEER', 'Volunteer'),
        ('ADMIN', 'Administrator')
    ], required=True)

class SignUpSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, style={'input_type': 'password'})
    password2 = serializers.CharField(write_only=True, style={'input_type': 'password'}, label='Confirm Password')
    user_type = serializers.ChoiceField(  # Keep this field for input
        choices=[('USER', 'Regular User'), ('VOLUNTEER', 'Volunteer'), ('ADMIN', 'Administrator')],
        write_only=True  # Mark as write-only to avoid serialization issues
    )
    mobile_number = PhoneNumberField(write_only=True)  # Mark as write-only

    class Meta:
        model = User
        fields = ['username', 'email', 'mobile_number', 'password', 'password2', 'user_type']

    # Keep validate() method the same

    def create(self, validated_data):
        # Extract UserProfile fields
        user_type = validated_data.pop('user_type')
        mobile_number = validated_data.pop('mobile_number')
        validated_data.pop('password2')

        # Create User
        user = User.objects.create_user(**validated_data)

        # Update or create UserProfile with user_type and mobile_number
        UserProfile.objects.update_or_create(
            user=user,
            defaults={
                'user_type': user_type,
                'mobile_number': mobile_number
            }
        )
        return user

    def to_representation(self, instance):
        """Include UserProfile data in the response."""
        data = super().to_representation(instance)
        try:
            profile = instance.userprofile
            data['user_type'] = profile.user_type
            data['mobile_number'] = str(profile.mobile_number)
        except UserProfile.DoesNotExist:
            data['user_type'] = None
            data['mobile_number'] = None
        return data


class PasswordResetRequestSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)

    def validate_email(self, value):
        if not User.objects.filter(email=value).exists():
            raise serializers.ValidationError("No user is associated with this email address.")
        return value
    
class AnimalReportSerializer(serializers.ModelSerializer):
    priority = serializers.ChoiceField(choices=['LOW', 'MEDIUM', 'HIGH'], default='MEDIUM')
    latitude = serializers.FloatField(write_only=True, required=True)
    longitude = serializers.FloatField(write_only=True, required=True)

    class Meta:
        model = AnimalReport
        # fields = ['photo', 'description', 'priority', 'latitude', 'longitude']
        exclude= ('location',)
        

    def validate(self, data):
        request = self.context.get('request')
        if not request:
            raise serializers.ValidationError("No request object found")

        # Ensure photo is present
        if 'photo' not in request.FILES:
            raise serializers.ValidationError("A photo is required")

        # Validate description
        if 'description' not in data:
            raise serializers.ValidationError("A description is required")

        # Validate location coordinates
        latitude = data.get('latitude')
        longitude = data.get('longitude')
        if latitude is None or longitude is None:
            raise serializers.ValidationError("Location coordinates are required")

        if not (-90 <= latitude <= 90) or not (-180 <= longitude <= 180):
            raise serializers.ValidationError("Invalid latitude or longitude")

        return data

    def create(self, validated_data):
        latitude = validated_data.pop('latitude')
        longitude = validated_data.pop('longitude')

        validated_data['location'] = Point(longitude, latitude, srid=4326)

        return super().create(validated_data)

