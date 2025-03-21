from django.shortcuts import render, redirect
from django.contrib import messages
from django.core.mail import send_mail
from django.http import JsonResponse
from django.conf import settings
from .models import JobOpening
import re

def career_view(request):
    jobs = JobOpening.objects.all()
    return render(request, 'base/career.html', {'jobs': jobs})

def team(request):
    return render(request, 'base/team.html')

def contact_us(request):
    if request.method == "POST":
        name = request.POST.get("name")
        email = request.POST.get("email")
        message = request.POST.get("message")

        subject = f"New Contact Us Message from {name}"
        body = f"Name: {name}\nEmail: {email}\n\nMessage:\n{message}"

        try:
            send_mail(
                subject, 
                body, 
                email, 
                [settings.DEFAULT_FROM_EMAIL],  # Replace with the receiver's email
                fail_silently=False
            )
            messages.success(request, "Your message has been sent successfully!")
        except Exception as e:
            messages.error(request, f"Error sending email: {e}")

        return redirect("contact_us")  # Ensure 'contact_us' is the correct URL name

    return render(request, "base/contact_us.html", {"contact_email": settings.ADMIN_EMAIL})

def about(request):
    return render(request, 'base/about.html')

def send_notification_email(request):
    if request.method == "POST":
        email = request.POST.get("email", "").strip()

        # Validate Email Format
        if not re.match(r"[^@]+@[^@]+\.[^@]+", email):
            return JsonResponse({"error": "Invalid email address!"}, status=400)

        try:
            # Send Email
            send_mail(
                "Wesalvator - Stay Notified!",
                "Thank you for subscribing! We will notify you when we launch.",
                settings.DEFAULT_FROM_EMAIL,  # Change to your SMTP configured sender email
                [email],
                fail_silently=False,
            )
            return JsonResponse({"success": "Notification email sent successfully!"})

        except Exception as e:
            return JsonResponse({"error": f"Error sending email: {str(e)}"}, status=500)

    return JsonResponse({"error": "Invalid request method!"}, status=400)