# 001 — Tareas

**Spec:** ./spec.md · **Plan:** ./plan.md

| # | Tarea | Requisitos | Depende de | Estado |
|---|---|---|---|---|
| T1 | Meta, estado completado e input congelado | R1.1, R1.2, R1.4, R1.6, R3.2 | — | ☑ 2026-09-19 |
| T2 | Punto de inicio y reinicio manual | R2.1, R2.2, R2.3, R2.5, R3.1 | T1 | ☑ 2026-09-19 |
| T3 | Zonas de muerte | R4.1, R4.2, R4.4 | T2 | ☑ 2026-09-19 |
| T4 | Casos borde: reentrada y prioridades | R1.3, R2.4, R4.3 | T3 | ☑ 2026-09-20 |
| T5 | Encadenar al siguiente nivel | R1.5 | T4 | ☑ 2026-09-20 |

El encadenado va **último** a propósito. En cuanto tocar la meta cambie de escena, probar
cualquier cosa que ocurra *después* de tocar la meta —R1.3, R2.4, R4.3— deja de ser
posible sin desarmarlo. El orden no es por importancia: es por qué se puede observar.

---

## T1 — Meta, estado completado e input congelado

**Requisitos:** R1.1, R1.2, R1.4, R1.6, R3.2

**Termina cuando:** corro el nivel de prueba, camino hasta la meta y el panel Output
anuncia el nivel completado una sola vez. A partir de ahí ninguna tecla responde: no
camino, no salto, no coloco ni borro copias. El jugador sigue sujeto a la gravedad, así
que si toqué la meta en el aire, cae.

**Verificación:**
- R1.1 — tocar la meta con el cuerpo: el Output lo anuncia.
- R1.2 — después de completar, probar las seis teclas una por una: ninguna hace nada.
- R1.4 — completar el nivel con las tres copias sin usar: se completa igual.
- R1.6 — colocar una copia que toque la meta **sin** que el jugador la toque: no pasa nada.
- R3.2 — al arrancar el nivel, el input responde normalmente: el nivel no nace completado.

---

## T2 — Punto de inicio y reinicio manual

**Requisitos:** R2.1, R2.2, R2.3, R2.5, R3.1

Incluye el cambio de D5: `LevelRules` pasa a ser dueño del `LevelData` y se lo entrega a
`CopySystem`, que deja de exportarlo por su cuenta.

**Termina cuando:** hay un marcador de inicio en la escena, el jugador arranca ahí sin
importar dónde lo dejé en el editor, y al accionar el reinicio vuelve a ese punto con
todas sus copias disponibles y sin arrastrar la velocidad que traía.

**Verificación:**
- R3.1 — mover el nodo del jugador a otra parte en el editor, correr: arranca en el
  marcador igual.
- R2.5 — accionar el reinicio: el jugador vuelve al marcador.
- R2.1 + R2.3 — reiniciar en pleno salto: aparece en el marcador quieto, no cayendo.
- R2.2 — colocar las tres copias, reiniciar: las tres desaparecen y el contador vuelve a
  `3/3`.
- D5 — el `CopySystem` ya no tiene casilla de `LevelData` en el Inspector y el límite de
  copias sigue saliendo del `.tres`: cambiarlo a 6 sigue dando seis copias.

---

## T3 — Zonas de muerte

**Requisitos:** R4.1, R4.2, R4.4

**Termina cuando:** hay una zona de muerte bajo el nivel, caer en ella reinicia igual que
el reinicio manual de T2, y las copias que caen ahí no disparan nada.

**Verificación:**
- R4.1 — caminar hasta el borde y caer: el nivel se reinicia solo.
- R4.2 — colocar una copia en el aire sobre la zona y dejar que la copia quede dentro:
  no reinicia. Solo el cuerpo del jugador muere.
- R4.4 — agregar una **segunda** zona de muerte y comprobar que las dos funcionan; después
  borrar las dos y comprobar que el nivel corre sin ninguna y el jugador cae para siempre
  sin errores.

---

## T4 — Casos borde: reentrada y prioridades

**Requisitos:** R1.3, R2.4, R4.3

**Termina cuando:** completar el nivel es un estado estable — no se puede volver a
completar, la muerte deja de existir, y el reinicio sigue siendo la única salida.

**Verificación:**
- R1.3 — completar el nivel quedando dentro de la meta, y confirmar que el Output lo
  anuncia **una sola vez**, no en cada frame de contacto.
- R4.3 — poner la meta justo encima de una zona de muerte, de forma que al tocarla el
  jugador caiga dentro de la zona: tiene que ganar, no reiniciar.
- R2.4 — después de completar el nivel, accionar el reinicio: funciona y el nivel vuelve
  a estar jugable desde el inicio.

---

## T5 — Encadenar al siguiente nivel

**Requisitos:** R1.5

**Termina cuando:** el `.tres` de un nivel declara cuál es el siguiente, y tocar la meta
me deja jugando en ese otro nivel.

**Verificación:**
- R1.5 — crear un segundo nivel de prueba distinguible del primero, declararlo como
  siguiente, tocar la meta: aparece el segundo nivel y se puede jugar.
- Completar el segundo nivel, que **no** declara siguiente: tiene que fallar de forma
  visible en desarrollo, no quedarse en silencio. Es la pregunta abierta de la spec y se
  resuelve recién con B10.
- D4 — confirmar que el cambio de escena no produce errores en el Output. Si aparecen
  mensajes sobre nodos liberados, el diferido no está haciendo su trabajo.

---

## Verificación de trazabilidad

**Todo criterio de la spec tiene tarea:**

| Criterio | Tarea | | Criterio | Tarea |
|---|---|---|---|---|
| R1.1 | T1 | | R2.4 | T4 |
| R1.2 | T1 | | R2.5 | T2 |
| R1.3 | T4 | | R3.1 | T2 |
| R1.4 | T1 | | R3.2 | T1 |
| R1.5 | T5 | | R4.1 | T3 |
| R1.6 | T1 | | R4.2 | T3 |
| R2.1 | T2 | | R4.3 | T4 |
| R2.2 | T2 | | R4.4 | T3 |
| R2.3 | T2 | | | |

17 de 17 criterios cubiertos. Ninguno queda sin tarea.

**Toda tarea cita criterios:** las cinco citan al menos uno. No hay alcance colado.

**Lo único que no cierra**, y ya estaba declarado: el último nivel sin siguiente. T5 lo
verifica como *falla visible*, que es lo más honesto que se puede hacer sin B10. No es un
criterio sin cubrir: es un criterio que la spec decidió no escribir todavía.
