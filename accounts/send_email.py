from django.core.mail import send_mail
from django.conf import settings


def send_mail_to_volunteer(volunteer_profile, report):
    """
    Sends an email notification to the assigned volunteer with report details.
    """
    subject = 'New Animal Report Assigned'
    message = f"""
    Hello {volunteer_profile.user.get_full_name() or volunteer_profile.user.username},

    A new animal report has been assigned to you. Here are the details:

    Description: {report.description}
    Location: Latitude {report.location.y}, Longitude {report.location.x}
    Reported by: {report.user.get_full_name() or report.user.username}

    Please check your dashboard for more details.

    Thank you,
    Rescue Team
    """
    recipient_list = [volunteer_profile.user.email]

    send_mail(subject, message, settings.EMAIL_HOST_USER, recipient_list, fail_silently=False)


def send_mail_to_org(profile, report, request):
    """
    Sends an email notification to the Organization when no volunteer is available.
    """
    subject = "New Animal Report - No Volunteers Available"
    message = f"""
    A new animal report requires Organization attention.

    Priority: {report.priority}
    Description: {report.description}
    Location: Latitude {report.location.y}, Longitude {report.location.x}
    Reported by: {request.user.get_full_name() or request.user.username}
    Contact: {request.user.userprofile.mobile_number}

    Please check the Organization panel for more details.

    Regards,
    Rescue Team
    """
    recipient_list = [profile.user.email]

    send_mail(subject, message, settings.DEFAULT_FROM_EMAIL, recipient_list, fail_silently=False)
