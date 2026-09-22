# Decisiones de arquitectura

Decisiones que el resto de las features tienen que respetar. Las que afectan a una sola
feature viven en su `docs/specs/NNN-.../plan.md` y no se repiten acá.

---

## 2026-09-16 — El movimiento del jugador es una máquina de estados explícita, no banderas

**Contexto.** Un plataformero 2D necesita coyote time, input buffering, jump cut y altura
de salto variable. Cada una de esas cosas es una regla sobre *en qué estado está el
jugador*. El camino más corto —un solo `_physics_process` manejado por `velocity` e
`is_on_floor()`— expresa esas reglas como booleanos sueltos, y tres booleanos describen
ocho estados cuando nunca se pensaron más de cuatro.

**Decisión.** `PlayerMotor` es un `CharacterBody2D` con una máquina de estados `enum` +
`match` en un solo archivo: `IDLE`, `RUN`, `AIR`. Cada estado responde cómo se entra, qué
lo interrumpe y hacia dónde sale.

**Alternativas descartadas.**
- *Ninguna máquina de estados.* Más corto hoy, y el camino conocido hacia un script de
  jugador de 400 líneas donde nadie puede explicar por qué el personaje a veces hace doble
  salto.
- *Simulación pura en un `RefCounted`, testeable sin `SceneTree`.* Descartada porque
  `move_and_slide()` e `is_on_floor()` son del nodo. Partirla dejaría la colisión adentro
  y las reglas afuera, con dos posiciones que mantener sincronizadas. Esa separación paga
  donde la lógica no depende de la física del motor — no acá.

**Consecuencias.** El trabajo de game feel entra como campos dentro de un estado en vez de
como refactor. Cuesta una capa de ceremonia mientras haya solo tres estados. Una máquina
de un estado por nodo sigue disponible más adelante si la lógica de entrada y salida
crece.

**Estado.** aceptada

---

## 2026-09-17 — Todo el input de juego pasa por un único `InputReader` estático

**Contexto.** Sistemas que llaman a `Input` directamente desparraman nombres de acción por
todo el código, y remapear (B21) pasaría a significar tocar cada sistema.

**Decisión.** `InputReader` es el único lugar que nombra acciones de input. Los sistemas
preguntan qué quiere hacer el jugador, nunca qué tecla está apretada. Es estático: la capa
no guarda estado, así que no hay nada que instanciar ni cablear. Se introdujo recién
cuando existió un segundo consumidor (`place_copy`), según el presupuesto de complejidad
del proyecto.

**Alternativas descartadas.**
- *Llamar a `Input` desde cada sistema.* Con un consumidor era defendible; con dos dejó de
  serlo.
- *Una instancia inyectable detrás de una interfaz.* Correcta en principio y sin pagar: no
  hay tests, ni replays, ni jugador controlado por IA. Ese es el disparador para
  revisarla.

**Consecuencias.** El remapeo y el replay tienen una sola costura. Vuelve trivial congelar
todo el input de una vez — ver la entrada siguiente, que es además el costo principal de
esta decisión.

**Estado.** aceptada

---

## 2026-09-18 — Un interruptor global congela el input de juego

**Contexto.** Completar un nivel tiene que frenar al jugador (spec 001, R1.2) sin frenar la
física: alguien que llega a la meta en el aire debería seguir cayendo.

**Decisión.** `InputReader` lleva una bandera estática `_enabled`. `LevelRules` la apaga al
completar y la vuelve a prender al salir del árbol. Los lectores devuelven valores neutros
mientras está apagada. La acción de reinicio ignora la bandera a propósito: reiniciar es
cómo un jugador sale de un nivel terminado o imposible, así que tiene que funcionar
exactamente cuando el input de juego no funciona.

**Alternativas descartadas.**
- *Apagar `_physics_process` en el jugador y el sistema de copias.* Hace más de lo pedido:
  frenaría también la gravedad, inventando un comportamiento que ningún requisito
  describe.
- *Un estado `FINISHED` en la máquina de estados del jugador.* Resuelve el jugador y no el
  sistema de copias, así que haría falta un segundo mecanismo igual.

