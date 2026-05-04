# 🌾 Admirals — Nodo 2: El Molino Admirals

> **Versión:** 1.0 (firmado)
> **Documento padre:** `00_PRODUCT_BIBLE.md` v1.2
> **Documentos hermanos:** `01_node_farm.md` v1.1 (proveedor upstream), `02_sonar_tablet.md` v1.0 (Manager Panel del Molinero).
> **Estado:** primera redacción completa de las 3 partes (15 secciones, ~870 líneas).

> **Lectura previa obligatoria:** Bible §3 (5 Pilares), §13.4 (División 3D vs Código), Granja §0-§6 (entender qué llega), Tablet §7 (Manager Panel modular).

---

## 0. Resumen ejecutivo

El **Molino Admirals** es el **segundo nodo de la Cadena del Pan** y el **primer cliente B2B real de la Granja**.

Recibe **grano** de la Granja (trigo, centeno, avena, maíz — dependiendo de oleada), lo **transforma físicamente** mediante un proceso completo (recepción → limpieza → molienda → cribado → ensacado → almacenamiento → despacho), y produce **harinas con calidad propagada** que la Panadería usará para hacer pan.

Es a la vez:

- **Una nave industrial-artesanal** con MLO propio: zona de recepción de camiones, silos verticales, sala de molienda con maquinaria visible, sala de cribado, ensacadora, almacén de producto terminado, despacho del molinero.
- **Un proceso productivo físico** con 6-7 etapas, todas físicamente jugables — no es un menú de "transformar grano".
- **Un puesto profesional** (el Molinero) con su rol RP, sus retos diarios, su empresa.
- **Un nodo del ecosistema** — recibe del Granjero, vende a la Panadera, pasa por Logística, factura por Banca, firma contratos en la Tablet.

> **El Molino es donde la Cadena empieza a sentirse real.** En Granja, el jugador ve plantas crecer. En el Molino, ve **el resultado de su trabajo upstream materializarse en producto distinto**. Esto es lo que ningún script de FiveM hace bien hoy.

---

## 1. Filosofía y posicionamiento

### 1.1 Tradicional + industrial — la decisión estética

El Molino Admirals **combina lo industrial moderno con lo artesanal tradicional**. No elegimos un extremo:

- **Industrial moderno** porque el gameplay necesita maquinaria con visual de proceso (rodillos girando, cribadoras vibrando, ensacadora soplando harina, cintas transportadoras moviéndose). Sin eso, no hay wooow.
- **Artesanal tradicional** porque la marca Admirals premia el oficio: el molinero con delantal blanco impoluto, la harina cayendo en el saco con polvillo en el aire, la firma del molinero en el saco, el aroma RP del molino.

**Inspiración visual:**
- Molinos industriales de cooperativa española (mediano tamaño, no factoría gigante).
- Tonos: piedra clara, madera envejecida, metal pintado verde militar / azul marino industrial.
- Iluminación: cálida, polvo en el aire iluminado por rayos de luz — **wooow atmosférico de código** (volumetric light + particle dust).

### 1.2 ¿Por qué un nodo dedicado al Molino?

> **Pregunta razonable: ¿no sería más fácil que el granjero "convierta" trigo en harina con un menú?**

No. Por 4 razones:

1. **Pilar 1 — Físico.** Molienda real es proceso de varias etapas — separarlo del trigo conserva la verdad.
2. **Pilar 2 — Cadena.** Una cadena necesita eslabones distinguibles. Si no hay Molinero, no hay relación B2B verdadera entre granjero y panadero.
3. **Pilar 3 — Detalle.** El molino es uno de los lugares más sensoriales del oficio alimentario (aroma, polvo, ruido). Merece su nodo.
4. **Estratégico.** Permite vender el Molino como **producto independiente** (un servidor puede comprar solo Granja + Molino y enchufar al granjero NPC bridge si no tiene panadero). Modularidad comercial.

### 1.3 Anti-patrones específicos del Molino

> Lo que **JAMÁS** vamos a hacer en este producto.

- ❌ **Menú "transformar 100kg trigo en 80kg harina"** sin proceso físico.
- ❌ **Maquinaria estática que no muestra el proceso.** Los rodillos giran. La cribadora vibra. La harina cae. La cinta se mueve.
- ❌ **Output sin trazabilidad.** Cada saco de harina conoce su batch_id de grano de origen → granja, parcela, fecha de cosecha, calidad input.
- ❌ **Sin diferenciación de tipos de harina.** Salir solo "harina" es plano — debe haber harina blanca, integral, de fuerza, espelta, etc.
- ❌ **Calidad que se pierde sin causa.** La harina debe heredar la calidad del grano + factor proceso. Si entra Calidad A, no puede salir Calidad C sin razón gameplay (suciedad, máquina mal calibrada, humedad alta).
- ❌ **Polvo de harina invisible.** El molino sin polvo en el aire NO es un molino. Wooow atmosférico de código requerido.
- ❌ **Saco genérico.** El saco lleva logo de la empresa molinera, fecha, batch_id, tipo, peso, calidad.

---

## 2. Topología del nodo — el MLO del Molino

### 2.1 Visión general del edificio

> **MLO único, identificable, ubicado en zona industrial.** Ubicación canónica recomendada: **Paleto Bay industrial** (silos altos visibles desde la carretera). Configurable por servidor.

**Tamaño:** mediano-grande. Aproximadamente 50m × 30m de planta + silos altos (10-15m) + zona exterior de carga/descarga.

### 2.2 Zonas funcionales

| # | Zona | Función | Visible desde fuera |
|---|---|---|---|
| Z1 | **Báscula de camiones** | Pesar entrada y salida de vehículos | Sí — entrada principal |
| Z2 | **Foso de descarga** | Vaciado del grano del camión a transporte interno | Sí — playa de descarga |
| Z3 | **Silos de grano** (3 silos) | Almacenamiento de grano por tipo / calidad | Sí — torres icónicas |
| Z4 | **Sala de limpieza** | Eliminación de impurezas (piedras, paja, polvo) | No — interior |
| Z5 | **Sala de molienda** | Molino de rodillos en cascada (3-4 pasadas) | No — interior, ventana grande |
| Z6 | **Sala de cribado / sasor** | Separación de harina, sémola y salvado | No — interior |
| Z7 | **Ensacadora** | Llenado automático y manual de sacos | No — interior |
| Z8 | **Almacén de harina** | Sacos paletizados, control humedad | No — interior |
| Z9 | **Despacho del molinero** | Oficina con dock Tablet + monitor | No — interior planta alta |
| Z10 | **Vestuario + aseos empleados** | Cambio ropa, taquillas | No — interior |
| Z11 | **Zona de carga camiones salida** | Despacho de pedidos | Sí — playa exterior |
| Z12 | **Patio exterior** | Aparcamiento + báscula + acceso | Sí — exterior |

