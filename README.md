# MenuGreen System

This is a modern .NET N-Tier architecture backend project for the MenuGreen application.

## 🏗️ Project Architecture

The solution `MenuGreen.sln` follows a multi-tier layered architecture:

- **MenuGreen.API (Presentation Layer)**
  - Receives HTTP requests, handles routing, and returns HTTP responses.
  - Contains Controllers, Middlewares, and Filters.
- **MenuGreen.BusinessLogicLayer (BLL)**
  - Contains all the core business logic of the application.
  - Implements Services, DTOs, Automapper profiles, and Validations.
- **MenuGreen.DataAccessLayer (DAL)**
  - Manages data access, persistence, and external resources.
  - Contains EF Core DbContext, Entities, Repositories, and unit of work implementations.

## 🚀 Getting Started

1. Open `MenuGreen.sln` in Visual Studio or Rider.
2. Set `MenuGreen.API` as the Startup Project.
3. Configure your database connection string in `MenuGreen.API/appsettings.Development.json`.
4. Run the project (`F5` or `dotnet run --project MenuGreen.API`).

## 🛠️ Tech Stack

- .NET 9
- Entity Framework Core
- Dependency Injection
- RESTful Web API

## 📝 Layer Dependencies
`MenuGreen.API` -> `MenuGreen.BusinessLogicLayer` -> `MenuGreen.DataAccessLayer`