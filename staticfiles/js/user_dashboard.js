let stream;
const camera = document.getElementById('camera');
const photoCanvas = document.getElementById('photoCanvas');
const photoPreview = document.getElementById('photoPreview');
const startButton = document.getElementById('startCamera');
const captureButton = document.getElementById('capturePhoto');
const retakeButton = document.getElementById('retakePhoto');


function getCookie(name) {
    let cookies = document.cookie.split('; ');
    for (let i = 0; i < cookies.length; i++) {
        let cookiePair = cookies[i].split('=');
        if (cookiePair[0] === name) {
            return cookiePair[1];
        }
    }
    return null;
}


// Camera handling
startButton.addEventListener('click', async () => {
    try {
        stream = await navigator.mediaDevices.getUserMedia({ video: true });
        camera.srcObject = stream;
        camera.style.display = 'block'; // Show the camera
        startButton.style.display = 'none'; // Hide the start button
        captureButton.style.display = 'block'; // Show the capture button
    } catch (err) {
        console.error('Error accessing camera:', err);
        alert('Could not access camera');
    }
});

captureButton.addEventListener('click', () => {
    if (!stream) {
        alert('Camera is not active');
        return;
    }
    photoCanvas.width = camera.videoWidth;
    photoCanvas.height = camera.videoHeight;
    photoCanvas.getContext('2d').drawImage(camera, 0, 0);

    // Convert canvas to base64 image data
    photoData.value = photoCanvas.toDataURL('image/jpeg');

    // Show preview and retake button
    photoPreview.src = photoData.value;
    photoPreview.style.display = 'block'; // Show the photo preview
    camera.style.display = 'none'; // Hide the camera
    captureButton.style.display = 'none'; // Hide the capture button
    retakeButton.style.display = 'block'; // Show the retake button

    // Stop camera stream
    stream.getTracks().forEach(track => track.stop());
    stream = null; // Clear the stream variable
});

retakeButton.addEventListener('click', async () => {
    photoPreview.style.display = 'none'; // Hide the photo preview
    retakeButton.style.display = 'none'; // Hide the retake button
    startButton.style.display = 'block'; // Show the start button again
    try {
        stream = await navigator.mediaDevices.getUserMedia({ video: true });
        camera.srcObject = stream;
        camera.style.display = 'block'; // Show the camera again
        startButton.style.display = 'none'; // Hide the start button
        captureButton.style.display = 'block'; // Show the capture button
    } catch (err) {
        console.error('Error accessing camera:', err);
        alert('Could not access camera');
    }
});

// Location handling
let map;
let userMarker;
let userLocationSaved = false; // To track if location has been saved to DB
let assignedVolunteerMarker = null;
let trackingLine = null;
let reportMarker = null;

const markerIcons = {   
    'USER': L.icon({
        iconUrl: '/static/images/user-marker.png',
        iconSize: [32, 32],
        iconAnchor: [16, 32],
        popupAnchor: [0, -32]
    }),
    'VOLUNTEER': L.icon({
        iconUrl: '/static/images/volunteer-marker.png',
        iconSize: [32, 32],
        iconAnchor: [16, 32],
        popupAnchor: [0, -32]
    }),
    'ADMIN': L.icon({
        iconUrl: '/static/images/admin-marker.png',
        iconSize: [32, 32],
        iconAnchor: [16, 32],
        popupAnchor: [0, -32]
    }),
    'REPORT': L.icon({
        iconUrl: '/static/images/marked.png',
        iconSize: [32, 32],
        iconAnchor: [16, 32],
        popupAnchor: [0, -32]
    })
};

// Add this helper function to calculate the zoom level for a 10km radius
function getZoomLevelForRadius(lat, radius) {
    // Earth's radius in kilometers
    const R = 6371;
    
    // Convert radius from km to radians
    const radiusRad = radius / R;
    
    // Calculate zoom level
    // 360 is the total degrees in a circle
    const zoom = Math.round(Math.log2(360 / (radiusRad * (180 / Math.PI) * 2)));
    
    return zoom;
}

// Initialize the map
function initMap() {
    map = L.map('map', {
        minZoom: 3,
        maxZoom: 18
    }).setView([0, 0], 13);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);

    // Remove the "Leaflet" attribution
    map.attributionControl.setPrefix('');

    // Add custom recenter control
    const recenterControl = L.Control.extend({
        options: {
            position: 'bottomleft'
        },

        onAdd: function(map) {
            const container = L.DomUtil.create('div', 'custom-map-control');
            container.innerHTML = '<i class="fas fa-crosshairs"></i>';
            container.title = 'Recenter Map';
            
            container.onclick = function() {
                recenterMap();
            }
            
            return container;
        }
    });

    map.addControl(new recenterControl());

    // Get user location and save to DB
    getUserLocation();
}

