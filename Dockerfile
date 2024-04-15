FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY homarr-updater.py .
CMD ["python", "homarr_updater.py"]
