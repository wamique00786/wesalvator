from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.auth.models import User
from django.contrib.auth.decorators import login_required, user_passes_test
from ..models import (
    Animal,
    MedicalRecord,
    RescueTask,
    VolunteerLocation,
    UserLocationHistory,
)
from accounts.models import UserProfile
from django.http import JsonResponse
from django.contrib.gis.geos import Point
from django.contrib.gis.measure import D
from django.views.decorators.csrf import ensure_csrf_cookie
from math import radians, sin, cos, sqrt, atan2
from django.utils import timezone
from datetime import timedelta
import logging
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated  

from django.contrib.auth import get_user_model
from ..serializers import (
    UserLocationSerializer,
    UserLocationHistorySerializer,
)

logger = logging.getLogger(__name__)

User = get_user_model()



@api_view(["POST", "GET"])
@permission_classes([IsAuthenticated])
def save_user_location(request):
    try:
        user_profile = request.user.userprofile  # Get the user's profile

        if request.method == "GET":
            # Fetch last 10 location history records for the user
            location_history = UserLocationHistory.objects.filter(
                user=request.user
            ).order_by("-timestamp")[:10]
            history_serializer = UserLocationHistorySerializer(
                location_history, many=True
            )

            return Response(
                {
                    "latitude": (
                        user_profile.location.y if user_profile.location else None
                    ),
                    "longitude": (
                        user_profile.location.x if user_profile.location else None
                    ),
                    "last_update": user_profile.last_location_update,
                    "location_history": history_serializer.data,  # Return last 10 location history records
                }
            )

        # Handle POST request (Updating location)
        serializer = UserLocationSerializer(
            user_profile, data=request.data, partial=True
        )
        if not serializer.is_valid():
            return Response(
                {"status": "error", "message": serializer.errors}, status=400
            )

        serializer.save()  # Updates user location and history

        # Clean up old location history (only keep last 24 hours)
        cleanup_time = timezone.now() - timedelta(hours=24)
        UserLocationHistory.objects.filter(
            user=request.user, timestamp__lt=cleanup_time
        ).delete()

        return Response(
            {"status": "success", "message": "Location updated successfully"}
        )

    except Exception as e:
        logger.error(f"Error saving location: {str(e)}")
        return Response({"status": "error", "message": str(e)}, status=400)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_all_users_locations(request):
    try:
        # Get active users (updated in last 5 minutes)
        active_time = timezone.now() - timedelta(minutes=5)
        users = UserProfile.objects.filter(
            location__isnull=False
        )

        users_data = []

        for user_profile in users:
            # Get location history for the last hour
            history = UserLocationHistory.objects.filter(
                user=user_profile.user,
                timestamp__gte=timezone.now() - timedelta(hours=1),
            ).order_by("-timestamp")

            location_history = [
                {
                    "latitude": h.location.y,
                    "longitude": h.location.x,
                    "timestamp": h.timestamp.isoformat(),
                }
                for h in history
            ]
            users_data.append(
                {
                    "id": user_profile.user.id,
                    "username": user_profile.user.username,
                    "phone":str( user_profile.mobile_number),
                    "user_type": user_profile.user_type,
                    "location": {
                        "latitude": user_profile.location.y if user_profile.location else None,
                        "longitude": user_profile.location.x if user_profile.location else None,
                        "last_update": user_profile.last_location_update.strftime("%B %d, %Y at %I:%M %p") if user_profile.last_location_update else None,
                    },
                    "location_history": location_history,
                }
            )

        return JsonResponse({"status": "success", "users": users_data})
    except Exception as e:
        logger.error(f"Error getting locations: {str(e)}")
        return JsonResponse({"status": "error", "message": str(e)}, status=400)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def get_user_info(request):
    try:
        user_profile = request.user.userprofile
        return JsonResponse(
            {
                "username": request.user.username,
                "phone": str(
                    user_profile.mobile_number
                ),  # Convert PhoneNumber object to string
                "location": {
                    "latitude": (
                        user_profile.location.y if user_profile.location else None
                    ),
                    "longitude": (
                        user_profile.location.x if user_profile.location else None
                    ),
                },
                "user_type": user_profile.user_type,
            }
        )
    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=400)


