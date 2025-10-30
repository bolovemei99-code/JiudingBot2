# Use Python 3.11 slim image for smaller size
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Create non-root user for security
RUN useradd -m -u 1000 botuser && \
    chown -R botuser:botuser /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY bot.py .

# Set ownership
RUN chown -R botuser:botuser /app

# Switch to non-root user
USER botuser

# Health check - since this is a bot, we check if the process is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep -f "python.*bot.py" || exit 1

# Run the bot
CMD ["python", "-u", "bot.py"]