### 2.3 Plano conceptual (vista superior)

```
                    PATIO EXTERIOR (Z12)
            ┌─────────────────────────────────┐
            │  [báscula Z1]      [sil Z3]     │
            │                    [sil Z3]     │
   entrada→ │  [foso Z2]         [sil Z3]     │
   camiones │                                  │
            │  ┌──────────────────────────┐   │
            │  │  Z4 Limpieza  Z5 Molienda│   │
            │  │  Z6 Cribado   Z7 Ensac   │   │
            │  │  Z8 Almacén    Z11 Carga │←──│ salida camiones
            │  │  Z10 Vestuar  ┌───────┐  │   │
            │  │               │Z9 Desp│  │   │
            │  │               └───────┘  │   │
            │  └──────────────────────────┘   │
            └─────────────────────────────────┘
```

**Flujo del grano:** Z2 → Z3 → Z4 → Z5 → Z6 → Z7 → Z8 → Z11 (lineal, intuitivo).

### 2.4 Detalles de zona crítica

#### Z3 — Los silos (icónicos)

- **3 silos verticales** de chapa galvanizada, 10-15m de alto.
- Cada silo tiene un **indicador de nivel** visible desde fuera (ventana lateral con mirilla + escala pintada).
- Cada silo se configura para un **tipo de grano** (trigo blanco / trigo integral / centeno / etc.). Se ve en cartel pintado.
- **Wooow del código:** shader de relleno (igual que silos Granja §6.3) + partículas sutiles cuando entra grano por arriba.
- Acceso a la cima por **escalera exterior** (anim de subir si el molinero quiere inspeccionar manualmente — RP).

#### Z5 — Sala de molienda (corazón del nodo)

- **Molino de rodillos en cascada** — 3-4 pares de rodillos, cada par muele más fino que el anterior.
- Visualmente: tubos verticales conectando los pares, válvulas, cinta transportadora elevada que lleva grano de uno a otro.
- **Rodillos giran cuando el molino está activo** — animación constante mientras procesa.
- Polvo de harina en el aire (partículas — código).
- Sonido de motor + rodillos chirriando + grano siendo triturado — **firma sonora del nodo**.
- **Panel de control** físico en la pared con palancas y pantallas analógicas (anim de operar).

#### Z7 — Ensacadora

- **Tolva** que dispensa harina por gravedad.
- Operario coloca un saco vacío bajo el dispensador.
- **Animación de llenado** (~5s) con polvo en el aire al final.
- Operario cierra el saco con grapadora industrial (anim).
- Saco etiquetado automáticamente con sello de empresa + batch + tipo + peso.
- **Cinta transportadora** lleva el saco al almacén.

#### Z9 — Despacho del molinero

- Oficina con vista a la sala de molienda (ventana grande).
- **Mesa con dock pro de Tablet** (Tablet §21.3) + monitor curvo + impresora.
- Sillón cómodo. Estanterías con muestrarios de harinas (decoración).
- Caja fuerte física en el suelo (caja de empresa — Granja §11.3).

---

## 3. Materias primas y productos

### 3.1 Inputs aceptados (qué grano entra)

| Oleada | Grano de entrada | Origen |
|---|---|---|
| **O1** | Trigo blando, trigo duro | Granja Admirals |
| **O2** | Centeno, avena | Granja Admirals (oleada 2) |
| **O3** | Maíz | Granja Admirals (oleada 1, pero molienda específica) |

> **Nota O1:** la Granja oleada 1 produce trigo común y trigo premium. El Molino los muele por separado y produce sus harinas correspondientes.

### 3.2 Outputs producidos (qué harinas salen)

#### Oleada 1 — productos base

| Producto | Input | Tipo | Uso downstream |
|---|---|---|---|
| **Harina blanca de fuerza** | Trigo blando común/premium | Saco 25kg / 50kg | Pan blanco, masa madre |
| **Harina blanca panadera** | Trigo blando | Saco 25kg / 50kg | Pan común, baguettes |
| **Harina integral** | Trigo blando integral | Saco 25kg | Pan integral |
| **Sémola fina** | Trigo duro | Saco 25kg | Pasta (futuro), pan especial |
| **Salvado** | Subproducto cribado | Saco 25kg | Alimentación animal (futuro), retail premium |

#### Oleada 2-3 — extensión

| Producto | Input | Tipo | Uso downstream |
|---|---|---|---|
| **Harina de centeno** | Centeno | Saco 25kg | Pan de centeno |
| **Harina de avena** | Avena | Saco 25kg | Galletas, repostería |
| **Harina de maíz** | Maíz | Saco 25kg | Tortillas, repostería |
| **Sémola gruesa** | Trigo duro | Saco 25kg | Cuscús, pasta artesanal |
| **Mezclas custom** | Configurable | Saco 25kg | Recetas premium |

### 3.3 Calidades de salida

> **Sistema de calidad heredado + modificado.** El sistema de propagación de calidad (Granja §3.5) llega hasta aquí.

**Fórmula de calidad de la harina:**

```
calidad_harina = (calidad_grano * 0.7) + (factor_proceso * 0.3)

donde factor_proceso depende de:
- Limpieza adecuada (impurezas residuales)
- Molienda fina y uniforme (calibración rodillos)
- Humedad correcta (<14.5%)
- Cribado limpio (sin contaminación entre tipos)
- Tiempo de almacenamiento (frescura)
```

**Niveles de salida:** S / A / B / C / D (mismo sistema que Granja).

> **Wooow:** el saco de harina lleva grabada la trazabilidad — un panadero puede comprar una harina S y verificar que viene de un trigo S de la parcela 3 de Granja del Valle. Confianza B2B real.

