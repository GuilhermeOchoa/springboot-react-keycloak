# Verifica se o contêiner do Keycloak está em execução
if (-not (docker ps --filter "name=keycloak" -q)) {
    Write-Host "[WARNING] Você deve inicializar o ambiente (./init-environment.sh) antes de inicializar o Keycloak."
    exit 1
}

# Define a porta do Keycloak (padrão: localhost:8080)
$KEYCLOAK_HOST_PORT = if ($args[0]) { $args[0] } else { "localhost:8080" }
Write-Host "KEYCLOAK_HOST_PORT: $KEYCLOAK_HOST_PORT"

# Obtém o token de administrador
Write-Host "Obtendo token de acesso do administrador..."
$ADMIN_TOKEN = (Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/realms/master/protocol/openid-connect/token" `
    -Method Post `
    -Headers @{"Content-Type" = "application/x-www-form-urlencoded"} `
    -Body @{
        username = "admin"
        password = "admin"
        grant_type = "password"
        client_id = "admin-cli"
    }).access_token

if (-not $ADMIN_TOKEN) {
    Write-Host "[ERRO] Falha ao obter o token de acesso do administrador."
    exit 1
}
Write-Host "ADMIN_TOKEN=$ADMIN_TOKEN"

# Cria o realm "company-services"
Write-Host "Criando o realm 'company-services'..."
$REALM_RESPONSE = Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms" `
    -Method Post `
    -Headers @{
        "Authorization" = "Bearer $ADMIN_TOKEN"
        "Content-Type" = "application/json"
    } `
    -Body (@{
        realm = "company-services"
        enabled = $true
        registrationAllowed = $true
    } | ConvertTo-Json)

if (-not $REALM_RESPONSE) {
    Write-Host "[ERRO] Falha ao criar o realm 'company-services'."
    exit 1
}
Write-Host "Realm 'company-services' criado com sucesso."

# Desativa a ação obrigatória "VERIFY_PROFILE"
Write-Host "Desativando a ação obrigatória 'VERIFY_PROFILE'..."
$VERIFY_PROFILE_REQUIRED_ACTION = Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/authentication/required-actions/VERIFY_PROFILE" `
    -Headers @{"Authorization" = "Bearer $ADMIN_TOKEN"}

if (-not $VERIFY_PROFILE_REQUIRED_ACTION) {
    Write-Host "[ERRO] Falha ao obter a ação obrigatória 'VERIFY_PROFILE'."
    exit 1
}

$VERIFY_PROFILE_REQUIRED_ACTION.enabled = $false
Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/authentication/required-actions/VERIFY_PROFILE" `
    -Method Put `
    -Headers @{
        "Authorization" = "Bearer $ADMIN_TOKEN"
        "Content-Type" = "application/json"
    } `
    -Body ($VERIFY_PROFILE_REQUIRED_ACTION | ConvertTo-Json -Depth 10)

Write-Host "Ação obrigatória 'VERIFY_PROFILE' desativada com sucesso."

# Cria o cliente "movies-app"
Write-Host "Criando o cliente 'movies-app'..."
$CLIENT_RESPONSE = Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/clients" `
    -Method Post `
    -Headers @{
        "Authorization" = "Bearer $ADMIN_TOKEN"
        "Content-Type" = "application/json"
    } `
    -Body (@{
        clientId = "movies-app"
        directAccessGrantsEnabled = $true
        publicClient = $true
        redirectUris = @("http://localhost:3000/*")
    } | ConvertTo-Json)

if (-not $CLIENT_RESPONSE) {
    Write-Host "[ERRO] Falha ao criar o cliente 'movies-app'."
    exit 1
}
Write-Host "Cliente 'movies-app' criado com sucesso."

# Captura o ID do cliente "movies-app"
$CLIENT_ID = (Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/clients" `
    -Headers @{"Authorization" = "Bearer $ADMIN_TOKEN"} | Where-Object { $_.clientId -eq "movies-app" }).id

if (-not $CLIENT_ID) {
    Write-Host "[ERRO] Falha ao obter o ID do cliente 'movies-app'."
    exit 1
}
Write-Host "CLIENT_ID=$CLIENT_ID"

