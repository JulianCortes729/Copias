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

Hay un segundo problema en la misma zona, y esta spec **no** lo resuelve: completar un
nivel tampoco se anuncia. Queda planteado acá porque es real y porque su solución no
cabe en este sistema — ver *Fuera de alcance*.

## Alcance

- El jugador ve, en todo momento, cuántas copias le quedan por colocar.
- Ese número refleja cualquier cosa que lo cambie: colocar, deshacer, borrar todo,
  reiniciar el nivel, empezar un nivel.
- Lo que se muestra queda fijo en la pantalla, no en el mundo del nivel.
- Un nivel mal armado se nota durante el desarrollo, no cuando lo juega alguien.

## Fuera de alcance

| Qué | Por qué queda afuera |
|---|---|
| **Aviso de nivel completado** | **Retirado de esta spec el 2026-09-21, tras `/clarifica`.** El aviso solo se puede ver si algo demora el cambio de nivel, y esa demora es una transición: B7. Especificarlo acá era escribir un requisito cuya única forma de verificarse es un caso que la spec 001 declara sin resolver. Ver el grupo R2, retirado pero conservado |
| Mostrar el total de copias del nivel ("3 / 5") | Decisión del 2026-09-21: se muestra solo el restante, que es el único dato accionable en el momento. El total se infiere reiniciando |
| Controles en pantalla (qué tecla hace qué) | Ahora no. Es un problema real —hoy nadie puede jugar sin que le expliquen— pero es enseñanza, no HUD: va con B10 o con un primer nivel que enseñe |
| Menú de pausa, botones, navegación | Otra spec: B10 |
| Animaciones, transiciones o efectos | Ahora no: es pulido, B17 |
| Tiempo de nivel, par times, medallas | Ahora no: B20 |
| Feedback de colocación inválida | Otra spec: B12. Y va en el mundo, donde el jugador está mirando, no en un rincón de la pantalla |
| Barra de vida, vidas, energía | El juego no tiene ninguno de esos conceptos |
| Ventanas más chicas que 1152 × 648 | Es el tamaño que el proyecto declara como diseño. Por debajo de eso no se garantiza nada, y R3.2 lo dice explícitamente |
| Qué pasa al completar el último nivel | Sigue siendo la pregunta abierta de la spec 001. Esta spec no la responde |

## Requisitos

### R1 — Contador de copias

- **R1.1** — MIENTRAS la escena de un nivel está cargada, el sistema de HUD DEBE mostrar
  cuántas copias le quedan al jugador por colocar, incluso con el nivel ya dado por
  completado.
  > **Por qué cambió** (2026-09-21, tras `/clarifica`): decía "MIENTRAS un nivel está en
  > juego", que se leía de dos maneras — con el nivel completado el contador podía seguir
  > visible o desaparecer, y las dos lecturas daban código distinto. Los *Casos borde* ya
  > asumían una de las dos sin que ningún requisito la fijara.
- **R1.2** — CUANDO la cantidad de copias disponibles cambia, el sistema de HUD DEBE
  actualizar el valor mostrado sin que el jugador tenga que hacer ninguna otra cosa.
- **R1.3** — CUANDO un nivel comienza, el sistema de HUD DEBE mostrar la cantidad total de
  copias que ese nivel otorga.
- **R1.4** — CUANDO el nivel se reinicia, el sistema de HUD DEBE volver a mostrar la
  cantidad total de copias que el nivel otorga.
- **R1.5** — MIENTRAS al jugador no le quedan copias, el sistema de HUD DEBE mostrar cero,
  y no ocultar el contador ni sustituirlo por otra cosa.

### R2 — Aviso de nivel completado *(retirado)*

> **Retirado el 2026-09-21, tras `/clarifica`.** No se borra: los IDs quedan quemados y el
> hueco es información. El grupo se movió a *Fuera de alcance* porque el aviso es
> inverificable mientras completar un nivel cambie de escena en el acto.
>
> **Decisión de diseño ya tomada, para quien escriba esa spec:** el aviso se queda en
> pantalla hasta que el nivel cambie o se reinicie. No se oculta solo tras un
> temporizador — un temporizador es estado que hay que cancelar al reiniciar, y no compra
> nada mientras no exista un menú del que salir.

### R3 — Ubicación en pantalla

