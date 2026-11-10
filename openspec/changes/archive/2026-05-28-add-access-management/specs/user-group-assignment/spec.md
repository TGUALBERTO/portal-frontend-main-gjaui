## ADDED Requirements

### Requirement: List portal users
The system SHALL display all portal users to an administrator via `GET /users`, each showing name and email, with client-side search.

#### Scenario: Users loaded
- **WHEN** an admin opens the Users screen
- **THEN** the system fetches `GET /users` and renders each user with name and email

#### Scenario: Search users
- **WHEN** an admin types a query in the search field
- **THEN** the list filters to users whose name or email matches the query

#### Scenario: Load fails
- **WHEN** the request to `GET /users` fails
- **THEN** the system shows an error state with a retry action

### Requirement: View members of a group
The system SHALL display the users belonging to a group via `GET /groups/{id}/users`.

#### Scenario: Members listed
- **WHEN** an admin opens a group's members section
- **THEN** the system fetches `GET /groups/{id}/users` and lists each member's name and email

### Requirement: Assign a user to a group
The system SHALL allow an administrator to add a user to a group via `POST /groups/{id}/users/{userId}`.

#### Scenario: Successful assignment
- **WHEN** an admin assigns a user to a group
- **THEN** the system calls `POST /groups/{id}/users/{userId}` and reflects the user as a member

#### Scenario: Assignment fails
- **WHEN** the assignment request fails
- **THEN** the system reverts the optimistic change and shows an error message

### Requirement: Remove a user from a group
The system SHALL allow an administrator to remove a user from a group via `DELETE /groups/{id}/users/{userId}`.

#### Scenario: Successful removal
- **WHEN** an admin removes a user from a group
- **THEN** the system calls `DELETE /groups/{id}/users/{userId}` and the user no longer appears as a member

### Requirement: Manage a user's groups from the user
The system SHALL allow an administrator to view and toggle a user's group memberships from a per-user group picker.

#### Scenario: Toggle membership
- **WHEN** an admin opens a user's group picker and toggles a group on or off
- **THEN** the system calls the corresponding add or remove endpoint and updates the displayed membership state