// Function to recenter the map on user's location with 10km radius
function recenterMap() {
    if (userMarker) {
        const pos = userMarker.getLatLng();
        
        // Remove existing radius circle if any
        if (window.radiusCircle) {
            window.radiusCircle.remove();
        }
        
        // Create new 10km radius circle
        window.radiusCircle = L.circle([pos.lat, pos.lng], {
            radius: 10000, // 10km in meters
            color: '#3388ff',
            fillColor: '#3388ff',
            fillOpacity: 0.1,
            weight: 1
        }).addTo(map);
        
        // Fit map to the radius circle bounds
        map.fitBounds(window.radiusCircle.getBounds());
    }
}

// Get user location & store it in the database once
function getUserLocation() {
    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
            (position) => {
                const latitude = position.coords.latitude;
                const longitude = position.coords.longitude;

                console.log("User location:", latitude, longitude);

                // Place a marker for the user
                userMarker = L.marker([latitude, longitude], { 
                    icon: markerIcons['USER']
                }).addTo(map);

                // Create a 10km radius circle
                if (window.radiusCircle) {
                    window.radiusCircle.remove();
                }
                window.radiusCircle = L.circle([latitude, longitude], {
                    radius: 10000, // 10km in meters
                    color: '#3388ff',
                    fillColor: '#3388ff',
                    fillOpacity: 0.1,
                    weight: 1
                }).addTo(map);

                // Set the map view to fit the radius
                map.fitBounds(window.radiusCircle.getBounds());

                // Add popup to user marker
                userMarker.bindPopup("Your Location").openPopup();

                // Store location in cookies
                document.cookie = `latitude=${latitude}; path=/`;
                document.cookie = `longitude=${longitude}; path=/`;
                console.log("Location stored in cookies.");

                // Save to database only once
                if (!userLocationSaved) {
                    saveUserLocation(latitude, longitude);
                    userLocationSaved = true;
                }

                // Set up live location tracking
                navigator.geolocation.watchPosition(
                    (newPosition) => {
                        const newLat = newPosition.coords.latitude;
                        const newLng = newPosition.coords.longitude;

                        // Update user marker position
                        userMarker.setLatLng([newLat, newLng]);
                        
                        // Update radius circle position
                        if (window.radiusCircle) {
                            window.radiusCircle.setLatLng([newLat, newLng]);
                        }

                        // Update cookies and save new location
                        document.cookie = `latitude=${newLat}; path=/`;
                        document.cookie = `longitude=${newLng}; path=/`;
                        saveUserLocation(newLat, newLng);
                    },
                    (error) => {
                        console.error("Error tracking location:", error);
                    },
                    { 
                        enableHighAccuracy: true,
                        timeout: 5000,
                        maximumAge: 0
                    }
                );
            },
            (error) => {
                console.error("Error getting location:", error);
            },
            { 
                enableHighAccuracy: true,
                timeout: 5000,
                maximumAge: 0
            }
        );
    } else {
        console.error("Geolocation is not supported by this browser.");
    }
}

// Save user's location to the backend API
function saveUserLocation(latitude, longitude) {
// Fetch CSRF Token
const csrfTokenElement = document.querySelector('[name=csrfmiddlewaretoken]');
const csrfToken = csrfTokenElement ? csrfTokenElement.value : null;
        if (!csrfToken) {
        console.error("CSRF token not found.");
            return;
        }
    fetch("/api/save-location/", {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            'X-CSRFToken': csrfToken,  // Include CSRF token in the request headers
        },
        body: JSON.stringify({ latitude, longitude })
    })
    .then(response => response.json())
    .then(data => console.log("Location saved:", data))
    .catch(error => console.error("Error saving location:", error));
}




