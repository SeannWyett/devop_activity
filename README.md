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
