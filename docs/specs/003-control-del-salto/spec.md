# 003 — Control del salto

**Estado:** borrador
**Ítem del backlog:** B8 — Game feel: coyote time, input buffering, jump cut
**Última actualización:** 2026-09-23

> **Esta spec se completa en dos tiempos, a propósito.** El comportamiento se decide
> ahora; los tres valores de feel (ventana de gracia, ventana de anticipación, salto
> mínimo) se encuentran jugando un prototipo y recién ahí se escriben acá. Hasta
> entonces los requisitos que los usan los nombran y remiten a *Preguntas abiertas*.
> Inventarlos ahora sería defender un número por haberlo escrito.

## Problema

Hoy el salto castiga al jugador por errores que no percibe como suyos. Si aprieta salto
un instante después de salir de un borde, no salta y cae al pozo. Si lo aprieta un
instante antes de tocar el piso, la pulsación se pierde. Y el salto mide siempre lo
mismo: no hay forma de dar un salto corto para apoyarse en un escalón bajo sin pasarse.
En un juego de puzzles eso es peor que en uno de acción: el jugador sabía la solución y
la perdió por un problema de ejecución.

Además, B5 dejó una decisión sin tomar: tomar carrera antes de saltar no cambia nada,
así que ningún obstáculo puede pedirla. Se decidió dejarlo así — ver R5.

## Alcance

- Saltar sigue siendo posible durante un instante después de salir caminando de un borde.
- Una pulsación de salto hecha un instante antes de tocar el piso no se pierde: se salta
  al tocarlo.
- La altura del salto depende de cuánto tiempo se mantiene apretado el botón.
- Tomar carrera no cambia hasta dónde llega un salto. Decidido el 2026-09-23.
- Saltar y colocar una copia a la vez hace las dos cosas.
- Nada de lo anterior rompe el nivel 1: sigue pidiendo exactamente 3 copias.

## Fuera de alcance

| Qué | Por qué queda afuera |
|---|---|
| Cambiar la altura máxima del salto, la gravedad o la velocidad de carrera | Ahora no. El nivel 1 y la aritmética de copias del GDD (32 / ~115 px por copia) salen de esos números medidos en B5. Cambiarlos es rehacer esa medición y ese nivel, y B8 existe justamente para congelar el salto antes de B11 |
| Caída más rápida que la subida, flotación en el punto más alto | Ahora no. Si el prototipo muestra que hacen falta, entran como **ítem nuevo del backlog**, con su propia spec y su propia medición — nunca como ampliación de esta |
| Que la ventana de gracia amplíe el alcance con el que se diseñan los niveles | Nunca. Decidido el 2026-09-23: los niveles se diseñan con el alcance medido **sin** gracia (R5.1). La gracia es margen de error del jugador, no una distancia que un nivel pueda exigir: un pozo que solo se cruza usándola castiga justo al jugador que no sabe que existe |
| Anticipación para colocar, deshacer o borrar copias | Nunca, mientras la colocación siga funcionando en cualquier estado. Anticipar una acción solo tiene sentido si la acción espera a un estado que todavía no llegó; colocar no espera nada, y una colocación bloqueada que se dispara sola medio segundo después sería una sorpresa, no una ayuda |
| Doble salto, salto en pared | Nunca. Rompe la regla del GDD de que la altura alcanzable es aritmética de copias |
| Animación, partículas o sonido del salto | Otra spec: presentación (B14, B17). Esta spec es solo simulación |
| Joystick, remapeo de controles | Otra spec: B21 |

## Requisitos

### R1 — Ventana de gracia al dejar el piso

- **R1.1** — CUANDO el jugador presiona salto dentro de la ventana de gracia (❓ P2),
  límite incluido, posterior a haber dejado el piso sin saltar, el sistema de salto DEBE
  ejecutar un salto cuya subida, medida desde el punto donde se presionó, sea igual a la
  de un salto desde el piso.
  > **Por qué cambió** (2026-09-23, tras `/clarifica`): decía "un salto idéntico al que
  > habría dado desde el piso", que se leía de dos maneras — misma subida desde donde se
  > apretó, o mismo punto más alto respecto del borde, compensando lo ya caído. Las dos
  > daban código distinto. Ganó la primera: el salto por gracia llega unos píxeles más
  > bajo que uno desde el borde, lo que cayó durante la ventana.
