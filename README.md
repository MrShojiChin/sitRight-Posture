# sitRight-Posture

sitRight-Posture is an iOS application designed to help users improve their posture by providing real-time analysis and feedback using the device's camera. It leverages computer vision to detect common postural issues such as forward head posture, rounded shoulders, and back slouch.

## Features

- **Real-time Posture Analysis**: Uses the front-facing camera to analyze the user's posture.
- **Multiple Analysis Types**:
    - **Forward Head Posture**: Detects if the user's head is positioned too far forward.
    - **Rounded Shoulders**: Identifies if the user's shoulders are slumping forward.
    - **Back Slouch**: Checks for excessive curvature in the upper back.
- **Dashboard**: Provides a summary of posture sessions and quick tips for maintaining good posture.
- **History**: (Future Implementation) Will track posture analysis results over time.
- **Customizable Settings**: Allows users to configure reminders and other app preferences.

## Technology Stack

- **UI Framework**: SwiftUI
- **Camera & Video**: AVFoundation
- **Computer Vision**: Vision Framework for human body pose detection.

## Setup

To run this project, you will need a Mac with Xcode installed.

1.  **Clone the repository**:
    ```bash
    git clone <repository-url>
    ```
2.  **Open the project in Xcode**:
    Navigate to the project directory and open the `sitRight-Posture.xcodeproj` file.
    ```bash
    cd sitRight-Posture
    open sitRight-Posture.xcodeproj
    ```
3.  **Run the application**:
    - Select a target simulator or a physical iOS device from the scheme menu in Xcode.
    - Click the "Run" button (or press `Cmd+R`).

    **Note**: To use the posture analysis features, you must run the application on a physical iOS device with a front-facing camera. The camera is not available in the iOS simulator. You will also need to grant camera permissions when prompted by the app.

## Usage

The app is organized into four main tabs:

-   **Dashboard**: The main screen that shows a summary of your activity and provides helpful tips for better posture.
-   **Analysis**: This is where you can perform a posture check.
    1.  Select the type of posture you want to analyze (e.g., Forward Head Posture).
    2.  Tap "Start Analysis".
    3.  Follow the on-screen guides to position yourself correctly in front of the camera.
    4.  The app will provide real-time feedback and results.
-   **History**: View your past analysis results to track your progress over time.
-   **Settings**: Configure notification reminders, detection sensitivity, and other preferences.

## Project Structure

The codebase is organized into the following directories:

-   `sitRight-Posture/`: The main project directory.
    -   `Models/`: Contains the data structures used throughout the app, such as `PostureMetrics` and `PostureType`.
    -   `Views/`: Contains all the SwiftUI views, which define the user interface.
    -   `ViewModels/`: Contains the view models that manage the state and logic for the views, such as `CameraViewModel`.
    -   `Services/`: Contains services that handle specific functionalities like camera management (`CameraManager`), pose analysis (`PostureAnalyzer`), and orientation detection (`OrientationDetector`).
    -   `Assets.xcassets/`: Stores all the image assets and app icons.
    -   `sitRight_PostureApp.swift`: The main entry point of the application.