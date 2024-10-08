# Smart Parking Locator
#! Worning is not ready yet working in progress... (Curently doing the admin panel by creating the whole functionality of adding marks on map in desired spots and then prepering the some kind of modal/seperate page displaying the parking from the top, admin task is to create the parking spot mark on map and then create within the reservation modal/page showing the parking from the top [ sth. like when you book a ticket for plane or cinema and you can see the whole room/plane inside] )

![Smart Parking Locator Banner](assets/banner.png)

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Screenshots](#screenshots)
- [Installation](#installation)
- [Usage](#usage)
- [Technologies Used](#technologies-used)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## Introduction

Welcome to **Smart Parking Locator**, a Flutter-based mobile application designed to simplify the search for available parking spots in real-time. Leveraging the power of Google Maps and advanced clustering algorithms, Smart Parking Locator provides users with an intuitive and efficient way to find, reserve, and manage parking spaces in crowded urban areas.

## Features

- **Real-Time Parking Availability:** View available and occupied parking spots on an interactive Google Map.
- **Clustering:** Efficiently displays parking spots using clustering to enhance map readability and performance.
- **Reservation System:** Reserve available parking spots directly from the app.
- **Dynamic Updates:** Receive real-time updates on parking spot availability.
- **Notifications:** Get notified about reservation confirmations, expirations, and availability changes.
- **User-Friendly Interface:** Intuitive design ensures a seamless user experience.

## Screenshots

![Home Screen](assets/home_screen.png)

![Reservation Dialog](assets/reservation_dialog.png)

![Occupied Spot](assets/occupied_spot.png)

## Installation

Follow these steps to set up and run the Smart Parking Locator application on your local machine.

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) installed on your machine.
- An IDE such as [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter and Dart plugins.
- A Google Maps API Key. You can obtain one from the [Google Cloud Console](https://console.cloud.google.com/).

### Steps

1. **Clone the Repository**

   ```bash
   git clone https://github.com/your-username/smart_parking_locator.git
   cd smart_parking_locator
   ```

2. **Install Dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Google Maps API Key**

   - Create a `.env` file in the root directory.
   - Add your Google Maps API Key:

     ```env
     GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY_HERE
     ```

   - Ensure that the `.env` file is included in your `.gitignore` to keep your API keys secure.

4. **Run the Application**

   ```bash
   flutter run
   ```

   Select your desired emulator or connected device to launch the app.

## Usage

1. **Launch the App**

   Open the Smart Parking Locator app on your device.

2. **Grant Location Permissions**

   Allow the app to access your location to display nearby parking spots.

3. **View Parking Spots**

   The map will display available and occupied parking spots. Clusters represent multiple spots in close proximity.

4. **Reserve a Spot**

   - Tap on an available parking spot marker.
   - A dialog will appear allowing you to reserve the spot.
   - Confirm your reservation to secure the spot.

5. **Manage Reservations**

   - Reserved spots can be managed from the reservation dialog.
   - Free up spots when no longer needed.

6. **Receive Notifications**

   Stay informed about your reservations and parking spot availability through timely notifications.

## Technologies Used

- **Flutter:** Cross-platform mobile application framework.
- **Dart:** Programming language used by Flutter.
- **Google Maps Flutter:** Integration of Google Maps into the Flutter app.
- **Supercluster:** Efficient clustering library for managing map markers.
- **Geolocator:** Access to device location services.
- **Flutter Polyline Points:** Drawing routes and polylines on the map.
- **Flutter Dotenv:** Managing environment variables securely.
- **UUID:** Generating unique identifiers for clusters and points.
- **Notification Service:** Handling in-app notifications.

## Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

### Steps to Contribute

1. **Fork the Repository**

   Click the **Fork** button at the top right corner of the repository page.

2. **Clone Your Fork**

   ```bash
   git clone https://github.com/your-username/smart_parking_locator.git
   cd smart_parking_locator
   ```

3. **Create a New Branch**

   ```bash
   git checkout -b feature/YourFeatureName
   ```

4. **Make Your Changes**

   Implement your feature or fix.

5. **Commit Your Changes**

   ```bash
   git commit -m "Add some feature"
   ```

6. **Push to the Branch**

   ```bash
   git push origin feature/YourFeatureName
   ```

7. **Open a Pull Request**

   Navigate to your fork on GitHub and click the **New Pull Request** button.

## License

Distributed under the MIT License. See [`LICENSE`](LICENSE) for more information.

## Contact

**Maciej Kos**  – maciek_k112@wp.pl

Project Link: [https://github.com/Maciasssss/smart_parking_locator](https://github.com/Maciasssss/smart_parking_locator)

---