// Function to fetch nearby volunteers
async function fetchNearbyVolunteers(latitude, longitude) {
    try {
        if (!latitude || !longitude) {
            console.error('Invalid coordinates');
            return;
        }

        const response = await fetch(
            `/api/volunteers/nearby/?lat=${latitude}&lng=${longitude}`,
            {
                method: 'GET',
                headers: {
                    'Accept': 'application/json',
                },
                credentials: 'include'
            }
        );

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        console.log('Fetched volunteers:', data);  // Debug log
        
        // Clear existing volunteer markers
        if (window.volunteerMarkers) {
            window.volunteerMarkers.forEach(marker => marker.remove());
        }
        window.volunteerMarkers = [];

        // Add markers for each volunteer
        data.forEach(volunteer => {
            if (volunteer.location && volunteer.location.coordinates) {
                const marker = L.marker([
                    volunteer.location.coordinates[1],  // latitude
                    volunteer.location.coordinates[0]   // longitude
                ], {icon: markerIcons['VOLUNTEER']}).addTo(map);

                const distance = volunteer.distance ? 
                    volunteer.distance.text : 
                    'Distance unknown';

                const mobile_number = volunteer.mobile_number ? 
                    volunteer.mobile_number: 
                    'Not available';
                console.log(mobile_number);

                const name = volunteer.user ? 
                    (volunteer.user.first_name || volunteer.user.username) : 
                    'Volunteer';

                // Simplified popup content
                marker.bindPopup(`
                    <div class="volunteer-popup">
                        <strong>${name}</strong><br>
                        ${distance}<br>
                        <strong>Mobile No:</strong> ${mobile_number}
                    </div>
                `);
                window.volunteerMarkers.push(marker);
            }
        });

        // Update volunteer count display if it exists
        const volunteerCountElement = document.getElementById('volunteerCount');
        if (volunteerCountElement) {
            volunteerCountElement.textContent = `Available Volunteers: ${data.length}`;
        }

    } catch (error) {
        console.error('Error fetching volunteers:', error);
    }
}

// // Function to fetch and display all admins on the map
async function fetchAdmins() {
    try {
        const response = await fetch('/api/admins/', {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
            },
            credentials: 'include'
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        console.log('Fetched admins:', data);

        // Remove existing admin markers
        if (window.adminMarkers) {
            window.adminMarkers.forEach(marker => marker.remove());
        }
        window.adminMarkers = [];

        // Add a single marker for all admins at the static location
        const staticLat = 18.5204;
        const staticLng = 73.8567;

        const marker = L.marker([staticLat, staticLng], {
            icon: markerIcons['ADMIN']
        }).addTo(map);

        marker.bindPopup(`
            <strong>Admin Office</strong><br>
            <strong>Location:</strong> Pune, Maharashtra, India
        `);
        
        window.adminMarkers.push(marker);

    } catch (error) {
        console.error('Error fetching admins:', error);
    }
}



// // Function to send report to admin
async function sendReportToAdmin() {
    const formData = new FormData();
    formData.append('photo', document.getElementById('imageData').value);  // Change to match the field name
    formData.append('description', document.getElementById('description').value);
    formData.append('latitude', document.getElementById('latitude').value);
    formData.append('longitude', document.getElementById('longitude').value);

    try {
        const response = await fetch('/api/admin/report/', {
            method: 'POST',
            body: formData,
        });
        if (!response.ok) throw new Error('Network response was not ok');
        const result = await response.json();
        alert(result.message);
    } catch (error) {
        console.error('Error sending report to admin:', error);
        alert('Failed to send report to admin.');
    }
}

// Function to submit the report
async function submitReport() {
    const descriptionInput = document.getElementById('description');
    const photoDataInput = document.getElementById('photoData'); // This holds base64

    if (!descriptionInput || !photoDataInput) {
        alert('Required input elements are missing.');
        return;
    }

    if (!descriptionInput.value || !photoDataInput.value) {
        alert('Please fill in all fields and ensure an image is captured.');
        return;
    }

    const latitude = getCookie('latitude');
    const longitude = getCookie('longitude');

    if (!latitude || !longitude) {
        alert('Location is not available. Please enable location services.');
        return;
    }

    try {

        // Clear existing tracking elements
        if (assignedVolunteerMarker) {
            assignedVolunteerMarker.remove();
            assignedVolunteerMarker = null;
        }
        if (trackingLine) {
            trackingLine.remove();
            trackingLine = null;
        }
        if (window.volunteerTrackingInterval) {
            clearInterval(window.volunteerTrackingInterval);
        }

        // Add report marker to the map
        if (reportMarker) {
            reportMarker.remove();
        }
        reportMarker = L.marker([parseFloat(latitude), parseFloat(longitude)], {
            icon: markerIcons['REPORT']
        }).addTo(map);
        reportMarker.bindPopup("Reported Location").openPopup();

        const formData = new FormData();
        const file = await convertBase64ToFile(photoDataInput.value, "captured_photo.jpg");
        formData.append('photo', file);
        formData.append('description', descriptionInput.value);
        formData.append('latitude',parseFloat(latitude)); // Ensure it's a number
        formData.append('longitude', parseFloat(longitude)); // Ensure it's a number
        formData.append('priority', document.getElementById('priority').value || 'MEDIUM');

        // Fetch CSRF Token
        const csrfToken = getCookie('csrftoken');
        if (!csrfToken) {
            throw new Error("CSRF token not found.");
        }

        const response = await fetch('/api/user_report/', {
            method: 'POST',
            body: formData,
            headers: {
                'X-CSRFToken': csrfToken,  // Include CSRF token in the request headers
            },
            credentials: "include"  // Required to include cookies (session authentication)
        });

        if (!response.ok) {
            throw new Error(`Error ${response.status}: ${response.statusText}`);
        }

        const result = await response.json();
        console.log('Report submission result:', result);

        if (result.assigned_volunteer) {
            // Create a task for the assigned volunteer
            const taskResponse = await fetch('/api/create_task/', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRFToken': csrfToken,
                },
                body: JSON.stringify({
                    title: 'Animal Rescue Request',
                    description: descriptionInput.value,
                    volunteer_id: result.assigned_volunteer.id,
                    latitude: parseFloat(latitude),
                    longitude: parseFloat(longitude),
                    report_id: result.report_id
                }),
                credentials: "include"
            });

            if (!taskResponse.ok) {
                console.error('Failed to create task for volunteer');
            }
            
            // Show the assigned volunteer on the map
            showAssignedVolunteer(
                result.assigned_volunteer,
                parseFloat(latitude),
                parseFloat(longitude)
            );
            
            // Start tracking the volunteer's movement
            startVolunteerTracking(
                result.assigned_volunteer.id,
                parseFloat(latitude),
                parseFloat(longitude)
            );

            alert(`Report submitted successfully. Volunteer ${result.assigned_volunteer.user.username} has been assigned.`);
        } else {
            alert('Report submitted, but no volunteer is currently available.');
        }

    } catch (error) {
        console.error('Error submitting report:', error);
        alert('Failed to submit report. Please try again.');
    }
}

