# This is intended to be used in production for Heroku. 

FROM python:3.6-alpine
MAINTAINER Read the Docs, Inc. <support@readthedocs.org>

RUN apk update \
  # psycopg2 dependencies
  && apk add --virtual build-deps gcc python3-dev musl-dev \
  && apk add postgresql-dev \
  # Pillow dependencies
  && apk add jpeg-dev zlib-dev freetype-dev lcms2-dev openjpeg-dev tiff-dev tk-dev tcl-dev \
  # CFFI dependencies
  && apk add libffi-dev py-cffi \
  # Translations dependencies
  && apk add gettext \
  # https://docs.djangoproject.com/en/dev/ref/django-admin/#dbshell
  && apk add postgresql-client \
  # Add Node dependencies for building static files
  && apk add nodejs npm \
  # Ensure git is on the system - some dependencies may rely on it
  && apk add git \
  # Needed to build Python Cryptography on Alpine Linux
  # https://cryptography.io/en/latest/installation.html#alpine
  && apk add openssl-dev cargo \
  # add dependencies to shell in for Heroku
  && apk add bash curl openssh iproute2

RUN addgroup -S django \
    && adduser -S -G django django

# Requirements are installed here to ensure they will be cached.
COPY ./requirements /requirements
RUN pip install --no-cache-dir -r /requirements/production.txt \
    && rm -rf /requirements

COPY ./docker-compose/production/django/start /start
RUN chmod +x /start
RUN chown django /start

COPY ./docker-compose/production/django/celery/worker/start /start-celeryworker
RUN chmod +x /start-celeryworker
RUN chown django /start-celeryworker

COPY ./docker-compose/production/django/celery/beat/start /start-celerybeat
RUN chmod +x /start-celerybeat
RUN chown django /start-celerybeat

# Explicitly copy files/directories so no configuration/data/secrets get copied
COPY ./adserver /app/adserver
COPY ./assets /app/assets
COPY ./config /app/config
COPY ./geoip /app/geoip
COPY ./templates /app/templates
COPY ./manage.py /app
COPY ./package.json /app
COPY ./webpack.config.js /app

# also for heroku
ADD ./.profile.d /app/.profile.d
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install node dependencies
WORKDIR /app
RUN npm cache clean --force
RUN npm install

# Heroku uses a dynamic port. 
EXPOSE $PORT

CMD ["/start"]
