from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.geos import Point
from django.contrib.gis.measure import D
from ..models import UserProfile
from rescue.models import AnimalReport
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from ..serializers import (
    UserProfileSerializer,
    AnimalReportSerializer,
    AnimalReportListSerializer,
)
from .. import send_email as sm
import logging
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny

logger = logging.getLogger(__name__)


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
            user_location = Point(
                float(lng), float(lat), srid=4326  # longitude first  # latitude second
            )

            # Query for nearby volunteers with distance annotation
            volunteers = (
                UserProfile.objects.filter(
                    user_type="VOLUNTEER", location__isnull=False
                )
                .annotate(distance=Distance("location", user_location))
                .filter(distance__lte=D(km=10))  # 10km radius
                .order_by("distance")
            )

            return volunteers

        except (ValueError, TypeError) as e:
            print(f"Error in NearbyVolunteersView: {str(e)}")
            return UserProfile.objects.none()

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context["distance"] = True  # Add flag to include distance in serializer
        return context


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

            if not request.data.get("latitude") or not request.data.get("longitude"):
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

            # Create the report with correct location SRID
            report = AnimalReport.objects.create(
                user=request.user,
                photo=request.FILES["photo"],
                description=request.data["description"],
                location=Point(
                    float(request.data["longitude"]),
                    float(request.data["latitude"]),
                    srid=4326,
                ),
                status="PENDING",
                priority=priority,
            )

            # Ensure the report location SRID is correct
            if report.location.srid != 4326:
                report.location.transform(4326)

            # **Find the nearest volunteer within 10km**
            nearest_volunteer = (
                UserProfile.objects.filter(
                    user_type="VOLUNTEER", location__isnull=False
                )
                .annotate(distance=Distance("location", report.location))
                .filter(distance__lte=D(km=10))  # Ensure using km for distance
                .order_by("distance")
                .first()
            )

            if nearest_volunteer:
                report.assigned_to = nearest_volunteer.user
                report.status = "ASSIGNED"
                report.save()

                # Send email to volunteer
                sm.send_mail_to_volunteer(nearest_volunteer, report)

                return Response(
                    {
                        "status": "success",
                        "message": "Report submitted and assigned to a volunteer.",
                        "volunteer": {
                            "name": nearest_volunteer.user.get_full_name()
                            or nearest_volunteer.user.username,
                            "distance": f"{nearest_volunteer.distance.km:.2f} km",
                        },
                        "priority": report.priority,
                    },
                    status=status.HTTP_201_CREATED,
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


class AnimalReportListView(generics.ListAPIView):
    queryset = AnimalReport.objects.all().order_by(
        "-timestamp"
    )  # Get reports in descending order
    serializer_class = AnimalReportListSerializer
    permission_classes = [IsAuthenticated]
