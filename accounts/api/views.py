from django.contrib.gis.geos import Point
from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.measure import D
from django.contrib.auth import authenticate, login
from django.contrib.auth.models import User
from django.contrib.auth.tokens import default_token_generator
from django.core.mail import send_mail
from django.conf import settings
from django.template.loader import render_to_string
from django.utils import timezone
from django.utils.http import urlsafe_base64_encode
from django.utils.encoding import force_bytes
import json
from django.contrib.sessions.models import Session

from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import api_view, permission_classes
from rest_framework.authtoken.models import Token

from ..models import UserProfile
from rescue.models import AnimalReport, AnimalReportImage, RescueTask
from ..serializers import (
    UserProfileSerializer,
    AnimalReportSerializer,
    AnimalReport2Serializer,
    AnimalReportListSerializer,
    PasswordResetRequestSerializer,
    LoginSerializer,
    SignUpSerializer
)
from .. import send_email as sm

import logging

logger = logging.getLogger(__name__)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_volunteer_location(request, volunteer_id):
    try:
        # Get the report location from query parameters
        report_lat = request.GET.get('reportLat')
        report_lng = request.GET.get('reportLng')

        # Base query to get volunteer
        volunteer_query = UserProfile.objects.filter(
            id=volunteer_id,
            user_type='VOLUNTEER'
        )

        # If we have report coordinates, calculate distance
        if report_lat and report_lng:
            report_location = Point(
                float(report_lng),
                float(report_lat),
                srid=4326
            )
            
            # Annotate with distance
            volunteer = volunteer_query.annotate(
                distance=Distance('location', report_location)
            ).first()

            if volunteer and volunteer.distance:
                # Convert distance to kilometers
                distance_km = volunteer.distance.km
                distance_text = f"{distance_km:.2f} km away"
            else:
                distance_text = "Distance unknown"
        else:
            volunteer = volunteer_query.first()
            distance_text = "Distance unknown"

        if not volunteer:
            return Response({
                'status': 'error',
                'message': 'Volunteer not found'
            }, status=404)
        
        if not volunteer.location:
            return Response({
                'status': 'error',
                'message': 'Volunteer location not available'
            }, status=404)

        return Response({
            'status': 'success',
            'user': {
                'username': volunteer.user.username,
                'id': volunteer.user.id
            },
            'location': {
                'type': 'Point',
                'coordinates': [
                    volunteer.location.x,
                    volunteer.location.y
                ]
            },
            'mobile_number': str(volunteer.mobile_number),
            'distance': {
                'text': distance_text,
                'value': distance_km if 'distance_km' in locals() else None
            }
        })

    except Exception as e:
        return Response({
            'status': 'error',
            'message': str(e)
        }, status=500)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def save_admin_location(request):
    try:
        # Ensure user is an admin
        if not hasattr(request.user, 'userprofile') or request.user.userprofile.user_type != 'ADMIN':
            return Response({
                'status': 'error',
                'message': 'Only admin users can update their location'
            }, status=403)

        # Use static coordinates for admin
        latitude = 18.5204
        longitude = 73.8567

        # Create Point object
        location = Point(longitude, latitude, srid=4326)

        # Update admin's location
        profile = request.user.userprofile
        profile.location = location
        profile.last_location_update = timezone.now()
        profile.save()

        return Response({
            'status': 'success',
            'message': 'Admin location set to default coordinates',
            'data': {
                'latitude': latitude,
                'longitude': longitude,
                'timestamp': timezone.now().isoformat()
            }
        })

    except Exception as e:
        return Response({
            'status': 'error',
            'message': str(e)
        }, status=500)

class AllVolunteersView(generics.ListAPIView):
    serializer_class = UserProfileSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        return UserProfile.objects.filter(user_type="VOLUNTEER")

class NearbyVolunteersView(generics.ListAPIView):
    serializer_class = UserProfileSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        try:
            lat = self.request.query_params.get("lat")
            lng = self.request.query_params.get("lng")

            if not lat or not lng:
                return UserProfile.objects.none()

            # Convert to float and create Point
            user_location = Point(float(lng), float(lat), srid=4326)  # longitude first, latitude second

            # Get active sessions
            active_sessions = Session.objects.filter(expire_date__gte=timezone.now())
            uid_list = []

            # Extract user IDs from valid sessions
            for session in active_sessions:
                try:
                    data = session.get_decoded()
                    uid = data.get('_auth_user_id')
                    if uid:
                        uid_list.append(uid)
                except:
                    continue

            # Query for logged-in volunteers with distance annotation
            volunteers = (
                UserProfile.objects.filter(
                    user_type="VOLUNTEER",
                    location__isnull=False,
                    user__id__in=uid_list  # Only get volunteers who are logged in
                )
                .annotate(distance=Distance("location", user_location))
                .order_by("distance")
            )

            print(f"Found {volunteers.count()} logged-in volunteers")
            return volunteers

        except (ValueError, TypeError) as e:
            print(f"Error in NearbyVolunteersView: {str(e)}")
            return UserProfile.objects.none()

    def get_serializer_context(self):
        """
        Passes additional context to serializer
        """
        context = super().get_serializer_context()
        context["distance"] = True  # Ensures distance is included in the response
        return context

