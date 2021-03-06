#!/bin/bash
set -e

# wait shortly and then run db migrations (retry on error)
while ! ./manage.py migrate 2>&1; do
  echo "⏳ Waiting on DB..."
  sleep 3
done

# create superuser silently
if [[ -z ${SUPERUSER_NAME} ]]; then
  SUPERUSER_NAME='admin'
fi
if [[ -z ${SUPERUSER_EMAIL} ]]; then
  SUPERUSER_EMAIL='admin@example.com'
fi
if [[ -z ${SUPERUSER_PASSWORD} ]]; then
  SUPERUSER_PASSWORD='admin'
fi
if [[ -z ${SUPERUSER_API_TOKEN} ]]; then
  SUPERUSER_API_TOKEN='0123456789abcdef0123456789abcdef01234567'
fi

echo "💡 Username: ${SUPERUSER_NAME}, E-Mail: ${SUPERUSER_EMAIL}, Password: ${SUPERUSER_PASSWORD}, Token: ${SUPERUSER_API_TOKEN}"

./manage.py shell --plain << END
from django.contrib.auth.models import User
from users.models import Token
if not User.objects.filter(username='${SUPERUSER_NAME}'):
    u=User.objects.create_superuser('${SUPERUSER_NAME}', '${SUPERUSER_EMAIL}', '${SUPERUSER_PASSWORD}')
    Token.objects.create(user=u, key='${SUPERUSER_API_TOKEN}')
END

# copy static files
./manage.py collectstatic --no-input

echo "✅ Initialisation is done."

# launch whatever is passed by docker via RUN
exec ${@}