# Cria o papel "MOVIES_USER"
Write-Host "Criando o papel 'MOVIES_USER'..."
Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/clients/$CLIENT_ID/roles" `
    -Method Post `
    -Headers @{
        "Authorization" = "Bearer $ADMIN_TOKEN"
        "Content-Type" = "application/json"
    } `
    -Body (@{
        name = "MOVIES_USER"
    } | ConvertTo-Json)

# Obtém o ID do papel "MOVIES_USER"
$MOVIES_USER_CLIENT_ROLE_ID = (Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/clients/$CLIENT_ID/roles/MOVIES_USER" `
    -Headers @{"Authorization" = "Bearer $ADMIN_TOKEN"}).id

if (-not $MOVIES_USER_CLIENT_ROLE_ID) {
    Write-Host "[ERRO] Falha ao criar ou obter o papel 'MOVIES_USER'."
    exit 1
}
Write-Host "MOVIES_USER_CLIENT_ROLE_ID=$MOVIES_USER_CLIENT_ROLE_ID"

# Cria o papel "MOVIES_ADMIN"
Write-Host "Criando o papel 'MOVIES_ADMIN'..."
Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/clients/$CLIENT_ID/roles" `
    -Method Post `
    -Headers @{
        "Authorization" = "Bearer $ADMIN_TOKEN"
        "Content-Type" = "application/json"
    } `
    -Body (@{
        name = "MOVIES_ADMIN"
    } | ConvertTo-Json)

# Obtém o ID do papel "MOVIES_ADMIN"
$MOVIES_ADMIN_CLIENT_ROLE_ID = (Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/clients/$CLIENT_ID/roles/MOVIES_ADMIN" `
    -Headers @{"Authorization" = "Bearer $ADMIN_TOKEN"}).id

if (-not $MOVIES_ADMIN_CLIENT_ROLE_ID) {
    Write-Host "[ERRO] Falha ao criar ou obter o papel 'MOVIES_ADMIN'."
    exit 1
}
Write-Host "MOVIES_ADMIN_CLIENT_ROLE_ID=$MOVIES_ADMIN_CLIENT_ROLE_ID"

# Cria o grupo "USERS"
Write-Host "Criando o grupo 'USERS'..."
$USERS_GROUP_ID = (Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/groups" `
    -Method Post `
    -Headers @{
        "Authorization" = "Bearer $ADMIN_TOKEN"
        "Content-Type" = "application/json"
    } `
    -Body (@{
        name = "USERS"
    } | ConvertTo-Json)).id

if (-not $USERS_GROUP_ID) {
    Write-Host "[ERRO] Falha ao criar o grupo 'USERS'."
    exit 1
}
Write-Host "USERS_GROUP_ID=$USERS_GROUP_ID"

# Cria o grupo "ADMINS"
Write-Host "Criando o grupo 'ADMINS'..."
$ADMINS_GROUP_ID = (Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/groups" `
    -Method Post `
    -Headers @{
        "Authorization" = "Bearer $ADMIN_TOKEN"
        "Content-Type" = "application/json"
    } `
    -Body (@{
        name = "ADMINS"
    } | ConvertTo-Json)).id

if (-not $ADMINS_GROUP_ID) {
    Write-Host "[ERRO] Falha ao criar o grupo 'ADMINS'."
    exit 1
}
Write-Host "ADMINS_GROUP_ID=$ADMINS_GROUP_ID"

# Define o grupo "USERS" como grupo padrão do realm
Write-Host "Definindo o grupo 'USERS' como grupo padrão do realm..."
Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/default-groups/$USERS_GROUP_ID" `
    -Method Put `
    -Headers @{"Authorization" = "Bearer $ADMIN_TOKEN"}

Write-Host "Grupo 'USERS' definido como padrão do realm."

# Atribui o papel "MOVIES_USER" ao grupo "USERS"
Write-Host "Atribuindo o papel 'MOVIES_USER' ao grupo 'USERS'..."
Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/groups/$USERS_GROUP_ID/role-mappings/clients/$CLIENT_ID" `
    -Method Post `
    -Headers @{
        "Authorization" = "Bearer $ADMIN_TOKEN"
        "Content-Type" = "application/json"
    } `
    -Body (@(
        @{
            id = $MOVIES_USER_CLIENT_ROLE_ID
            name = "MOVIES_USER"
        }
    ) | ConvertTo-Json)

