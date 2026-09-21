# 002 — HUD de nivel

**Estado:** borrador
**Ítem del backlog:** B6 — HUD: copias restantes
**Última actualización:** 2026-09-21

## Problema

El límite de copias es la restricción principal del puzzle: con dos no se llega y con
tres sí. Pero hoy ese número no existe para el jugador. Vive en el panel Output del
editor, que es información para quien desarrolla el juego, no para quien lo juega. Un
jugador que quiere saber cuántas copias le quedan tiene que contar de memoria las que
colocó, y lo tiene que hacer mientras resuelve el puzzle — o sea que el juego le cobra
atención por un dato que él mismo generó.

Lo mismo al ganar: completar un nivel no se anuncia. El jugador deduce que ganó porque
los controles dejan de responderle, que es la forma más parecida a un cuelgue que tiene
un juego de avisar algo bueno.

## Alcance

- El jugador ve, en todo momento, cuántas copias le quedan por colocar.
- Ese número refleja cualquier cosa que lo cambie: colocar, deshacer, borrar todo,
  reiniciar el nivel, empezar un nivel.
- Al completar un nivel, el jugador ve un aviso de que lo completó.
- Lo que se muestra queda fijo en la pantalla, no en el mundo del nivel.

## Fuera de alcance

| Qué | Por qué queda afuera |
|---|---|
| Mostrar el total de copias del nivel ("3 / 5") | Decisión del 2026-09-21: se muestra solo el restante, que es el único dato accionable en el momento. El total se infiere reiniciando |
| Controles en pantalla (qué tecla hace qué) | Ahora no. Es un problema real —hoy nadie puede jugar sin que le expliquen— pero es enseñanza, no HUD: va con B10 o con un primer nivel que enseñe |
| Menú de pausa, botones, navegación | Otra spec: B10 |
| Animaciones, transiciones o efectos del aviso | Ahora no: es pulido, B17 |
| Tiempo de nivel, par times, medallas | Ahora no: B20 |
| Feedback de colocación inválida | Otra spec: B12. Y va en el mundo, donde el jugador está mirando, no en un rincón de la pantalla |
| Barra de vida, vidas, energía | El juego no tiene ninguno de esos conceptos |
| Qué pasa al completar el último nivel | Sigue siendo la pregunta abierta de la spec 001. Esta spec no la responde |

## Requisitos

### R1 — Contador de copias

- **R1.1** — MIENTRAS un nivel está en juego, el sistema de HUD DEBE mostrar cuántas
  copias le quedan al jugador por colocar.
- **R1.2** — CUANDO la cantidad de copias disponibles cambia, el sistema de HUD DEBE
  actualizar el valor mostrado sin que el jugador tenga que hacer ninguna otra cosa.
- **R1.3** — CUANDO un nivel comienza, el sistema de HUD DEBE mostrar la cantidad total de
  copias que ese nivel otorga.
- **R1.4** — CUANDO el nivel se reinicia, el sistema de HUD DEBE volver a mostrar la
  cantidad total de copias que el nivel otorga.
- **R1.5** — MIENTRAS al jugador no le quedan copias, el sistema de HUD DEBE mostrar cero,
  y no ocultar el contador ni sustituirlo por otra cosa.

### R2 — Aviso de nivel completado

- **R2.1** — CUANDO el nivel se da por completado, el sistema de HUD DEBE mostrar un aviso
  de que el nivel fue completado.
- **R2.2** — MIENTRAS el nivel no está dado por completado, el sistema de HUD DEBE mantener
  ese aviso oculto.
- **R2.3** — CUANDO un nivel comienza, el sistema de HUD DEBE mantener ese aviso oculto.
- **R2.4** — CUANDO el nivel se reinicia, el sistema de HUD DEBE ocultar ese aviso.

### R3 — Ubicación en pantalla

- **R3.1** — El sistema de HUD DEBE mantener lo que muestra en una posición fija de la
  pantalla, independiente de dónde esté el jugador y de cómo se desplace la vista del
  nivel.
