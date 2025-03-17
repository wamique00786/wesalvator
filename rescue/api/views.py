from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.auth.models import User
from django.contrib.auth.decorators import login_required, user_passes_test
from ..models import (
    RescueTask,
    UserLocationHistory,
)
from accounts.models import UserProfile
from django.http import JsonResponse
from django.contrib.gis.geos import Point
from django.contrib.gis.measure import D
from django.views.decorators.csrf import ensure_csrf_cookie
from math import radians, sin, cos, sqrt, atan2
from django.utils import timezone
from datetime import timedelta, datetime
import logging
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated  

from django.contrib.auth import get_user_model
from ..serializers import (
    UserLocationSerializer,
    UserLocationHistorySerializer,
    UserProfileSerializer
)

logger = logging.getLogger(__name__)

User = get_user_model()

@api_view(["POST", "GET"])
@permission_classes([IsAuthenticated])
def save_user_location(request):
    try:
        user_profile = request.user.userprofile  # Get the user's profile

        if request.method == "GET":
            # Serialize current user profile
            user_serializer = UserProfileSerializer(user_profile, context={"request": request})
            
            # Fetch last 10 location history records for the user
            location_history = UserLocationHistory.objects.filter(
                user=request.user
            ).order_by("-timestamp")[:10]
            history_serializer = UserLocationHistorySerializer(
                location_history, many=True
            )

            return Response(
                {
                    "user": user_serializer.data,  # Current user details
                    "location_history": history_serializer.data,  # Last 10 location history records
                }
            )

        # Update last_location_update timestamp
        user_profile.last_location_update = timezone.now()

        # Get coordinates from request
        latitude = float(request.data.get('latitude'))
        longitude = float(request.data.get('longitude'))

        # Create Point object
        location = Point(longitude, latitude, srid=4326)

        # Update location
        user_profile.location = location
        user_profile.save()

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

        return Response({
            "status": "success",
            "message": "Location updated successfully",
            "timestamp": user_profile.last_location_update
        })

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

@login_required
def rescued_animals_today(request):
    # Get today's date
    today = timezone.now().date()
    
    # Get all completed tasks from today using is_completed and created_at
    completed_tasks = RescueTask.objects.filter(
        created_at__date=today,
        is_completed=True
    ).select_related('assigned_to', 'report').order_by('-created_at')

    return render(request, "rescue/rescued_animals_today.html", {
        "completed_tasks": completed_tasks,
    })

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
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_task(request):
    try:
        data = request.data
        volunteer_id = data.get('volunteer_id')
        report_id = data.get('report_id')
        
        task = RescueTask.objects.create(
            title=data.get('title'),
            description=data.get('description'),
            assigned_to_id=volunteer_id,
            report_id=report_id,
            location=Point(
                float(data.get('longitude')),
                float(data.get('latitude'))
            ),
            priority=data.get('priority', 'MEDIUM')
        )
        
        return Response({
            'status': 'success',
            'task_id': task.id
        })
    except Exception as e:
        return Response({
            'status': 'error',
            'message': str(e)
        }, status=400)

@login_required
def complete_task(request, task_id):
    task = get_object_or_404(RescueTask, id=task_id, assigned_to=request.user)
    task.is_completed = True
    task.save()
    return redirect("volunteer_dashboard")  # Redirect back to the dashboard
