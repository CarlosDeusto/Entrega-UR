# Visualizador UR3e

1. Extrae **todo `UR.zip`** en una carpeta de Windows 10/11 de 64 bits.
2. Conecta el PC a la red del robot o de URSim y cambia las IP en `codigos/robots.json`.
3. Abre con doble clic uno de estos archivos:

| Archivo | Script | Qué muestra |
| --- | --- | --- |
| `ejecutar_primaria.bat` | `codigos/primaria.py` | Primer robot del JSON, interfaz primaria (30001) |
| `ejecutar_tiempo_real.bat` | `codigos/tiempo_real.py` | Primer robot del JSON, interfaz de tiempo real (30003) |
| `ejecutar_multirobot.bat` | `codigos/multirobot.py` | Todos los robots del JSON, cada uno con su puerto y posición |
| `ejecutar_ensenar_reproducir.bat` | `codigos/ensenar_reproducir.py` | Enseñar y reproducir (sobresaliente): primer robot del JSON, primaria (30001), envío de órdenes URScript |

`codigos/configuracion.py` solo lee y comprueba `robots.json`.

No necesitas instalar Python ni librerías, usar Internet ni ejecutar `setup.bat`
antes: los BAT preparan automáticamente el Python incluido en el ZIP. El primer
arranque tarda algo más. Necesitas un robot o URSim accesible por red.

También se pueden ejecutar desde un terminal con el entorno ya preparado:

```
python codigos/primaria.py [IP]
python codigos/tiempo_real.py [IP]
python codigos/multirobot.py
python codigos/ensenar_reproducir.py [IP]
```

Si no se indica la IP, `primaria.py`, `tiempo_real.py` y
`ensenar_reproducir.py` usan la del primer robot de `robots.json`.

## Formato de `robots.json`

```json
[
  {"nombre": "UR3e 1", "ip": "10.172.18.86", "puerto": 30001, "posicion": [0, 0, 0, 0, 0, 0]},
  {"nombre": "UR3e 2", "ip": "10.172.18.155", "puerto": 30003, "posicion": [0, 1, 0, 0, 0, 3.1416]}
]
```

`puerto` es 30001 (primaria) o 30003 (tiempo real). `posicion` es la base del
robot en la escena: `[x, y, z, giro_x, giro_y, giro_z]` en metros y radianes.

## Comportamiento

La terminal avisa de conexiones, desconexiones y cambios de estado del robot, e
imprime cada segundo los estados recibidos por segundo y los 6 `q_actual` en
grados. Si se cierra URSim, se apaga el controlador o falla la red, el robot
simulado conserva la última postura y el programa reintenta la conexión. En
`multirobot.py` un robot desconectado no detiene a los demás.

Para salir, cierra la ventana de PyBullet o pulsa **Ctrl+C**.

## Enseñar y reproducir (sobresaliente)

Requisitos en el robot o URSim:

- Encendido, con los frenos liberados (modo 7, Normal).
- En modo **Remoto**: Ajustes → Sistema → Control remoto, y seleccionar
  **Remoto** arriba a la derecha.
- En el robot real, solo con autorización y presencia del profesor.

Teclas (con la ventana de PyBullet activa):

| Tecla | Acción |
| --- | --- |
| **A** | Añadir la postura actual del robot |
| **D** | Añadir la postura de los deslizadores (robot translúcido) |
| **T** | Copiar la postura del robot a los deslizadores |
| **B** | Borrar el último punto |
| **V** | Previsualizar la secuencia en el robot translúcido |
| **E** | Ejecutar la secuencia (antes rehace la conexión) |
| **R** | Reanudar una secuencia detenida |
| **C** | Cancelar (detiene el robot si se mueve) |
| **G** | Guardar en `codigos/secuencia.json` |
| **L** | Cargar de `codigos/secuencia.json` |
| **H** | Ayuda |

Al pulsar **E**, el programa cierra la conexión y abre otra, porque la abierta
antes de pasar el robot a modo Remoto no acepta órdenes. Espera al primer estado
de la conexión nueva (máximo 5 s) y entonces empieza la secuencia.

Funcionamiento: envía un `movej` por punto con v = 0,3 rad/s y a = 0,5 rad/s²,
con los ángulos validados en ±2π. No envía el siguiente hasta ver que
`isProgramRunning` pasa a verdadero (máximo 2 s) y vuelve a falso con `q_actual`
a menos de 0,01 rad del punto. Si llega un error del robot (mensaje 20, subtipos
6 o 10, o modo de seguridad anómalo), una parada de protección o de emergencia,
o se pierde la conexión, detiene la secuencia, muestra el motivo y espera **R**
o **C**.
