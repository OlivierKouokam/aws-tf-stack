# Recipe API

A Spring Boot 3.4.2 RESTful service for managing recipes, featuring JWT‑based authentication, MySQL persistence, and OpenAPI documentation.  

## Table of Contents

- [Features](#features)  
- [Tech Stack](#tech-stack)  
- [Prerequisites](#prerequisites)  
- [Getting Started](#getting-started)  
- [Configuration](#configuration)  
- [Running the Application](#running-the-application)  
- [API Endpoints](#api-endpoints)  
  - [Authentication](#authentication)  
  - [Recipes](#recipes)  
- [API Documentation](#api-documentation)  
- [Data Initialization](#data-initialization)  
- [Contributing](#contributing)  
- [License](#license)  

## Features

- **User registration & login** with JWT tokens for stateless authentication. 
- **CRUD‑style read operations** on recipes, including pagination and flexible filtering by cuisine, title, ingredients, and cooking time. 
- **Role‑based security**: `/api/auth/**` and Swagger UI are publicly accessible; all other endpoints require a valid Bearer token. 
- **CORS support** to allow requests from a configured frontend origin. 
- **OpenAPI/Swagger UI** for interactive API exploration. 

## Tech Stack

- **Java 17**  
- **Spring Boot** 3.4.2 
- **Spring Data JPA** for ORM with Hibernate 
- **Spring Security + JWT** for authentication and authorization 
- **MySQL** as the relational database (via `mysql-connector-j`) 
- **Lombok** to reduce boilerplate code  
- **Springdoc OpenAPI** (`springdoc-openapi-starter-webmvc-ui`) for API docs 

## Prerequisites

- **Java 17** or higher  
- **Maven 3.8+**  
- **MySQL 5.7+** (or compatible)  
- Optional: **SSL keystore** if you plan to run on HTTPS (default port 8443)

## Getting Started

1. **Clone the repository**  
   ```bash
   git clone https://github.com/codingwitharmand/recipe-api.git
   cd recipe-api
   ```

2. **Configure MySQL database**
    - Create a database named `recipe-demo` (or change in config)
    - Update credentials in `src/main/resources/application.yml`:
      ```yaml
      spring:
        datasource:
          url: jdbc:mysql://localhost:3306/recipe-demo
          username: your_db_user
          password: your_db_pass
      ```
 

3. **Set application properties**
    - In `application.yml`, adjust:
      ```yaml
      app:
        frontend-url: http://localhost:5173
        secret-key: your_secret_key
        expiration-time: 86400000  # in milliseconds
      server:
        port: 8443
        ssl:
          key-store: classpath:keystore.p12
          key-store-password: password
          key-store-type: PKCS12
          key-alias: your_alias
      ```


## Configuration

| Property                      | Description                             |
| ----------------------------- | --------------------------------------- |
| `spring.datasource.*`         | MySQL connection details                |
| `app.frontend-url`            | Allowed CORS origin                     |
| `app.secret-key`              | Secret for signing JWTs                 |
| `app.expiration-time`         | JWT expiration in milliseconds          |
| `server.ssl.*`                | SSL (HTTPS) configuration               |

## Running the Application

```bash
# Build and run with Maven (uses embedded Maven wrapper)
./mvnw spring-boot:run
```

The application will start on **https://localhost:8443** by default.

## API Endpoints

### Authentication

| Method | Endpoint            | Description                  | Body                                      |
| ------ | --------------------| ---------------------------- | ----------------------------------------- |
| POST   | `/api/auth/register`| Register a new user          | `{ "username": "...", "password": "..." }` |
| POST   | `/api/auth/login`   | Authenticate and get a JWT   | `{ "username": "...", "password": "..." }` |

### Recipes

> All recipe endpoints require `Authorization: Bearer <token>` header.

| Method | Endpoint                     | Description                                                   | Query Params                                                             |
| ------ | -----------------------------| ------------------------------------------------------------- | -------------------------------------------------------------------------|
| GET    | `/api/recipes`               | Get paginated list of all recipes                             | `pageNumber` (default `0`), `pageSize` (default `10`)                    |
| GET    | `/api/recipes/filter`        | Filter recipes by various fields                              | `cuisine`, `title`, `ingredients`, `maxCookingTime`                     |

## API Documentation

Once running, access the interactive Swagger UI at:  
**https://localhost:8443/swagger-ui.html**

## Data Initialization

The application will run any SQL scripts located in `classpath:db/data.sql` on startup to seed initial data.

## Contributing

1. Fork the repo
2. Create your feature branch (`git checkout -b feature/YourFeature`)
3. Commit your changes (`git commit -m 'Add YourFeature'`)
4. Push to the branch (`git push origin feature/YourFeature`)
5. Open a Pull Request

## License

This project is not released under **License**.