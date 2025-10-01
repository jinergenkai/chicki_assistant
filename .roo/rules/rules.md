# Project Rules & Structure

## 1. File Structure Overview

- **lib/controllers/**: Contains GetXControllers. Each controller is tied to a specific screen and manages its logic/state.
- **lib/services/**: Contains GetXServices. Services communicate via the event bus and should be created per distinct logic domain.
- **lib/core/app_event_bus.dart**: Central event bus for controller-service communication.
- **lib/ui/screens/**: Each screen has its own folder. Screens instantiate their respective GetXControllers.
- **lib/ui/widgets/**: Shared and screen-specific widgets.
- **lib/utils/**: Utility functions (e.g., file, permission).

## 2. GetXController Rules

- Each screen must have its own GetXController in `lib/controllers/`.
- Controllers handle UI logic/state for their screen.
- Controllers should only interact with services via the event bus.

## 3. GetXService Rules

- Services reside in `lib/services/`.
- Each service should encapsulate a single logic domain.
- Services communicate with controllers using the event bus.
- Create a new service for each distinct logic if needed.

## 4. Event Bus Communication

- Use `lib/core/app_event_bus.dart` for all controller-service interactions.
- Avoid direct calls between controllers and services; always use events.

## 5. Widgets

- Shared widgets go in `lib/ui/widgets/`.
- Screen-specific widgets should be placed in their respective screen folders.

## 6. Utilities

- Place file and permission utilities in `lib/utils/`.
- Utilities should be stateless and reusable.

## 7. General Guidelines

- Keep logic separated: UI in controllers, business logic in services.
- Prefer composition over inheritance for widgets and logic.
- Follow Dart/Flutter best practices for naming and structure.
