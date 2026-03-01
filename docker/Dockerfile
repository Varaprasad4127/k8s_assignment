FROM python:3.11-slim

# Create non-root user
RUN useradd -u 1001 -m appuser

WORKDIR /app

# Install only required dependency
RUN pip install --no-cache-dir flask

# Copy application files
COPY app.py .
COPY templates/ templates/
COPY static/ static/

# Switch to non-root user
USER 1001

EXPOSE 5000

CMD ["python", "app.py"]