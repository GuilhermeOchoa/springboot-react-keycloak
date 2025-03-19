# Configurações
$keycloakHostPort = "localhost:8080"
$adminToken = "<YOUR_ADMIN_TOKEN>"  # Substitua com o token de admin obtido

# Função para verificar se um realm existe
function Check-RealmExist($realmName) {
    $realmExists = (Invoke-RestMethod -Uri "http://$keycloakHostPort/admin/realms" -Headers @{Authorization = "Bearer $adminToken"} | Where-Object { $_.realm -eq $realmName })
    return $realmExists -ne $null
}

# Função para criar o realm se não existir
if (-not (Check-RealmExist "company-services")) {
    Write-Host "Criando o realm 'company-services'..."
    Invoke-RestMethod -Uri "http://$keycloakHostPort/admin/realms" -Method Post -Headers @{Authorization = "Bearer $adminToken"} -Body '{"realm": "company-services", "enabled": true}' -ContentType "application/json"
} else {
    Write-Host "O realm 'company-services' já existe."
}

# Função para verificar se o cliente existe
function Check-ClientExist($clientId) {
    $clientExists = (Invoke-RestMethod -Uri "http://$keycloakHostPort/admin/realms/company-services/clients" -Headers @{Authorization = "Bearer $adminToken"} | Where-Object { $_.clientId -eq $clientId })
    return $clientExists -ne $null
}

# Criar cliente se não existir
if (-not (Check-ClientExist "movies-app")) {
    Write-Host "Criando cliente 'movies-app'..."
    Invoke-RestMethod -Uri "http://$keycloakHostPort/admin/realms/company-services/clients" -Method Post -Headers @{Authorization = "Bearer $adminToken"} -Body '{"clientId": "movies-app", "enabled": true, "redirectUris": [ "http://localhost:3000/*" ], "publicClient": true, "protocol": "openid-connect"}' -ContentType "application/json"
} else {
    Write-Host "O cliente 'movies-app' já existe."
}

# Função para verificar se a role existe
function Check-RoleExist($roleName) {
    $roleExists = (Invoke-RestMethod -Uri "http://$keycloakHostPort/admin/realms/company-services/roles" -Headers @{Authorization = "Bearer $adminToken"} | Where-Object { $_.name -eq $roleName })
    return $roleExists -ne $null
}

# Criar roles se não existirem
if (-not (Check-RoleExist "MOVIES_USER")) {
    Write-Host "Criando role 'MOVIES_USER'..."
    Invoke-RestMethod -Uri "http://$keycloakHostPort/admin/realms/company-services/roles" -Method Post -Headers @{Authorization = "Bearer $adminToken"} -Body '{"name": "MOVIES_USER"}' -ContentType "application/json"
} else {
    Write-Host "A role 'MOVIES_USER' já existe."
}

if (-not (Check-RoleExist "MOVIES_ADMIN")) {
    Write-Host "Criando role 'MOVIES_ADMIN'..."
    Invoke-RestMethod -Uri "http://$keycloakHostPort/admin/realms/company-services/roles" -Method Post -Headers @{Authorization = "Bearer $adminToken"} -Body '{"name": "MOVIES_ADMIN"}' -ContentType "application/json"
} else {
    Write-Host "A role 'MOVIES_ADMIN' já existe."
}

# Função para verificar se o grupo existe
function Check-GroupExist($groupName) {
    $groupExists = (Invoke-RestMethod -Uri "http://$keycloakHostPort/admin/realms/company-services/groups" -Headers @{Authorization = "Bearer $adminToken"} | Where-Object { $_.name -eq $groupName })
    return $groupExists -ne $null
}

# Criar grupos se não existirem
if (-not (Check-GroupExist "USERS")) {
    Write-Host "Criando grupo 'USERS'..."
    Invoke-RestMethod -Uri "http://$keycloakHostPort/admin/realms/company-services/groups" -Method Post -Headers @{Authorization = "Bearer $adminToken"} -Body '{"name": "USERS"}' -ContentType "application/json"
} else {
    Write-Host "O grupo 'USERS' já existe."
}

if (-not (Check-GroupExist "ADMINS")) {
    Write-Host "Criando grupo 'ADMINS'..."
    Invoke-RestMethod -Uri "http://$keycloakHostPort/admin/realms/company-services/groups" -Method Post -Headers @{Authorization = "Bearer $adminToken"} -Body '{"name": "ADMINS"}' -ContentType "application/json"
} else {
    Write-Host "O grupo 'ADMINS' já existe."
}

# Função para associar um grupo a um usuário
function Associate-GroupToUser($username, $groupName) {
    $userUri = "http://$keycloakHostPort/admin/realms/company-services/users"
    $userExists = Invoke-RestMethod -Uri $userUri -Headers @{Authorization = "Bearer $adminToken"} | Where-Object { $_.username -eq $username }
    
    if ($userExists) {
        $userId = $userExists[0].id
        $groupUri = "http://$keycloakHostPort/admin/realms/company-services/users/$userId/groups"
        $groupId = (Invoke-RestMethod -Uri "http://$keycloakHostPort/admin/realms/company-services/groups" -Headers @{Authorization = "Bearer $adminToken"} | Where-Object { $_.name -eq $groupName }).id
        Write-Host "Associando o grupo '$groupName' ao usuário '$username'..."
        $groupBody = @{ "id" = $groupId }
        Invoke-RestMethod -Uri $groupUri -Method Post -Headers @{Authorization = "Bearer $adminToken"} -Body ($groupBody | ConvertTo-Json) -ContentType "application/json"
    } else {
        Write-Host "O usuário '$username' não foi encontrado."
    }
}

# Associando os grupos 'USERS' e 'ADMINS' aos respectivos usuários
Associate-GroupToUser "user" "USERS"
Associate-GroupToUser "admin" "ADMINS"

Write-Host "Script finalizado!"
