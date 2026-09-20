# 001 — Reglas de nivel

**Estado:** aprobada
**Ítem del backlog:** B3 — `LevelRules`: meta alcanzada → nivel completado; reinicio
**Última actualización:** 2026-09-17

## Problema

Hoy el jugador puede moverse, saltar y apilar copias, pero no hay nada que ganar, nada
que perder, ni forma de volver a intentarlo. Un nivel no termina nunca y un error de
colocación obliga a cerrar el juego. Sin una condición de victoria, ninguna disposición
de plataformas es un puzzle: es un espacio donde deambular.

## Alcance

- Cada nivel tiene una meta que el jugador puede alcanzar.
- Tocar la meta da el nivel por completado y cede el paso al siguiente nivel.
- Cada nivel puede tener zonas donde el jugador muere; morir reinicia el nivel.
- El jugador puede reiniciar el nivel manualmente en cualquier momento.
- Un nivel arranca siempre en el mismo estado, sin importar cómo terminó el intento
  anterior.

## Fuera de alcance

| Qué | Por qué queda afuera |
|---|---|
| Pantalla o cartel de victoria | Otra spec: la interfaz es B6 y B10 |
| Guardar qué niveles se completaron | Otra spec: B13 |
| Tiempo de nivel, par times, medallas | Ahora no: B20, después del release |
| Peligros que maten: pinchos, enemigos, límite de tiempo | Otra spec, si alguna vez existen. Acá **morir es exactamente entrar en una zona de muerte**, y nada más |
| Menú al que volver desde un nivel | Otra spec: B10 |
| Más de una meta por nivel, o metas que se desbloquean | Nunca, salvo que un nivel lo pida. Una meta por nivel es la regla |
| Transiciones animadas entre niveles | Ahora no: es pulido, B17 |

## Requisitos

### R1 — Completar el nivel

- **R1.1** — CUANDO el cuerpo del jugador entra en contacto con la meta, el sistema de
  reglas de nivel DEBE dar el nivel por completado.
- **R1.2** — MIENTRAS el nivel está dado por completado, el sistema de reglas de nivel
  DEBE ignorar el input de movimiento, salto, colocación y borrado de copias.
- **R1.3** — SI el jugador vuelve a tocar la meta con el nivel ya dado por completado,
  ENTONCES el sistema de reglas de nivel DEBE ignorar el contacto.
- **R1.4** — El sistema de reglas de nivel DEBE dar el nivel por completado sin importar
  cuántas copias hayan quedado sin usar.
- **R1.5** — CUANDO el nivel queda dado por completado, el sistema de reglas de nivel
  DEBE poner en juego el nivel siguiente declarado por el nivel actual.
- **R1.6** — SI una copia entra en contacto con la meta, ENTONCES el sistema de reglas de
  nivel DEBE ignorar el contacto. Solo el cuerpo del jugador completa un nivel.
  > **Cómo se verifica** (agregado el 2026-09-18, tras `/conforme`): por inspección de
  > código, no jugando. Copia y jugador miden lo mismo y el jugador siempre queda parado
  > sobre la copia, así que no existe una posición donde la copia toque la meta y el
  > jugador no. El criterio sigue siendo correcto; lo que estaba mal era darlo por
  > comprobable con los medios actuales. Cuando exista suite de tests, pasa a un test con
  > este ID.

### R2 — Reinicio del nivel

- **R2.1** — CUANDO el nivel se reinicia, el sistema de reglas de nivel DEBE situar al
  jugador en la posición de inicio del nivel.
- **R2.2** — CUANDO el nivel se reinicia, el sistema de reglas de nivel DEBE retirar todas
  las copias colocadas y devolver el total disponible al valor del nivel.
- **R2.3** — CUANDO el nivel se reinicia, el sistema de reglas de nivel DEBE anular la
  velocidad del jugador.
