# 002 — Tareas

**Spec:** ./spec.md · **Plan:** ./plan.md

| # | Tarea | Requisitos | Depende de | Estado |
|---|---|---|---|---|
| T1 | Confirmar cuándo se resuelve una referencia del Inspector | R1.3 | — | ☐ |
| T2 | El contador dice la verdad siempre | R1.1, R1.2, R1.3, R1.4, R1.5, R4.1 | T1 | ☐ |
| T3 | La ubicación aguanta la ventana | R3.1, R3.2 | T2 | ☐ |
| T4 | Afinar el formato mirándolo | R1.1 | T3 | ☐ |

## T1 — Confirmar cuándo se resuelve una referencia del Inspector

**Requisitos:** R1.3

Antes de escribir una línea del HUD. La decisión D3 del plan apoya R1.3 en que un
`@export var copy_system: CopySystem` ya esté resuelto cuando corre `_enter_tree()`, y eso
está marcado `⚠️API` porque no se verificó. Si resulta falso, D3 no existe y T2 se escribe
distinto — de ahí que esto vaya primero y no al final como comprobación.

**Termina cuando:** un script descartable, colgado de `level_01` con una referencia puesta
en el Inspector, imprime en el panel Output si esa referencia es `null` o no, en
`_enter_tree()` y de nuevo en `_ready()`. Dos líneas, y la primera es la respuesta.

**Verificación:** correr `level_01` con F5 y leer el Output. Si `_enter_tree()` reporta la
referencia ya resuelta, D3 queda en pie. Si reporta `null`, se toma el plan B que el plan
ya declara —conectar en `_ready()` y pedir el valor actual con `call_deferred`— y se anota
la corrección en `plan.md`, porque una decisión que se cae se corrige, no se borra.

## T2 — El contador dice la verdad siempre

**Requisitos:** R1.1, R1.2, R1.3, R1.4, R1.5, R4.1

El grueso del sistema, y una sola responsabilidad: que el número en pantalla coincida con
las copias que quedan, pase lo que pase. Incluye `src/ui/hud.gd`, `src/ui/hud.tscn`, la
suscripción a `copies_changed` según lo que haya respondido T1, la desconexión en
`_exit_tree()` y el `assert` que sostiene R4.1.

**Termina cuando:** corriendo `level_01`, el número en pantalla acompaña los cinco gestos
sin que haya que hacer nada más.

**Verificación:** cinco pruebas manuales, una por criterio.

| Gesto | Qué tiene que verse | Criterio |
|---|---|---|
| Arrancar el nivel | `3`, que es el `copy_limit` del `.tres` | R1.3 |
| Colocar con **E** | baja a `2` en el acto | R1.2 |
| Deshacer con **Q** | vuelve a `3` | R1.2 |
| Gastar las tres | `0`, visible, no oculto ni reemplazado | R1.5 |
| Borrar todo con **C** | vuelve a `3` | R1.2 |
| Reiniciar con **R** tras gastar copias | vuelve a `3` | R1.4 |
| Completar el nivel | el contador sigue en pantalla con su valor | R1.1 |
| Vaciar `Copy System` en el Inspector y correr | falla con un mensaje que nombra qué falta | R4.1 |

## T3 — La ubicación aguanta la ventana

**Requisitos:** R3.1, R3.2

Trabajo de editor, sin código: anclas, márgenes y tamaño de fuente en `hud.tscn`.

**Termina cuando:** el contador se lee bien en la ventana de diseño y no se corta ni se va
de cuadro al agrandarla o al cambiarle la proporción.

**Verificación:** correr y arrastrar el borde de la ventana — más ancha, más alta, y una
proporción muy ancha. Nada se corta ni se superpone con el nivel.

⚠️ **R3.1 queda verificado solo por construcción.** Sin cámara (B9) no existe una vista
que se desplace, así que no hay forma de observar que el HUD no la sigue. Lo garantiza el
`CanvasLayer` de D4, no una prueba. Se anota en la spec como pendiente de B9, igual que se
hizo con R1.6 de la spec 001.

## T4 — Afinar el formato mirándolo

**Requisitos:** R1.1

El último paso y el único que no se decide leyendo: si un `3` desnudo se entiende o si
hace falta `Copias: 3`. El plan lo dejó como `@export var label_format`, así que se prueba
cambiando el valor en el Inspector, sin tocar el script. El valor que gane queda en
`hud.tscn`.

**Termina cuando:** alguien que nunca vio el juego mira la pantalla y sabe qué es ese
número — o se acepta que no, y eso empuja los controles en pantalla hacia B10, que es
donde la spec ya los mandó.

**Verificación:** mirarlo. No hay criterio numérico y no se inventa uno: es feel, y el
método dice que el valor se encuentra probando y recién después se fija.

Cierra también la divergencia que anotó el plan: si `LevelHud` se acepta como nombre, el
diagrama de sistemas del `GDD.md` se actualiza en el mismo commit.

## Trazabilidad

**Todo criterio vivo de la spec aparece en al menos una tarea:**

| Criterio | Tareas |
|---|---|
| R1.1 | T2, T4 |
| R1.2 | T2 |
| R1.3 | T1, T2 |
| R1.4 | T2 |
| R1.5 | T2 |
| R3.1 | T3 *(por construcción; verificación real pendiente de B9)* |
| R3.2 | T3 |
| R4.1 | T2 |

Los 8 criterios vivos están cubiertos. No sobra ninguno.

**Toda tarea cita al menos un criterio:** T1 → R1.3 · T2 → seis criterios · T3 → R3.1,
R3.2 · T4 → R1.1. Ninguna tarea es alcance que se coló.

**Lo que no cierra, dicho explícitamente:**

- **R3.1 no se puede verificar hoy.** Está cubierto por T3 y garantizado por el
  `CanvasLayer`, pero no probado. Es una deuda declarada, no un criterio cumplido.
- **El grupo R2 está retirado** y no aparece acá, como corresponde. El aviso de nivel
  completado y la señal `completed` sin consumidor siguen siendo deuda de B7.