- **R3.2** — CUANDO la ventana cambia de tamaño o de proporción, el sistema de HUD DEBE
  seguir mostrando íntegro todo lo que muestra.

## Casos borde

- **Un nivel que otorga cero copias.** El contador muestra cero desde el primer instante.
  Válido: el nivel declara ese límite y R1.5 lo cubre.
- **El jugador completa el nivel con copias sin usar.** El contador queda en el valor que
  tenía y el aviso aparece igual. Las dos cosas conviven; el aviso no reemplaza al
  contador.
- **El jugador reinicia con el aviso en pantalla.** Cubierto por R2.4: el aviso se va y el
  contador vuelve al total.
- **El jugador coloca y deshace la misma copia en rápida sucesión.** El contador termina en
  el valor correcto. No hay estado que se acumule: cada cambio informa el valor completo,
  no un incremento.
- **El nivel se completa y el siguiente entra en juego de inmediato.** El aviso se muestra
  durante un instante imperceptible. No es un fallo de este sistema — ver Preguntas
  abiertas.

## Requisitos de performance

Ninguno como criterio de aceptación. Lo que el HUD muestra cambia por eventos discretos
—colocar, deshacer, borrar, reiniciar, completar— y no escala con nada. Fijar un número de
milisegundos acá sería inventar un requisito para tener uno.

Lo que sí hay es una restricción de implementación, y va al plan: nada de esto se
recalcula por fotograma.

## Estado actual del código

La spec describe el destino; esto es lo que ya existe y estos requisitos reutilizan:

- El sistema de copias ya avisa cada vez que la cantidad disponible cambia, y ya lo avisa
  al colocar, al deshacer, al borrar todo y al arrancar el nivel (B2). R1.2, R1.3 y R1.4
  se apoyan en ese aviso; no lo redefinen.
- El sistema de reglas de nivel ya avisa que el nivel se completó (B3). Ese aviso **hoy no
  tiene ningún destinatario**: R2.1 es su primer consumidor.
- El reinicio de nivel ya existe y ya devuelve el total de copias (B3, R2.2 de la 001).
  R1.4 observa el resultado de eso.

## Preguntas abiertas

- ❓ **¿El aviso de nivel completado se alcanza a ver?** Hoy completar un nivel pone en
  juego el siguiente de inmediato (R1.5 de la spec 001), así que el aviso de R2.1 aparece
  y desaparece en el mismo suspiro. Solo sería visible al final de la cadena, donde no hay
  nivel siguiente — que es justo el caso que la spec 001 dejó sin resolver. Tres salidas
  posibles, y hay que elegir una antes de implementar R2:
  1. Se acepta: el aviso existe para el final de la cadena y para cuando haya menú (B10).
  2. Se demora el cambio de nivel para que el aviso se lea. Eso modifica la spec 001 y
     suena a B7 (transiciones), no a HUD.
  3. Se saca R2 de esta spec y el aviso se diseña junto con las transiciones.

## Notas para el plan

Material que se sacó de los requisitos por ser implementación, y que `/plan` tiene que
levantar:

- **El HUD no calcula ni conserva el estado que muestra: lo recibe.** Se escribió primero
  como requisito (`R3.1 — el sistema DEBE obtener toda la información del estado del
  juego, sin calcularla por su cuenta`) y se sacó al aplicarle el test del método: ese
  criterio se rompe al cambiar de patrón sin que el jugador perciba ninguna diferencia.
  Eso lo vuelve arquitectura, no comportamiento. Es la regla de capas del GDD y pertenece
  al plan.
- Nada de lo que muestra el HUD se recalcula por fotograma.
- Dónde vive el HUD —dentro de cada nivel o una sola vez para todo el juego— es decisión
  de plan. Afecta a B7 y a B10, así que si la decisión obliga a otras features a
  respetarla, va también a `DECISIONES.md`.
