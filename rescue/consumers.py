import json
from datetime import timedelta
from django.utils.timezone import now
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.layers import get_channel_layer
from asgiref.sync import sync_to_async
from rescue.models import VolunteerLocation

# Dictionary to store active volunteer locations
volunteer_locations = {}

class LocationConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        """Handle WebSocket connection."""
        self.user = self.scope["user"]
        self.volunteer_id = None

        if not self.user or not self.user.is_authenticated:
            print("❌ Unauthorized WebSocket attempt.")
            await self.close()
            return

        self.volunteer_id = str(self.user.id)
        volunteer_locations[self.volunteer_id] = {"latitude": None, "longitude": None}

        await self.accept()
        await self.channel_layer.group_add("volunteers", self.channel_name)
        print(f"✅ Volunteer {self.volunteer_id} connected.")

    async def disconnect(self, close_code):
        """Handle WebSocket disconnection."""
        if self.volunteer_id:
            volunteer_locations.pop(self.volunteer_id, None)  # Remove from in-memory store
            await self.channel_layer.group_discard("volunteers", self.channel_name)
            print(f"🚪 Volunteer {self.volunteer_id} disconnected.")

    async def receive(self, text_data):
        """Handle incoming location updates."""
        if not self.volunteer_id:
            await self.send(json.dumps({"error": "Unauthorized"}))
            await self.close()
            return

        try:
            data = json.loads(text_data)
            print(data)
            latitude = data.get("latitude")
            longitude = data.get("longitude")

            if latitude is not None and longitude is not None:
                # Update in-memory location
                volunteer_locations[self.volunteer_id] = {"latitude": latitude, "longitude": longitude}
                print(f"📍 Updated {self.volunteer_id} location: {latitude}, {longitude}")

                # Update the database
                await self.update_volunteer_location(latitude, longitude)

                # Remove outdated entries (older than 24 hours)
                await self.cleanup_old_locations()

                # Broadcast updated locations
                await self.broadcast_volunteer_locations()
        except json.JSONDecodeError:
            await self.send(json.dumps({"error": "Invalid JSON format"}))

    @sync_to_async
    def update_volunteer_location(self, latitude, longitude):
        """Update location in VolunteerLocation."""
        try:
            # Ensure latitude and longitude are not None
            latitude = float(latitude) if latitude is not None else 0.0
            longitude = float(longitude) if longitude is not None else 0.0

            # Use update_or_create to avoid inserting null values
            volunteer_location, created = VolunteerLocation.objects.update_or_create(
                volunteer_id=self.volunteer_id,
                defaults={"latitude": latitude, "longitude": longitude, "updated_at": now()},
            )

            print(f"✅ Volunteer {self.volunteer_id} location updated in DB.")
        except Exception as e:
            print(f"⚠️ Error updating location: {str(e)}")

    async def broadcast_volunteer_locations(self):
        """Broadcast updated volunteer locations to all clients."""
        channel_layer = get_channel_layer()
        message = json.dumps({"type": "volunteer_locations", "locations": volunteer_locations})
        
        # Send the message to all volunteers in the group
        await channel_layer.group_send("volunteers", {"type": "send_location_update", "message": message})


    @sync_to_async
    def cleanup_old_locations(self):
        """Delete volunteer locations older than 24 hours."""
        cutoff_time = now() - timedelta(hours=24)
        deleted_count, _ = VolunteerLocation.objects.filter(updated_at__lt=cutoff_time).delete()
        if deleted_count > 0:
            print(f"🗑️ Deleted {deleted_count} outdated volunteer locations.")


    async def send_location_update(self, event):
        """Send location updates to WebSocket clients."""
        await self.send(text_data=event["message"])