---

## 4. Proceso físico — el ciclo del Molinero

### 4.1 Las 7 etapas del ciclo

> **Cada etapa es física, jugable, observable.** Ningún menú reemplaza una etapa.

| # | Etapa | Duración | Operario | Físico |
|---|---|---|---|---|
| **1** | Recepción y báscula | ~3 min | Empleado báscula o molinero | Sí — camión, báscula, ticket |
| **2** | Descarga al silo | ~5 min | Camionero + empleado | Sí — apertura compuerta camión, transporte neumático |
| **3** | Limpieza | ~10 min (pasivo) | Automático con supervisión | Sí — máquina visible, ruidos, partículas |
| **4** | Molienda | ~15-20 min (pasivo) | Automático con supervisión | Sí — rodillos, ruido, polvo |
| **5** | Cribado | ~5 min (pasivo) | Automático | Sí — cribadora vibrante, separación visible |
| **6** | Ensacado | ~3 min/saco activo | Operario | Sí — manual con grapadora, etiquetado |
| **7** | Almacenado y despacho | Variable | Operario + camionero salida | Sí — paleta, carretilla, carga camión |

**Total ciclo completo (de grano a saco listo para vender):** ~45-60 minutos in-game para un lote estándar de 1000kg de trigo → ~750kg de harina + 200kg de subproductos + pérdidas.

### 4.2 Etapa 1 — Recepción y báscula

1. Camión del granjero (o transportista) entra al patio.
2. Sube a la **báscula** — peso bruto registrado automáticamente.
3. Empleado del molino (o el molinero mismo) lee el albarán en la **Tablet**.
4. **Inspección visual rápida** del grano (RP — el camionero abre una compuerta, el empleado mete una pala manual, observa).
5. Si OK, el sistema confirma recepción. Se genera **albarán de entrada** firmado en Tablet.
6. Si rechazo (suciedad excesiva, humedad alta, color sospechoso) → camión devuelto, notificación al granjero.
7. **Pago automático** al granjero según contrato — se actualiza Banca de ambos.

### 4.3 Etapa 2 — Descarga al silo

1. Camión avanza al **foso de descarga** (Z2).
2. Compuerta inferior del camión se abre (animación) — grano cae al foso por gravedad.
3. **Transporte neumático** (tubo + soplador) lleva el grano al silo configurado.
4. **Wooow visual:** se ve el grano entrar por la parte superior del silo (partículas) + nivel del silo sube en tiempo real (shader de relleno).
5. Sonido constante de soplador + grano cayendo en silo metálico — **wooow auditivo**.
6. Camión sale, vuelve a báscula → peso vacío → **diferencia = peso descargado**, registrado en sistema.

### 4.4 Etapa 3 — Limpieza

1. Molinero abre la compuerta del silo desde el **panel de control** o desde **Tablet** (Manager Panel — vista Operations).
2. Grano fluye por gravedad a la sala de limpieza.
3. **Máquina de limpieza** trabaja:
   - Cribas vibratorias separan piedras y palos.
   - Aspirador elimina polvo y paja.
   - Imán retira metales accidentales.
4. **Wooow:** se ve la máquina vibrar, el polvo subir por el aspirador, el grano salir limpio por el otro lado.
5. **Pérdida típica:** 1-3% del grano descartado como impurezas.
6. El grano limpio cae al **silo intermedio** o pasa directo a molienda según configuración.

### 4.5 Etapa 4 — Molienda

1. Grano limpio entra al **molino de rodillos** (Z5).
2. **Pasada 1 (rotura):** rodillos estriados rompen el grano grueso. Salida: mezcla de harina, sémola, salvado.
3. **Pasada 2-3 (compresión):** rodillos lisos compactan y reducen. Salida: harina más fina + sémola más fina.
4. **Pasada 4 (acabado):** rodillos finos producen la harina final.
5. Entre cada par de rodillos, una **cribadora intermedia** separa lo que ya es lo bastante fino de lo que necesita más molienda.
6. **Wooow visual:** todos los rodillos giran simultáneamente. El grano fluye visiblemente entre niveles. Polvo de harina en el aire (volumétrico).
7. **Wooow sonoro:** firma sonora del nodo — motor industrial + chirrido continuo + grano triturado.
8. **Variables de control:**
   - **Calibración** de rodillos (gap entre ellos) — afecta finura.
   - **Velocidad** de alimentación — afecta calidad.
   - **Humedad** del grano — clave (idealmente 14-16%).

### 4.6 Etapa 5 — Cribado final (sasor)

1. Producto post-molienda entra a la **cribadora final** (Z6).
2. Cribadora **vibrante** (anim constante) separa por tamaño en 3-4 niveles:
   - **Harina blanca fina** (sale por arriba — la mejor calidad).
   - **Harina semolada** (medio).
   - **Sémola** (más gruesa — solo si trigo duro).
   - **Salvado** (cáscara — sale por abajo).
3. Cada output va a su **silo intermedio dedicado** (silos pequeños 1-2m, internos a la nave).
4. **Wooow:** la cribadora vibra visiblemente, ruido distinto al molino (más frecuencia).

### 4.7 Etapa 6 — Ensacado

1. Operario coloca **saco vacío** bajo el dispensador del silo intermedio del producto deseado.
2. Pulsa botón → **dispensador llena el saco** automáticamente hasta peso configurado (25kg / 50kg).
3. **Animación de llenado** (~5s) — saco se llena visiblemente, polvo en el aire al final.
4. Operario **cierra el saco** con grapadora industrial (anim manual).
5. **Etiqueta automática** se imprime en el saco:
   - Logo de la empresa.
   - Tipo de harina.
   - Calidad (S/A/B/C/D).
   - Peso.
   - Fecha de molienda.
   - Batch_id (trazabilidad upstream).
   - Sello del molinero (firma).
6. Operario carga el saco a una **paleta** (animación de carga repetitiva — RP).
7. Cuando paleta llena (~30 sacos), **carretilla elevadora** la lleva al almacén.

### 4.8 Etapa 7 — Almacenado y despacho

