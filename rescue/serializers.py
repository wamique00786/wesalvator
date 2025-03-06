from rest_framework import serializers
from django.contrib.gis.geos import Point
from django.contrib.gis.measure import D
from django.contrib.gis.db.models.functions import Distance
from accounts.models import UserProfile
from .models import UserLocationHistory
from django.utils import timezone

class UserProfileSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(source='user.id')
    name = serializers.SerializerMethodField()
    distance = serializers.SerializerMethodField()
    location = serializers.SerializerMethodField()

    class Meta:
        model = UserProfile
        fields = ['id', 'name', 'distance', 'location']

    def get_name(self, obj):
        return obj.user.get_full_name() or obj.user.username

    def get_distance(self, obj):
        # Ensure distance annotation exists before accessing it
        return f"{getattr(obj, 'distance', 0):.2f} km"

    def get_location(self, obj):
        if obj.location:
            return {
                "latitude": obj.location.y,
                "longitude": obj.location.x
            }
        return {"latitude": None, "longitude": None}

class UserLocationSerializer(serializers.ModelSerializer):
    latitude = serializers.FloatField(write_only=True)
    longitude = serializers.FloatField(write_only=True)

    class Meta:
        model = UserProfile
        fields = ['latitude', 'longitude']

    def update(self, instance, validated_data):
        latitude = validated_data.get('latitude')
        longitude = validated_data.get('longitude')

        if latitude is None or longitude is None:
            raise serializers.ValidationError("Latitude and longitude are required.")

        # Convert to Point object
        location_point = Point(longitude, latitude, srid=4326)

        # Update user's current location
        instance.location = location_point
        instance.last_location_update = timezone.now()
        instance.save()

        # Save to UserLocationHistory
        UserLocationHistory.objects.create(
            user=instance.user,
            location=location_point,
            timestamp=timezone.now(),
            user_type=instance.user_type
        )

        return instance

class UserLocationHistorySerializer(serializers.ModelSerializer):
    latitude = serializers.SerializerMethodField()
    longitude = serializers.SerializerMethodField()

    class Meta:
        model = UserLocationHistory
        fields = ['latitude', 'longitude', 'timestamp', 'user_type']

    def get_latitude(self, obj):
        return obj.location.y

    def get_longitude(self, obj):
        return obj.location.x