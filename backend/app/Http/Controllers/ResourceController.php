<?php

namespace App\Http\Controllers;

use App\Models\Aparelho;
use App\Models\Cliente;
use App\Models\OrdemServico;
use App\Models\Part;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class ResourceController extends Controller
{
    private const MODELS = ['clientes' => Cliente::class, 'aparelhos' => Aparelho::class, 'ordens-servico' => OrdemServico::class, 'users' => User::class, 'parts' => Part::class];

    private const STATUSES = ['received', 'diagnosing', 'awaiting_parts', 'repairing', 'completed', 'delivered', 'cancelled'];

    private function model(Request $request): string
    {
        $resource = $request->route('resource');
        abort_unless(isset(self::MODELS[$resource]), 404);
        if ($resource === 'users') {
            abort_unless($request->user()->role === 'admin', 403);
        }

        return self::MODELS[$resource];
    }

    private function query(Request $request)
    {
        $model = $this->model($request);
        $query = $model::query();
        if ($model === OrdemServico::class) {
            $query->with(['aparelho.cliente', 'assignedUser', 'history.user']);
        }
        if ($model === Aparelho::class) {
            $query->with('cliente');
        }

        return $query;
    }

    private function validated(Request $request, ?int $id = null): array
    {
        $rules = match ($request->route('resource')) {
            'clientes' => ['name' => 'required|string|max:255', 'email' => 'nullable|email|max:255', 'phone' => 'required|string|max:30', 'address' => 'nullable|string|max:2000'],
            'aparelhos' => ['cliente_id' => 'nullable|integer|exists:clientes,id', 'brand' => 'required|string|max:255', 'model' => 'required|string|max:255', 'imei' => ['nullable', 'string', 'max:30', Rule::unique('aparelhos')->ignore($id)], 'notes' => 'nullable|string|max:5000'],
            'ordens-servico' => ['aparelho_id' => 'required|integer|exists:aparelhos,id', 'assigned_to' => 'nullable|integer|exists:users,id', 'problem' => 'required|string|max:5000', 'diagnosis' => 'nullable|string|max:5000', 'status' => ['required', Rule::in(self::STATUSES)], 'price' => 'required|numeric|min:0|max:99999999.99', 'notes' => 'nullable|string|max:5000'],
            'users' => ['name' => 'required|string|max:255', 'email' => ['required', 'email', 'max:255', Rule::unique('users')->ignore($id)], 'password' => ($id ? 'sometimes' : 'required').'|string|min:8|max:255', 'role' => ['required', Rule::in(['admin', 'employee'])]],
            'parts' => ['name' => 'required|string|max:255', 'sku' => ['required', 'string', 'max:255', Rule::unique('parts')->ignore($id)], 'quantity' => 'required|integer|min:0|max:2147483647', 'price' => 'required|numeric|min:0|max:99999999.99'],
        };

        return $request->validate($rules);
    }

    public function index(Request $request)
    {
        $query = $this->query($request);
        $request->validate(['search' => 'nullable|string|max:255', 'status' => ['nullable', Rule::in(self::STATUSES)]]);
        if ($search = $request->query('search')) {
            $columns = match ($request->route('resource')) {
                'ordens-servico' => ['number', 'problem'], 'aparelhos' => ['brand', 'model', 'imei'], default => ['name']
            };
            $query->where(function ($q) use ($columns, $search) {
                foreach ($columns as $column) {
                    $q->orWhere($column, 'like', '%'.$search.'%');
                }
            });
        }
        if ($request->route('resource') === 'ordens-servico' && $request->filled('status')) {
            $query->where('status', $request->query('status'));
        }

        return $query->latest('id')->get();
    }

    public function show(Request $request, string $resource, int $id)
    {
        return $this->query($request)->findOrFail($id);
    }

    public function store(Request $request)
    {
        $model = $this->model($request);
        $data = $this->validated($request);
        $row = DB::transaction(function () use ($request, $model, $data) {
            if ($model === OrdemServico::class) {
                $data = [...$data, 'number' => 'TF-'.Str::ulid(), 'created_by' => $request->user()->id];
            }
            $row = $model::create($data);
            if ($model === OrdemServico::class) {
                $row->history()->create(['status' => $row->status, 'user_id' => $request->user()->id]);
            }

            return $row;
        });

        return response()->json($this->query($request)->findOrFail($row->id), 201);
    }

    public function update(Request $request, string $resource, int $id)
    {
        $row = $this->query($request)->findOrFail($id);
        $data = $this->validated($request, $id);
        abort_if($resource === 'users' && $id === $request->user()->id && $data['role'] !== 'admin', 422, 'Você não pode remover sua própria permissão de administrador.');
        DB::transaction(function () use ($request, $row, $data, $resource) {
            $locked = $row->newQuery()->lockForUpdate()->findOrFail($row->id);
            $oldStatus = $locked->getAttribute('status');
            $locked->update($data);
            if ($resource === 'ordens-servico' && $oldStatus !== $locked->status) {
                $locked->history()->create(['status' => $locked->status, 'user_id' => $request->user()->id]);
            }
            if ($resource === 'users' && ($data['role'] !== $row->role || isset($data['password']))) {
                $locked->tokens()->delete();
            }
        });

        return $this->query($request)->findOrFail($id);
    }

    public function destroy(Request $request, string $resource, int $id)
    {
        $row = $this->query($request)->findOrFail($id);
        abort_if($resource === 'users' && $id === $request->user()->id, 422, 'Você não pode excluir sua própria conta.');
        abort_if($resource === 'clientes' && $row->aparelhos()->exists(), 409, 'Remova os aparelhos vinculados antes de excluir este cliente.');
        abort_if($resource === 'aparelhos' && $row->ordens()->exists(), 409, 'Remova as ordens vinculadas antes de excluir este aparelho.');
        DB::transaction(function () use ($resource, $row) {
            if ($resource === 'users') {
                $row->tokens()->delete();
            } $row->delete();
        });

        return response()->noContent();
    }
}
