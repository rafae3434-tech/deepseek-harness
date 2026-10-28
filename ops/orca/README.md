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