**Consecuencias.** ⚠️ Esto mete estado global mutable en una capa deliberadamente sin
estado — un singleton con otro nombre. Se rompe el día que haya dos jugadores, un replay
grabado, o un menú de pausa que necesite input mientras el juego está congelado (B10).
Además sobrevive a los cambios de escena, así que quien lo apaga se hace dueño de volver a
prenderlo.

**Estado.** aceptada

---

## 2026-09-17 — Colocar una copia deja al jugador parado encima

**Contexto.** Las copias nacen donde está parado el jugador, así que jugador y copia se
solapan. La primera implementación hacía que una copia fuera intangible para su dueño
hasta que se corriera. Jugarlo expuso la falla: una copia colocada mientras caés se
solidifica *arriba* tuyo, inútil como escalón.

**Decisión.** Colocar una copia deja al jugador parado encima, siempre — en el piso y en
el aire. La colocación se rechaza, y la copia no se gasta, cuando el destino está ocupado.

**Alternativas descartadas.**
- *Copias intangibles que se solidifican al salir.* Superada. Solo funcionaba colocando
  durante la subida de un salto.
- *Rechazar la colocación cuando hay solapamiento.* La acción más obvia del juego —dejar
  un escalón donde estás parado— sería justo la que falla.
- *Plataformas de una sola dirección.* Elimina el problema pero prohíbe usar copias como
  paredes, recortando el espacio de puzzles.

**Consecuencias.** Borró ~50 líneas: excepciones de colisión, el probe de proximidad y una
señal. La altura alcanzable pasó a ser aritmética en vez de una prueba de habilidad de
salto, y el límite de copias por nivel se volvió la restricción principal del puzzle. El
diseño de niveles (B11) tiene que tratarlo como tal. Copias y jugador tienen que seguir
midiendo lo mismo para que la subida calce.

> **Corregido el 2026-09-21, con la medición de B5/H1.** Esta entrada decía que cada copia
> vale exactamente un piso de altura. Es falso: vale 32 px colocada parado y ~115 px
> colocada en pleno salto. La altura sigue siendo aritmética, pero con dos constantes, y
> el techo de un nivel se diseña contra la segunda.

**Estado.** aceptada

---

## 2026-09-17 — La ocupación se prueba por solapamiento de formas, no por contacto

**Contexto.** Rechazar una colocación bloqueada usaba al principio `test_move()` con
`recovery_as_collision`. Informaba cualquier *contacto*, así que estar parado al lado de
una copia existente bloqueaba la colocación incluso con el espacio de arriba
completamente libre.

**Decisión.** La ocupación es una consulta `intersect_shape()` contra el estado del
espacio con `margin = 0`, usando la propia forma de colisión del jugador. Los cuerpos que
apenas se tocan no cuentan como que ocupan.

**Alternativas descartadas.**
- *`test_move()` con `recovery_as_collision`.* Superada. Responde una pregunta distinta de
  la que se estaba haciendo.

**Consecuencias.** Cualquier chequeo futuro de "¿esto entra acá?" debería usar la misma
consulta y no una prueba de movimiento. Aloca un `Array` por consulta; aceptable porque
corre al apretar una tecla, nunca por frame, y sin medir en ninguno de los dos casos.

**Estado.** aceptada

---

## 2026-09-20 — Un nivel se reinicia en caliente en vez de recargar la escena

**Contexto.** La spec 001 exige que el reinicio devuelva al jugador al inicio, retire las
copias colocadas y cancele la velocidad (R2.1–R2.3). Un juego de puzzles se reinicia
muchas veces por minuto.

**Decisión.** `LevelRules.restart()` hace esas tres cosas sobre la escena viva.

**Alternativas descartadas.**
- *`get_tree().reload_current_scene()`.* Tres líneas, e imposible olvidarse de algún
  estado. Era la opción más barata y más segura; esta es la decisión más discutible del
  proyecto hasta ahora. Perdió porque el estado por intento que tiene que sobrevivir a un
  reinicio —un contador de intentos (B20), un efecto de transición (B17)— obligaría a
  deshacerla más adelante.