// Helper function to convert base64 to File object
async function convertBase64ToFile(base64String, filename) {
    const response = await fetch(base64String);
    const blob = await response.blob();
    return new File([blob], filename, { type: 'image/jpeg' });
}

// Add this new function to get route coordinates
async function getRouteCoordinates(startLat, startLng, endLat, endLng) {
    try {
        // OSRM expects coordinates in longitude,latitude format
        const response = await fetch(
            `https://router.project-osrm.org/route/v1/driving/` +
            `${startLng},${startLat};${endLng},${endLat}` +
            `?overview=full&geometries=geojson`
        );

        if (!response.ok) {
            throw new Error('Failed to get route');
        }

        const data = await response.json();

        if (data.code !== 'Ok' || !data.routes[0]) {
            throw new Error('No route found');
        }

        return data.routes[0].geometry.coordinates.map(coord => [coord[1], coord[0]]);
    } catch (error) {
        console.error('OSRM routing error:', error);
        throw error;
    }
}

// Add these new functions for volunteer tracking
async function showAssignedVolunteer(volunteer, reportLat, reportLng) {
    console.log('Showing assigned volunteer:', volunteer);
    console.log('Report location:', reportLat, reportLng);

    // Remove existing assigned volunteer marker and tracking line
    if (assignedVolunteerMarker) {
        assignedVolunteerMarker.remove();
    }
    if (trackingLine) {
        trackingLine.remove();
    }

    // Create marker for the assigned volunteer
    const volunteerLatLng = [
        volunteer.location.coordinates[1], 
        volunteer.location.coordinates[0]
    ];

    // Create marker for the assigned volunteer
    assignedVolunteerMarker = L.marker(volunteerLatLng, {
        icon: markerIcons['VOLUNTEER'],
        zIndexOffset: 1000
    }).addTo(map);

    try {
        // Get the route coordinates
        const routeCoordinates = await getRouteCoordinates(
            volunteerLatLng[0], volunteerLatLng[1],
            reportLat, reportLng
        );

        // Create the route line with road path
        trackingLine = L.polyline(routeCoordinates, {
            color: '#FF4444',
            weight: 4,
            opacity: 0.8,
            lineCap: 'round',
            lineJoin: 'round',
            dashArray: null // Remove dashed line style
        }).addTo(map);

        // Store the report location and route for updates
        window.reportLocation = [reportLat, reportLng];
        window.lastRouteCoordinates = routeCoordinates;

        // Create popup for the assigned volunteer
        const popupContent = `
            <div class="assigned-volunteer-popup">
                <strong>Assigned Volunteer:</strong><br>
                ${volunteer.user.username}<br>
                <strong>Mobile:</strong> ${volunteer.mobile_number}<br>
                <strong>Distance:</strong> ${volunteer.distance.text}
                <br><small>Volunteer is on the way!</small>
            </div>
        `;
        assignedVolunteerMarker.bindPopup(popupContent).openPopup();

        // Fit map bounds to show the entire route
        const bounds = L.latLngBounds(routeCoordinates);
        map.fitBounds(bounds, { padding: [50, 50] });

    } catch (error) {
        console.error('Error creating route:', error);
        // Fallback to straight line if routing fails
        trackingLine = L.polyline(
            [volunteerLatLng, [reportLat, reportLng]],
            {
                color: '#FF4444',
                weight: 3,
                dashArray: '10, 10',
                opacity: 0.7
            }
        ).addTo(map);
    }
}

