---
name: backend-python
description: |
  Modern Python backend stack: FastAPI, SQLAlchemy 2.0, Pydantic v2, uv, ruff.
  Use when: building Python APIs, async services, or working with Python backend code.
  Triggers: "fastapi", "python backend", "sqlalchemy", "pydantic", "uv", "ruff",
  "python api", "async python".
---

# Python Backend Stack

> **Live docs:** Add `use context7` to prompt for up-to-date FastAPI, SQLAlchemy, Pydantic documentation.

## Tooling (2025)

| Tool | Purpose | Why |
|------|---------|-----|
| **uv** | Package manager | 10-100x faster than pip |
| **ruff** | Linter + formatter | Replaces black, isort, flake8 |
| **FastAPI** | Web framework | Async, auto-docs, Pydantic |
| **SQLAlchemy 2.0** | ORM | Async support, type hints |
| **Pydantic v2** | Validation | 5-50x faster than v1 |
| **pytest** | Testing | See [testing.md](references/testing.md) |

## Project Setup

```bash
# Initialize
uv init my-api
cd my-api
uv add fastapi sqlalchemy[asyncio] pydantic pydantic-settings
uv add --dev ruff pytest pytest-asyncio httpx

# pyproject.toml
[tool.ruff]
line-length = 100
select = ["E", "F", "I", "N", "UP", "B", "A", "C4", "SIM"]

[tool.ruff.format]
quote-style = "double"

[tool.pytest.ini_options]
asyncio_mode = "auto"
```

## Project Structure

```
src/
├── main.py              # FastAPI app
├── config.py            # Settings (pydantic-settings)
├── db/
│   ├── __init__.py
│   ├── engine.py        # Async engine + session
│   └── models.py        # SQLAlchemy models
├── api/
│   ├── __init__.py
│   ├── deps.py          # Dependencies (get_db, get_user)
│   └── routes/
│       ├── __init__.py
│       ├── auth.py
│       └── users.py
├── schemas/             # Pydantic models
│   ├── __init__.py
│   └── user.py
└── services/            # Business logic
    └── user.py
tests/
├── conftest.py
└── test_users.py
```

## FastAPI Patterns

### Basic App

```python
from fastapi import FastAPI
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await init_db()
    yield
    # Shutdown
    await close_db()

app = FastAPI(lifespan=lifespan)
```

### Route with Dependencies

```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/users", tags=["users"])

@router.get("/{user_id}", response_model=UserOut)
async def get_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
```

### Pydantic Schemas

```python
from pydantic import BaseModel, EmailStr, Field
from datetime import datetime

class UserCreate(BaseModel):
    email: EmailStr
    name: str = Field(min_length=1, max_length=100)

class UserOut(BaseModel):
    id: int
    email: str
    name: str
    created_at: datetime

    model_config = {"from_attributes": True}  # For ORM mode
```

### Settings

```python
from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    database_url: str
    secret_key: str
    debug: bool = False

    model_config = {"env_file": ".env"}

@lru_cache
def get_settings() -> Settings:
    return Settings()
```

## SQLAlchemy 2.0 Async

### Engine Setup

```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, DeclarativeBase

engine = create_async_engine(
    "postgresql+asyncpg://user:pass@localhost/db",
    echo=False,
    pool_size=5,
    max_overflow=10,
)

AsyncSessionLocal = sessionmaker(
    engine, class_=AsyncSession, expire_on_commit=False
)

class Base(DeclarativeBase):
    pass
```

### Models

```python
from sqlalchemy import String, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from datetime import datetime

class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(100))
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)

    posts: Mapped[list["Post"]] = relationship(back_populates="author")
```

### Database Dependency

```python
from typing import AsyncGenerator

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
```

### Queries

```python
from sqlalchemy import select
from sqlalchemy.orm import selectinload

# Get one
user = await db.get(User, user_id)

# Query with filter
stmt = select(User).where(User.email == email)
result = await db.execute(stmt)
user = result.scalar_one_or_none()

# Eager load relationships
stmt = select(User).options(selectinload(User.posts)).where(User.id == user_id)

# Pagination
stmt = select(User).offset(skip).limit(limit).order_by(User.created_at.desc())
result = await db.execute(stmt)
users = result.scalars().all()
```

## Error Handling

```python
from fastapi import HTTPException, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request, exc):
    return JSONResponse(
        status_code=422,
        content={"error": {"code": "VALIDATION_ERROR", "details": exc.errors()}},
    )

# Custom exceptions
class NotFoundError(Exception):
    def __init__(self, resource: str, id: int):
        self.resource = resource
        self.id = id

@app.exception_handler(NotFoundError)
async def not_found_handler(request, exc):
    return JSONResponse(
        status_code=404,
        content={"error": {"message": f"{exc.resource} {exc.id} not found"}},
    )
```

## Anti-patterns

| Don't | Do Instead |
|-------|------------|
| `pip install` | `uv add` |
| `black` + `isort` + `flake8` | `ruff` |
| SQLAlchemy 1.x style | SQLAlchemy 2.0 with `Mapped[]` |
| Pydantic v1 | Pydantic v2 (`model_config`, not `Config`) |
| Sync database calls | Async with `asyncpg`/`aiosqlite` |
| Global DB session | Dependency injection |
| Business logic in routes | Services layer |

## Memory Protocol

At **session start**: read `memory/CONTEXT.md` + `memory/handoffs.md` (staff, architect sections) + skim `memory/open-questions.md` for your open items.

At **session end**: replace your section in `memory/handoffs.md`, append new entries to `memory/decisions.md`, update `memory/open-questions.md`, and update the "Last activity" line in `memory/CONTEXT.md`.

Full protocol and file formats: see [memory-manager skill](../memory-manager/SKILL.md).
