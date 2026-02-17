# MapNavigator Transport


---

## Overview

iOS application for searching destinations and viewing routes from Collège LaSalle Montréal with multiple transport modes.

---

## Features Implemented

### Part A - Setup 
- ✅ SwiftUI project created
- ✅ Location permission in Info.plist
- ✅ LocationManager with delegate methods

### Part B - Default Location & Markers 
- ✅ Map centered on Collège LaSalle (45.4919, -73.5794)
- ✅ Red marker: "Collège LaSalle"
- ✅ Blue marker: "You" (user location)

### Part C - Zoom Controls 
- ✅ Zoom in/out buttons
- ✅ Zooms at current camera center

### Part D - Search & Destination 
- ✅ Search bar with MKLocalSearch
- ✅ Green "Destination" marker
- ✅ Error handling for invalid searches

### Part E - Transport Modes 
- 🚗 Automobile
- 🚇 Transit
- 🚶 Walking
- 🚴 Cycling
- ✅ Routes recalculate when mode changes

### Part F - Route Drawing
- ✅ Blue route line on map
- ✅ Camera fits to show full route
- ✅ Distance (km) and time (min) displayed


---

## Error Handling

The application includes comprehensive error handling:

- **Invalid searches:** Displays "No results found" for gibberish or nonsense queries
- **Distance validation:** Results beyond 100km from Montreal are automatically rejected
- **Transit unavailability:** Suggests alternative transport modes (automobile/walking)
- **Network failures:** Displays descriptive error messages

---

## Technologies Used

- SwiftUI
- MapKit
- Core Location
- MKDirections

---

## Technical Notes

### Cycling Mode
MapKit's `MKDirectionsTransportType` does not include native cycling support in iOS 14-15. The cycling mode uses automobile routing as an approximation. This is a known limitation of the MapKit framework.

### Transit Mode
Public transit routing depends on available transit data in Apple Maps. Routes may not be available for all origin-destination pairs in the Montreal area.

---

## Screenshots

### Default View
<img src="screenshots-map/Defaultview.png" width="300" alt="Default View">

*Map centered on Collège LaSalle with red marker and blue user location marker*

### Route with Automobile Mode
<img src="screenshots-map/Routeautomobile.png" width="300" alt="Route Automobile">

*Blue route line from LaSalle to destination with distance and time information*

### Walking Mode
<img src="screenshots-map/Routewalking.png" width="300" alt="Route Walking">

*Walking route showing different travel time compared to automobile mode*

### Error Handling
<img src="screenshots-map/ErrorHandling.png" width="300" alt="Error Handling">

*Error alert for invalid search or unavailable transit route*

---

