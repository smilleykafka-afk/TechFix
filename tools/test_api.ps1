param([string]$BaseUrl = 'http://localhost:8000/api')
$ErrorActionPreference = 'Stop'
$suffix = [guid]::NewGuid().ToString('N')
$password = [guid]::NewGuid().ToString('N')
$email = "docker-$suffix@example.com"
$headers = @{ Accept = 'application/json' }
function Request($Method, $Path, $Body = $null) {
    $params = @{ Method = $Method; Uri = "$BaseUrl$Path"; Headers = $headers }
    if ($null -ne $Body) {
        $params.ContentType = 'application/json'
        $params.Body = $Body | ConvertTo-Json -Depth 10
    }
    Invoke-RestMethod @params
}
$customer = $null
$device = $null
$order = $null
try {
    $session = Request Post '/register' @{name='Docker smoke test';email=$email;password=$password;password_confirmation=$password;role='admin'}
    if ($session.user.role -ne 'employee') { throw 'Public registration allowed privilege escalation.' }
    $headers.Authorization = "Bearer $($session.token)"
    $profile = Request Get '/profile'
    if ($profile.email -ne $email) { throw 'Profile does not match registered user.' }
    $customer = Request Post '/clientes' @{name="Docker $suffix";phone='41999999999'}
    $device = Request Post '/aparelhos' @{cliente_id=$customer.id;brand='Samsung';model='Docker test'}
    $orderBody = @{aparelho_id=$device.id;assigned_to=$profile.id;problem='Smoke test';status='received';price=250}
    $order = Request Post '/ordens-servico' $orderBody
    $orderBody.status = 'completed'
    $updated = Request Put "/ordens-servico/$($order.id)" $orderBody
    if ($updated.status -ne 'completed' -or $updated.history.Count -ne 2) { throw 'Repair status or history was not saved.' }
    $null = Request Get '/dashboard'
    Write-Output 'PASS: registration, employee role, bearer authentication, profile, customer/device/order creation, status history and dashboard.'
} finally {
    # Remove only records created by this run, in dependency order.
    if ($order) { $null = Request Delete "/ordens-servico/$($order.id)" }
    if ($device) { $null = Request Delete "/aparelhos/$($device.id)" }
    if ($customer) { $null = Request Delete "/clientes/$($customer.id)" }
    if ($headers.Authorization) { $null = Request Post '/logout' @{} }
}
Write-Output "Created test employee: $email (logged out). Business test records removed."