1. **Almacén Z8:** paletas apiladas. Control de humedad (sensor visible — RP). Control de roedores (RP — gato de molino futuro 🐱).
2. **Pedidos** entran vía Tablet > Manager Panel > Pedidos.
3. Cuando llega camión a recoger pedido (cliente o transportista contratado):
   - Báscula entrada (camión vacío).
   - Carga de paletas con carretilla elevadora.
   - Báscula salida (camión cargado).
   - Diferencia = peso despachado.
   - **Albarán de salida** firmado en Tablet (cliente firma con la suya — inter-tablet §19.2).
   - **Pago automático** según contrato.

### 4.9 Variables del proceso (qué afecta a la calidad y rendimiento)

| Variable | Rango | Efecto |
|---|---|---|
| **Humedad grano entrada** | 12-18% | Óptimo 14-16%. Fuera: harina mala calidad |
| **Humedad ambiente molino** | <60% | Si alta: harina apelmaza |
| **Calibración rodillos** | 0.05-0.5mm gap | Fino: harina premium pero más lento. Grueso: rápido pero más sémola |
| **Velocidad alimentación** | 50-100% | Lento: mejor calidad. Rápido: más cantidad |
| **Limpieza máquinas** | Ciclos de mantenimiento | Sin limpiar: contaminación cruzada de tipos de harina |
| **Tiempo desde molienda** | Días | Harina recién molida más sabrosa pero menos estable. >30 días: pérdida calidad |

> **Wooow del Manager Panel:** todas estas variables se ven en tiempo real en la vista Operations. El molinero **toma decisiones** — ¿produzco rápido y de calidad media, o lento y premium?

---

## 5. Maquinaria — catálogo detallado

> **Aplicando regla Bible §13.4** desde el inicio: el 3D entrega modelos sólidos con la idea wooow CORE (rigs animables, partes intercambiables); el código añade rotación, partículas, shaders, sonido espacial.

### 5.1 Tabla maestra

| ID | Máquina | Origen | Wooow del 3D | Wooow del código |
|---|---|---|---|---|
| MQ-01 | **Báscula de camiones** | Custom propio | Pieza embebida en suelo + display digital | Display dinámico con peso real-time |
| MQ-02 | **Foso de descarga** | Custom propio | Rejilla metálica + foso visible | Partículas de grano cayendo, sonido |
| MQ-03 | **Silo de grano** (×3) | Custom propio | Cilindro chapa galvanizada + escalera + ventana mirilla | Shader de relleno + partículas top + nivel sincronizado a estado |
| MQ-04 | **Tubería de transporte neumático** | Custom propio | Tubos verticales + soplador externo | Sonido de soplador + partículas en codos |
| MQ-05 | **Máquina de limpieza** | Custom propio | Caja metálica + cribas vibrantes + aspirador externo | Anim de vibración + partículas polvo + sonido grano sobre cribas |
| MQ-06 | **Molino de rodillos** (4 pares) | Custom propio | Estructura metálica + rodillos individuales animables + tubos verticales conectores + panel control | Rotación de cada rodillo + polvo volumétrico + sonido firma del nodo |
| MQ-07 | **Cribadora final / Sasor** | Custom propio | Caja oscilante con tamices internos visibles + 4 salidas de producto | Animación oscilante + partículas en cada salida + sonido distintivo |
| MQ-08 | **Silos intermedios** (4-6) | Custom propio | Cilindros pequeños (1-2m) interiores | Shader relleno + indicador LED de nivel |
| MQ-09 | **Ensacadora dispensador** | Custom propio | Tolva inferior + boquilla + soporte saco | Animación de flujo de harina + partículas + peso real-time |
| MQ-10 | **Grapadora industrial de saco** | Custom propio | Brazo articulado | Anim de cierre + sonido staccato grapas |
| MQ-11 | **Etiquetadora** | Custom propio | Cabezal de impresión + sticker visible | Anim de impresión + texto generado dinámicamente |
| MQ-12 | **Cinta transportadora** (varias) | Custom propio | Cinta + rodillos + estructura | Movimiento continuo + sacos animados encima |
| MQ-13 | **Carretilla elevadora** | GTA V (forklift) tuneo livery | — | Livery propia + animación brazos pre-existente |
| MQ-14 | **Paleta de madera** | Prop estándar | Modelo simple | — |
| MQ-15 | **Saco de harina** (genérico + variantes) | Custom propio | Saco con relieve "ADMIRALS" + zona impresión etiqueta | Etiqueta dinámica con datos del lote |
| MQ-16 | **Panel de control molino** | Custom propio | Panel pared con palancas + pantallas analógicas | Pantallas dinámicas + sonido click palanca |
| MQ-17 | **Sensor humedad ambiente** | Custom propio | Caja pequeña + display | Display dinámico + alertas |

### 5.2 Detalle por máquina crítica

#### MQ-06 — Molino de rodillos (la pieza estrella del nodo)

> **Si la cosechadora es la estrella de la Granja, el molino de rodillos es la estrella del Molino.**

- **Estructura visible:**
  - Pisos: 2 niveles verticales conectados por tubos.
  - 4 pares de rodillos: 2 estriados (rotura) + 2 lisos (acabado).
  - Cada par en su carcasa metálica con ventana de inspección (puedes ver girar los rodillos).
  - Tubos verticales transparentes parcialmente — el grano cae por gravedad de un nivel a otro.
  - Cinta transportadora elevada lleva grano de la limpieza al primer par.
  - Panel de control en pared lateral.

- **Animaciones (rigs del 3D):**
  - Cada rodillo gira independiente.
  - Las cribadoras intermedias entre pares vibran.
  - Las palancas del panel se pueden mover.

- **Shaders / partículas (código):**
  - Polvo volumétrico flotante alrededor del molino cuando opera.
  - Partículas de harina cayendo dentro de los tubos.
  - Iluminación cálida con polvo iluminado por rayos (god rays).
  - Vibración sutil de la estructura cuando opera.

- **Sonido (audio team):**
  - Firma sonora: motor eléctrico grande + chirrido continuo de rodillos + impacto leve de grano.
  - Cambia cuando se ajusta velocidad o calibración.
  - Se oye desde **dentro del MLO entero** — no solo en la sala (audio espacial 3D).

- **Estados:**
  - **Apagado:** silencio, rodillos inmóviles.
  - **Calentando:** rodillos giran sin grano (10s arranque), motor sube tono.
  - **Operando:** todos los rodillos rotando + grano fluyendo + polvo + ruido.
  - **Parando:** flujo de grano se corta, rodillos giran 5s más vacíos antes de pararse.

