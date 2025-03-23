# Verifica se o contêiner do Keycloak está em execução
if (-not (docker ps --filter "name=keycloak" -q)) {
    Write-Host "[WARNING] You must initialize the environment (./init-environment.sh) before initializing Keycloak"
    exit 1
}

# Define a porta do Keycloak (padrão: localhost:8080)
$KEYCLOAK_HOST_PORT = if ($args[0]) { $args[0] } else { "localhost:8080" }
Write-Host "KEYCLOAK_HOST_PORT: $KEYCLOAK_HOST_PORT"

# Obtém o token de administrador
Write-Host "Getting admin access token"
Write-Host "--------------------------"
try {
    $ADMIN_TOKEN = (Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/realms/master/protocol/openid-connect/token" `
        -Method Post `
        -Headers @{"Content-Type" = "application/x-www-form-urlencoded"} `
        -Body @{
            username = "admin"
            password = "admin"
            grant_type = "password"
            client_id = "admin-cli"
        }).access_token
    Write-Host "ADMIN_TOKEN=$ADMIN_TOKEN"
} catch {
    Write-Host "[ERROR] Failed to get admin access token. Details: $_"
    exit 1
}

# Verifica se o realm "company-services" já existe
Write-Host "Checking if company-services realm exists"
try {
    $REALM_EXISTS = Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services" `
        -Headers @{"Authorization" = "Bearer $ADMIN_TOKEN"} `
        -ErrorAction SilentlyContinue
} catch {
    $REALM_EXISTS = $null
}

if (-not $REALM_EXISTS) {
    Write-Host "Creating company-services realm"
    Write-Host "-------------------------------"
    try {
        Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms" `
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
        Write-Host "Realm 'company-services' created successfully."
    } catch {
        Write-Host "[ERROR] Failed to create realm 'company-services'. Details: $_"
        exit 1
    }
} else {
    Write-Host "Realm 'company-services' already exists. Skipping creation."
}

# Desativa a ação obrigatória "VERIFY_PROFILE"
Write-Host "Disabling required action Verify Profile"
Write-Host "----------------------------------------"
try {
    $VERIFY_PROFILE_REQUIRED_ACTION = Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/authentication/required-actions/VERIFY_PROFILE" `
        -Headers @{"Authorization" = "Bearer $ADMIN_TOKEN"}

    $VERIFY_PROFILE_REQUIRED_ACTION.enabled = $false

    Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/authentication/required-actions/VERIFY_PROFILE" `
        -Method Put `
        -Headers @{
            "Authorization" = "Bearer $ADMIN_TOKEN"
            "Content-Type" = "application/json"
        } `
        -Body ($VERIFY_PROFILE_REQUIRED_ACTION | ConvertTo-Json -Depth 10)
    Write-Host "Required action 'VERIFY_PROFILE' disabled successfully."
} catch {
    Write-Host "[ERROR] Failed to disable required action 'VERIFY_PROFILE'. Details: $_"
    exit 1
}

# Cria o cliente "movies-app"
Write-Host "Creating movies-app client"
Write-Host "--------------------------"
try {
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
    Write-Host "Client 'movies-app' created successfully."
} catch {
    Write-Host "[ERROR] Failed to create client 'movies-app'. Details: $_"
    exit 1
}

# Obtém o ID do cliente "movies-app"
Write-Host "Getting movies-app client ID"
Write-Host "----------------------------"
try {
    $CLIENTS = Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/clients" `
        -Headers @{"Authorization" = "Bearer $ADMIN_TOKEN"}

    $CLIENT_ID = ($CLIENTS | Where-Object { $_.clientId -eq "movies-app" }).id

    if (-not $CLIENT_ID) {
        Write-Host "[ERROR] Failed to retrieve movies-app client ID."
        exit 1
    }
    Write-Host "CLIENT_ID=$CLIENT_ID"
} catch {
    Write-Host "[ERROR] Failed to retrieve movies-app client ID. Details: $_"
    exit 1
}

# Verifica se o cliente "movies-app" existe
Write-Host "Verifying movies-app client"
Write-Host "--------------------------"
try {
    $MOVIES_APP_CLIENT = Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/clients/$CLIENT_ID" `
        -Headers @{"Authorization" = "Bearer $ADMIN_TOKEN"}
    Write-Host "Client 'movies-app' verified successfully."
} catch {
    Write-Host "[ERROR] Failed to verify client 'movies-app'. Details: $_"
    exit 1
}

