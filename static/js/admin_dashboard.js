document.addEventListener('DOMContentLoaded', function () {
    console.log("Admin Dashboard JS Loaded");  // Debugging message

    // Retrieve data from the template
    const chartData = {
        totalAnimals: parseInt(document.getElementById('totalAnimalsValue').dataset.value, 10) || 0,
        underTreatment: parseInt(document.getElementById('underTreatmentValue').dataset.value, 10) || 0,
        recovered: parseInt(document.getElementById('recoveredValue').dataset.value, 10) || 0,
        volunteerCount: parseInt(document.getElementById('volunteerCountValue').dataset.value, 10) || 0
    };

    // Initialize the charts with the data
    initializeCharts(chartData);
});

// Store chart instances to prevent duplicate rendering
const chartInstances = {};

function initializeCharts(chartData) {
    const createStatChart = (canvasId, value, color) => {
        const canvas = document.getElementById(canvasId);
        if (!canvas) {
            console.error(`Canvas with ID ${canvasId} not found.`);
            return;
        }

        // Destroy existing chart if it exists
        if (chartInstances[canvasId]) {
            chartInstances[canvasId].destroy();
        }

        // Create a new Chart instance
        chartInstances[canvasId] = new Chart(canvas.getContext('2d'), {
            type: 'doughnut',
            data: {
                datasets: [{
                    data: [value, 100 - value],
                    backgroundColor: [color, '#f8f9fa'],
                    borderColor: [color, '#dee2e6'],
                    borderWidth: 1
                }]
            },
            options: {
                cutout: '70%',
                plugins: {
                    legend: { display: false },
                    tooltip: { enabled: false }
                },
                animation: {
                    onComplete: function () {
                        const chartInstance = this;
                        const ctx = chartInstance.ctx;
                        const centerX = (chartInstance.chartArea.left + chartInstance.chartArea.right) / 2;
                        const centerY = (chartInstance.chartArea.top + chartInstance.chartArea.bottom) / 2;

                        ctx.save();
                        ctx.font = 'bold 24px Arial';
                        ctx.fillStyle = '#2d3436';
                        ctx.textAlign = 'center';
                        ctx.textBaseline = 'middle';
                        ctx.fillText(value, centerX, centerY);
                        ctx.restore();
                    }
                }
            }
        });
    };

    // Initialize all charts
    createStatChart('totalAnimalsChart', chartData.totalAnimals, '#4e73df');
    createStatChart('underTreatmentChart', chartData.underTreatment, '#1cc88a');
    createStatChart('recoveredChart', chartData.recovered, '#36b9cc');
    createStatChart('volunteerChart', chartData.volunteerCount, '#f6c23e');
}

let map;

function viewVolunteerMap(username, phone, latitude, longitude, userType) {
    console.log("Username:", username); // Debugging line
    console.log("Phone:", phone); // Debugging line
    console.log("Latitude:", latitude); // Debugging line
    console.log("Longitude:", longitude); // Debugging line
    console.log("User Type:", userType); // Debugging line
    // Show the map container
    const mapContainer = document.getElementById('map');
    mapContainer.style.display = 'block';

    if (map) {
        map.remove(); // Remove the existing map instance
    }

    // Initialize the map
    map = L.map('map').setView([latitude, longitude], 13); // Center the map on the volunteer's location

    // Add OpenStreetMap tiles
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors'
    }).addTo(map);

    // Create a marker for the volunteer
    const marker = L.marker([latitude, longitude]).addTo(map);

    // Create popup content
    const popupContent = `
        <div class="user-popup">
            <strong>Username:</strong> ${username}<br>
            <strong>Phone:</strong> ${phone}<br>
            <strong>Location:</strong> (${latitude.toFixed(6)}, ${longitude.toFixed(6)})<br>
            <strong>User Type:</strong> ${userType}
        </div>
    `;

    // Bind the popup to the marker
    marker.bindPopup(popupContent).openPopup();

    // Set the map view to the marker
    map.setView([latitude, longitude], 13);
}

// Function to get CSRF token
function getCookie(name) {
    let cookieValue = null;
    if (document.cookie && document.cookie !== '') {
        const cookies = document.cookie.split(';');
        for (let i = 0; i < cookies.length; i++) {
            const cookie = cookies[i].trim();
            if (cookie.substring(0, name.length + 1) === (name + '=')) {
                cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                break;
            }
        }
    }
    return cookieValue;
}

function updateAdminLocation() {
    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
            async (position) => {
                const { latitude, longitude } = position.coords;
                console.log('Admin location captured:', latitude, longitude);
                
                try {
                    const response = await fetch('/api/save-admin-location/', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'X-CSRFToken': getCookie('csrftoken'),
                        },
                        body: JSON.stringify({ 
                            latitude: latitude,
                            longitude: longitude 
                        }),
                        credentials: 'include'
                    });

                    if (!response.ok) {
                        throw new Error('Failed to update location');
                    }

                    const data = await response.json();
                    console.log('Location update response:', data);
                } catch (error) {
                    console.error('Error updating location:', error);
                }
            },
            (error) => {
                console.error('Error getting location:', error);
            },
            {
                enableHighAccuracy: true,
                timeout: 5000,
                maximumAge: 0
            }
        );
    }
}

// Initialize location tracking
document.addEventListener('DOMContentLoaded', function() {
    console.log("Admin dashboard loaded, starting location tracking");
    updateAdminLocation(); // Initial update
    setInterval(updateAdminLocation, 10000); // Update every 10 seconds
});