def volunteer_locations(request):
    volunteers = UserProfile.objects.filter(user_type="VOLUNTEER").exclude(
        location__isnull=True
    )
    data = [
        {
            "username": volunteer.user.username,
            "latitude": volunteer.location.y,
            "longitude": volunteer.location.x,
        }
        for volunteer in volunteers
    ]
    return JsonResponse(data, safe=False)


def calculate_distance(lat1, lon1, lat2, lon2):
    # Convert latitude and longitude from degrees to radians
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])

    # Haversine formula
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))
    r = 6371  # Radius of earth in kilometers
    return r * c


def get_nearest_volunteers(animal_lat, animal_lon, radius_km=10):
    # Create a point for the animal's location
    animal_location = Point(animal_lon, animal_lat)  # Note: (longitude, latitude)

    # Fetch volunteers within the specified radius
    nearby_volunteers = UserProfile.objects.filter(
        user_type="VOLUNTEER", location__distance_lte=(animal_location, D(km=radius_km))
    )

    return nearby_volunteers


def animal_location_view(request, animal_id):
    animal = get_object_or_404(Animal, id=animal_id)
    medical_records = MedicalRecord.objects.filter(animal=animal)
    nearby_volunteers = get_nearest_volunteers(
        animal.latitude, animal.longitude
    )  # Assuming Animal has latitude and longitude

    context = {
        "animal": animal,
        "medical_records": medical_records,
        "nearby_volunteers": nearby_volunteers,
    }
    return render(request, "rescue/animal_location.html", context)


@login_required
def rescued_animals_today(request):
    today = timezone.now().date()
    rescued_animals = Animal.objects.filter(rescue_date=today)

    return render(
        request,
        "rescue/rescued_animals_today.html",
        {
            "rescued_animals": rescued_animals,
            "total_rescued_today": rescued_animals.count(),
        },
    )


@api_view(["POST"])
@permission_classes([IsAuthenticated])
@ensure_csrf_cookie
def update_volunteer_location(request):
    print("Received location update request")  # Debug print
    try:
        latitude = float(request.data.get("latitude"))
        longitude = float(request.data.get("longitude"))

        print(f"Received coordinates: lat={latitude}, lng={longitude}")  # Debug print

        # Create a Point object with SRID 4326 (WGS 84)
        location = Point(longitude, latitude, srid=4326)

        # Update the volunteer's location
        user_profile = request.user.userprofile
        user_profile.location = location
        user_profile.save()

        print("Location updated successfully")  # Debug print

        return Response({"status": "success"})
    except Exception as e:
        return Response({"status": "error", "message": str(e)}, status=400)


def get_volunteer_locations(request):
    locations = []
    for user in UserProfile.objects.filter(user_type="VOLUNTEER", location__isnull=False).all():
        locations.append(
            {
                "id": user.id,
                "name": user,
                "location": user.location,
            }
        )
    return JsonResponse(locations, safe=False)


@login_required
def complete_task(request, task_id):
    task = get_object_or_404(RescueTask, id=task_id, assigned_to=request.user)
    task.is_completed = True
    task.save()
    return redirect("volunteer_dashboard")  # Redirect back to the dashboard


@user_passes_test(lambda u: u.is_staff)  # Ensure only admins can access this view
def add_task(request):
    if request.method == "POST":
        title = request.POST.get("title")
        description = request.POST.get("description")
        assigned_to = request.POST.get("assigned_to")  # Get the user ID from the form
        task = RescueTask.objects.create(
            title=title, description=description, assigned_to_id=assigned_to
        )
        return redirect("volunteer_dashboard")  # Redirect to the dashboard or task list

    # Fetch all volunteers for the assignment form
    volunteers = User.objects.filter(
        is_staff=False
    )  # Assuming non-staff are volunteers
    return render(request, "rescue/add_task.html", {"volunteers": volunteers})
