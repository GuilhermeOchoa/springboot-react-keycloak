# Define os parâmetros da requisição
$body = @{
    username = "admin"
    password = "admin"
    grant_type = "password"
    client_id = "movies-app"
}

# Função para codificar valores no formato application/x-www-form-urlencoded
function UrlEncode($value) {
    return [System.Uri]::EscapeDataString($value)
}

# Converte o corpo da requisição para o formato application/x-www-form-urlencoded
$formData = ($body.GetEnumerator() | ForEach-Object { 
    "$(UrlEncode $_.Key)=$(UrlEncode $_.Value)" 
}) -join "&"

try {
    # Faz a requisição POST para obter o token
    $response = Invoke-RestMethod -Uri "http://localhost:8080/realms/company-services/protocol/openid-connect/token" `
        -Method Post `
        -Headers @{"Content-Type" = "application/x-www-form-urlencoded"} `
        -Body $formData

    # Extrai o access_token da resposta
    $ACCESS_TOKEN = $response.access_token

    # Exibe o token
    Write-Host "Access Token: $ACCESS_TOKEN"
} catch {
    # Exibe mensagens de erro detalhadas
    if ($_.Exception.Response) {
        $errorResponse = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $responseBody = $reader.ReadToEnd()
        Write-Host "[ERROR] Failed to get access token. Response: $responseBody"
    } else {
        Write-Host "[ERROR] Failed to get access token. Details: $_"
    }
    exit 1
}