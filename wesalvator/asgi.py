import os
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
from django.urls import re_path
from rescue.consumers import LocationConsumer  # Ensure correct import

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "wesalvator.settings")

websocket_urlpatterns = [
    re_path(r"ws/location/$", LocationConsumer.as_asgi()),
]

application = ProtocolTypeRouter({
    "http": get_asgi_application(),
    "websocket": AuthMiddlewareStack(
        URLRouter(websocket_urlpatterns)
    ),
})