class AdminUserListView(generics.ListAPIView):
    """
    API View to fetch all admin users and calculate the distance from the authenticated user.
    """
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        # Get all admin profiles
        admins = UserProfile.objects.filter(user_type="ADMIN").select_related('user')
        
        # Set static location for all admins
        static_point = Point(73.8567, 18.5204, srid=4326)  # longitude, latitude
        
        for admin in admins:
            admin.location = static_point
            admin.save()
        
        return admins


class UserReportView(generics.CreateAPIView):
    serializer_class = AnimalReportSerializer
    permission_classes = [IsAuthenticated]

    def create(self, request, *args, **kwargs):
        try:
            logger.info(f"Received data: {request.data}")

            # Validate required fields
            if "photo" not in request.FILES:
                return Response(
                    {"status": "error", "message": "Photo is required"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            if not request.data.get("description"):
                return Response(
                    {"status": "error", "message": "Description is required"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            latitude = request.data.get("latitude")
            longitude = request.data.get("longitude")
            if not latitude or not longitude:
                return Response(
                    {"status": "error", "message": "Location coordinates are required"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            # Ensure priority is valid
            priority = request.data.get("priority", "MEDIUM").strip().upper()
            if priority not in ["LOW", "MEDIUM", "HIGH"]:
                return Response(
                    {
                        "status": "error",
                        "message": "Invalid priority. Choose from LOW, MEDIUM, HIGH",
                    },
                    status=status.HTTP_400_BAD_REQUEST,
                )

            logger.info(f"Final Priority assigned: {priority}")

            # Create report location point
            report_location = Point(float(longitude), float(latitude), srid=4326)

            # Get active sessions to find logged-in volunteers
            active_sessions = Session.objects.filter(expire_date__gte=timezone.now())
            logged_in_user_ids = []

            # Extract user IDs from valid sessions
            for session in active_sessions:
                try:
                    data = session.get_decoded()
                    uid = data.get('_auth_user_id')
                    if uid:
                        logged_in_user_ids.append(int(uid))
                except:
                    continue

            # Find nearest logged-in volunteer within 10km
            nearest_volunteer = (
                UserProfile.objects.filter(
                    user_type="VOLUNTEER",
                    location__isnull=False,
                    user__id__in=logged_in_user_ids  # Only get logged-in volunteers
                )
                .annotate(
                    distance=Distance("location", report_location)
                )
                .filter(distance__lte=D(km=10))  # Within 10km radius
                .order_by("distance")
                .first()
            )

            report = AnimalReport.objects.create(
                user=request.user,
                photo=request.FILES["photo"],
                description=request.data["description"],
                location=report_location,
                status="PENDING",
                priority=priority,
            )

            if nearest_volunteer:
                report.assigned_to = nearest_volunteer.user
                report.status = "ASSIGNED"
                report.save()

                # Create a rescue task for the volunteer
                task = RescueTask.objects.create(
                    title=f"Animal Rescue #{report.id}",
                    description=report.description,
                    assigned_to=nearest_volunteer.user,
                    location=report_location,
                    priority=priority,
                    report=report,
                    is_completed=False
                )

                # Send email to volunteer
                sm.send_mail_to_volunteer(nearest_volunteer, report)

                return Response(
                    {
                        "status": "success",
                        "message": "Report submitted and assigned to a volunteer.",
                        "task_id": task.id,
                        "assigned_volunteer": {
                            "id": nearest_volunteer.id,
                            "user": {
                                "username": nearest_volunteer.user.username,
                                "id": nearest_volunteer.user.id
                            },
                            "location": {
                                "type": "Point",
                                "coordinates": [
                                    nearest_volunteer.location.x,
                                    nearest_volunteer.location.y
                                ]
                            },
                            "mobile_number": str(nearest_volunteer.mobile_number),
                            "distance": {
                                "text": f"{nearest_volunteer.distance.km:.2f} km away",
                                "value": nearest_volunteer.distance.km
                            }
                        },
                        "priority": report.priority
                    }, 
                    status=status.HTTP_201_CREATED
                )

            # **If no volunteers, assign to admin**
            admin_profile = UserProfile.objects.filter(user_type="ADMIN").first()
            if admin_profile:
                report.assigned_to = admin_profile.user
                report.status = "ADMIN_REVIEW"
                report.save()

                sm.send_mail_to_admin(admin_profile, report, request)

                return Response(
                    {
                        "status": "success",
                        "message": "No nearby volunteers available. Report assigned to admin.",
                        "assigned_to": "admin",
                        "priority": report.priority,
                    },
                    status=status.HTTP_201_CREATED,
                )

            return Response(
                {
                    "status": "success",
                    "message": "Report submitted. Waiting for assignment.",
                    "priority": report.priority,
                },
                status=status.HTTP_201_CREATED,
            )

        except Exception as e:
            logger.error(f"Error in UserReportView: {str(e)}")
            return Response(
                {"status": "error", "message": f"Error processing report: {str(e)}"},
                status=status.HTTP_400_BAD_REQUEST,
            )

    def get(self, request, *args, **kwargs):
        return Response(
            {
                "message": "Please use POST method to submit an animal report.",
                "required_fields": {
                    "photo": "Image file from camera",
                    "description": "Text description of the situation",
                    "latitude": "Current location latitude",
                    "longitude": "Current location longitude",
                    "priority": "LOW, MEDIUM, or HIGH (optional, defaults to MEDIUM)",
                },
            },
            status=status.HTTP_405_METHOD_NOT_ALLOWED,
        )

### v2 of user-report
class UserReportV2View(generics.CreateAPIView):
    serializer_class = AnimalReport2Serializer
    permission_classes = [IsAuthenticated]

    def create(self, request, *args, **kwargs):
        try:
            logger.info(f"Received data: {request.data}")

            # Validate required fields
            if not request.data.get("description"):
                return Response({"status": "error", "message": "Description is required"}, status=status.HTTP_400_BAD_REQUEST)

            if not request.data.get("latitude") or not request.data.get("longitude"):
                return Response({"status": "error", "message": "Location coordinates are required"}, status=status.HTTP_400_BAD_REQUEST)

            # Ensure priority is valid
            priority = request.data.get("priority", "MEDIUM").strip().upper()
            if priority not in ["LOW", "MEDIUM", "HIGH"]:
                return Response({"status": "error", "message": "Invalid priority. Choose from LOW, MEDIUM, HIGH"}, status=status.HTTP_400_BAD_REQUEST)

            logger.info(f"Final Priority assigned: {priority}")

            # Create the report
            report = AnimalReport.objects.create(
                user=request.user,
                description=request.data["description"],
                location=Point(float(request.data["longitude"]), float(request.data["latitude"]), srid=4326),
                status="PENDING",
                priority=priority,
            )

            # Handle multiple images
            if "photos" in request.FILES:
                images = request.FILES.getlist("photos")  # Get list of images
                for image in images:
                    AnimalReportImage.objects.create(report=report, image=image)

            return Response(
                {"status": "success", "message": "Report submitted.", "priority": report.priority},
                status=status.HTTP_201_CREATED,
            )

        except Exception as e:
            logger.error(f"Error in UserReportV2View: {str(e)}")
            return Response({"status": "error", "message": f"Error processing report: {str(e)}"}, status=status.HTTP_400_BAD_REQUEST)


class AnimalReportListView(generics.ListAPIView):
    queryset = AnimalReport.objects.all().order_by(
        "-timestamp"
    )  # Get reports in descending order
    serializer_class = AnimalReportListSerializer
    permission_classes = [IsAuthenticated]

#### Login/Signup View Class ###

class PasswordResetRequestView(generics.GenericAPIView):
    serializer_class = PasswordResetRequestSerializer
    permission_classes = [AllowAny]  # Allow any user to access this view

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            user = User.objects.get(email=email)
            subject = "Password Reset Requested"
            email_template_name = "registration/password_reset_email.html"
            context = {
                "email": user.email,
                "domain": request.get_host(),
                "site_name": "Wesalvatore",
                "uid": urlsafe_base64_encode(force_bytes(user.pk)),
                "token": default_token_generator.make_token(user),
                "protocol": "http",
            }
            email = render_to_string(email_template_name, context)
            send_mail(subject, email, settings.DEFAULT_FROM_EMAIL, [user.email], fail_silently=False)
            return Response({"message": "A password reset link has been sent to your email."}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LoginView(generics.GenericAPIView):
    serializer_class = LoginSerializer
    permission_classes = [AllowAny]  # Allow any user to access this view

    def get(self, request, *args, **kwargs):
        return Response({
            "message": "Please provide your username, password, and user type to log in."
        }, status=status.HTTP_200_OK)

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            username = serializer.validated_data['username']
            password = serializer.validated_data['password']
            user_type = serializer.validated_data['user_type']

            # Authenticate user
            user = authenticate(request, username=username, password=password)
            if user is None:
                return Response({
                    "error": "Invalid username or password."
                }, status=status.HTTP_401_UNAUTHORIZED)

            # Retrieve or create user profile
            profile, created = UserProfile.objects.get_or_create(user=user)
            
            if profile.user_type != user_type:
                return Response({
                    "error": f"This account is not registered as {user_type}."
                }, status=status.HTTP_403_FORBIDDEN)

            # Log in the user and generate a token
            login(request, user)  # Optional: Only needed for session-based authentication
            token, _ = Token.objects.get_or_create(user=user)

            return Response({
                "message": "Login successful.",
                "user_type": profile.user_type,
                "token": token.key  # Return the token
            }, status=status.HTTP_200_OK)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class SignUpView(generics.CreateAPIView):
    serializer_class = SignUpSerializer
    permission_classes = [AllowAny]  # Allow any user to access this view

    def get(self, request, *args, **kwargs):
        return Response({
            "message": "Please provide the following fields to sign up: username, email, password, user_type, mobile_number."
        }, status=status.HTTP_200_OK)

    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            return Response({
                "user": serializer.data,
                "message": "User created successfully."
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
