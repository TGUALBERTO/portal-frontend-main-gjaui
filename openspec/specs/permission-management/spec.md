# permission-management Specification

## Purpose
Provide administrators with the ability to view and edit per-feature CRUD permissions for a selected group through a responsive permission matrix.

## Requirements

### Requirement: Display a group's permissions per feature
The system SHALL present a permission matrix for a selected group, showing every feature and its four CRUD flags (create, read, update, delete), pre-populated from the group's current permissions.

#### Scenario: Matrix populated for existing group
- **WHEN** an admin opens the permission editor for a group
- **THEN** the system fetches all features and renders one row per feature with the group's current CRUD flags checked

#### Scenario: Feature with no permission
- **WHEN** a feature has no permission entry for the group
- **THEN** the system renders that feature with all four CRUD flags unchecked

### Requirement: Edit and save group permissions
The system SHALL allow an administrator to toggle CRUD flags per feature and persist the result via `PUT /groups/{id}/permissions`, which fully replaces the group's permissions.

#### Scenario: Save updated permissions
- **WHEN** an admin toggles CRUD flags and saves
- **THEN** the system sends the full set of features with at least one enabled flag to `PUT /groups/{id}/permissions` and shows a success message

#### Scenario: Feature with all flags cleared is removed
- **WHEN** an admin clears all four flags for a feature and saves
- **THEN** that feature is omitted from the request payload, removing the group's permission on it

#### Scenario: Save fails
- **WHEN** the permission save request fails
- **THEN** the system shows an error message and keeps the unsaved edits

### Requirement: Responsive permission matrix
The system SHALL adapt the permission matrix layout to screen width.

#### Scenario: Mobile layout
- **WHEN** the screen is narrow
- **THEN** the system renders one card per feature with four toggle chips (C/R/U/D) and no horizontal scrolling

#### Scenario: Wide layout
- **WHEN** the screen is wide (tablet/desktop)
- **THEN** the system renders a table with feature rows and CRUD checkbox columns

### Requirement: Select a group to manage permissions
The system SHALL allow an administrator to pick a group from the dedicated Permissions screen before editing its matrix.

#### Scenario: Group picker
- **WHEN** an admin opens the Permissions screen
- **THEN** the system lists groups and, on selecting one, shows that group's permission matrix for editing