#### MQ-09 — Ensacadora

- Operario interactúa físicamente: coloca saco bajo boquilla, pulsa botón.
- Boquilla baja sutilmente (hidráulica visible), abraza el saco.
- Flujo de harina visible (partículas constantes durante 5s).
- Saco se llena (modelo cambia de "vacío" a "lleno" con interpolación de stages).
- Al terminar, polvo escapa por los bordes (partícula corta).
- Operario retira saco lleno, lo lleva a la grapadora.

#### MQ-15 — Saco de harina (icónico)

- Modelo del saco con **logo Admirals embossed** en relieve.
- **Zona de etiqueta** plana lateral donde se imprime dinámicamente:
  ```
  ┌──────────────────────────┐
  │ MOLINO DE PEDRO          │
  │ Harina blanca de fuerza  │
  │ Calidad A · 25 kg        │
  │ Lote: ML-2026-0431-A     │
  │ Molienda: 30/04/2026      │
  │ Origen: Granja del Valle │
  └──────────────────────────┘
  ```
- 5 stages de "vejez visual" del saco (recién impreso, normal, ligeramente desgastado, sucio, muy desgastado) — útil para gameplay de stock antiguo.

---

## 6. Sistema de empresa — adaptación al Molino

> **Reusa la arquitectura validada de Granja §11.** Mismo modelo: 4 roles, dual-pool de caja, contratos B2B vía Tablet. Los específicos del Molino son los puestos.

### 6.1 Roles del Molino

| Rol | Permisos | Salario base/turno | Tareas |
|---|---|---|---|
| **Owner / Molinero jefe** | Total (idéntico a Granja Owner) | Variable (beneficio) | Gestión, decisiones estratégicas, contratos B2B |
| **Manager / Encargado** | Operaciones + RRHH | Alto fijo | Supervisar turno, asignar tareas, calibrar molino |
| **Maquinista** | Operar molino, rodillos, cribadora | Medio-alto | Calibrar, vigilar, ajustar variables |
| **Operario ensacador** | Ensacar, etiquetar, cargar paletas | Medio | Trabajo manual repetitivo en Z7 |
| **Empleado báscula** | Pesar camiones, gestionar entradas/salidas | Medio | Recepción / despacho, papeleo |
| **Conductor carretilla** | Operar forklift, mover paletas | Medio | Entre Z7, Z8 y Z11 |
| **Empleado limpieza/mantenimiento** | Limpiar máquinas, mantener | Bajo-medio | Limpieza programada de molino, lubricación |
| **Temporal** | Acepta una tarea concreta del Mercado | Por tarea | Misma lógica Granja §11.7 |

> **El Molino puede operar con 1 sola persona** (Owner haciendo todo — RP solo) o **plantilla de 6-8 personas** (modo empresa real).

### 6.2 Caja física y banca (idéntico a Granja)

- **Caja física** en el despacho del molinero (Z9) — billetes visibles, animación al abrir.
- **Cuenta empresarial** vía Banca > Tablet.
- Pagos B2B llegan automáticamente a la cuenta. Pagos a empleados, repuestos, electricidad salen de la cuenta.
- Caja física para gastos pequeños del día.

### 6.3 Contratos B2B (los más importantes del Molino)

> **El Molino es el nodo donde la Cadena del Pan empieza a sentirse como negocio.**

**Tipo A — Suministro recurrente upstream (granjero → molino):**
- *"La Granja del Valle suministra al Molino de Pedro 5,000 kg de trigo blando calidad >= A semanal a 0.45$/kg, durante 3 meses."*
- Firmado vía Tablet > Notas & Contratos. Pagos automáticos en Banca.

**Tipo B — Suministro recurrente downstream (molino → panadería):**
- *"El Molino de Pedro suministra a la Panadería del Sur 800 kg de harina blanca de fuerza calidad A semanal a 1.20$/kg, durante 3 meses."*

**Tipo C — Compra puntual:**
- *"La Cooperativa Norte compra 2,000 kg de harina integral al Molino de Pedro, recogida 25/04, pago contado."*

**Tipo D — Exclusividad:**
- *"El Molino de Pedro produce harina exclusiva premium 'Sello Pedro' solo para la Panadería Lucía Foods. Pago premium 30% sobre tarifa estándar."*

**Tipo E — Calidad mínima garantizada:**
- *"Toda harina entregada a la Panadería del Sur debe tener calidad >= A o el lote se devuelve."*

### 6.4 Reputación cross-empresa

- Al cumplir contratos sin issues, sube la reputación del Molino.
- Reputación visible en Mercado para que panaderos descubran al Molino.
- Reputación afecta a precio premium aceptado por clientes.

---

## 7. Manager Panel del Molinero — apps Tablet específicas

> **La app Manager Panel** es la misma del ecosistema (Tablet §7), pero con su instancia "Molinero" registrada al instalar el resource del Molino. **5 áreas, mismo lenguaje visual** que la del Granjero.

### 7.1 Vista Operations — el corazón

**Lo que muestra:**

```
┌─────────────────────────────────────────────────────┐
│ Operations — Molino de Pedro                       │
├─────────────────────────────────────────────────────┤
│ ESTADO ACTUAL                                       │
│ ● Molino: OPERANDO  (calibración: 0.18mm, vel 80%) │
│ ● Producción hora: 65 kg/h  Calidad media: A       │
│ ● Humedad amb: 52%  ✓                                │
│                                                     │
│ SILOS ENTRADA                                       │
│ ┌──────────┬────────┬──────────┐                   │
│ │ S1 Trigo │ 1,840kg│ ████████░ 92% │             │
│ │ S2 Centeno│ 0    │ ░░░░░░░░ 0%  │             │
│ │ S3 Maíz  │ 600kg │ ████░░░░░ 30% │             │
│ └──────────┴────────┴──────────┘                   │
│                                                     │
│ SILOS INTERMEDIOS                                   │
│ Harina blanca:  340kg  Sémola: 80kg  Salvado: 60kg│
│                                                     │
│ ALMACÉN HARINA (PALETAS)                           │
│ Fuerza A: 12 paletas │ Panadera A: 8 │ Integral B:5│
│                                                     │
│ TAREAS DEL DÍA                                      │
│ ☑ Recepción 06:00 — Granja Valle (5,000kg trigo) ✓ │
│ ☐ Despacho 14:00 — Panadería Sur (800kg fuerza)   │
│ ☐ Limpieza programada molino (cada 7 días)         │
│                                                     │
│ ALERTAS                                             │
│ ⚠ Calibración rodillos pasada 30d — recalibrar     │
└─────────────────────────────────────────────────────┘
```