Write-Host "Papel 'MOVIES_USER' atribuído ao grupo 'USERS'."

# Atribui os papéis "MOVIES_USER" e "MOVIES_ADMIN" ao grupo "ADMINS"
Write-Host "Atribuindo os papéis 'MOVIES_USER' e 'MOVIES_ADMIN' ao grupo 'ADMINS'..."
Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/groups/$ADMINS_GROUP_ID/role-mappings/clients/$CLIENT_ID" `
    -Method Post `
    -Headers @{
        "Authorization" = "Bearer $ADMIN_TOKEN"
        "Content-Type" = "application/json"
    } `
    -Body (@(
        @{
            id = $MOVIES_USER_CLIENT_ROLE_ID
            name = "MOVIES_USER"
        },
        @{
            id = $MOVIES_ADMIN_CLIENT_ROLE_ID
            name = "MOVIES_ADMIN"
        }
    ) | ConvertTo-Json)

Write-Host "Papéis atribuídos ao grupo 'ADMINS'."

# Cria o usuário "user"
Write-Host "Criando o usuário 'user'..."
$USER_ID = (Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/users" `
    -Method Post `
    -Headers @{
        "Authorization" = "Bearer $ADMIN_TOKEN"
        "Content-Type" = "application/json"
    } `
    -Body (@{
        username = "user"
        enabled = $true
        credentials = @(
            @{
                type = "password"
                value = "user"
                temporary = $false
            }
        )
    } | ConvertTo-Json)).id

if (-not $USER_ID) {
    Write-Host "[ERRO] Falha ao criar o usuário 'user'."
    exit 1
}
Write-Host "USER_ID=$USER_ID"

# Atribui o grupo "USERS" ao usuário "user"
Write-Host "Atribuindo o grupo 'USERS' ao usuário 'user'..."
Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/users/$USER_ID/groups/$USERS_GROUP_ID" `
    -Method Put `
    -Headers @{"Authorization" = "Bearer $ADMIN_TOKEN"}

Write-Host "Grupo 'USERS' atribuído ao usuário 'user'."

# Cria o usuário "admin"
Write-Host "Criando o usuário 'admin'..."
$ADMIN_ID = (Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/users" `
    -Method Post `
    -Headers @{
        "Authorization" = "Bearer $ADMIN_TOKEN"
        "Content-Type" = "application/json"
    } `
    -Body (@{
        username = "admin"
        enabled = $true
        credentials = @(
            @{
                type = "password"
                value = "admin"
                temporary = $false
            }
        )
    } | ConvertTo-Json)).id

if (-not $ADMIN_ID) {
    Write-Host "[ERRO] Falha ao criar o usuário 'admin'."
    exit 1
}
Write-Host "ADMIN_ID=$ADMIN_ID"

# Atribui o grupo "ADMINS" ao usuário "admin"
Write-Host "Atribuindo o grupo 'ADMINS' ao usuário 'admin'..."
Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/users/$ADMIN_ID/groups/$ADMINS_GROUP_ID" `
    -Method Put `
    -Headers @{"Authorization" = "Bearer $ADMIN_TOKEN"}

Write-Host "Grupo 'ADMINS' atribuído ao usuário 'admin'."

# Obtém o token de acesso para o usuário "user"
Write-Host "Obtendo token de acesso para o usuário 'user'..."
$USER_TOKEN = (Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/realms/company-services/protocol/openid-connect/token" `
    -Method Post `
    -Headers @{"Content-Type" = "application/x-www-form-urlencoded"} `
    -Body @{
        username = "user"
        password = "user"
        grant_type = "password"
        client_id = "movies-app"
    }).access_token

Write-Host "USER_TOKEN=$USER_TOKEN"

# Obtém o token de acesso para o usuário "admin"
Write-Host "Obtendo token de acesso para o usuário 'admin'..."
$ADMIN_TOKEN = (Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/realms/company-services/protocol/openid-connect/token" `
    -Method Post `
    -Headers @{"Content-Type" = "application/x-www-form-urlencoded"} `
    -Body @{
        username = "admin"
        password = "admin"
        grant_type = "password"
        client_id = "movies-app"
    }).access_token

Write-Host "ADMIN_TOKEN=$ADMIN_TOKEN"

Write-Host "Configuração do Keycloak concluída com sucesso!"