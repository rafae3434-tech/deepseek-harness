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

Graphify queda instalado con un lanzador reproducible en
`scripts/graphify-orca.sh`. La ruta predeterminada es estructural y local:
extrae el código con AST, no necesita API key y usa `scripts` como corpus para
mantener el consumo bajo. Se puede cambiar el alcance con
`GRAPHIFY_PATH=...` y la salida con `GRAPHIFY_OUT=...`.

La extracción semántica de documentación es opcional y se activa con
`GRAPHIFY_MODE=semantic`; requiere una clave administrada externamente y puede
usar Gemini (`GRAPHIFY_PROVIDER=gemini`) u OpenRouter con un modelo `:free`.
La extracción sólo se marca `PASS` cuando produce un `graphify-out/graph.json`
no vacío. Los fixtures binarios de pruebas se excluyen mediante
`.graphifyignore` para evitar que un archivo ofimático cifrado detenga el
análisis.

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

## Tailscale local

Tailscale queda registrado como integración de terminal de solo lectura para
Orca. El estado, las IP propias y la conectividad se pueden consultar con
`scripts/tailscale-orca-status.sh`. Las operaciones que cambian la sesión,
rutas, publicación, SSH o exposición de servicios requieren aprobación
explícita y no reciben claves de autenticación.

## AWS Agent Toolkit

El MCP oficial de AWS queda habilitado para consultas de solo lectura usando
la sesión temporal de `aws login`. El proxy está fijado en
`mcp-proxy-for-aws@1.6.3`. Orca debe solicitar aprobación antes de cualquier
operación que cree, modifique o elimine recursos, y la política local bloquea
el aprovisionamiento por defecto.

## Recuperación en otro equipo

`ops/orca/replication.yaml` es el inventario declarativo de restauración.
Después de clonar el repositorio y reinstalar los runtimes locales, ejecuta
`scripts/verify-replication.sh`. El chequeo no crea recursos, no cambia cuentas
y nunca imprime valores de secretos. Las claves se vuelven a resolver desde
1Password y las sesiones externas se reautentican sólo cuando sea necesario.

REA mantiene dos límites deliberados: el análisis de navegador necesita un
endpoint CDP de bucle local con orígenes explícitos, y los motores Hopper,
Ghidra e IDA son capacidades opcionales de análisis nativo, no requisitos para
el flujo Harness/Orca.

## Trabajadores opcionales

Strands Agents, LangGraph y Microsoft Agent Framework se mantienen en
`outputs/orca-workers-uv-venv/` y se registran en `ops/orca/workers.yaml`.
Orca los activa por tarea; ninguno puede reemplazar al coordinador ni hacer
llamadas de modelo por defecto. `scripts/verify-framework-workers.sh` valida
las importaciones sin contactar proveedores.

## REA + Google

La sesión dedicada de Chrome usa el perfil local
`~/.local/share/rea-google-cdp-profile`, CDP en `127.0.0.1:9222` y orígenes
Google explícitos. El usuario debe iniciar sesión manualmente. Es posible
usar varias cuentas dentro de ese perfil, pero no se conceden cookies ni
acceso global al perfil personal existente.

Ghidra 12.1.4 y un JDK 21 libre quedan instalados fuera del repositorio en
`outputs/rea-tools/`. `scripts/rea-ghidra-env.sh` prepara `JAVA_HOME` y
`GHIDRA_INSTALL_DIR` para las sesiones de REA. Hopper e IDA permanecen fuera
del despliegue por ser productos propietarios; para esos casos se usa Ghidra
y las inspecciones integradas de REA.
