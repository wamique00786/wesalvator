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
    })
};

// Initialize the map
function initMap() {
    map = L.map('map').setView([0, 0], 13);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);

    // Get user location and save to DB
    getUserLocation();

    // Fetch nearby volunteers & admins every 10 seconds
    setInterval(() => {
        if (userMarker) {
            const { lat, lng } = userMarker.getLatLng();
            fetchNearbyVolunteers(lat, lng);
            fetchAdmins();
        }
    }, 10000);
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
                userMarker = L.marker([latitude, longitude], { icon: markerIcons['USER'] }).addTo(map)
                    .bindPopup("Your Location").openPopup();

                // Center the map on the user
                map.setView([latitude, longitude], 13);

                // Store location in cookies
                document.cookie = `latitude=${latitude}; path=/`;
                document.cookie = `longitude=${longitude}; path=/`;
                console.log("Location stored in cookies.");

                // Save to database only once
                if (!userLocationSaved) {
                    saveUserLocation(latitude, longitude);
                    userLocationSaved = true; // Prevent multiple API calls
                }
            },
            (error) => {
                console.error("Error getting location:", error);
            },
            { enableHighAccuracy: true, timeout: 5000, maximumAge: 0 }
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
                }
            }
        );

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();
        
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

                marker.bindPopup(
                    `<strong>${name}</strong><br>${distance} <br>
                    <strong>Mobile No.</strong>${mobile_number}`
                );
                window.volunteerMarkers.push(marker);
            }
        });

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
            }
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();

        // Remove existing admin markers
        if (window.adminMarkers) {
            window.adminMarkers.forEach(marker => marker.remove());
        }
        window.adminMarkers = [];

        // Loop through each admin and add them to the map
        data.forEach(admin => {
            if (admin.location && admin.location.coordinates) {
                const marker = L.marker([
                    admin.location.coordinates[1], // latitude
                    admin.location.coordinates[0]  // longitude
                ], { icon: markerIcons['ADMIN'] }).addTo(map);

                // Get admin name
                const name = admin.user.first_name || admin.user.username || "Admin";

                // Get distance text
                const distance = admin.distance ? admin.distance.text : "Distance unknown";
                const mobile_number = admin.mobile_number ? admin.mobile_number : "Not available";

                // Bind popup with name and distance
                marker.bindPopup(`<strong>${name}</strong><br>${distance}<br>
                    <strong>Mobile No.</strong>${mobile_number}`);
                
                // Store marker in global array
                window.adminMarkers.push(marker);
            }
        });

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
        // Convert base64 to Blob
        const base64Data = photoDataInput.value;
        const byteCharacters = atob(base64Data.split(',')[1]);
        const byteNumbers = new Array(byteCharacters.length);
        for (let i = 0; i < byteCharacters.length; i++) {
            byteNumbers[i] = byteCharacters.charCodeAt(i);
        }
        const byteArray = new Uint8Array(byteNumbers);
        const file = new File([byteArray], "captured_photo.jpg", { type: "image/jpeg" });

        const formData = new FormData();
        formData.append('photo', file);
        formData.append('description', descriptionInput.value);
        formData.append('latitude',parseFloat(latitude)); // Ensure it's a number
        formData.append('longitude', parseFloat(longitude)); // Ensure it's a number
        formData.append('priority', document.getElementById('priority').value || 'MEDIUM');

        // Fetch CSRF Token
        const csrfTokenElement = document.querySelector('[name=csrfmiddlewaretoken]');
        const csrfToken = csrfTokenElement ? csrfTokenElement.value : null;
        if (!csrfToken) {
            console.error("CSRF token not found.");
            return;
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
        alert(result.message);
    } catch (error) {
        console.error('Error submitting report:', error);
        alert('Failed to submit report. Please try again.');
    }
}

// Add event listener to the report form submission
document.getElementById('reportAnimalForm').addEventListener('submit', (event) => {
    event.preventDefault(); // Prevent default form submission
    submitReport(); // Call the submitReport function
});

// Initialize map when page loads
document.addEventListener('DOMContentLoaded', initMap);
