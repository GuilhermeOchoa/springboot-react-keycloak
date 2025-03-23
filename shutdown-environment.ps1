Write-Host
Write-Host "Starting the environment shutdown"
Write-Host "================================="

Write-Host
Write-Host "Removing containers"
Write-Host "-------------------"
docker rm -fv mongodb keycloak postgres

Write-Host
Write-Host "Removing network"
Write-Host "----------------"
docker network rm springboot-react-keycloak-net

Write-Host
Write-Host "Environment shutdown successfully"
Write-Host "================================="
Write-Host