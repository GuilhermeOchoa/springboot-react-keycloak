# Define o access_token
$ACCESS_TOKEN = "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJuakY4Z3Qza1N6YmJtV1RJTG1XZmdSUHNuWTVIb05YZ29EX0lvNV9LVDFNIn0.eyJleHAiOjE3NDI3MDQxMjcsImlhdCI6MTc0MjcwMzgyNywianRpIjoiYTAzZWFlZDYtYzk4Mi00NWYwLWExY2ItYmE3YzcyNjNhMmQzIiwiaXNzIjoiaHR0cDovL2xvY2FsaG9zdDo4MDgwL3JlYWxtcy9jb21wYW55LXNlcnZpY2VzIiwiYXVkIjoiYWNjb3VudCIsInN1YiI6IjY0M2VkMDM4LWJhNzItNDE2ZC05ZjlkLWJlZTRmNzY1NmYwMCIsInR5cCI6IkJlYXJlciIsImF6cCI6Im1vdmllcy1hcHAiLCJzaWQiOiJiZWI5NjU1ZS04NjE4LTRmNGYtODhmNC01YmZlNGE2OTFmOWEiLCJhY3IiOiIxIiwiYWxsb3dlZC1vcmlnaW5zIjpbImh0dHA6Ly9sb2NhbGhvc3Q6MzAwMCJdLCJyZWFsbV9hY2Nlc3MiOnsicm9sZXMiOlsib2ZmbGluZV9hY2Nlc3MiLCJkZWZhdWx0LXJvbGVzLWNvbXBhbnktc2VydmljZXMiLCJ1bWFfYXV0aG9yaXphdGlvbiJdfSwicmVzb3VyY2VfYWNjZXNzIjp7ImFjY291bnQiOnsicm9sZXMiOlsibWFuYWdlLWFjY291bnQiLCJtYW5hZ2UtYWNjb3VudC1saW5rcyIsInZpZXctcHJvZmlsZSJdfX0sInNjb3BlIjoicHJvZmlsZSBlbWFpbCIsImVtYWlsX3ZlcmlmaWVkIjpmYWxzZSwicHJlZmVycmVkX3VzZXJuYW1lIjoiYWRtaW4ifQ.rLhn8wbpxLz9pSePkJIgJGie-3a4FBCcHKh7Yhsi2aPGDEtRd49op_4mEEOFj12xImRvwRL4cuE0BSI-mniAhQC2AXKdTpt5EYHbJPFksAwtcvXSTwaumQPULnKkYQjeoeShyou_9WsM4zpS1PtWBgH5HjH3LsqY26FsgtdpELBzshBlqHxZmEgOON40NjQIhMXdSHMcSi67mg1Td3LMPANej9NDsWsN6p1ZlASiDHYCL0dJt0K3-7rv3Vv1n58Wfnnb9y5j-6MUr2YI37HVQ5jpHjYmVcp1QLsAC8-MdHVGaEFrf42ZaT5Ez2XkNif21ZY5Ih6RKn_7Z7TD_6ajig"

# Define o corpo da requisição em formato JSON
$body = @{
    imdbId = "tt5580036"
    title = "I, Tonya"
    director = "Craig Gillespie"
    year = 2017
    poster = "https://m.media-amazon.com/images/M/MV5BMjI5MDY1NjYzMl5BMl5BanBnXkFtZTgwNjIzNDAxNDM@._V1_SX300.jpg"
} | ConvertTo-Json

try {
    # Faz a requisição POST
    $response = Invoke-RestMethod -Uri "http://localhost:9080/api/movies" `
        -Method Post `
        -Headers @{
            "Authorization" = "Bearer $ACCESS_TOKEN"
            "Content-Type" = "application/json"
        } `
        -Body $body

    # Exibe a resposta
    Write-Host "Response: $($response | ConvertTo-Json -Depth 10)"
} catch {
    # Exibe mensagens de erro detalhadas
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorResponse = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $responseBody = $reader.ReadToEnd()
        Write-Host "[ERROR] Failed to create movie. Status Code: $statusCode"
        Write-Host "Response Body: $responseBody"
    } else {
        Write-Host "[ERROR] Failed to create movie. Details: $_"
    }
    exit 1
}