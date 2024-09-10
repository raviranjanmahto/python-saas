# Set the python version as a build-time argument with Python 3.12 as the default
ARG PYTHON_VERSION=3.12-slim-bullseye
FROM python:${PYTHON_VERSION}

# Upgrade pip to the latest version
RUN pip install --upgrade pip

# Set Python-related environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install OS dependencies for Postgres, Pillow, CairoSVG, and others
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libjpeg-dev \
    libcairo2 \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Create the directory for the application code
WORKDIR /code

# Copy the requirements file into a temporary location
COPY requirements.txt /tmp/requirements.txt

# Install the dependencies from the requirements file
RUN pip install -r /tmp/requirements.txt

# Copy the entire project code into the container
COPY ./src /code

# Set environment variables for Django secrets
ARG DJANGO_SECRET_KEY
ENV DJANGO_SECRET_KEY=${DJANGO_SECRET_KEY}

ARG DJANGO_DEBUG=0
ENV DJANGO_DEBUG=${DJANGO_DEBUG}

# Set static root environment variable
ENV STATIC_ROOT=/code/staticfiles

# Create static files directory
RUN mkdir -p $STATIC_ROOT

# Run static files collection command
RUN python manage.py collectstatic --noinput

# Set the Django default project name
ARG PROJ_NAME="raviranjan"

# Create a bash script to run the Django project at runtime
RUN printf "#!/bin/bash\n" > ./paracord_runner.sh && \
    printf "RUN_PORT=\"\${PORT:-8000}\"\n\n" >> ./paracord_runner.sh && \
    printf "python manage.py migrate --no-input\n" >> ./paracord_runner.sh && \
    printf "gunicorn ${PROJ_NAME}.wsgi:application --bind \"0.0.0.0:\$RUN_PORT\"\n" >> ./paracord_runner.sh

# Make the bash script executable
RUN chmod +x paracord_runner.sh

# Clean up apt cache to reduce image size
RUN apt-get purge -y --auto-remove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Expose the port on which the app will run
EXPOSE 8000

# Run the Django project via the runtime script
CMD ["./paracord_runner.sh"]
