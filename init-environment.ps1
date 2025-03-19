$MONGO_VERSION = "8.0.5"
$POSTGRES_VERSION = "17.2"
$KEYCLOAK_VERSION = "26.1.3"

Write-Host "Starting environment"
Write-Host "===================="

Write-Host "`nCreating network"
docker network create springboot-react-keycloak-net

Write-Host "`nStarting MongoDB"
docker run -d --name mongodb -p 27017:27017 --network=springboot-react-keycloak-net mongo:$MONGO_VERSION

Write-Host "`nStarting PostgreSQL"
docker run -d --name postgres -p 5432:5432 -e POSTGRES_DB=keycloak -e POSTGRES_USER=keycloak -e POSTGRES_PASSWORD=password --network=springboot-react-keycloak-net postgres:$POSTGRES_VERSION

Write-Host "`nStarting Keycloak"
docker run -d --name keycloak -p 8080:8080 -e KC_BOOTSTRAP_ADMIN_USERNAME=admin -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin -e KC_DB=postgres -e KC_DB_URL_HOST=postgres -e KC_DB_URL_DATABASE=keycloak -e KC_DB_USERNAME=keycloak -e KC_DB_PASSWORD=password --network=springboot-react-keycloak-net quay.io/keycloak/keycloak:$KEYCLOAK_VERSION start-dev

docker start $(docker ps -aq)

Write-Host "`nEnvironment Up and Running"
Write-Host "=========================="
