$items = [System.Collections.Generic.List[object]]::new()
function Add-Request($name, $method, $path, $body = $null, $capture = $null, $authenticated = $true) {
    $headers = @(@{key='Accept';value='application/json'}, @{key='Content-Type';value='application/json'})
    $request = @{method=$method; header=$headers; url='{{base_url}}/'+$path}
    if ($authenticated) { $request.auth = @{type='bearer';bearer=@(@{key='token';value='{{token}}';type='string'})} }
    else { $request.auth = @{type='noauth'} }
    if ($null -ne $body) { $request.body = @{mode='raw';raw=($body | ConvertTo-Json -Depth 10);options=@{raw=@{language='json'}}} }
    $lines = @('pm.test("Request succeeds", () => pm.expect(pm.response.code).to.be.oneOf([200,201,204]));')
    if ($capture) { $lines += 'if (pm.response.code < 300) pm.collectionVariables.set("'+$capture+'", pm.response.json().'+ $(if ($capture -eq 'token') {'token'} else {'id'})+');' }
    $items.Add(@{name=$name;request=$request;event=@(@{listen='test';script=@{type='text/javascript';exec=$lines}})})
}
Add-Request 'Register employee (use a new email)' POST 'register' @{name='Demo Employee';email='{{email}}';password='{{password}}';password_confirmation='{{password}}'} 'token' $false
Add-Request 'Login' POST 'login' @{email='{{email}}';password='{{password}}'} 'token' $false
Add-Request 'Profile' GET 'profile'
Add-Request 'Update profile' PUT 'profile' @{name='Demo Employee Updated';email='{{email}}'}
Add-Request 'Dashboard' GET 'dashboard'
Add-Request 'Employees for assignment' GET 'employees'
$customer = @{name='Demo Customer';phone='41999999999';email='customer@example.com';address='Rua Central, 100'}
$device = @{cliente_id='{{customer_id}}';brand='Samsung';model='Galaxy A54';notes='Aparelho recebido sem carregador'}
$order = @{aparelho_id='{{device_id}}';problem='Tela quebrada';status='received';price=250;diagnosis='Substituir display'}
$part = @{name='Display A54';sku='DEMO-A54';quantity=4;price=95}
foreach ($entry in @(@{resource='clientes';id='customer_id';data=$customer}, @{resource='aparelhos';id='device_id';data=$device}, @{resource='ordens-servico';id='order_id';data=$order}, @{resource='parts';id='part_id';data=$part})) {
  Add-Request ('Create '+$entry.resource) POST $entry.resource $entry.data $entry.id
  Add-Request ('List '+$entry.resource) GET ($entry.resource+'?search=')
  Add-Request ('Read '+$entry.resource) GET ($entry.resource+'/{{'+$entry.id+'}}')
  if ($entry.resource -eq 'ordens-servico') { $entry.data.status = 'completed' }
  Add-Request ('Update '+$entry.resource) PUT ($entry.resource+'/{{'+$entry.id+'}}') $entry.data
}
Add-Request 'Filter completed repairs' GET 'ordens-servico?status=completed'
foreach ($entry in @(@{r='ordens-servico';id='order_id'}, @{r='aparelhos';id='device_id'}, @{r='clientes';id='customer_id'}, @{r='parts';id='part_id'})) {
  Add-Request ('Delete '+$entry.r) DELETE ($entry.r+'/{{'+$entry.id+'}}')
}
Add-Request 'Logout' POST 'logout'
$adminItems = [System.Collections.Generic.List[object]]::new()
$mainItems = @($items.ToArray())
$items.Clear()
Add-Request 'Login as administrator' POST 'login' @{email='{{admin_email}}';password='{{admin_password}}'} 'token' $false
$employee = @{name='Managed employee';email='managed@example.com';password='Example12345!';role='employee'}
Add-Request 'Create employee' POST 'users' $employee 'employee_id'
Add-Request 'List staff' GET 'users'
Add-Request 'Read employee' GET 'users/{{employee_id}}'
$employee.name = 'Updated employee'
Add-Request 'Update employee' PUT 'users/{{employee_id}}' $employee
Add-Request 'Delete employee' DELETE 'users/{{employee_id}}'
Add-Request 'Logout administrator' POST 'logout'
$collection = @{
  info=@{name='TechFix API';schema='https://schema.getpostman.com/json/collection/v2.1.0/collection.json';description='Run Employee workflow, then Administrator workflow. Use a new registration email and configure administrator credentials. Tokens and created IDs are captured automatically.'}
  variable=@(@{key='base_url';value='http://localhost:8000/api'}, @{key='email';value='demo@example.com'}, @{key='password';value='Example12345!'}, @{key='admin_email';value='admin@example.com'}, @{key='admin_password';value=''}, @{key='token';value=''})
  item=@(@{name='Employee workflow';item=$mainItems}, @{name='Administrator workflow';item=@($items.ToArray())})
}
[IO.File]::WriteAllText((Join-Path (Get-Location) 'docs/TechFix.postman_collection.json'), ($collection | ConvertTo-Json -Depth 30), [Text.UTF8Encoding]::new($false))
