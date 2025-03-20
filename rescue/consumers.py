import json
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.layers import get_channel_layer

# Dictionary to store volunteer locations
volunteer_locations = {}

class LocationConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        """Handle WebSocket connection."""
        self.user = self.scope["user"]  # Get the logged-in user
        self.volunteer_id = None  # Default to None to prevent AttributeError

        if not self.user or not self.user.is_authenticated:
            print("❌ Unauthorized WebSocket attempt.")
            await self.close()
            return

        self.volunteer_id = str(self.user.id)  # Assign only if authenticated
        volunteer_locations[self.volunteer_id] = {"latitude": None, "longitude": None}

        # Accept WebSocket connection
        await self.accept()
        await self.channel_layer.group_add("volunteers", self.channel_name)
        print(f"✅ Volunteer {self.volunteer_id} connected.")

    async def disconnect(self, close_code):
        """Handle WebSocket disconnection."""
        if self.volunteer_id:
            volunteer_locations.pop(self.volunteer_id, None)  # Safe removal
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
            latitude = data.get("latitude")
            longitude = data.get("longitude")

            if latitude is not None and longitude is not None:
                # Update this volunteer's location
                volunteer_locations[self.volunteer_id] = {"latitude": latitude, "longitude": longitude}
                print(f"📍 Updated {self.volunteer_id} location: {latitude}, {longitude}")

                # Broadcast updated locations to all users
                await self.broadcast_volunteer_locations()
        except json.JSONDecodeError:
            await self.send(json.dumps({"error": "Invalid JSON format"}))

    async def broadcast_volunteer_locations(self):
        """Send updated locations to all connected users."""
        volunteer_list = [
            {"id": vid, "latitude": v["latitude"], "longitude": v["longitude"]}
            for vid, v in volunteer_locations.items() if v["latitude"] is not None and v["longitude"] is not None
        ]

        message = json.dumps({"volunteers": volunteer_list})

        # Send message to all connected clients
        channel_layer = get_channel_layer()
        await channel_layer.group_send("volunteers", {
            "type": "send_location_update",
            "message": message
        })

    async def send_location_update(self, event):
        """Send location updates to WebSocket clients."""
        await self.send(text_data=event["message"])
