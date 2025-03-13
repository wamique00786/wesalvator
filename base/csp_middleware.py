class ContentSecurityPolicyMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)

        response['Content-Security-Policy'] = (
            "default-src 'self'; "
            "script-src 'self' https://unpkg.com https://cdn.jsdelivr.net "
            "https://translate.google.com https://translate.googleapis.com "
            "https://translate-pa.googleapis.com https://cdnjs.cloudflare.com "
            "https://code.jquery.com 'unsafe-inline'; "  
            "style-src 'self' https://unpkg.com https://cdn.jsdelivr.net https://cdnjs.cloudflare.com "
            "https://www.gstatic.com https://fonts.googleapis.com 'unsafe-inline'; "
            "img-src 'self' data: https://*.tile.openstreetmap.org https://unpkg.com "
            "https://fonts.gstatic.com https://www.google.com https://www.gstatic.com "
            "https://translate.googleapis.com http://translate.google.com https://translate.google.com; "
            "font-src 'self' https://cdnjs.cloudflare.com https://fonts.gstatic.com https://fonts.googleapis.com; "
            "object-src 'none'; "
            "connect-src 'self' data: https://nominatim.openstreetmap.org "
            "https://translate.googleapis.com https://translate-pa.googleapis.com "
            "https://ipwhois.app https://ipapi.co http://ip-api.com "
            "https://router.project-osrm.org/route/v1/driving/; "
            "form-action 'self' data:; "
        )

        return response
