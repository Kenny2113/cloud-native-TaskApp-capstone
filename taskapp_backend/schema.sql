-- Team Task Manager Database Schema
-- PostgreSQL Database Schema
-- Drop existing tables if they exist
DROP TABLE IF EXISTS tasks;

DROP TABLE IF EXISTS users;

-- Create users table
CREATE TABLE
    users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(80) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

-- Create tasks table
CREATE TABLE
    tasks (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users (id) ON DELETE CASCADE,
        title VARCHAR(200) NOT NULL,
        description TEXT DEFAULT '',
        priority VARCHAR(20) NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
        status VARCHAR(20) NOT NULL DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'done')),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

-- Create indexes for faster queries
CREATE INDEX idx_tasks_status ON tasks (status);

CREATE INDEX idx_tasks_created_at ON tasks (created_at);

CREATE INDEX idx_tasks_user_id ON tasks (user_id);

-- Insert sample data
INSERT INTO
    tasks (title, description, priority, status)
VALUES
    (
        'Setup Project Repository',
        'Initialize git repository and create project structure',
        'high',
        'done'
    ),
    (
        'Design Database Schema',
        'Create PostgreSQL database schema for task management',
        'high',
        'done'
    ),
    (
        'Implement REST API',
        'Build Flask REST API with CRUD operations',
        'high',
        'in_progress'
    ),
    (
        'Create Frontend UI',
        'Build React frontend with Kanban board',
        'medium',
        'in_progress'
    ),
    (
        'Add Authentication',
        'Implement user authentication and authorization',
        'medium',
        'todo'
    ),
    (
        'Write Documentation',
        'Create comprehensive README and API documentation',
        'low',
        'todo'
    );