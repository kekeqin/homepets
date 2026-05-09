# AGENTS.md

## Project Overview

HomePets — a family pet-raising system built to improve parent-child interaction through task-based pet feeding and leveling.

- **Backend**: Python 3.12+, FastAPI, SQLModel, PostgreSQL, uv (package manager), Docker
- **Frontend**: Flutter (latest stable), Riverpod, GoRouter, Dio
- **Methodology**: TDD-driven, clean code, best practices

---

## Repository Structure

```
backend/          # Python FastAPI backend
  app/
    api/          # Route handlers
    models/       # SQLModel models
    schemas/      # Pydantic/SQLModel request/response schemas
    services/     # Business logic
    core/         # Config, security, dependencies, database
    tests/        # Pytest tests (conftest.py has fixtures)
  pyproject.toml  # uv / Python project config
  Dockerfile

app/              # Flutter frontend
  lib/
    core/         # Router, constants
    models/
    screens/      # Grouped by feature (auth/, family/, pet/, tasks/, shop/, etc.)
    services/     # API service layer
    providers/    # Riverpod providers
    widgets/      # Reusable widgets
  test/           # Flutter tests
  pubspec.yaml
```

---

## Build / Lint / Test Commands

### Backend (Python)

```bash
# Install dependencies
uv sync

# Run dev server
uv run uvicorn app.main:app --reload

# Run all tests
uv run pytest

# Run a single test file
uv run pytest app/tests/test_pets.py

# Run a single test function
uv run pytest app/tests/test_pets.py::test_feed_pet

# Run tests with coverage
uv run pytest --cov=app

# Lint & format
uv run ruff check .
uv run ruff format .

# Type checking
uv run mypy app/

# Run all checks (lint + typecheck + test)
uv run ruff check . && uv run ruff format --check . && uv run mypy app/ && uv run pytest
```

### Frontend (Flutter)

```bash
# Install dependencies
flutter pub get

# Run app
flutter run

# Run all tests
flutter test

# Run a single test file
flutter test test/widgets/pet_card_test.dart

# Run a single test by name
flutter test --name "should display pet level"

# Lint / analyze
flutter analyze

# Format
dart format lib/ test/
```

---

## Code Style — Python Backend

### Imports
- Use absolute imports; no relative imports (`from app.models import Pet`, not `from .models import Pet`).
- Sort with `ruff` (isort-compatible): stdlib → third-party → local.
- Avoid wildcard imports (`from x import *`).

### Naming
- **Files/modules**: `snake_case.py`
- **Classes**: `PascalCase`
- **Functions/variables**: `snake_case`
- **Constants**: `UPPER_SNAKE_CASE`
- **Pydantic/SQLModel fields**: `snake_case` matching DB column names

### Types
- All public functions must have full type annotations (parameters + return).
- Use `SQLModel` for both ORM models and request/response schemas where possible.
- Prefer `model_validate()` over manual parsing.
- Use `X | None` (Python 3.10+ style) for nullable fields, not `Optional[X]`.

### Error Handling
- Raise `HTTPException` in route handlers for API errors.
- Use custom exception classes in `app/core/exceptions.py` for business logic errors; map them to HTTP responses in exception handlers.
- Never swallow exceptions silently — always log or re-raise.

### General
- Keep route handlers thin; delegate to service layer functions.
- Use dependency injection via `Depends()` for DB sessions, auth, etc.
- Follow REST conventions: plural nouns for resources (`/pets`, `/tasks`), standard HTTP methods.
- Write docstrings for public service functions and complex logic.
- Max line length: 100 characters.

---

## Code Style — Flutter Frontend

### Naming
- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables/functions/methods**: `camelCase`
- **Widgets**: Suffix with purpose if unclear (e.g., `PetCard`, `TaskListView`)

### File Organization
- One primary widget/class per file.
- Group by feature, not by type (e.g., `screens/pet/pet_screen.dart`, not `screens/pet_screen.dart`).
- Keep widgets small; extract reusable parts into `widgets/`.

### State Management
- Use **Riverpod** consistently (flutter_riverpod). Providers go in `providers/`.
- Avoid business logic in widget `build()` methods.

### Error Handling
- Use try/catch for async operations (API calls).
- Display user-friendly error messages via snackbars or dialogs.
- Log errors for debugging.

### General
- Run `flutter analyze` with zero warnings before committing.
- Use `const` constructors wherever possible.
- Prefer `final` over `var` when the variable won't be reassigned.

---

## Testing Conventions

### Backend
- Test files mirror source structure: `app/models/pet.py` → `app/tests/test_models_pet.py` or `app/tests/test_pets.py`.
- Use `pytest` fixtures for DB sessions and test clients (see `conftest.py`).
- Use `factory` patterns or fixture helpers for creating test data.
- Test naming: `test_<action>_<expected_result>` (e.g., `test_feed_pet_increases_level`).
- Each test should be independent; use transactions/rollbacks for DB isolation.

### Frontend
- Test files mirror lib structure: `lib/widgets/pet_card.dart` → `test/widgets/pet_card_test.dart`.
- Use `widget_test.dart` for widget tests, `*_test.dart` for unit tests.
- Follow `given-when-then` or `Arrange-Act-Assert` pattern.
- Use `mocktail` for mocking dependencies.

---

## Git Workflow

- Commit messages: imperative mood, concise (`Add pet feeding endpoint`, not `Added` or `Adds`).
- One logical change per commit.
- Run lint + tests before committing. After code changes, agents should run the smallest
  relevant lint/test checks for the files and behavior touched. Full test suites are required
  before commit/release or when explicitly requested, but are not required after every code edit.
- Do not commit `.env`, secrets, or generated files.

---

## Agent Guidelines

1. Always check if a dependency exists in `pyproject.toml` / `pubspec.yaml` before importing a new library. Ask the user before adding new dependencies.
2. When creating new files, follow the existing directory structure above.
3. After editing backend code, run the smallest relevant checks for the change. Examples:
   `uv run ruff check .` for small code edits, targeted `uv run pytest ...` for touched
   behavior, and full `uv run ruff check . && uv run ruff format . && uv run pytest` before
   commit/release or when explicitly requested.
4. After editing frontend code, run the smallest relevant checks for the change. Examples:
   `flutter analyze` for small UI/code edits, targeted `flutter test ...` for touched behavior,
   and full `flutter analyze && flutter test` before commit/release or when explicitly requested.
5. Prefer editing existing files over creating new ones.
6. Follow TDD when requested: write failing test first, then implement.
7. Use Chinese for user-facing strings in the app (target audience is Chinese families).