# Renova o token de administrador
Write-Host "Renewing admin access token"
Write-Host "--------------------------"
try {
    $ADMIN_TOKEN = (Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/realms/master/protocol/openid-connect/token" `
        -Method Post `
        -Headers @{"Content-Type" = "application/x-www-form-urlencoded"} `
        -Body @{
            username = "admin"
            password = "admin"
            grant_type = "password"
            client_id = "admin-cli"
        }).access_token
    Write-Host "ADMIN_TOKEN renewed successfully."
} catch {
    Write-Host "[ERROR] Failed to renew admin access token. Details: $_"
    exit 1
}

# Cria os papéis "MOVIES_USER" e "MOVIES_ADMIN"
Write-Host "Creating client roles MOVIES_USER and MOVIES_ADMIN"
Write-Host "--------------------------------------------------"
try {
    Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/clients/$CLIENT_ID/roles" `
        -Method Post `
        -Headers @{
            "Authorization" = "Bearer $ADMIN_TOKEN"
            "Content-Type" = "application/json"
        } `
        -Body (@{
            name = "MOVIES_USER"
        } | ConvertTo-Json)

    Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/clients/$CLIENT_ID/roles" `
        -Method Post `
        -Headers @{
            "Authorization" = "Bearer $ADMIN_TOKEN"
            "Content-Type" = "application/json"
        } `
        -Body (@{
            name = "MOVIES_ADMIN"
        } | ConvertTo-Json)
    Write-Host "Client roles 'MOVIES_USER' and 'MOVIES_ADMIN' created successfully."
} catch {
    Write-Host "[ERROR] Failed to create client roles. Details: $_"
    exit 1
}

# Cria os grupos "USERS" e "ADMINS"
Write-Host "Creating groups USERS and ADMINS"
Write-Host "--------------------------------"
try {
    $USERS_GROUP_ID = (Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/groups" `
        -Method Post `
        -Headers @{
            "Authorization" = "Bearer $ADMIN_TOKEN"
            "Content-Type" = "application/json"
        } `
        -Body (@{
            name = "USERS"
        } | ConvertTo-Json)).id

    $ADMINS_GROUP_ID = (Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/groups" `
        -Method Post `
        -Headers @{
            "Authorization" = "Bearer $ADMIN_TOKEN"
            "Content-Type" = "application/json"
        } `
        -Body (@{
            name = "ADMINS"
        } | ConvertTo-Json)).id
    Write-Host "Groups 'USERS' and 'ADMINS' created successfully."
} catch {
    Write-Host "[ERROR] Failed to create groups. Details: $_"
    exit 1
}

# Atribui papéis aos grupos
Write-Host "Assigning roles to groups"
Write-Host "-------------------------"
try {
    # Atribui MOVIES_USER ao grupo USERS
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

    # Atribui MOVIES_USER e MOVIES_ADMIN ao grupo ADMINS
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
    Write-Host "Roles assigned to groups successfully."
} catch {
    Write-Host "[ERROR] Failed to assign roles to groups. Details: $_"
    exit 1
}

# Cria os usuários "user" e "admin"
Write-Host "Creating users 'user' and 'admin'"
Write-Host "---------------------------------"
try {
    # Cria o usuário "user"
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

    # Atribui o grupo "USERS" ao usuário "user"
    Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/users/$USER_ID/groups/$USERS_GROUP_ID" `
        -Method Put `
        -Headers @{"Authorization" = "Bearer $ADMIN_TOKEN"}

    # Cria o usuário "admin"
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

    # Atribui o grupo "ADMINS" ao usuário "admin"
    Invoke-RestMethod -Uri "http://$KEYCLOAK_HOST_PORT/admin/realms/company-services/users/$ADMIN_ID/groups/$ADMINS_GROUP_ID" `
        -Method Put `
        -Headers @{"Authorization" = "Bearer $ADMIN_TOKEN"}

    Write-Host "Users 'user' and 'admin' created successfully."
} catch {
    Write-Host "[ERROR] Failed to create users. Details: $_"
    exit 1
}

Write-Host "Keycloak setup completed successfully!"