// Function to update volunteer position
function startVolunteerTracking(volunteerId, reportLat, reportLng) {
    console.log('Starting volunteer tracking:', volunteerId);
    // Clear any existing tracking interval
    if (window.volunteerTrackingInterval) {
        clearInterval(window.volunteerTrackingInterval);
    }

    // Set up tracking interval
    window.volunteerTrackingInterval = setInterval(async () => {
        try {
            const response = await fetch(
                `/api/volunteer/location/${volunteerId}/?reportLat=${reportLat}&reportLng=${reportLng}`
            );
            if (!response.ok) throw new Error('Failed to fetch volunteer location');
            
            const data = await response.json();
            console.log('Received volunteer location update:', data);
            
            if (data.location && assignedVolunteerMarker) {
                // Update volunteer marker position
                const newLatLng = [
                    data.location.coordinates[1],
                    data.location.coordinates[0]
                ];
                assignedVolunteerMarker.setLatLng(newLatLng);

                // Update route
                try {
                    const newRouteCoordinates = await getRouteCoordinates(
                        newLatLng[0], newLatLng[1],
                        reportLat, reportLng
                    );

                    if (trackingLine) {
                        // Smooth transition to new route
                        const currentCoords = trackingLine.getLatLngs();
                        if (JSON.stringify(currentCoords) !== JSON.stringify(newRouteCoordinates)) {
                            trackingLine.setLatLngs(newRouteCoordinates);
                        }
                    } else {
                        trackingLine = L.polyline(newRouteCoordinates, {
                            color: '#FF4444',
                            weight: 4,
                            opacity: 0.8,
                            lineCap: 'round',
                            lineJoin: 'round'
                        }).addTo(map);
                    }

                    // Update popup content with new distance
                    const popupContent = `
                        <div class="assigned-volunteer-popup">
                            <strong>Assigned Volunteer:</strong><br>
                            ${data.user.username}<br>
                            <strong>Mobile:</strong> ${data.mobile_number}<br>
                            <strong>Distance:</strong> ${data.distance.text}
                            <small>Volunteer is on the way!</small>
                        </div>
                    `;
                    assignedVolunteerMarker.setPopupContent(popupContent);

                } catch (error) {
                    console.error('Error updating route:', error);
                }
            }
        } catch (error) {
            console.error('Error updating volunteer location:', error);
        }
    }, 5000); // Update every 5 seconds
}

// Add event listener to the report form submission
document.getElementById('reportAnimalForm').addEventListener('submit', (event) => {
    event.preventDefault(); // Prevent default form submission
    submitReport(); // Call the submitReport function
});

// Single event listener for initialization
document.addEventListener('DOMContentLoaded', () => {
    console.log('DOM Content Loaded');
    
    // Initialize map first
    initMap();
    
    // Wait a short moment for map and user location to initialize
    setTimeout(() => {
        // Initial fetch of locations
        if (userMarker) {
            const { lat, lng } = userMarker.getLatLng();
            console.log('Initial location fetch:', lat, lng);
            
            // Save initial user location
            saveUserLocation(lat, lng);
            
            // Fetch initial volunteer and admin locations
            fetchNearbyVolunteers(lat, lng);
            fetchAdmins();
        } else {
            console.log('User marker not yet initialized');
        }

        // Set up periodic updates for all locations
        setInterval(() => {
            if (userMarker) {
                const { lat, lng } = userMarker.getLatLng();
                console.log('Updating locations:', lat, lng);
                
                // Update user location in database
                saveUserLocation(lat, lng);
                
                // Fetch updated volunteer and admin locations
                fetchNearbyVolunteers(lat, lng);
            }
        }, 10000); // Update every 10 seconds
    }, 2000); // Wait 2 seconds for initialization
});
