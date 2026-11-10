# group-management Specification

## Purpose
Provide administrators with the ability to manage access groups, including listing, creating, editing, and deleting groups, with access restricted to administrators.

## Requirements

### Requirement: List access groups
The system SHALL display all access groups to an administrator, fetched from `GET /groups`, each showing its name and description.

#### Scenario: Groups loaded successfully
- **WHEN** an admin opens the Groups screen
- **THEN** the system fetches `GET /groups` and renders each group with name and description

#### Scenario: No groups exist
- **WHEN** the groups list returns empty
- **THEN** the system shows an empty state inviting the admin to create a group

#### Scenario: Load fails
- **WHEN** the request to `GET /groups` fails
- **THEN** the system shows an error state with a retry action

### Requirement: Create access group
The system SHALL allow an administrator to create a group with a name (required, max 120 chars) and optional description (max 500 chars) via `POST /groups`.

#### Scenario: Successful creation
- **WHEN** an admin submits a valid new group name and optional description
- **THEN** the system calls `POST /groups`, shows a success message, and the new group appears in the list

#### Scenario: Duplicate name
- **WHEN** the admin submits a name that already exists and the backend returns a conflict
- **THEN** the system shows the conflict message and keeps the form open

#### Scenario: Missing name
- **WHEN** the admin submits an empty name
- **THEN** the system blocks submission and shows a validation error

### Requirement: Edit access group
The system SHALL allow an administrator to update an existing group's name and description via `PUT /groups/{id}`.

#### Scenario: Successful update
- **WHEN** an admin edits a group's name or description and saves
- **THEN** the system calls `PUT /groups/{id}`, shows a success message, and the list reflects the change

### Requirement: Delete access group
The system SHALL allow an administrator to delete a non-protected group via `DELETE /groups/{id}`, after confirmation.

#### Scenario: Successful deletion
- **WHEN** an admin confirms deletion of a regular group
- **THEN** the system calls `DELETE /groups/{id}` and removes the group from the list

#### Scenario: ADMIN group is protected
- **WHEN** the admin views the ADMIN group row
- **THEN** the delete action is disabled

#### Scenario: Backend rejects deletion
- **WHEN** the backend returns a conflict (e.g., attempting to delete ADMIN)
- **THEN** the system shows the rejection message and the group remains

### Requirement: Restrict access to administrators
The system SHALL only expose group-management screens to users in the ADMIN group.

#### Scenario: Non-admin blocked
- **WHEN** a non-admin user attempts to open a group-management route
- **THEN** the system redirects them away from the route