**Consecuencias.** Todo lo que se agregue a un nivel y tenga estado hay que reiniciarlo
explícitamente en `restart()`, y olvidarse aparece recién en un segundo intento. Si esa
lista pasa de tres o cuatro entradas, recargar la escena pasa a ser la respuesta correcta
y esto habría que revertirlo.

**Estado.** aceptada

---

## 2026-09-20 — Un nivel declara sus datos una sola vez, y el dueño es `LevelRules`

**Contexto.** `CopySystem` exportaba su propia casilla de `LevelData`. Agregar un segundo
sistema que necesitara el mismo recurso le daría a un nivel dos casillas del Inspector
capaces de apuntar a recursos distintos — un desajuste que no levanta ningún error y
produce reglas contradictorias.

**Decisión.** `LevelRules` es dueño del `LevelData` del nivel y se lo entrega a quien lo
necesite durante el arranque. `CopySystem` lo recibe por `setup()` en vez de exportarlo.
La entrega es explícita porque el orden de `_ready()` entre hermanos sigue al árbol de
escena y no es algo en lo que apoyarse.

**Alternativas descartadas.**
- *Que cada sistema exporte su propia casilla.* Mala configuración silenciosa.
- *Un autoload con los datos del nivel actual.* Estado global para un problema que
  resuelve un dueño único.

**Consecuencias.** Los sistemas nuevos que necesiten datos del nivel se los piden a
`LevelRules`, no a su propia casilla del Inspector. Agregar un nivel es editar un `.tres`,
nunca un script. La cadena de entrega se alarga con cada consumidor; si se vuelve
incómoda, revisar.

**Estado.** aceptada

---

## 2026-09-20 — El cuerpo del jugador se identifica por referencia inyectada

**Contexto.** Las metas y las zonas de muerte tienen que reaccionar al cuerpo del jugador
e ignorar sus copias (spec 001, R1.6 y R4.2).

**Decisión.** Los manejadores comparan el cuerpo informado contra la referencia al jugador
que ya está inyectada en `LevelRules`.

**Alternativas descartadas.**
- *Capas de colisión.* Estrictamente mejor en performance —filtra el motor y la señal
  nunca se dispara— pero compra configuración de capas invisible desde el código a cambio
  de un ahorro que nadie midió. Revisar si alguna vez aparecen señales ignoradas en el
  Profiler.
- *Grupos (`is_in_group("player")`).* Prohibido por los estándares del proyecto: un grupo
  haciendo de referencia es una búsqueda global disfrazada.

**Consecuencias.** Toda área que reaccione al jugador necesita esa referencia cableada en
el Inspector. Explícito, y falla ruidosamente por `assert` cuando falta.

**Estado.** aceptada

---

## 2026-09-21 — El HUD vive dentro de cada nivel

**Contexto.** La spec 002 pone un contador de copias en pantalla. Alguien tiene que ser su
dueño, y la elección se estira más allá de esta feature: B7 quiere un HUD que sobreviva a
una transición, B10 quiere uno que siga vivo durante la pausa.

**Decisión.** `hud.tscn` se agrega a un nivel como cualquier otro nodo y muere con él.
Recibe por el Inspector una referencia al `CopySystem` de su propio nivel, se suscribe a
`copies_changed` y escribe lo que le llega. Sin estado global, sin búsquedas, sin
registro.

**Alternativas descartadas.**
- *Un HUD único que sobreviva a los cambios de escena.* Mejor para B7 y B10, y por eso
  queda anotado acá en vez de descartado sin más. Pierde hoy porque tendría que enterarse
  de qué nivel acaba de cargarse y recablearse en cada cambio —el problema que un dueño
  único ya resolvió para los datos de nivel— y porque una segunda pieza de estado global
  profundizaría la deuda que ya arrastra el interruptor de `InputReader`.
- *Nodos sueltos copiados en cada nivel.* Doce niveles significa cambiar la tipografía en
  doce lugares.

**Consecuencias.** Cada nivel tiene que cablear su propio HUD, y un nivel que se olvide
falla ruidosamente por `assert`. El HUD se reconstruye en cada cambio de nivel, lo que se
va a ver como un parpadeo cuando B7 agregue transiciones — eso, o que B10 necesite el HUD
vivo durante la pausa, es el disparador para revisar esta decisión.

**Estado.** aceptada
