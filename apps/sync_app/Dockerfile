FROM python:3.11-slim

WORKDIR /app

RUN pip install poetry

COPY pyproject.toml poetry.lock ./
RUN poetry config virtualenvs.create false \
    && poetry install --no-interaction --no-ansi

COPY sync_app/ ./sync_app/

CMD ["uvicorn", "sync_app.main:app", "--host", "0.0.0.0", "--port", "8000"]