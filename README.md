Project Title: DevOps-Lab-1
Description: Establishing a laravel project and map its devops workflow
Students:
Seann Wyett Larga
Mark Llorca
BSIT 4-3

Software requirement: Laravel Installed, VS code installed(IDE)
Laravel installation instructions

1. Clone the Repository and Navigate to It
   git clone <repository-url>
   cd <project-folder-name>
2. Install PHP Dependencies
   composer install
3. Setup .env configurations
4. Configure database
5. Run database migrations
6. start development server
   php artisan serve

Database name: laravel_request_system
Database import instructions
Step 1: Configure Environment Variables
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=your_database_name
DB_USERNAME=root
DB_PASSWORD=your_password
Step 2: Create the Database
CREATE DATABASE your_database_name;
Step 3: Import the .sql File
mysql -u root -p your_database_name < /path/to/your-file.sql
Step 4: Verify the Connection
php artisan db:show

Commands neededd to run the project
composer install

Github repo link:
https://github.com/SeannWyett/devop_activity.git

## Request Data Model

The project contains a `requests` table for storing request information.

### Request Fields

- id - Unique request number
- requester_name - Name of the requester
- requester_email - Requester's email address
- item_name - Requested item or service
- quantity - Number of items requested
- purpose - Reason for the request
- status - Current request status; defaults to pending
- created_at - Request creation timestamp
- updated_at - Request update timestamp

### Migration

Run the following command to create the requests table:

php artisan migrate

### Verify Migration

Check the migration status using:

php artisan migrate:status

The requests table can also be inspected using phpMyAdmin.

## User Stories

### Requester

As a requester, I want to submit a request with my name, email, requested item, quantity, and purpose so that my request can be properly recorded.

### Staff Reviewer

As a staff reviewer, I want to see the request details and status so that I can identify requests that are still pending.

### Record Keeper

As a record keeper, I want requests to have creation and update timestamps so that I can track when request records were created or modified.

### Testing

Run the Laravel tests using:

```bash
php artisan test
```

Security tests include:

- Students can only access their own requests.
- Students cannot access another student's request.
- Admins can access all requests.
- Students cannot update request status.
- Invalid input is rejected.
- CSRF-protected requests reject invalid or missing CSRF tokens.
- User-submitted protected fields cannot change ownership or privileges.

### Dependency Audit

Run:

```bash
composer audit
```

The result should be recorded here:

```text
No security vulnerability advisories found.
```
## Laboratory 3 Verification

Verification instruction: Test student ownership and deny access to another student's request.