- **R1.2** — SI el jugador dejó el piso saltando, ENTONCES el sistema de salto DEBE
  negarle la ventana de gracia de ese vuelo.

### R2 — Anticipación del salto

- **R2.1** — CUANDO el jugador toca el piso habiendo presionado salto en el aire dentro de
  la ventana de anticipación (❓ P2) previa, límite incluido, el sistema de salto DEBE
  ejecutar el salto en el mismo tick en que toca el piso.
  > **Por qué cambió** (2026-09-23, tras `/clarifica`): se agregó "límite incluido". Sin
  > eso, una pulsación exactamente en el borde de la ventana entraba o no según quién
  > escribiera el test.
- **R2.2** — SI la pulsación de salto en el aire es más vieja que la ventana de
  anticipación al tocar el piso, ENTONCES el sistema de salto DEBE descartarla.
- **R2.3** — El sistema de salto DEBE producir como máximo un salto por cada pulsación del
  botón, sin importar por cuántas ventanas haya pasado esa pulsación.

### R3 — Altura según cuánto se mantiene el botón

- **R3.1** — CUANDO el jugador suelta salto a mitad de la subida de un salto, el sistema
  de salto DEBE alcanzar una altura estrictamente mayor que la mínima (R3.2) y
  estrictamente menor que la máxima (R3.4).
  > **Por qué cambió** (2026-09-23, tras `/clarifica`): decía "terminar esa subida más
  > abajo de lo que la habría terminado manteniéndolo", sin cota. Cerca del punto más alto
  > la diferencia es menor a un píxel, y el instrumento redondea a píxeles enteros: una
  > implementación correcta fallaba la prueba. Fijar el momento de soltar en la mitad de
  > la subida la vuelve decidible.
- **R3.2** — CUANDO el jugador mantiene salto durante un solo tick, el sistema de salto
  DEBE alcanzar la altura de salto mínima (❓ P2).
  > **Por qué cambió** (2026-09-23, tras `/clarifica`): decía "presiona y suelta lo más
  > rápido posible". Eso depende de la mano de quien prueba: nadie suelta un botón en un
  > tick, así que dos personas medían mínimos distintos con el mismo código.
- **R3.3** — SI el jugador suelta salto mientras cae, ENTONCES el sistema de salto DEBE
  dejar la caída sin alterar.
- **R3.4** — MIENTRAS el jugador mantiene salto durante toda la subida, el sistema de
  salto DEBE alcanzar la misma altura que medía el salto antes de esta spec, con el mismo
  instrumento y en las mismas condiciones.

### R4 — Lo que no se puede romper

- **R4.1** — CUANDO el jugador presiona salto estando en el piso, el sistema de salto DEBE
  iniciar la subida en ese mismo tick.
  > Hoy ya es así. Se escribe porque la anticipación es la forma clásica de meter un tick
  > de demora sin que nadie lo note a simple vista.
- **R4.2** — El sistema de salto DEBE mantener el punto más alto alcanzable con 2 copias
  en el nivel 1 por debajo de la altura de la meta, medido con el instrumento de B5.
  > **Por qué cambió** (2026-09-23, tras `/clarifica`): decía "mantener en 3 la cantidad
  > mínima de copias". Eso exige demostrar que con 2 **no** se llega, y eso no se prueba
  > jugando: que alguien no llegue no demuestra que nadie pueda. Se partió en dos: el
  > techo medido con 2 copias (este) y la meta alcanzable con 3 (R4.5).
- **R4.3** — CUANDO el nivel se reinicia, el sistema de salto DEBE descartar cualquier
  pulsación anticipada y cualquier ventana de gracia pendiente.
- **R4.4** — MIENTRAS el input de juego está congelado (nivel completado, spec 001 R1.2),
  el sistema de salto DEBE abstenerse de iniciar saltos.
  > **Por qué cambió** (2026-09-23, tras `/clarifica`): decía "ignorar las pulsaciones
  > anticipadas antes del congelamiento". Cubría la anticipación y dejaba abierta la
  > ventana de gracia: un salto por gracia durante el congelamiento no lo prohibía nada.
- **R4.5** — El sistema de salto DEBE permitir alcanzar la meta del nivel 1 con 3 copias.

### R5 — Control en el aire

