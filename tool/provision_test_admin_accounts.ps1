$apiKey = 'AIzaSyAL5HaR_-Ey1a8olyC1hDI0mGqmUpWj4go'

$accounts = @(
  @{ email = 'admin1@bhandaripariwar.app'; password = 'Bhandari@123' },
  @{ email = 'admin2@bhandaripariwar.app'; password = 'Bhandari@234' },
  @{ email = 'admin3@bhandaripariwar.app'; password = 'Bhandari@345' },
  @{ email = 'admin4@bhandaripariwar.app'; password = 'Bhandari@456' }
)

foreach ($account in $accounts) {
  $body = @{
    email = $account.email
    password = $account.password
    returnSecureToken = $true
  } | ConvertTo-Json

  try {
    $response = Invoke-RestMethod `
      -Method Post `
      -Uri "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey" `
      -ContentType 'application/json' `
      -Body $body

    Write-Output "CREATED $($account.email) uid=$($response.localId)"
  } catch {
    $message = $_.ErrorDetails.Message
    if ($message) {
      try {
        $parsed = $message | ConvertFrom-Json
        if ($parsed.error.message -eq 'EMAIL_EXISTS') {
          Write-Output "EXISTS $($account.email)"
          continue
        }
      } catch {
      }
    }

    throw
  }
}