- **R3.1** — El sistema de HUD DEBE mantener lo que muestra en una posición fija de la
  pantalla, independiente de dónde esté el jugador y de cómo se desplace la vista del
  nivel.
- **R3.2** — MIENTRAS la ventana mide 1152 × 648 píxeles o más en ambos lados, CUANDO la
  ventana cambia de tamaño o de proporción, el sistema de HUD DEBE seguir mostrando
  íntegro todo lo que muestra.
  > **Por qué cambió** (2026-09-21, tras `/clarifica`): no tenía cota. Tal como estaba
  > exigía funcionar en una ventana de 120 × 80 px, que es imposible y que nadie pretendía.

### R4 — Nivel mal armado

- **R4.1** — SI un nivel se pone en juego con un HUD que no quedó conectado al estado que
  debe mostrar, ENTONCES el sistema de HUD DEBE fallar de forma visible durante el
  desarrollo, en vez de mostrar un valor por defecto que disimule el problema.

## Casos borde

- **Un nivel que otorga cero copias.** El contador muestra cero desde el primer instante.
  Válido: el nivel declara ese límite y R1.5 lo cubre.
- **El jugador completa el nivel con copias sin usar.** El contador sigue visible y con el
  valor que tenía — R1.1. Ver cuántas sobraron en el momento de ganar es la información
  más interesante del nivel, y es la base de lo que B20 va a medir.
- **El jugador coloca y deshace la misma copia en rápida sucesión.** El contador termina en
  el valor correcto.
- **El jugador agranda la ventana a una proporción muy ancha.** Cubierto por R3.2: todo
  sigue visible. Por debajo del tamaño de diseño no se garantiza nada, y está declarado
  fuera de alcance.

## Requisitos de performance

Ninguno como criterio de aceptación. Lo que el HUD muestra cambia por eventos discretos
—colocar, deshacer, borrar, reiniciar— y no escala con nada. Fijar un número de
milisegundos acá sería inventar un requisito para tener uno.

Lo que sí hay es una restricción de implementación, y va al plan: nada de esto se
recalcula por fotograma.

## Estado actual del código

La spec describe el destino; esto es lo que ya existe y estos requisitos reutilizan:

- El sistema de copias ya avisa cada vez que la cantidad disponible cambia, y ya lo avisa
  al colocar, al deshacer, al borrar todo y al arrancar el nivel (B2). R1.2, R1.3 y R1.4
  se apoyan en ese aviso; no lo redefinen.
- El reinicio de nivel ya existe y ya devuelve el total de copias (B3, R2.2 de la 001).
  R1.4 observa el resultado de eso.
- El sistema de reglas de nivel ya avisa que el nivel se completó (B3). Ese aviso sigue
  **sin ningún destinatario** — el retiro del grupo R2 lo deja donde estaba, y es deuda
  declarada que resuelve B7.

## Preguntas abiertas

- ❓ **Un nivel armado sin HUD en absoluto: ¿quién se da cuenta?** R4.1 cubre el HUD que
  está presente pero mal conectado, porque eso el propio HUD lo puede detectar. La
  ausencia total no: un sistema que no existe no puede quejarse de no existir. Si se
  quiere cubrir, el requisito le corresponde a otro sistema —el que ya verifica que un
  nivel esté bien armado, spec 001— y sería una modificación de esa spec, no de esta.

## Notas para el plan

Material que se sacó de los requisitos por ser implementación, y que `/plan` tiene que
levantar:

- **El HUD no calcula ni conserva el estado que muestra: lo recibe.** Se escribió primero
  como requisito (`R3.1 — el sistema DEBE obtener toda la información del estado del
  juego, sin calcularla por su cuenta`) y se sacó al aplicarle el test del método: ese
  criterio se rompe al cambiar de patrón sin que el jugador perciba ninguna diferencia.
  Eso lo vuelve arquitectura, no comportamiento. Es la regla de capas del GDD.
- **Cada aviso de cambio informa el valor completo, no un incremento**, así que el HUD no
  acumula estado propio y no puede desincronizarse. Estaba escrito dentro de un caso
  borde, que es implementación escondida donde nadie la busca.
- Nada de lo que muestra el HUD se recalcula por fotograma.
- Dónde vive el HUD —dentro de cada nivel o una sola vez para todo el juego— es decisión
  de plan. Afecta a B7 y a B10, así que si la decisión obliga a otras features a
  respetarla, va también a `DECISIONES.md`.
