# Default values
DEFAULT_CONTAINER="postgres"

CONTAINER="${1:-$DEFAULT_CONTAINER}"

existing_name=$(docker ps -a --format "{{.Names}}" | grep "^${CONTAINER}$")
existing_id=$(docker ps -a --format "{{.ID}}" | grep "^${CONTAINER}$")

if [ -z "$existing_name" ] && [ -z "$existing_id" ]; then
  echo "$CONTAINER does not exist"
else
  name=$(docker inspect --format '{{.Name}}' $CONTAINER | sed 's/\///')

  echo "Nuking $name..."

  docker stop ${CONTAINER} > /dev/null 2>&1
  docker rm ${CONTAINER} > /dev/null 2>&1

  echo "Nuked $name!"
fi