**Operaciones rápidas:**
- Arrancar / parar molino.
- Ajustar calibración (slider 0.05-0.5mm).
- Ajustar velocidad (slider 50-100%).
- Ver detalle de cada silo (tap → estadísticas).

### 7.2 Vista Personnel

Idéntica conceptualmente a Granja §12.2:
- Lista de empleados con foto, rol, productividad, salario.
- Gráfico de productividad por turno.
- Botones contratar / despedir / ascender / asignar tarea.
- **Tareas específicas del Molino:** "Calibrar molino", "Limpiar cribadora", "Etiquetar 50 sacos", "Cargar paleta a camión X".

### 7.3 Vista Finance

- Ingresos (ventas a panaderías + venta directa retail si la hay).
- Gastos (compra de grano + nóminas + electricidad + mantenimiento + repuestos).
- Beneficio mes / trimestre / año.
- **Coste por kg de harina producido** (KPI clave del molinero — muestra si calibrar lento + premium es realmente rentable vs calibrar rápido).
- Gráficos en vivo.

### 7.4 Vista Inventory

- Estado de los 3 silos de entrada (kg + tipo + calidad + antigüedad).
- Estado de los silos intermedios.
- Estado del almacén de harina (paletas + calidad + fecha molienda + lote).
- **Alertas:** harina con >30 días en almacén → vender con descuento o destinar a downstream menos exigente (alimentación animal futuro).
- **Trazabilidad** completa: tap en una paleta → ver el batch_id de grano de origen, parcela, granjero.

### 7.5 Vista Strategic

- **Pedidos abiertos / propuestas recibidas:** ver cuáles cumplir, cuáles rechazar.
- **Calendario de entregas** próximas semanas.
- **Sugerencias** de producción según pedidos pendientes ("Tienes 800kg pendientes de fuerza para mañana — el silo S1 tiene 1,840kg de trigo blando, suficiente").
- **Comparativa con otros molinos del mapa** (RP — datos abiertos del Mercado): tu calidad media vs media del mercado, tu precio vs media.
- **Predicción** de necesidad de grano según pedidos firmados.

### 7.6 Wooow del Manager Panel (específicos del Molino)

- **Vista en vivo del molino:** un mini-stream del estado del molino (rodillos girando, indicadores de calidad y velocidad). Realmente refleja el mundo físico.
- **Trazabilidad clickable:** desde la paleta → al lote → al campo → al granjero. Toda la cadena visible.
- **Optimizador:** botón "Optimizar producción" sugiere combinación calibración/velocidad para maximizar beneficio según pedidos pendientes.

---

## 8. Mercado y contratos — los pilares del B2B

> El Molino vive de relaciones B2B. Sus 2 conexiones críticas:
>
> - **Upstream:** Granjeros (le venden grano).
> - **Downstream:** Panaderías (le compran harina).

### 8.1 Encontrar granjeros (upstream)

- Tablet > Mercado > Productos > filtro "Trigo blando".
- Lista de granjeros activos en el servidor con su reputación + precio + calidad típica.
- Tap en un granjero → ver historial + ofertas activas → proponer contrato Tipo A (suministro recurrente) o comprar lote puntual.
- **Wooow:** el molinero puede **visitar físicamente** la granja antes de firmar — RP valoración de proveedor.

### 8.2 Encontrar panaderías (downstream)

- Mismo flujo, en sentido inverso: el molino publica oferta de harina o responde a peticiones de panaderías.
- Las panaderías premium (alta reputación) pagan más → incentivo para producir calidad alta.

### 8.3 Logística

- El molino raramente transporta. Lo normal:
  - **Granjero entrega** al molino (camión propio o transportista contratado).
  - **Panadero recoge** del molino (idem).
- **Servicio de logística Admirals** (Tablet > Logística): si ninguna parte tiene transporte, contratar transportista jugador.

### 8.4 Tarifas tipo (referencia, ajustables por servidor)

| Concepto | Precio |
|---|---|
| Trigo blando común (granja → molino) | ~0.40$/kg |
| Trigo blando premium | ~0.55$/kg |
| Trigo duro (semolas) | ~0.50$/kg |
| Harina blanca panadera (molino → panadería) | ~1.10$/kg |
| Harina blanca de fuerza | ~1.30$/kg |
| Harina integral | ~1.20$/kg |
| Sémola | ~1.40$/kg |
| Salvado (subproducto) | ~0.30$/kg |

**Margen típico del molino:** ~30-40% bruto, antes de gastos.

---

## 9. Edge cases del Molino

### 9.1 Grano rechazado en recepción

- Empleado báscula detecta humedad excesiva o impurezas.
- Tablet permite **rechazar la entrega** con motivo.
- Notificación al granjero.
- Camión devuelve el grano (RP — coste de logística asumido por granjero por defecto).
- Reputación del granjero baja levemente.

### 9.2 Avería del molino

- Eventos aleatorios o por falta de mantenimiento:
  - Rodillo se desgasta (calidad baja gradualmente — alerta).
  - Cribadora se rompe (cribado sin separación correcta).
  - Soplador del transporte neumático falla (no se puede cargar silo).
- **Reparación:**
  - Empleado de mantenimiento puede arreglar (tarea con duración + repuesto).
  - O contratar al **Mecánico Admirals** (vertical futura) para reparación rápida.
- **Coste:** repuestos + tiempo perdido.

### 9.3 Mezcla cruzada de tipos (contaminación)

- Si el molino procesa centeno y luego trigo sin **limpieza intermedia adecuada**, la harina de trigo lleva trazas de centeno.
- **Síntoma:** calidad cae a B / C aunque el grano sea premium.
- **Notificación:** "Posible contaminación cruzada — limpiar máquina antes del siguiente lote."

