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
Verification instruction: Test administrator access and administrator-only status updates.


# Lab 4 — Docker Containerization

## 1. Project Overview

This laboratory containerizes the Laravel Request System using Docker Compose. The application uses separate containers for the web server, Laravel application, and MySQL database.

The purpose is to provide a consistent environment, simplify application startup, keep database records persistent, and apply basic container security practices.

## 2. Docker Architecture

The project contains three main services:

| Service | Image / Configuration | Responsibility |
|---|---|---|
| `web` | Nginx | Receives browser requests and forwards PHP requests to the Laravel application. |
| `app` | Custom PHP/Laravel image | Runs the Laravel application and Artisan commands. |
| `db` | MySQL 8.4 | Stores application records in a persistent database volume. |

### Architecture Diagram

```text
Browser
   |
   | http://127.0.0.1:8080
   v
+------------------+
|   web (Nginx)    |
|   Port 8080:80   |
+------------------+
   |
   | FastCGI
   v
+------------------+
| app (Laravel)    |
| PHP-FPM :9000    |
+------------------+
   |
   | MySQL connection
   v
+------------------+
| db (MySQL 8.4)   |
| Internal :3306   |
+------------------+
   |
   v
  db_data
 (named volume)
```

The services communicate through the Docker Compose network. The MySQL database does not publish its ports to the host. The named volume `db_data` stores database data independently of the application container.

## 3. Requirements

Install the following software before running the project:

- Docker Desktop
- Docker Compose
- Git
- A web browser

## 4. Environment Configuration

The project uses `.env.container` for private container environment settings. The example file `.env.container.example` provides a template without real credentials.

### Setup

1. Make sure Docker Desktop is running.
2. Create `.env.container` from the example file if it does not already exist.
3. Edit `.env.container` and provide the required local application and database settings.
4. Set the database password variables required by `compose.yaml` in your terminal or local environment.

Example PowerShell commands for the current terminal session:

```powershell
$env:DB_PASSWORD = "your-local-database-password"
$env:DB_ROOT_PASSWORD = "your-local-root-password"
```

Use your actual local values, and never commit real passwords to GitHub.

Confirm that the real environment file is ignored:

```powershell
git check-ignore .env.container
```

Expected result: `.env.container` is listed as an ignored file.

## 5. Build and Start the Containers

Run these commands from the project directory.

### Validate the Compose configuration

```powershell
docker compose config --quiet
```

If the command returns without an error, the Compose configuration passes this validation.

### Build and start the services

```powershell
docker compose up -d --build
```

### Check the running services

```powershell
docker compose ps
```

The `app` and `db` services should become healthy, and the `web` service should be running.

### Access the application

Open the following address in a browser:

http://127.0.0.1:8080

## 6. Database Migrations

Migrations create or update the database tables required by Laravel.

Before running migrations, ensure the database container is healthy and the application is configured to connect to the correct database.

Check the migration status:

```powershell
docker compose exec app php artisan migrate:status
```

Run any pending migrations:

```powershell
docker compose exec app php artisan migrate --force
```

The `--force` option allows migrations to run in a production-mode Laravel environment. Review pending migrations before applying them.

**Important:** Do not use `php artisan migrate:fresh` for this persistence exercise. It drops existing tables and can delete database records. Do not remove the `db_data` volume.

## 7. Health and Troubleshooting

### Check service status

```powershell
docker compose ps
```

### View application logs

```powershell
docker compose logs app
```

### View web server logs

```powershell
docker compose logs web
```

### View database logs

```powershell
docker compose logs db
```

### Check the application container's health

```powershell
docker inspect devops-activity-app-1 --format '{{json .State.Health}}'
```

If a service fails, inspect its status and logs before attempting to restart or rebuild it.

## 8. Database Persistence Test

The persistence test checks whether database records survive application container replacement and a complete Compose restart.

### Test A: Recreate the application container

Record the current app container ID:

```powershell
docker compose ps -q app
```

Recreate only the app container:

```powershell
docker compose up -d --force-recreate --no-deps app
docker compose restart web
```

Get the new app container ID:

```powershell
docker compose ps -q app
```

Log in to the application and verify that the previously recorded test request still exists.

### Test B: Restart the Compose environment

Stop the containers without removing the named volume:

```powershell
docker compose down
```

Start them again:

```powershell
docker compose up -d
```

Check the service status:

```powershell
docker compose ps
```

Log in and verify that the same request still exists with its original details.

### Recorded Results

- The app container ID changed from `e92e15a4eb292ee86ec2fbccc92b37ddcf3cbd3011affbc947a5736614641681` to `c0320fad932445fd9f6ea98b164e56485bf7caf0c8499a632b86867d582997a8`.
- The test request remained available after the app container was recreated.
- The test request also remained available after the full Compose restart.
- These observations support that the database records persist independently of the app container and across a Compose restart.

**Warning:** Do not run `docker compose down -v` during this test. Removing the named volume can delete the stored database data. A persistent volume is not a substitute for a database backup.

## 9. Security Inspection

The following commands help inspect the container environment.

### Check the application runtime user

```powershell
docker compose exec app id
```

The tested container returned:

```text
uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

This indicates that the application process uses the `www-data` account rather than the root account for this command.

### Check whether MySQL ports are published

```powershell
docker inspect devops-activity-db-1 --format '{{json .NetworkSettings.Ports}}'
```

The tested result was:

```json
{"3306/tcp":null,"33060/tcp":null}
```

This indicates that neither database port was published to the host in the inspected container.

### Check the web port

```powershell
docker compose ps
```

The tested web service exposed:

```text
127.0.0.1:8080->80/tcp
```

Binding to `127.0.0.1` restricts this published port to the local host.

### Check Git status and ignored files

```powershell
git status
git check-ignore .env.container
git diff --check
```

Before committing, verify that real environment files, passwords, tokens, database dumps, and other sensitive files are not staged.

## 10. Application Verification

The application should be tested using the fictional student accounts and administrator account prepared for the laboratory.

Verify the following:

- Students can view their own requests.
- A student cannot access another student's protected request.
- The administrator can view requests and update request statuses.
- New requests can be created and saved.
- Request data remains available after the persistence tests.

Record the actual results and capture screenshots for the laboratory report. Do not report a test as passed unless it was performed and verified.

## 11. Git and Submission

Before committing, review all changed and untracked files:

```powershell
git status
git diff --check
```

Stage only the intended laboratory files after checking that no secrets or unrelated changes are included.

```powershell
git add .dockerignore .env.container.example Dockerfile compose.yaml docker/
git add README.md
git status
```

Review the staged changes before committing:

```powershell
git diff --cached
```

If the staged changes are correct, commit and push the laboratory branch:

```powershell
git commit -m "Configure reproducible Laravel container environment"
git push -u origin feature/lab4-containers
```

Create a pull request and request a review from your partner. Record the repository URL, pull request URL, reviewed commit SHA, and merge commit SHA in the laboratory submission.

## 12. Conclusion

Docker Compose provides a consistent way to run the Laravel Request System using separate web, application, and database services. The persistence tests showed that the recorded request remained available after application container replacement and a full Compose restart. The security inspection also confirmed that the app ran as `www-data`, the inspected MySQL ports were not published to the host, and the web service was bound to localhost. These checks provide evidence of the container setup and its tested behavior.