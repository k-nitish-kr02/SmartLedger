-- MySQL initialization script for SmartLedger
-- This script creates databases and grants necessary permissions

-- Create databases if they don't exist
CREATE DATABASE IF NOT EXISTS authservice;
CREATE DATABASE IF NOT EXISTS userservice;
CREATE DATABASE IF NOT EXISTS expenseservice;

-- Grant all privileges on these databases to the 'test' user
GRANT ALL PRIVILEGES ON authservice.* TO 'test'@'%';
GRANT ALL PRIVILEGES ON userservice.* TO 'test'@'%';
GRANT ALL PRIVILEGES ON expenseservice.* TO 'test'@'%';

-- Flush privileges to ensure they take effect
FLUSH PRIVILEGES;

