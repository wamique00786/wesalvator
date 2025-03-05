# rescue/utils.py
from django.core.mail import send_mail
from django.conf import settings

def send_notification_to_volunteer(volunteer_profile, report , longitude, latitude):
    subject = 'New Animal Report Assigned'
    message = f"""
    Hello {volunteer_profile.user.get_full_name() or volunteer_profile.user.username},

    A new animal report has been assigned to you. Here are the details:

    Description: {report.description}
    Location: Latitude {latitude}, Longitude {longitude}
    Reported by: {report.user.get_full_name() or report.user.username}

    Please check your dashboard for more details.

    Thank you,
    Rescue Team
    """
    recipient_list = [volunteer_profile.user.email]
    send_mail(subject, message, settings.EMAIL_HOST_USER, recipient_list)