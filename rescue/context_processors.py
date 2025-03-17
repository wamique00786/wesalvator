from django.utils import timezone
from .models import RescueTask

def rescued_animals_count(request):
    """
    Context processor to provide the count of animals rescued today
    to all templates.
    """
    today = timezone.now().date()
    total_rescued_today = RescueTask.objects.filter(
        created_at__date=today,
        is_completed=True
    ).count()

    return {
        'total_rescued_today': total_rescued_today
    } 