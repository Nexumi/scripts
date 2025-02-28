# Default values
DEFAULT_PASSWORD="pwd"
DEFAULT_HOST="localhost"
DEFAULT_PORT="5432"
DEFAULT_TABLE="app"
DEFAULT_DATABASE="powercard_db"

# Parse command-line options
while getopts "w:h:p:t:d:" opt; do
  case $opt in
    w)
      PASSWORD="$OPTARG"
      ;;
    h)
      HOST_NAME="$OPTARG"
      ;;
    p)
      HOST_PORT="$OPTARG"
      ;;
    t)
      TABLE_NAME="$OPTARG"
      ;;
    d)
      DATABASE_NAME="$OPTARG"
      ;;
    \?)
      echo "Usage: $0 [-w password] [-h host] [-p port] [-t table_name] [-d database_name]"
      exit 1
      ;;
  esac
done

# Set defaults if not set by user
PASSWORD="${PASSWORD:-$DEFAULT_PASSWORD}"
HOST_NAME="${HOST_NAME:-$DEFAULT_HOST}"
HOST_PORT="${HOST_PORT:-$DEFAULT_PORT}"
TABLE_NAME="${TABLE_NAME:-$DEFAULT_TABLE}"
DATABASE_NAME="${DATABASE_NAME:-$DEFAULT_DATABASE}"

PGPASSWORD=${PASSWORD} psql -h ${HOST_NAME} -p ${HOST_PORT} -U ${TABLE_NAME} ${DATABASE_NAME}
