# 001 — Reglas de nivel

**Estado:** borrador
**Ítem del backlog:** B3 — `LevelRules`: meta alcanzada → nivel completado; reinicio manual
**Última actualización:** 2026-09-17

## Problema

Hoy el jugador puede moverse, saltar y apilar copias, pero no hay nada que ganar ni forma
de volver a intentarlo. Un nivel no termina nunca y un error de colocación obliga a cerrar
el juego. Sin una condición de victoria, ninguna disposición de plataformas es un puzzle:
es un espacio donde deambular.

## Alcance

- Cada nivel tiene una meta que el jugador puede alcanzar.
- Tocar la meta da el nivel por completado.
- El jugador puede reiniciar el nivel en cualquier momento y volver al estado inicial.
- Un nivel arranca siempre en el mismo estado, sin importar cómo terminó el intento anterior.

## Fuera de alcance

| Qué | Por qué queda afuera |
|---|---|
| Pasar al siguiente nivel al completar uno | Otra spec: el encadenado de niveles es B7 |
| Pantalla o cartel de victoria | Otra spec: la interfaz es B6 y B10 |
| Guardar qué niveles se completaron | Otra spec: B13 |
| Tiempo de nivel, par times, medallas | Ahora no: B20, después del release |
| Muerte por caída, pinchos o cualquier peligro | Ahora no. **El backlog P1–P3 no tiene sistema de muerte**, y decidir uno acá sería alcance colado. Ver preguntas abiertas |
| Más de una meta por nivel, o metas que se desbloquean | Nunca, salvo que un nivel lo pida. Una meta por nivel es la regla |

## Requisitos

### R1 — Completar el nivel

- **R1.1** — CUANDO el jugador entra en contacto con la meta, el sistema de reglas de
  nivel DEBE dar el nivel por completado.
- **R1.2** — MIENTRAS el nivel está dado por completado, el sistema de reglas de nivel
  DEBE ignorar el input de movimiento, salto, colocación y borrado de copias.
- **R1.3** — SI el jugador vuelve a tocar la meta con el nivel ya dado por completado,
  ENTONCES el sistema de reglas de nivel DEBE ignorar el contacto.
- **R1.4** — El sistema de reglas de nivel DEBE dar el nivel por completado sin importar
  cuántas copias hayan quedado sin usar.

### R2 — Reinicio manual

- **R2.1** — CUANDO el jugador acciona el reinicio, el sistema de reglas de nivel DEBE
  situar al jugador en la posición de inicio del nivel.
- **R2.2** — CUANDO el jugador acciona el reinicio, el sistema de reglas de nivel DEBE
  retirar todas las copias colocadas y devolver el total disponible al valor del nivel.
- **R2.3** — CUANDO el jugador acciona el reinicio, el sistema de reglas de nivel DEBE
  anular la velocidad del jugador.
- **R2.4** — MIENTRAS el nivel está dado por completado, el sistema de reglas de nivel
  DEBE seguir aceptando el reinicio.

### R3 — Estado inicial de un nivel

- **R3.1** — CUANDO un nivel comienza, el sistema de reglas de nivel DEBE situar al
  jugador en la posición de inicio declarada por ese nivel.
- **R3.2** — CUANDO un nivel comienza, el sistema de reglas de nivel DEBE dar el nivel
  por no completado.

## Casos borde

- **El jugador toca la meta en el mismo instante en que coloca una copia.** Cubierto por
  R1.2: una vez completado, la colocación se ignora. Si la colocación se resolvió primero,
  el nivel se completa igual y la copia gastada no importa — R1.4.
- **El jugador reinicia en pleno salto.** Cubierto por R2.1 y R2.3: vuelve al inicio y sin
  velocidad heredada, no cayendo desde donde estaba.
- **El jugador reinicia sin haberse movido ni colocado nada.** No hay efecto observable.
  Válido, no es un error.
- **El jugador completa el nivel sin usar ninguna copia.** Válido — R1.4. Es un nivel mal
  diseñado, no un bug del sistema.
- **El jugador cae fuera de los límites del nivel.** ⚠️ **Sin requisito.** Hoy caería
  indefinidamente. Ver preguntas abiertas.
- **El nivel no declara posición de inicio.** Es un error de autoría del nivel, no un
  estado de juego. Debe fallar de forma visible en desarrollo, no elegir un valor por
  defecto que oculte el problema.

## Requisitos de performance

Ninguno. El sistema reacciona a dos eventos discretos —tocar la meta y accionar el
reinicio— y no escala con la cantidad de entidades. Poner un número acá sería inventar
un requisito para tener uno.

## Estado actual del código

Parte de lo que este sistema necesita ya existe, y la spec describe el destino, no el
punto de partida:

- El total de copias por nivel ya sale de un recurso de datos del nivel (hecho en B2),
  así que R2.2 tiene de dónde leer el valor a restituir.
- Retirar todas las copias colocadas ya existe como capacidad (B2, acción `clear_copies`).
  R2.2 la reutiliza; no la redefine.

## Preguntas abiertas

- ❓ **¿Qué percibe el jugador al completar un nivel?** Hoy no hay interfaz (B6, B10) ni
  encadenado de niveles (B7), así que no hay respuesta honesta todavía. La spec fija
  *que* el nivel se da por completado y que el input se congela; **qué se ve** es un
  requisito que se agrega cuando exista alguno de esos dos sistemas.
- ❓ **¿Caer fuera del nivel debe reiniciar solo?** No hay sistema de muerte en el backlog
  P1–P3. Si la respuesta es sí, es un requisito nuevo en esta spec; si es "el nivel se
  diseña cerrado para que no se pueda caer", es una regla de diseño de niveles y va al GDD.
  Las dos son defendibles y la decisión no es técnica.
- ❓ **¿La meta se activa al tocarla con cualquier parte del cuerpo, o hay que apoyarse
  encima?** Cambia qué niveles son construibles: una meta que se activa por contacto puede
  ir en una pared; una que exige pisarla, no.
- ❓ **¿El reinicio y el "borrar todas las copias" son la misma acción?** Hoy `C` borra
  todas las copias sin mover al jugador. El reinicio hace eso y además lo devuelve al
  inicio. Dos acciones que se parecen mucho pueden confundir; una sola puede quitar
  control fino. No se decide en el papel.