### 9.4 Stock de harina envejecido

- Harina con >30 días en almacén pierde frescura.
- Se puede vender:
  - A precio reducido a panaderías que aceptan B/C.
  - A canal alimentación animal (futuro).
- O **descartar** — pérdida pura.

### 9.5 Empleados sin tareas

- Si el molino no tiene grano para procesar, los empleados quedan ociosos.
- Manager Panel sugiere: "5 empleados sin tarea las próximas 2h. ¿Reducir turnos? ¿Asignar mantenimiento?".
- **Buena gestión:** evitar pagar nóminas por tiempo muerto.

### 9.6 Pedido grande que excede capacidad

- Panadería pide 5,000kg en 24h. Molino procesa máximo 3,000kg/24h.
- Manager Panel **avisa** al firmar contrato: "Capacidad insuficiente — propones plazo más largo o reducción".
- Opciones: rechazar, contraproponer plazo, subcontratar a otro molino (oleada 2-3).

### 9.7 Quiebra del molino

- Mismo modelo Granja §15: cuenta empresarial < 0 sostenido → notificación.
- Si no recupera → administración NPC → liquidación o recuperación vía notaría.
- **Activos** (silos llenos, paletas) se subastan.

---

## 10. Hooks a otras verticales

- **Cuando salga la vertical Pasta Italiana** (futuro): el molino vende sémola directamente. Sinergia.
- **Cuando salga Alimentación Animal** (futuro): el salvado tiene canal real de venta.
- **Cuando salga Cervecería** (futuro): el molino muele cebada malteada para cervecería. Nueva línea.
- **Cuando salga el Mecánico Admirals**: reparaciones del molino se subcontratan.
- **Cuando salga la Cooperativa Mayorista** (Granja oleada 3): nodo intermedio que conecta con muchos molinos.

---

## 11. Assets 3D — briefing equipo 3D

> **Aplicando regla Bible §13.4**: el 3D entrega el modelo funcional con la idea wooow CORE. El código añade el shimmer.

### 11.1 MLO completo

| ID | Asset | Origen | Prioridad | Oleada |
|---|---|---|---|---|
| MLO-MILL-01 | **MLO Molino completo** (estructura exterior + interior con todas las zonas Z1-Z12) | Custom propio | Alta | 1 |

### 11.2 Maquinaria (los 17 ítems del catálogo §5.1)

Toda la lista §5.1 se delega al equipo 3D. Resumen:

- **Críticos (alta prioridad, oleada 1):** MQ-01, MQ-02, MQ-03 (silos), MQ-05, MQ-06 ⭐, MQ-07, MQ-08, MQ-09, MQ-10, MQ-12, MQ-15 (saco icónico), MQ-16.
- **Secundarios (oleada 1):** MQ-04, MQ-11, MQ-14, MQ-17.
- **Reuso GTA V:** MQ-13 (forklift) — solo livery propia.

Total assets de máquinas: **~16 modelos custom + 1 livery GTA V**. Razonable para oleada 1.

### 11.3 Props auxiliares y decorativos

| ID | Asset | Origen | Prioridad |
|---|---|---|---|
| PRP-MILL-01 | Tarjeta báscula impresa | Custom propio | Media |
| PRP-MILL-02 | Muestrario de harinas (tubos cristal — decoración despacho) | Custom propio | Baja |
| PRP-MILL-03 | Cartel "MOLINO ADMIRALS" exterior | Custom propio | Alta |
| PRP-MILL-04 | Mono de trabajo del molinero (uniforme) | Custom propio | Media |
| PRP-MILL-05 | Delantal blanco con logo bordado | Custom propio | Media |
| PRP-MILL-06 | Mascarilla anti-polvo del operario | Custom propio | Baja |

### 11.4 Lo que NO se pide al 3D

> **Recordatorio Bible §13.4:**
>
> NO al equipo 3D:
> - Polvo volumétrico flotando (CÓDIGO).
> - Rayos de luz iluminando polvo (CÓDIGO + LIGHTING).
> - Sonido del molino (AUDIO).
> - Animación de saco etiquetándose (CÓDIGO renderiza la etiqueta).
> - Estado de calidad reflejado en el saco (CÓDIGO actualiza).
> - Vibración sutil de la estructura cuando opera (CÓDIGO con shaders).
> - Iluminación cálida de la sala (LIGHTING + CÓDIGO).

Total contenido para el 3D: **~17 modelos máquinas + 1 MLO + 6 props auxiliares = <25 assets para oleada 1.** Coherente con regla "no sobrecargar al 3D".

---

## 12. Animaciones requeridas

### 12.1 Animaciones del personaje

- Pesar camión (subir, parar, esperar, bajar — anim de conductor).
- Inspección visual del grano (camionero abre compuerta → empleado mete pala manual + observa).
- Operar panel de control molino (anim de palanca + lectura de pantalla).
- Calibrar molino (girar volante de calibración con esfuerzo).
- Colocar saco vacío bajo dispensador.
- Pulsar botón de llenado.
- Retirar saco lleno (anim de carga, peso visible).
- Cerrar saco con grapadora industrial.
- Cargar saco sobre paleta.
- Conducir carretilla elevadora (anim ya GTA V).
- Limpiar cribadora con cepillo manual (RP).
- Inspeccionar silo subiendo escalera externa.
- Firmar albarán en Tablet con cliente cara a cara.

### 12.2 Animaciones de la maquinaria (rigs del 3D)

- Rodillos del molino girando (4 pares × 2 rodillos = 8 elementos animables).
- Cribadora oscilante.
- Cribas vibratorias de la limpieza.
- Cinta transportadora moviéndose.
- Boquilla del dispensador bajando/subiendo (hidráulica).
- Compuertas de silos abriéndose.
- Carretilla elevadora (elevación brazos — GTA V nativo).

### 12.3 Animaciones internas de UI / Manager Panel (CÓDIGO)

> Frontend React + Framer Motion, no equipo 3D.

- Selector de calibración con feedback visual de "óptimo / subóptimo".
- Gráfico de producción en vivo subiendo / bajando.
- Indicador de calidad cambiando de color en tiempo real.
- Animación de paleta llegando al almacén.
- Trazabilidad: animación de "viaje" del grano de origen a producto final cuando se hace tap.