> Decidido el 2026-09-23 (P1): **el control en el aire sigue siendo total.** Tomar carrera
> no cambia el alcance, y los puzzles siguen siendo de copias, no de ejecución. El
> requisito protege la consecuencia medible de esa decisión, que es además el alcance con
> el que se diseñan los niveles.

- **R5.1** — El sistema de movimiento DEBE mantener el alcance horizontal de un salto
  mantenido desde el piso, sin usar la ventana de gracia, en 139 px partiendo parado y
  147 px partiendo a velocidad máxima, medido con el instrumento de B5 y en las
  condiciones de esa medición.

### R6 — Salto y copias a la vez

- **R6.1** — CUANDO el jugador presiona salto y colocar en el mismo tick estando en el
  piso, y la colocación tiene lugar, el sistema de salto DEBE ejecutar el salto desde
  encima de la copia recién colocada.
  > Agregado el 2026-09-23, tras `/clarifica` (P6). Hoy el resultado depende del orden
  > en que corren los sistemas, que no está fijado por nada: leyendo el código, en uno
  > de los dos órdenes el salto se pierde (⚠️ sin reproducir todavía).
- **R6.2** — SI el jugador queda parado sobre una copia colocada en el aire, ENTONCES el
  sistema de salto DEBE descartar cualquier pulsación anticipada pendiente.
  > Agregado el 2026-09-23, tras `/clarifica` (P3). Colocar es "quiero pararme acá": un
  > salto apretado de más antes de decidirlo no puede lanzar al jugador desde la copia.

## Casos borde

- **El jugador sale caminando del borde de una copia.** Una copia es piso: R1.1 aplica
  igual que en cualquier borde.
- **El jugador deshace la copia sobre la que está parado.** Deja el piso sin saltar, pero
  no caminando. ❓ **Pendiente — P4.**
- **El jugador anticipa un salto y en ese instante coloca una copia en el aire.** Queda
  parado sobre la copia y no salta — R6.2.
- **El jugador anticipa un salto y suelta el botón antes de tocar el piso.** ¿Sale un
  salto completo o el mínimo? ❓ **Pendiente — P5.**
- **El jugador presiona salto y colocar en el mismo tick, parado en el piso.** Se sube a
  la copia y salta desde ahí — R6.1.
- **Lo mismo, pero la colocación está bloqueada** (no hay lugar arriba). No hay copia de
  la que saltar: R6.1 no aplica y el salto sale desde el piso, como R4.1.
- **El jugador presiona salto y colocar en el mismo tick, en el aire y sin ventana de
  gracia.** ❓ **Pendiente — P7.**
- **El jugador mantiene salto apretado al aterrizar, sin volver a pulsar.** No salta.
  Mantener no es pulsar: R2.1 habla de una pulsación, y R2.3 impide reusarla.
- **El jugador pulsa dos veces dentro de la ventana de anticipación.** Un solo salto —
  R2.3.
- **El jugador usa la ventana de gracia y después suelta el botón.** El corte de altura
  aplica igual: R3 habla de cualquier salto, no solo del que sale del piso.
- **El jugador golpea un techo durante la subida y después suelta.** Ya no está subiendo:
  R3.3, la caída no se toca.
- **El nivel arranca con el jugador en el aire** (el punto de inicio puede estar arriba
  del piso). No hay ventana de gracia: nunca dejó el piso. R1.1 y R4.3.
- **El jugador anticipa un salto, toca la meta en el aire y aterriza con el nivel
  completado.** No salta — R4.4.
- **Un pozo que solo se cruza usando la ventana de gracia.** Error de diseño del nivel,
  no del sistema: los niveles se diseñan contra R5.1. Ver *Fuera de alcance*.

## Requisitos de performance

Ninguno como criterio de aceptación. El sistema corre en cada tick, pero para una sola
entidad y con un costo que no escala con nada del nivel. Poner un número de milisegundos
acá sería inventar un requisito para tener uno.

La restricción que sí existe es de implementación y va al plan: cero allocations por tick
en el camino del salto.

## Estado actual del código

La spec describe el destino; esto es lo que ya existe:

- El salto solo arranca desde el piso y solo en el tick en que se presiona el botón (B1).
  R4.1 protege esa inmediatez; R1 y R2 amplían *cuándo* se puede arrancar.