- **R2.4** — MIENTRAS el nivel está dado por completado, el sistema de reglas de nivel
  DEBE seguir aceptando el reinicio manual.
- **R2.5** — CUANDO el jugador acciona el reinicio manual, el sistema de reglas de nivel
  DEBE reiniciar el nivel.

### R3 — Estado inicial de un nivel

- **R3.1** — CUANDO un nivel comienza, el sistema de reglas de nivel DEBE situar al
  jugador en el punto de inicio que ese nivel declara explícitamente, independiente de
  dónde haya quedado el jugador al construir la escena.
- **R3.2** — CUANDO un nivel comienza, el sistema de reglas de nivel DEBE dar el nivel
  por no completado.

### R4 — Muerte y caída

- **R4.1** — CUANDO el cuerpo del jugador entra en una zona de muerte, el sistema de
  reglas de nivel DEBE reiniciar el nivel.
- **R4.2** — SI una copia entra en una zona de muerte, ENTONCES el sistema de reglas de
  nivel DEBE ignorar el contacto.
- **R4.3** — MIENTRAS el nivel está dado por completado, el sistema de reglas de nivel
  DEBE ignorar las zonas de muerte.
- **R4.4** — El sistema de reglas de nivel DEBE admitir cualquier cantidad de zonas de
  muerte por nivel, incluida ninguna.

## Casos borde

- **El jugador toca la meta y entra en una zona de muerte en el mismo instante.** Gana:
  R4.3 desactiva las zonas de muerte en cuanto el nivel está completado.
- **El jugador toca la meta en el mismo instante en que coloca una copia.** Cubierto por
  R1.2 y R1.4: el nivel se completa y la copia gastada no cambia nada.
- **El jugador reinicia en pleno salto.** Cubierto por R2.1 y R2.3: vuelve al inicio sin
  velocidad heredada, no cayendo desde donde estaba.
- **El jugador reinicia sin haberse movido ni colocado nada.** Sin efecto observable.
  Válido, no es un error.
- **El jugador completa el nivel sin usar ninguna copia.** Válido — R1.4. Es un nivel mal
  diseñado, no un fallo del sistema.
- **Un nivel sin zonas de muerte.** Válido — R4.4. El jugador no puede morir ahí.
- **El punto de inicio de un nivel cae dentro de una zona de muerte.** Produciría un
  reinicio en bucle. Es un error de autoría del nivel, no un estado de juego: debe fallar
  de forma visible en desarrollo, no resolverse silenciosamente.
- **Un nivel no declara punto de inicio, o no declara nivel siguiente.** Mismo criterio:
  error de autoría, falla visible, nunca un valor por defecto que esconda el problema.

## Requisitos de performance

Ninguno. El sistema reacciona a eventos discretos —tocar la meta, entrar en una zona de
muerte, accionar el reinicio— y no escala con la cantidad de entidades. Poner un número
acá sería inventar un requisito para tener uno.

## Estado actual del código

La spec describe el destino; esto es lo que ya existe y que estos requisitos reutilizan:

- El total de copias que otorga un nivel ya se define como dato del nivel (B2). R2.2 lee
  ese valor para restituirlo; no lo redefine.
- La capacidad de retirar todas las copias colocadas ya existe (B2). R2.2 la reutiliza.

## Preguntas abiertas

- ❓ **¿Qué ocurre al completar el último nivel?** R1.5 exige poner en juego el nivel
  siguiente, y el último no tiene. La respuesta natural es volver a un menú, pero el menú
  es B10 y todavía no existe. Se decide cuando exista; hasta entonces es la única parte
  de esta spec sin cubrir, y debe fallar de forma visible en vez de simular que funciona.

## Notas para el plan

Material que se sacó de los requisitos por ser implementación, y que `/plan` tiene que
levantar en *Reutilización de lo existente*: la acción de input que hoy borra todas las
copias, y el hecho de que el límite por nivel vive en un recurso de datos.
