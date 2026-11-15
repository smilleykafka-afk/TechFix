<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TechFixTest extends TestCase
{
    use RefreshDatabase;

    private function account(string $role = 'employee'): array
    {
        $this->app['auth']->forgetGuards();
        $user = User::factory()->create(['role' => $role]);

        return [$user, ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken]];
    }

    public function test_registration_cannot_escalate_privileges_and_logout_revokes_token(): void
    {
        $response = $this->postJson('/api/register', ['name' => 'Ana', 'email' => 'ana@example.com', 'password' => 'secret123', 'password_confirmation' => 'secret123', 'role' => 'admin'])
            ->assertCreated()->assertJsonPath('user.role', 'employee');
        $headers = ['Authorization' => 'Bearer '.$response->json('token')];
        $this->getJson('/api/profile', $headers)->assertOk()->assertJsonMissingPath('password');
        $this->postJson('/api/logout', [], $headers)->assertNoContent();
        $this->app['auth']->forgetGuards();
        $this->getJson('/api/profile', $headers)->assertUnauthorized();
    }

    public function test_login_rejects_bad_password_and_issues_working_token(): void
    {
        User::factory()->create(['email' => 'test@example.com', 'password' => 'secret123']);
        $this->postJson('/api/login', ['email' => 'test@example.com', 'password' => 'wrong'])->assertUnprocessable();
        $token = $this->postJson('/api/login', ['email' => 'test@example.com', 'password' => 'secret123'])->assertOk()->json('token');
        $this->getJson('/api/profile', ['Authorization' => 'Bearer '.$token])->assertOk();
    }

    public function test_employee_cannot_manage_users_and_admin_can(): void
    {
        [$employee, $headers] = $this->account();
        $this->getJson('/api/users', $headers)->assertForbidden();
        $this->postJson('/api/users', ['name' => 'Blocked'], $headers)->assertForbidden();
        $this->getJson('/api/employees', $headers)->assertOk()->assertJsonMissingPath('0.email');
        [$admin, $headers] = $this->account('admin');
        $id = $this->postJson('/api/users', ['name' => 'New employee', 'email' => 'new@example.com', 'password' => 'secret123', 'role' => 'employee'], $headers)->assertCreated()->json('id');
        $this->getJson('/api/users/'.$id, $headers)->assertOk();
        $this->putJson('/api/users/'.$id, ['name' => 'Edited', 'email' => 'new@example.com', 'role' => 'employee'], $headers)->assertOk();
        $this->deleteJson('/api/users/'.$admin->id, [], $headers)->assertUnprocessable();
        $this->deleteJson('/api/users/'.$id, [], $headers)->assertNoContent();
    }

    public function test_repair_workflow_filters_history_relationships_and_deletion(): void
    {
        [$user, $h] = $this->account();
        $customer = ['name' => 'Customer', 'phone' => '41999999999', 'email' => 'customer@example.com'];
        $cid = $this->postJson('/api/clientes', $customer, $h)->assertCreated()->json('id');
        $this->getJson('/api/clientes?search=Customer', $h)->assertOk()->assertJsonCount(1);
        $this->putJson('/api/clientes/'.$cid, [...$customer, 'name' => 'Updated'], $h)->assertOk();
        $device = ['cliente_id' => $cid, 'brand' => 'Samsung', 'model' => 'Galaxy A54'];
        $did = $this->postJson('/api/aparelhos', $device, $h)->assertCreated()->json('id');
        $this->getJson('/api/aparelhos/'.$did, $h)->assertOk()->assertJsonPath('cliente.name', 'Updated');
        $this->putJson('/api/aparelhos/'.$did, [...$device, 'model' => 'Galaxy S24'], $h)->assertOk();
        $order = ['aparelho_id' => $did, 'assigned_to' => $user->id, 'problem' => 'Broken screen', 'status' => 'received', 'price' => 250];
        $created = $this->postJson('/api/ordens-servico', $order, $h)->assertCreated();
        $oid = $created->json('id');
        $second = $this->postJson('/api/ordens-servico', $order, $h)->assertCreated();
        $this->assertNotEquals($created->json('number'), $second->json('number'));
        $this->putJson('/api/ordens-servico/'.$oid, [...$order, 'status' => 'completed'], $h)->assertOk()->assertJsonCount(2, 'history');
        $this->getJson('/api/ordens-servico?status=completed', $h)->assertOk()->assertJsonCount(1);
        $this->getJson('/api/dashboard', $h)->assertOk()->assertJsonPath('open_orders', 1)->assertJsonPath('completed_orders', 1);
        $this->deleteJson('/api/clientes/'.$cid, [], $h)->assertConflict();
        $this->deleteJson('/api/aparelhos/'.$did, [], $h)->assertConflict();
        $this->deleteJson('/api/ordens-servico/'.$oid, [], $h)->assertNoContent();
        $this->deleteJson('/api/ordens-servico/'.$second->json('id'), [], $h)->assertNoContent();
        $this->deleteJson('/api/aparelhos/'.$did, [], $h)->assertNoContent();
        $this->deleteJson('/api/clientes/'.$cid, [], $h)->assertNoContent();
        $this->getJson('/api/clientes', $h)->assertOk()->assertExactJson([]);
    }

    public function test_devices_can_be_created_without_customers_and_used_in_orders(): void
    {
        [$user, $headers] = $this->account();
        $device = ['brand' => 'Samsung', 'model' => 'Independent device'];
        $id = $this->postJson('/api/aparelhos', $device, $headers)
            ->assertCreated()->assertJsonPath('cliente', null)->json('id');
        $this->assertDatabaseHas('aparelhos', ['id' => $id, 'cliente_id' => null]);
        $this->postJson('/api/ordens-servico', [
            'aparelho_id' => $id, 'problem' => 'Broken screen', 'status' => 'received', 'price' => 100,
        ], $headers)->assertCreated()->assertJsonPath('aparelho.cliente', null);
        $this->postJson('/api/aparelhos', [...$device, 'cliente_id' => 999999], $headers)
            ->assertUnprocessable()->assertJsonValidationErrors('cliente_id');
        $customer = $this->postJson('/api/clientes', ['name' => 'Optional customer', 'phone' => '41999999999'], $headers)
            ->assertCreated()->json('id');
        $this->putJson('/api/aparelhos/'.$id, [...$device, 'cliente_id' => $customer], $headers)
            ->assertOk()->assertJsonPath('cliente.id', $customer);
        $this->putJson('/api/aparelhos/'.$id, [...$device, 'cliente_id' => null], $headers)
            ->assertOk()->assertJsonPath('cliente_id', null)->assertJsonPath('cliente', null);
        $this->deleteJson('/api/clientes/'.$customer, [], $headers)->assertNoContent();
    }

    public function test_inventory_crud_profile_and_validation(): void
    {
        [$user, $h] = $this->account();
        $part = ['name' => 'Display', 'sku' => 'DSP-01', 'quantity' => 5, 'price' => 80];
        $id = $this->postJson('/api/parts', $part, $h)->assertCreated()->json('id');
        $this->getJson('/api/parts/'.$id, $h)->assertOk();
        $this->putJson('/api/parts/'.$id, [...$part, 'quantity' => 3], $h)->assertOk()->assertJsonPath('quantity', 3);
        $this->postJson('/api/parts', [...$part, 'quantity' => -1], $h)->assertUnprocessable();
        $this->postJson('/api/clientes', [], $h)->assertUnprocessable()->assertJsonValidationErrors(['name', 'phone']);
        $this->postJson('/api/ordens-servico', ['aparelho_id' => 999999, 'status' => 'invalid'], $h)->assertUnprocessable();
        $this->putJson('/api/profile', ['name' => 'New name', 'email' => $user->email, 'role' => 'admin'], $h)->assertOk()->assertJsonPath('role', 'employee');
        $this->deleteJson('/api/parts/'.$id, [], $h)->assertNoContent();
        $this->getJson('/api/parts/'.$id, $h)->assertNotFound();
    }

    public function test_all_resource_routes_require_authentication(): void
    {
        foreach (['clientes', 'aparelhos', 'ordens-servico', 'users', 'parts'] as $resource) {
            $this->getJson('/api/'.$resource)->assertUnauthorized();
            $this->postJson('/api/'.$resource, [])->assertUnauthorized();
            $this->putJson('/api/'.$resource.'/1', [])->assertUnauthorized();
            $this->deleteJson('/api/'.$resource.'/1')->assertUnauthorized();
        }
    }
}
