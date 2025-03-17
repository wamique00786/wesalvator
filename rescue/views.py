from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from .models import (
    AnimalReport,
    RescueTask,

)
from accounts.models import UserProfile
import logging
from django.contrib.auth import get_user_model
logger = logging.getLogger(__name__)

User = get_user_model()


def home(request):
    if request.user.is_authenticated:
        return redirect("dashboard")
    return render(request, "landing_page/landing_page.html")


@login_required
def user_dashboard(request):
    user_profile = UserProfile.objects.get(user=request.user)
    if request.user.is_superuser:
        return redirect("/admin/")
    if user_profile.user_type != "USER":
        return redirect(f"{user_profile.user_type.lower()}_dashboard")

    # Fetch recent animal reports by the user
    recent_reports = AnimalReport.objects.filter(user=request.user).order_by(
        "-timestamp"
    )[:5]

    context = {
        "user_profile": user_profile,
        "recent_reports": recent_reports,
    }

    response = render(request, "rescue/user_dashboard.html", context)
    response["Content-Security-Policy"] = (
        "default-src 'self'; "
        "script-src 'self' 'unsafe-inline' https://unpkg.com https://cdn.jsdelivr.net; "
        "style-src 'self' 'unsafe-inline' https://unpkg.com https://cdn.jsdelivr.net; "
        "img-src 'self' blob: data: https://unpkg.com; "
        "media-src 'self' blob:; "
        "object-src 'none';"
    )
    return response


@login_required
def volunteer_dashboard(request):
    print(f"Logged in user: {request.user.username}")  # Debug print
    try:
        # Fetch the user's profile
        user_profile = UserProfile.objects.get(user=request.user)
        print(f"User profile type: {user_profile.user_type}")  # Debug print

        # Check if the user is a volunteer
        if user_profile.user_type != "VOLUNTEER":
            messages.error(request, "Access denied. Volunteer privileges required.")
            return redirect("user_dashboard")

        # Fetch all volunteers' locations
        volunteers = UserProfile.objects.filter(user_type="VOLUNTEER").exclude(
            location__isnull=True
        )

        # Fetch tasks assigned to the volunteer
        available_tasks = RescueTask.objects.filter(
            assigned_to=request.user,
            is_completed=False
        ).order_by('-created_at')

        completed_tasks = RescueTask.objects.filter(
            assigned_to=request.user, is_completed=True
        ).order_by('-created_at')

        print(f"Available tasks for {request.user.username}: {available_tasks}")
        print(f"Completed tasks for {request.user.username}: {completed_tasks}")

        # Prepare context data
        context = {
            "user_profile": user_profile,
            "volunteers": volunteers,
            "available_tasks": available_tasks,  # Add available tasks to context
            "completed_tasks": completed_tasks,  # Add completed tasks to context
        }

        # Set cookies for the volunteer's location
        if user_profile.location:
            latitude = (
                user_profile.location.y
            )  # Assuming location is a PointField (longitude, latitude)
            longitude = user_profile.location.x
            response = render(request, "rescue/volunteer_dashboard.html", context)
            response.set_cookie(
                "user_latitude", latitude, max_age=60 * 60 * 24 * 7
            )  # Store for 7 days
            response.set_cookie(
                "user_longitude", longitude, max_age=60 * 60 * 24 * 7
            )  # Store for 7 days
            return response

        return render(
            request, "rescue/volunteer_dashboard.html", context
        )  # Pass the full context
    except UserProfile.DoesNotExist:
        messages.error(request, "User profile not found")
        return redirect("login")


@login_required
def admin_dashboard(request):
    user_profile = UserProfile.objects.get(user=request.user)
    if user_profile.user_type != "ADMIN":
        return redirect(f"{user_profile.user_type.lower()}_dashboard")

    volunteers = UserProfile.objects.all()

    context = {
        "user_profile": user_profile,
        "volunteer_count": UserProfile.objects.filter(user_type="VOLUNTEER").count(),
        "volunteers": UserProfile.objects.filter(user_type="VOLUNTEER"),
    }
    return render(request, "rescue/org_dashboard.html", context)


@login_required
def dashboard(request):
    try:
        user_profile = UserProfile.objects.get(user=request.user)
        # Redirect based on user type
        if user_profile.user_type == "VOLUNTEER":
            return redirect("volunteer_dashboard")
        elif user_profile.user_type == "ADMIN":
            return redirect("org_dashboard")
        else:
            return redirect("user_dashboard")
    except UserProfile.DoesNotExist:
        # Create a default user profile if it doesn't exist
        user_profile = UserProfile.objects.create(user=request.user, user_type="USER")
        return redirect("user_dashboard")


# Add these decorator functions
def is_admin(user):
    return hasattr(user, "userprofile") and user.userprofile.user_type == "ADMIN"


def is_volunteer(user):
    return hasattr(user, "userprofile") and user.userprofile.user_type == "VOLUNTEER"
