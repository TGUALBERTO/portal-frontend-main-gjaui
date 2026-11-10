# feature-management Specification

## Purpose
Provide administrators with the ability to manage features, including listing, creating, editing, and deleting features.

## Requirements

### Requirement: List features
The system SHALL display all features to an administrator via `GET /features`, each showing its label, code, module, and icon.

#### Scenario: Features loaded
- **WHEN** an admin opens the Features screen
- **THEN** the system fetches `GET /features` and renders each feature with its icon, label, code, and module

#### Scenario: No features
- **WHEN** the features list is empty
- **THEN** the system shows an empty state with an action to create a feature

### Requirement: Create feature
The system SHALL allow an administrator to create a feature with a unique code (required, max 80), label (required, max 120), optional icon name (max 80), and module (required, max 80) via `POST /features`.

#### Scenario: Successful creation
- **WHEN** an admin submits valid feature fields
- **THEN** the system calls `POST /features`, shows success, and the feature appears in the list

#### Scenario: Duplicate code
- **WHEN** the admin submits a code that already exists and the backend returns a conflict
- **THEN** the system shows the conflict message and keeps the form open

#### Scenario: Missing required field
- **WHEN** the admin submits with a missing code, label, or module
- **THEN** the system blocks submission and shows a validation error

### Requirement: Edit feature
The system SHALL allow an administrator to update an existing feature via `PUT /features/{id}`.

#### Scenario: Successful update
- **WHEN** an admin edits feature fields and saves
- **THEN** the system calls `PUT /features/{id}`, shows success, and the list reflects the change

### Requirement: Delete feature
The system SHALL allow an administrator to delete a feature via `DELETE /features/{id}` after confirmation.

#### Scenario: Successful deletion
- **WHEN** an admin confirms deleting a feature
- **THEN** the system calls `DELETE /features/{id}` and removes it from the list
