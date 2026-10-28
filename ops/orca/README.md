# Orca + DeepSeek Harness

Esta carpeta contiene la configuración declarativa para orquestar el checkout
local desde Orca. No contiene claves: los proveedores se resuelven por
referencias de entorno administradas por 1Password en tiempo de ejecución.

## Principios operativos

- Codex permanece fuera de esta configuración y se reserva para reparación,
  diagnóstico y recuperación.
- El host por defecto es `local` y el workspace permitido es este checkout.
- Las acciones destructivas, credenciales, facturación, publicación externa,
  SSH, cambios físicos y accesos fuera del workspace requieren aprobación
  explícita.
- Los agentes pueden leer, probar y editar dentro de su worktree; no reciben
  acceso global al sistema ni a los valores de las claves.
- Playwright, Firecrawl, Nuclei y REA se activan sólo para tareas que los
  necesiten y con objetivos pertenecientes a la aplicación de prueba propia.

## Componentes registrados

| Rol | Agente/sustrato | Uso |
|---|---|---|
| coordinador | Orca | Descomponer, delegar, recopilar resultados |
| executor | DeepSeek Harness | Modelo por defecto de Abliteration y MCP locales |
| implementación | OpenCode/Copilot/Gemini/Claude según disponibilidad | Trabajo aislado en worktree |
| reparación | Codex | Diagnóstico y recuperación; configuración intacta |
| evidencia | REA + Nuclei | Inspección estática y comprobaciones acotadas |

La disponibilidad de una cuenta no se infiere del nombre del agente: Orca debe
mostrarla como administrada antes de lanzar una sesión autenticada.

## Comprobación

Desde la raíz del checkout:

```bash
./scripts/verify-orca-harness.sh
```

El script sólo emite estado y no imprime secretos. Para una primera ejecución
de Harness² use `--dry-run`, `k=1` y una tarea mínima; una ejecución completa
puede generar múltiples llamadas de modelo y consumir cuota.

## Routing y salud

`ops/orca/provider-routing.yaml` documenta el fallback acotado y
`scripts/provider-route.sh` selecciona el primer proveedor que responda a un
canario corto. `scripts/orca-health-snapshot.sh` genera un informe temporal sin
credenciales:

```bash
./scripts/orca-health-snapshot.sh /tmp/orca-harness-health.json
```

Harness² queda instalado de forma aislada en `outputs/harness2-venv/`; su demo
local ya pasó sin credenciales.

Graphify queda instalado con su extra Gemini y tiene un lanzador reproducible
en `scripts/graphify-orca.sh`. Por defecto usa un modelo `:free` de OpenRouter;
se puede seleccionar Gemini con `GRAPHIFY_PROVIDER=gemini`. La extracción
semántica sólo se marca `PASS` cuando produce `graphify-out/graph.json`.

Antigravity CLI queda registrado como `agy` (el nombre oficial del ejecutable),
y `npx` queda disponible mediante el shim local de npm 11. REA se valida con
`npx --yes rea-agents@6.8.0 mcp doctor --format json` antes de usarlo.

## GitHub MCP preparado

GitHub MCP queda preparado en modo `read-only` para `rafae3434-tech/deepseek-harness`.
La configuración está en `ops/orca/github-mcp.yaml` y sólo espera la referencia
`GITHUB_PERSONAL_ACCESS_TOKEN` administrada por 1Password. No se reutiliza
`GITHUB_MODELS_TOKEN_1` porque su alcance no está confirmado.

Para activarlo, crea un fine-grained token con `Metadata`, `Contents`, `Issues`
y `Pull requests` en `Read-only`, limitado a este repositorio, y guárdalo como
variable oculta `GITHUB_PERSONAL_ACCESS_TOKEN` en 1Password. Después responde
`token guardado`; la verificación sólo mostrará nombres de variables y estados,
nunca el valor secreto.