---

## 13. Sonidos requeridos

### 13.1 Sonidos del proceso productivo (firma sonora del nodo)

- **Soplador de transporte neumático** (loop de motor + aire).
- **Grano cayendo en silo metálico** (loop con eco).
- **Vibración cribas de limpieza** (buzz + grano sobre metal).
- **Motor del molino** ⭐ (firma sonora, motor industrial grande).
- **Rodillos triturando grano** ⭐ (chirrido continuo característico).
- **Cribadora oscilante** (ruido distinto al molino, frecuencia diferente).
- **Cinta transportadora** (loop suave).
- **Dispensador llenando saco** (flujo de harina + zumbido del dispensador).
- **Grapadora industrial cerrando saco** (staccato metálico).
- **Etiquetadora imprimiendo** (motor pequeño + click).

### 13.2 Sonidos puntuales

- Báscula bip al pesar.
- Camión descargando (compuerta hidráulica).
- Carretilla elevadora (GTA V nativo).
- Saco golpeando paleta al cargar.
- Sello del molinero al firmar albarán.

### 13.3 Sonidos ambiente del MLO

- Polvo de harina en aire (sutil — casi inaudible pero presente).
- Eco de la nave industrial (reverberación característica).
- Murmullo de operarios trabajando.

---

## 14. Anti-patrones específicos del Molino + Roadmap

### 14.1 Anti-patrones (recordatorio)

- ❌ Menú "transformar grano en harina" sin proceso físico.
- ❌ Maquinaria estática sin animación.
- ❌ Output sin trazabilidad upstream.
- ❌ Saco genérico sin etiqueta dinámica.
- ❌ Polvo de harina invisible (sin partículas).
- ❌ Sin diferenciación de tipos de harina.
- ❌ Calidad que se pierde sin causa identificable.
- ❌ Sin firma sonora del molino (sin la firma sonora, no es un molino).

### 14.2 Roadmap de oleadas

#### Oleada 1 — Lanzamiento

- MLO completo con todas las zonas Z1-Z12.
- Maquinaria oleada 1 (16 modelos críticos).
- Procesamiento de **trigo blando + trigo duro** → **5 productos base** (fuerza, panadera, integral, sémola, salvado).
- Calidad heredada + factor proceso.
- Saco icónico con etiqueta dinámica + trazabilidad.
- Sistema de empresa (4 roles principales: Owner, Manager, Maquinista, Operario ensacador).
- Manager Panel del Molinero (5 vistas).
- Contratos B2B Tipos A-E.
- Edge cases 9.1-9.7 cubiertos.
- Wooow polvo + iluminación cálida + firma sonora.

#### Oleada 2 — Update gratis tras 2-3 meses

- **Centeno + avena** como nuevos inputs → **harinas correspondientes**.
- **Mezclas custom** (recetas configurables del molinero).
- **Sistema de averías + repuestos** ampliado.
- **Auditoría de trazabilidad** (panaderos pueden auditar el origen RP).
- **Subcontratación** entre molinos (un molino satura → reasigna a otro).

#### Oleada 3 — Update tras 6 meses

- **Maíz + cebada malteada** → harinas y maltas.
- **Cooperativa Mayorista de Molinos** (NPC nodo intermedio).
- **Compra/venta del Molino entero** (alineado con Granja oleada 3).
- **Apps adicionales en Tablet:** App "Análisis de calidad" (panel de análisis de grano y harina con gráficos profesionales).
- **Visitas de inspección** (RP — el panadero visita el molino para auditar; mecánica social).

### 14.3 Hooks a verticales futuras

| Cuando salga | Beneficio para el Molino |
|---|---|
| **Pasta Italiana** | Sémola tiene canal premium real |
| **Cervecería** | Nuevo input (cebada malteada) → nueva línea de producto |
| **Alimentación Animal** | Salvado deja de ser subproducto para volverse línea propia |
| **Mecánico Admirals** | Reparaciones se subcontratan, ahorro de tiempo |
| **Distribución Mayorista** | Cooperativas compran lotes grandes con descuento volumen |

---

## 15. Estado del documento

- **Versión:** 1.0 (firmado).
- **Próxima revisión:** evolución según verticales futuras (pasta, alimentación animal).
- **Documentos directamente relacionados:**
  - `01_node_farm.md` v1.1 — proveedor upstream.
  - `02_sonar_tablet.md` v1.0 — Manager Panel del Molinero.
  - `04_node_bakery.md` (próximo) — cliente downstream principal.
- **Documentos derivados pendientes:**
  - `economy/01_economic_model.md` — números reales de tarifas y márgenes ajustables por servidor.
  - `art/01_art_direction.md` — paleta exacta del Molino (industrial + tradicional).
  - `technical/01_architecture.md` — schema de propagación de calidad upstream → downstream.

---

## Resumen ejecutivo del documento (cierre)

El **Molino Admirals** es el segundo nodo de la Cadena del Pan, **el primer cliente B2B real de la Granja**, y la pieza donde el ecosistema empieza a sentirse como un negocio interconectado.

**Pilares cumplidos:**
- ✅ **Pilar 1 (Físico):** todas las 7 etapas son físicas y observables. El proceso del molino es visible desde la calle (silos icónicos), audible en todo el MLO (firma sonora), y tangible en el saco final con su etiqueta dinámica.
- ✅ **Pilar 2 (Cadena):** consume grano de la Granja, produce harina para la Panadería, propaga calidad y trazabilidad upstream→downstream.
- ✅ **Pilar 3 (Detalle):** polvo volumétrico, iluminación cálida, sonido firma del molino, etiqueta del saco con trazabilidad completa.
- ✅ **Pilar 4 (Assets propios):** ~17 máquinas custom + MLO único. Solo forklift reusa GTA V con livery.
- ✅ **Pilar 5 (Tablet):** Manager Panel del Molinero con 5 vistas, contratos B2B firmados digitalmente, trazabilidad clickable.

**Briefing 3D respetado (Bible §13.4):** ~25 assets para oleada 1. El polvo, los shaders, los sonidos, las partículas, la iluminación dinámica — todo eso lo hace el código.

**El Molino es la prueba de que la Cadena del Pan no es marketing, es real.**

---

*"Stone-ground excellence."*
