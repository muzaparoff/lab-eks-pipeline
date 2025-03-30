FROM python:3.10-alpine
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
# Optionally pass version to backend as env
ARG APP_VERSION
ENV APP_VERSION=${APP_VERSION}
CMD ["python", "app.py"]