- El control en el aire es total: acelera igual que en el piso. Por eso saltar parado
  cubre 139 px de distancia y saltar corriendo 147 (medido en B5/H1, alcance horizontal).
  R5.1 lo congela tal cual.
- Colocar una copia deja al jugador parado encima, en el piso y en el aire (`DECISIONES.md`,
  2026-09-17). Es la raíz de R6 y de P4.
- El reinicio ya anula la velocidad del jugador (spec 001, R2.3) y el congelamiento de
  input ya existe (spec 001, R1.2). R4.3 y R4.4 agregan estado nuevo que esos dos tienen
  que cubrir.
- Existe un instrumento que mide subida y alcance de un salto (B5). R3, R4.2, R4.5 y R5.1
  se verifican con él.

## Preguntas abiertas

Respondidas el 2026-09-23 en `/clarifica`: P1 (R5), P3 (R6.2), P6 (R6.1), la lectura de
"idéntico" (R1.1) y el alcance de diseño (*Fuera de alcance*). Los IDs no se reusan.

- ❓ **P2 — Los tres valores de feel:** duración de la ventana de gracia, duración de la
  ventana de anticipación y altura del salto mínimo. Se encuentran en un prototipo con
  los valores afinables sin tocar código, se miden con el instrumento de B5 y recién ahí
  se escriben acá, cada uno en su requisito. Ninguno se completa antes.
- ❓ **P4 — Deshacer la copia bajo los pies, ¿da ventana de gracia?** Con R1.1 escrita tal
  cual, sí: el jugador dejó el piso sin saltar. Si se quiere que no, R1.1 tiene que decir
  "caminando fuera del piso", y la diferencia tiene que tener un motivo de diseño.
- ❓ **P5 — Un salto anticipado con el botón ya soltado al tocar el piso: ¿completo o
  mínimo?** La primera respeta la intención de "saltar"; la segunda respeta lo que el
  botón dice en ese momento.
- ❓ **P7 — Salto y colocar en el mismo tick, en el aire.** Abierta por las respuestas a
  P3 y P6, que tiran para lados distintos: si cuenta como "a la vez", R6.1 dice que salta
  desde la copia; si cuenta como una pulsación previa a la colocación, R6.2 dice que no.
  Hay que elegir cuál de las dos reglas gana cuando coinciden en el mismo tick.

## Notas para el plan

Material que se sacó de los requisitos por ser implementación, y que `/plan` tiene que
levantar:

- **La altura de R3.4 se mide antes de tocar el código.** Sin ese número, R3.4 no tiene
  contra qué compararse. R5.1 ya tiene los suyos (139 / 147 px), pero conviene volver a
  medirlos en el mismo momento, con las mismas condiciones.
- **"La mitad de la subida" de R3.1** es la mitad del tiempo que tarda un salto mantenido
  en llegar a su punto más alto, medido junto con R3.4.
- **R3.1 y R3.2 se verifican con input simulado, no con la mano.** Soltar el botón en un
  tick exacto no es algo que una persona pueda repetir.
- **R6.1 exige fijar el orden** entre el sistema de salto y el de copias dentro del tick.
  Hoy no lo fija nada.
- **Dos decisiones de esta spec las tiene que respetar B11**: el control en el aire total
  (R5) y que los niveles se diseñan sin contar la ventana de gracia. Por la regla de la
  skill `spec-driven`, eso las vuelve candidatas a `DECISIONES.md`.
- **El prototipo de P2 necesita una condición de fin** —tiempo acotado o una prueba
  concreta que tiene que pasar—, o "hasta que se sienta bien" no termina nunca.
- Las ventanas se cuentan en tiempo, no en ticks. Hoy da igual con el paso fijo, pero
  contar ticks ata el feel a la frecuencia de física.
- Los tres valores de P2 tienen que poder cambiarse desde el editor sin tocar el script:
  el prototipo consiste justamente en cambiarlos muchas veces.
- La guía general (≈100 ms de gracia, 100–150 ms de anticipación) sirve como **punto de
  partida del prototipo**, no como valor de esta spec.
- Cero allocations por tick.
- Verificar R2.1, R4.1 y R6.1 exige ver en qué tick llega la pulsación y en qué tick
  cambia la velocidad; el instrumento de B5 hoy no lo informa.
