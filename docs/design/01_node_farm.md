# 🌾 Admirals — Nodo 1: La Granja Admirals

> **Versión:** 1.1
> **Documento padre:** `00_PRODUCT_BIBLE.md` v1.2
> **Estado:** firmado tras revisión del fundador. Cambios v1.1: §14 reestructurado con división de responsabilidades 3D / código / animación / audio (regla global Bible §13.4). §15.0 filosofía de scope 3D añadida. §13.4 robos movido a oleada 2. §20 drones agrícolas expandidos como idea del fundador.

> **Lectura previa obligatoria:** Product Bible §3 (5 Pilares), §7 (Producto), §8 (Primer producto comercial), §13.3 (Arquitectura completa, contenido en oleadas).

---

## 0. Resumen ejecutivo

La **Granja Admirals** es la **plataforma agrícola raíz** del ecosistema. No es solo "el nodo de cereales" — es el origen físico de **todas las materias primas vegetales** del producto, hoy y a futuro.

Es el primer producto comercial del estudio, junto con la Tablet y la Cadena del Pan, y es **la pieza más ambiciosa del lanzamiento**: un MLO único, 10+ campos, invernaderos, flota de maquinaria, sistema agrícola completo con estaciones, calidad propagada, plagas, fertilización, y un sistema de empresa con roles, salarios y contabilidad — todo gestionado desde la Tablet.

Cada decisión de este documento responde a la pregunta: *¿esto provoca el "wooow" en el primer minuto, y mantiene la profundidad en la hora 100?*

---

## 1. Visión y filosofía del nodo

### 1.1 La promesa de la Granja

> *"Cuando un jugador entra por primera vez a la Granja Admirals, ve un imperio agrícola vivo: tractores rodando por campos enormes, aspersores creando arcoíris al amanecer, cosechadoras dejando rastros físicos en el trigo, invernaderos con plantas reales creciendo dentro, una oficina con vista panorámica al valle, y una flota organizada en el granero. Sabe en 10 segundos que esto no es un script — es un mundo."*

### 1.2 Las 4 ideas-fuerza del nodo

1. **El campo es un personaje, no un decorado.** Crece, cambia con las estaciones, recuerda lo que se hizo en él. La parcela que descuidaste el mes pasado rinde menos hoy.
2. **Diversidad agrícola = diversidad de gameplay.** Cosechar trigo no se siente igual que recoger lechuga. Cada cultivo tiene su ritmo, sus herramientas, su animación, su sonido.
3. **El imperio es escalable.** Un jugador solo lleva 2 campos. Un equipo de 5 lleva 10. La granja no obliga a ser muchos — premia serlo.
4. **La gestión es un placer, no una carga.** El Manager Panel de la Tablet convierte la administración en una experiencia satisfactoria, casi adictiva, no en un menú aburrido.

### 1.3 Lo que la Granja NO es

- **No es un farming script.** Los farming scripts son loops cerrados: vas, recoges, vendes, repites. La Granja es una empresa con activos, empleados, cuentas, decisiones estratégicas.
- **No es una simulación agrícola hardcore.** No reproducimos *Farming Simulator*. Tomamos su realismo visual y lo adaptamos al ritmo de un servidor de RP.
- **No es un MLO con jobs encima.** Es un sistema integrado donde el espacio físico, los activos, el calendario y la economía son una sola cosa.

---

## 2. Escala y ubicación

### 2.1 Escala (decisión locked)

**Imperio agrícola.** No granja casera, no parcela íntima.

| Componente | Cantidad MVP |
|---|---|
| Campos extensivos (cereales) | **6** (4 grandes + 2 medianos) |
| Parcelas hortícolas (vegetables) | **4** (organizadas en eras/surcos) |
| Invernaderos | **2** (uno tunel + uno industrial de cristal) |
| Silos de grano | **3** (visualmente prominentes) |
| Cámaras frigoríficas | **1** (almacén de perecederos) |
| Almacén seco (tubérculos/bulbos) | **1** |
| Garaje/granero de maquinaria | **1** (con capacidad ~12 vehículos + props) |
| Casa principal | **1** |
| Oficina ejecutiva | **1** |
| Vestuario empleados | **1** |
| Zona de carga | **1** (acceso de camiones, montacargas, palets) |

> **Total:** 12+ campos productivos + 8+ edificaciones funcionales + flota completa = **el MLO + outdoor más ambicioso del primer producto**.

### 2.2 Ubicación en el mapa

**Decisión:** ubicación canónica en **Grapeseed**, con extensión opcional a Paleto Bay y Sandy Shores configurables por el servidor.

- **Grapeseed (canónica):** zona agrícola natural de GTA V. La granja prefab única ocupa una parcela grande al norte de la población, con vista a las montañas. Coordenadas exactas a definir tras tour del mapa con el equipo 3D.
- **Paleto Bay (configurable):** alternativa más fría/húmeda. Otra estética visual.
- **Sandy Shores (configurable):** alternativa árida/desértica. Cultivos limitados (los desiertos no rinden cereales — esto se respeta).

> **Importante:** la granja prefab es **única e identificable** (un servidor que la usa la reconoce al instante). No es un MLO genérico replicable infinitas veces. Si un servidor quiere varias granjas, puede colocarla en zonas distintas, pero **es siempre la misma granja**, no granjas distintas. Esto refuerza la marca y reduce el coste de producción 3D.

### 2.3 Coexistencia con el mapa nativo

- **Respeto a los assets nativos:** si Rockstar puso un campo en Grapeseed, lo aprovechamos como referencia visual y decorativo. Pero los campos productivos son **nuestros**, con colisiones, props y shaders propios.
- **Cero choque con MLOs comunes:** la Granja Admirals está diseñada para no pisar otras zonas habitualmente usadas por servidores RP (Sandy police, Paleto sheriff, etc.).

---

## 3. Layout del MLO (anatomía espacial)

El MLO de la Granja se divide en **3 zonas** físicamente diferenciadas. El jugador percibe la diferencia al cruzar de una a otra (luz, sonido ambiente, props).

### 3.1 Zona de habitación y mando (la "casa")

Edificio central de **2 plantas**, estética rancho californiano premium (madera oscura tratada, piedra en cimientos, tejas, porche con mecedoras).

**Planta baja:**
- **Vestíbulo** con perchero, paragüero, mapa enmarcado de la propiedad.
- **Salón social** con chimenea funcional (humo del tubo en exterior), sofás, librería, decantador de whisky (decorativo). Espacio para reuniones de RP entre socios.
- **Cocina rural** funcional (los empleados pueden comer aquí — futuro hook con sistema de comida).
- **Aseo** (porque el detalle se nota).

**Planta alta:**
- **Despacho del dueño** — escritorio de roble, monitor con la Tablet acoplada (animación de docking — wooow detail), mapa estratégico de la finca en pared, archivadores con contratos físicos.
- **Dormitorio principal** del dueño (futuro hook con sistema de housing/spawn).
- **Sala de juntas pequeña** — mesa para 6, donde se firman contratos importantes con NPCs o jugadores.

**Entrada de la finca:** puerta automática con sensor (los empleados con tarjeta entran solos — animación de barrera levantándose).

### 3.2 Zona operativa (donde se trabaja)

Fuera de la casa, organizada en cuadrícula funcional:

- **Granero/Garaje de maquinaria** — nave grande con luz cenital. Capacidad para tractor grande, tractor pequeño, cosechadora, sembradora, fertilizadora, fumigadora, cisterna, montacargas, 2 camiones. Tablero de herramientas en pared (no decorativo — interactivo). Banco de mecánico (donde se hacen las reparaciones in situ — link al sistema de mantenimiento). Dispensador de combustible privado (no es la gasolinera del mapa — la granja es autosuficiente).
- **Vestuario empleados** — taquillas con números (cada empleado tiene la suya). Aquí se ficha la entrada (wooow detail: tarjeta física que se pasa por lector, suena el bip, queda registrado en la Tablet del gerente).
- **Almacén de semillas y suministros** — estanterías con sacos etiquetados de cada cultivo, palets con fertilizante, garrafas de fitosanitarios. Visualmente ordenado, casi de inventario militar.
- **Zona de carga** — explanada de hormigón con marcas viales pintadas (zona de espera, zona de carga, zona de salida). Aquí maniobran los camiones de transportistas externos. Dos rampas de carga + un puente-grúa para palets pesados.

### 3.3 Zona productiva (donde crece la materia prima)

La **explanada agrícola** que rodea la zona operativa:

- **6 campos extensivos** para cereales — cada uno >=80×80m. Visualmente impresionantes desde arriba (drone shot natural).
- **4 parcelas hortícolas** — más pequeñas (~30×30m), divididas en eras con caminos entre ellas. Aquí trabaja la gente a pie con carros y herramientas manuales.
- **2 invernaderos** — contiguos, con accesos y climas distintos:
  - **Invernadero túnel** (común): plástico, estructura de arcos, ventilación natural. Para hortalizas robustas (pepino, calabacín, lechuga si fuera de temporada).
  - **Invernadero industrial cristal** (premium): paneles de vidrio, automatización, sistema de riego por goteo, control de clima. Para tomate premium, pimiento, aromáticas. Visualmente espectacular sobre todo de noche (luz interior dorada filtrándose).
- **Silos de grano** — 3 unidades cilíndricas metálicas con escalera lateral, de 12m de altura, **con indicador físico de nivel exterior** (línea de pintura que se rellena con un shader según contenido — wooow detail).
- **Estanque/depósito de agua** funcional — alimenta el sistema de riego. Es físico, tiene agua animada, los aspersores beben de aquí. Si se vacía, no hay riego (causa-efecto).

### 3.4 Vista cenital (mapa mental)

```
                    [ENTRADA + portón automático]
                              │
       ┌──────────────────────┼──────────────────────┐
       │                      │                      │
   [Campo cereal 1]       [CASA 2 plantas]      [Campo cereal 2]
   [Campo cereal 3]            ║                 [Campo cereal 4]
                          ┌────╨────┐
                          │ Oficina │
                          │ + Patio │
                          └────┬────┘
                               │
   ┌─────────┬─────────┬───────┴────────┬─────────┬────────┐
   │ Granero │ Vestua- │  Almacén       │ Zona de │ Silos  │
   │ + Garage│ rio     │  semillas      │ carga   │ (x3)   │
   └─────────┴─────────┴────────────────┴─────────┴────────┘
                               │
   ┌──────────┬─────────┬──────┴──────┬──────────┬─────────┐
   │ Parcela  │ Parcela │ Invernadero │ Parcela  │ Parcela │
   │ hortí. 1 │ horti.2 │  túnel +    │ hortí. 3 │ hortí.4 │
   │          │         │  cristal    │          │         │
   └──────────┴─────────┴─────────────┴──────────┴─────────┘
                  [Estanque agua + Campo cereal 5/6]
```

Layout final lo ajustará el director artístico — esto es la guía conceptual.

---

## 4. Tierras de cultivo (sistema de tipos de terreno)

### 4.1 Tipos de terreno (4 tipos)

Cada tipo soporta un subset de cultivos y tiene mecánicas distintas.

| Tipo | Visual | Cultivos soportados | Maquinaria | Tamaño típico |
|---|---|---|---|---|
| **Campo extensivo** | Tierra arada en hileras grandes, 80×80m+ | Trigo, cebada, maíz, centeno, avena, girasol, caña | Tractor + arado + sembradora + cosechadora | Grande |
| **Parcela hortícola** | Eras alineadas con caminos, 30×30m | Tomate, pimiento, pepino, lechuga, col, espinaca, cebolla, ajo, mostaza | Manual + tractor pequeño + carros | Mediano |
| **Campo de tubérculos** | Surcos profundos, tierra removida | Patata, futuras raíces | Tractor + sacador de patatas | Mediano-grande |
| **Invernadero** | Indoor, eras controladas | Cualquier hortaliza (con bonus de calidad y sin restricción estacional) | Manual + sistema de riego automatizado | Pequeño-mediano |

### 4.2 Calidad del terreno

Cada parcela tiene un atributo `land_quality` (1-5):

- Heredada de la posición en el mapa (terrenos premium del MLO Grapeseed son 4-5; extensiones a Sandy Shores serían 1-2).
- **Se degrada con uso intensivo sin rotación** (si plantas trigo 5 veces seguidas, baja).
- **Se regenera con descanso** (parcela en barbecho 1 ciclo recupera 1 punto).
- **Se mejora con compost/estiércol** (sistema futuro — hook arquitectónico ya).

Calidad del terreno **multiplica** el rendimiento y la calidad final del cultivo. Es la primera variable de la cadena de calidad (ver §7).

### 4.3 Rotación y barbecho

- El Manager Panel sugiere rotaciones óptimas (alfalfa después de cereal, etc.).
- Marcar una parcela en "barbecho" la deja descansar visualmente (hierba salvaje, flores silvestres — wooow detail) durante un ciclo.
- Sistema **opcional pero premiado**: el jugador hardcore que rota parcelas obtiene mejor calidad sostenida.

---

## 5. Catálogo de cultivos (oleada 1 detallada)

> **Recordatorio Bible §8.3:** la Granja soporta arquitectónicamente todos los cultivos. La oleada 1 entrega los siguientes **completamente jugables**. Las oleadas 2-3 añaden los demás sin tocar código.

### 5.1 Cereales (oleada 1)

| Cultivo | Tipo terreno | Estación ideal | Ciclo (config default) | Maquinaria cosecha | Output |
|---|---|---|---|---|---|
| **Trigo** | Extensivo | Primavera-Verano | 30 min | Cosechadora | Grano de trigo (saco 50kg) |
| **Cebada** | Extensivo | Primavera-Verano | 28 min | Cosechadora | Grano de cebada (saco 50kg) |
| **Maíz** | Extensivo | Verano | 35 min | Cosechadora con cabezal de maíz | Mazorca de maíz (caja 25kg) |

### 5.2 Hortalizas frutales (oleada 1)

| Cultivo | Tipo terreno | Estación ideal | Ciclo | Cosecha | Output |
|---|---|---|---|---|---|
| **Tomate** | Parcela / Invernadero | Verano (parcela) / cualquiera (inv.) | 25 min | Manual (cesto) | Caja de tomates (15kg) |
| **Pimiento** | Parcela / Invernadero | Verano | 28 min | Manual (cesto) | Caja de pimientos (12kg) |
| **Pepino** | Parcela / Invernadero | Verano | 22 min | Manual (cesto) | Caja de pepinos (15kg) |

### 5.3 Hojas (oleada 1)

| Cultivo | Tipo terreno | Estación ideal | Ciclo | Cosecha | Output |
|---|---|---|---|---|---|
| **Lechuga** | Parcela / Invernadero | Primavera-Otoño | 18 min | Manual (cuchillo, animación de cortar) | Caja de lechugas (8kg) |
| **Col** | Parcela | Otoño-Invierno | 30 min | Manual | Caja de coles (20kg) |
| **Espinaca** | Parcela | Primavera-Otoño | 20 min | Manual | Caja de espinacas (6kg) |

### 5.4 Bulbos (oleada 1)

| Cultivo | Tipo terreno | Estación ideal | Ciclo | Cosecha | Output |
|---|---|---|---|---|---|
| **Cebolla** | Parcela | Verano | 32 min | Tractor pequeño + manual (recogida) | Saco de cebollas (25kg) |
| **Ajo** | Parcela | Verano | 30 min | Manual (recogida) | Trenza de ajos (5kg) |

### 5.5 Tubérculos (oleada 1)

| Cultivo | Tipo terreno | Estación ideal | Ciclo | Cosecha | Output |
|---|---|---|---|---|---|
| **Patata** | Tubérculos | Primavera-Otoño | 33 min | Sacador de patatas (tractor) | Saco de patatas (30kg) |

### 5.6 Variedades común vs premium

Cada cultivo tiene 2 variantes:

- **Común:** semilla barata, ciclo estándar, calidad base 1-3 (según condiciones).
- **Premium:** semilla 3-4× más cara, ciclo +20%, **calidad base 3-5**, demanda específica en restaurantes/panaderías top.

Ejemplos:
- *Trigo común* vs *Trigo artesano* (panes premium lo demandan).
- *Tomate común* vs *Tomate San Marzano* (pizzerías premium lo demandan).
- *Patata común* vs *Patata gourmet* (restaurantes top).

La diferencia visible: las premium tienen **modelo 3D ligeramente distinto** (más vibrante, más grande, mejor textura) y un icono dorado en la Tablet.

### 5.7 Cultivos de oleadas posteriores (referencia)

- **Oleada 2:** centeno, avena, girasol, caña de azúcar.
- **Oleada 3:** mostaza, especias variadas (orégano, albahaca, romero, tomillo) — todos en invernadero/eras pequeñas.

Arquitectónicamente listos desde el día 1 (ver `docs/technical/01_architecture.md` cuando exista).

---

## 6. Sistema de estaciones

### 6.1 Filosofía

Las estaciones convierten la Granja en una empresa real, no un loop infinito plano. Sin estaciones, plantar es un click. Con estaciones, **cada decisión importa**: qué planto, cuándo, dónde. Es el delta más grande entre Admirals y "un farming script más".

### 6.2 Las 4 estaciones

| Estación | Visual | Cultivos óptimos | Cultivos penalizados |
|---|---|---|---|
| **Primavera** | Hierba verde brillante, flores silvestres en bordes, rocío matinal | Trigo, cebada, lechuga, espinaca, ajo, cebolla | Maíz (-30%), tomate (no madura) |
| **Verano** | Hierba seca dorada, *heat shimmer* en horizonte, días largos | Maíz, tomate, pimiento, pepino, girasol, cebolla, ajo (cosecha) | Lechuga (-40%), espinaca |
| **Otoño** | Hojas amarillas/rojas, niebla matinal, viento racheado | Cosecha cereales, col, espinaca tardía, patata | Tomate ya no madura |
| **Invierno** | Suelo escarchado (Grapeseed) o nevado (Paleto), silencio | Solo invernaderos productivos. Campos exteriores en barbecho natural | Cualquier cultivo de exterior fracasa |

### 6.3 Configuración temporal

| Modo | Duración / estación | Servidor objetivo |
|---|---|---|
| **Sprint** | 1-2 h reales | Casual, sesiones cortas |
| **Default Admirals** | **6 h reales** (1 día real ≈ 1 año agrícola) | Equilibrio recomendado |
| **Realista** | 12-24 h | RP serio, planificación por días |
| **Hardcore** | 3 días | Agricultura seria como en realidad |

Reloj global del servidor sincronizado, visible desde la Tablet.

### 6.4 Mecánica del impacto estacional

- **Rendimiento:** ±30-50% según matching.
- **Calidad final:** ±2 niveles (variable `season_match` en §7).
- **Tiempo de ciclo:** ±20% (verano acelera tomate, otoño retrasa).
- **Riesgo de plagas:** + en estaciones cálido-húmedas según cultivo.
- **Visual del terreno:** los campos cambian según **stage del ciclo + estación combinados** (campo arado en primavera ≠ campo arado en invierno).

### 6.5 Invernaderos: la excepción

- **Ignoran las estaciones.** Producen siempre.
- **Coste:** consumen energía continua (factura mensual). Sin pago, los cultivos dentro mueren progresivamente.
- **Invernadero industrial:** sin penalización de calidad nunca, siempre nivel 4-5.
- **Invernadero túnel:** rinde 3-4 (decente, no premium). Opción intermedia.

Decisión económica real: ¿pago invernadero caro para tomate premium todo el año, o juego con la estación?

### 6.6 Eventos meteorológicos (capa estocástica)

| Evento | Frecuencia | Efecto |
|---|---|---|
| **Lluvia natural** | Frecuente primavera/otoño | Sustituye un riego, coste 0. Pero si cae durante cosecha: daño +20% al grano expuesto |
| **Sequía** | Verano sin lluvia | Riego +50% obligatorio, push notification |
| **Helada** | Primavera tardía, raro | Daño a brotes -15%. Mitigación: cubrir con malla (acción manual, animación de desplegar — wooow) |
| **Tormenta** | Raro, otoño | Daño a infraestructura: invernadero túnel se rompe (reparable). Notificación 30 min antes |
| **Plaga estacional** | Verano húmedo | +30% probabilidad de plagas en pepino y tomate |
| **Granizo** | Muy raro | Daño 30% a cultivos altos. Cobertura: malla anti-granizo premium |
| **Bonus de cosecha** | ~5% aleatorio | +5 calidad inesperada (mística) |

Todos configurables on/off por servidor. Default: todos activos.

---

## 7. Sistema de calidad propagada

### 7.1 Filosofía: la calidad viaja

> Una espiga de trigo no nace siendo "calidad B". **Llega a calidad B porque el granjero tomó decisiones que la llevaron ahí.** Y esa B viaja: la harina molida será B, el pan horneado será B (o C si el panadero falla también), el cliente paga precio B.

Esto distingue Admirals: la calidad no es un atributo aleatorio del item — **es la huella de las decisiones del jugador**, propagada por toda la cadena.

### 7.2 Variables de la cadena de calidad (`quality_score`, 0-100)

Para cada cosecha individual:

| Variable | Peso | Cómo se obtiene |
|---|---|---|
| `land_quality` | 15% | Atributo del terreno (1-5) → 3-15 puntos |
| `seed_grade` | 15% | Común=base / Premium=+15 |
| `season_match` | 15% | Estación ideal=+15 / off=-15 / fuerte penalización=-30 |
| `irrigation_score` | 15% | Riegos en ventana óptima durante el ciclo |
| `fertilization_score` | 12% | Aplicaciones de fertilizante en momentos correctos |
| `plague_protection` | 10% | Tratamientos cuando aplica (selectivo por cultivo) |
| `harvest_timing` | 10% | Cosechado en stage óptimo (ni temprano ni tarde) |
| `weather_events` | 8% | Bonus/malus por eventos sufridos |

Score final → niveles S/A/B/C/D.

### 7.3 Niveles de calidad

| Score | Letra | Visual | Demanda |
|---|---|---|---|
| 90-100 | **S — Premium** | Icono dorado, brillo en Tablet, sello físico dorado en saco/caja | Restaurantes top, panaderías premium, exportación |
| 75-89 | **A — Excelente** | Icono plateado | Mercado general premium |
| 60-74 | **B — Bueno** | Icono azul | Mercado general |
| 45-59 | **C — Estándar** | Icono blanco | Mercado base, NPC seguro |
| 0-44 | **D — Bajo** | Icono opaco, ligero daño visible en modelo | Solo NPC base, precio mínimo |

### 7.4 Cómo se ve la calidad

- **En Tablet:** icono de color + estrellas en el inventario.
- **En el mundo:** sello físico visible en saco/caja (dorado, plateado, etc. — modelo 3D distinto).
- **En procesado:** la calidad se hereda. Trigo S → harina S. Pero un molino mal mantenido degrada -1 nivel ("calidad de proceso").
- **En venta:** el cliente jugador en una panadería ve la calidad antes de comprar (display físico).

### 7.5 Calidad y precio (regla económica)

- Diferencia entre S y D: **3-4× el precio final**.
- Esto es el incentivo económico real para jugar bien.
- Sin sistema de calidad, los farms scripts colapsan en "spam click cosechar = dinero". Con calidad, hay decisión estratégica continua.

### 7.6 Lote (`batch_id`) — trazabilidad completa

Cada cosecha genera un `batch_id` único. El batch viaja con el item por toda la cadena. Beneficios:

- **Trazabilidad:** un cliente final que come pan con un batch contaminado puede rastrearse al campo origen.
- **Storytelling RP:** "este pan es de la cosecha 2025-Otoño-Marcos, top calidad" → pequeñas etiquetas en producto final.
- **Auditoría:** el dueño de la granja sabe qué batches están donde, en qué estado, cuánto valen.

---

## 8. Ciclo agrícola — etapa por etapa

### 8.1 Diagrama del ciclo completo

```
[Tierra disponible / fallow]
      │
      ▼
  Etapa 1: Preparación (arar, fertilizar base)
      │
      ▼
  Etapa 2: Siembra
      │
      ▼
  Etapa 3-5: Mantenimiento (riego, fertilización, plagas)
      │   └─ Etapa 6: Crecimiento visible (automático)
      ▼
  Etapa 7: Cosecha
      │
      ▼
  Etapa 8: Descarga
      │
      ▼
  Etapa 9: Almacenamiento
      │
      ▼
  [Output: transporte / venta]

[Maquinaria] ──── Etapa 10: Mantenimiento (paralelo, continuo)
```

### 8.2 Etapa 1 — Preparación de la tierra

**Prerequisitos:** parcela en `fallow`, maquinaria adecuada disponible y con combustible.

**Métodos según cultivo:**

| Cultivo | Método | Vehículo | Implemento | Duración |
|---|---|---|---|---|
| Cereales | Arado profundo | Tractor grande | Arado de vertedera | 4-6 min/campo |
| Hortalizas | Cultivado superficial | Tractor pequeño | Cultivador | 2-3 min/parcela |
| Tubérculos | Surcado profundo | Tractor mediano | Surcador | 3-4 min/campo |
| Invernaderos | Manual con azada | A pie | Azada + rastrillo | 3-5 min/era |

**Acción del jugador:**
1. Entra al granero, target en tractor → seleccionar implemento (props físicos colgados de pared).
2. Animación de subir, arrancar, conducir al campo.
3. En el campo: acción "Iniciar arado". Tractor avanza en líneas paralelas (autopilot suave) o conducción manual.
4. Mientras ara: partículas de tierra removida, sonido de motor cargado, polvo por detrás.
5. Al terminar: parcela cambia visualmente a "tierra arada" (textura marrón removida).

**Variables afectadas:**
- Si parcela `compacted` (no arada en N ciclos): preparación +50% tiempo, `land_quality` -1 temporal.
- Aplicar **estiércol/compost** durante preparación (segundo paso opcional con remolque): `land_quality` +1 permanente.

**Wooow detail:** rastros de neumáticos persistentes en la tierra, polvo levantándose, sonido distinto por implemento (arado vs cultivador).

### 8.3 Etapa 2 — Siembra

**Prerequisitos:** parcela `prepared`, sacos de semilla en almacén, sembradora o herramienta manual.

**Métodos:**

| Cultivo | Método | Detalle |
|---|---|---|
| Cereales | Sembradora mecánica | Tractor + sembradora cargada de sacos. Tubos liberan grano en hileras. |
| Maíz | Sembradora de precisión | Distancia regular entre semillas, marca de hilera específica. |
| Hortalizas | Sembradora pequeña O manual | Manual: andar con saco al hombro, gesto de esparcir. |
| Patata | Sembradora de tubérculos | Tractor con sembradora especial; patatas-semilla se entierran. |
| Lechuga / delicadas | Plantel manual | Plantar planteles ya germinados (compra previa NPC vivero o futuro nodo "Vivero"). Animación de agacharse, plantar, agacharse, plantar. |

**Acción del jugador (manual, ejemplo):**
1. Recoge saco del almacén (animación de cargar al hombro — peso real).
2. Va a parcela arada.
3. Activa "Sembrar" — animación de andar mientras esparce con la mano.
4. Cada paso = franja sembrada. Visual: pequeñas marcas verde/marrón.
5. Saco se vacía visualmente (modelo 3D con stages: lleno → medio → casi vacío → vacío).

**Wooow:**
- Semillas visibles cayendo del puño (partícula).
- Saco con stages 3D.
- Si llueve durante siembra, semillas se ven mojadas (textura distinta).

**Variables afectadas:**
- `seed_grade` (común vs premium) se fija en este momento.
- `seeding_quality` (0-100) según cobertura: si jugador siembra bien (cubre todo), 100. Si se salta zonas, bajo. Afecta rendimiento final.

### 8.4 Etapa 3 — Riego

**Prerequisitos:** cultivo sembrado, agua disponible (estanque con nivel), sistema de riego elegido.

**Sistemas de riego:**

| Sistema | Cuándo aplica | Cómo funciona | Coste |
|---|---|---|---|
| **Aspersores fijos** | Campos extensivos | Instalación inicial cara. Activación desde Tablet (app Granja → Riego). Riego autónomo con tiempo configurable. Aspersores giratorios físicos, agua pulverizada, **arcoíris bajo sol** | Inicial alto / mantenimiento bajo |
| **Tractor cisterna** | Cualquier campo, ruta flexible | Tractor + cisterna llenada en estanque. Conducir activando manguera. Manguera con animación física, agua disparada en arco | Sin instalación / requiere combustible y trabajo |
| **Riego por goteo** | Invernaderos | Sistema fijo invisible. Auto-activado. Casi sin coste operativo | Coste medio inicial / casi nada después |
| **Manual con regadera/manguera** | Parcelas pequeñas, plantas individuales | Jugador a pie. Animación lenta pero satisfactoria | Solo tiempo |

**Mecánica:**
- Cada cultivo necesita N riegos (configurable, default 2-4).
- Cada riego tiene **ventana óptima** (no demasiado seguido ni separado).
- Regar en ventana = `irrigation_score` +20. Fuera = +5 o 0. No regar = -30.
- Si llovió, riego se "marca como hecho" automáticamente.

**Wooow details:**
- Aspersores con animación física real (no sprite plano).
- Arcoíris bajo cierta luz solar (shader).
- Tierra cambia de color al recibir agua (más oscura).
- Sonido específico: aspersor mecánico "tch-tch-tch", manguera "shhhh".
- Pájaros se acercan al campo recién regado (fauna scripted).

### 8.5 Etapa 4 — Fertilización

**Prerequisitos:** cultivo en fase media de crecimiento (idealmente), fertilizante en almacén.

**Tipos de fertilizante:**

| Tipo | Precio | Efecto | Compatible |
|---|---|---|---|
| **Estiércol orgánico** | Bajo | +10 score, mejora suelo | Todos |
| **Fertilizante químico estándar** | Medio | +20 score | Todos |
| **Fertilizante específico premium** | Alto | +30 score, sin riesgo de daño | Cultivos premium |
| **Compost casero** (sistema futuro) | Gratis | +15 score | Todos |

**Aplicación:**
- **Fertilizadora (vehículo)** para campos extensivos: tractor + remolque difusor. Gránulos esparcidos visualmente.
- **Manual** (saco al hombro + animación de esparcir) para parcelas pequeñas.
- **Riego mezclado con fertilizante líquido**: en sistemas de riego por goteo de invernadero (programable desde Tablet).

**Riesgo de sobre-fertilización:** 2× la dosis quema el cultivo (-20% rendimiento). Tablet avisa si detecta exceso reciente.

**Wooow:** gránulos volando del difusor del tractor; cultivo cambia ligeramente de tono (verde más intenso) minutos después.

### 8.6 Etapa 5 — Tratamiento de plagas (selectivo)

> Solo aplica a cultivos susceptibles: tomate, pepino, lechuga, col, patata. Cereales y bulbos casi no se tratan.

**Detección:**
- Aleatorio según estación + condiciones (verano húmedo = +probabilidad).
- Campo afectado muestra señal visual (hojas amarillentas, manchas, modelos de bichos).
- **Notificación push en Tablet:** *"⚠️ Plaga detectada: pulgón en parcela hortícola 3. Daño estimado si no se trata: 30%."*

**Aplicación:**
- **Fumigadora** (tractor + tanque pulverizador): pasa por el campo, niebla de pulverización física visible.
- **Mochila pulverizadora manual**: para invernaderos y parcelas pequeñas.
- **Drone fumigador**: oleada futura — anti-feature por ahora.

**Variables:**
- Tratar en primeras 24h in-game de detección: -90% daño.
- Tratar tarde: -50% daño.
- No tratar: pérdida total de calidad y -30 a -60% rendimiento.

**Wooow:** la niebla de pulverización es física, visible desde lejos. El cultivo afectado, al tratarse, transiciona de "enfermo" a "sano" en minutos (lerp de textura).

### 8.7 Etapa 6 — Crecimiento visible (automático)

> **Esta es la pieza más wooow del nodo.** Ningún competidor en FiveM muestra crecimiento físico real de cultivos.

**Sistema:**
Cada cultivo tiene **N stages de crecimiento** (default 5-7). Cada stage = modelo 3D distinto. Transiciones automáticas según tiempo + variables del ciclo.

**Stages del trigo (ejemplo):**

| Stage | Visual | % ciclo |
|---|---|---|
| 0 | Tierra arada vacía | Antes de sembrar |
| 1 | Brotes verdes pequeños esparcidos | 15% |
| 2 | Brotes formados, hojas alargadas | 35% |
| 3 | Trigo joven verde, ~30 cm | 55% |
| 4 | Trigo medio, espigas formándose | 70% |
| 5 | **Trigo dorado maduro, espigas pesadas, se mueve con el viento** | 85-100% |
| 6 | Cosechado: rastrojo en hileras | post-cosecha |

**Stages del tomate:**

| Stage | Visual |
|---|---|
| 0 | Plantel pequeño plantado |
| 1 | Mata mediana |
| 2 | Mata adulta con flores amarillas |
| 3 | Mata con tomates verdes |
| 4 | Mata con tomates rojos maduros |
| 5 | Cosechado (mata sin frutos, lista para retirar) |

**Wooow detail crítico:**
- **Stages 4-5 de cultivos altos** (trigo, maíz, girasol) **se mueven con el viento** (shader de vegetación). Este detalle solo, ya genera el "wooow".
- Transición entre stages: suave si jugador está mirando, instantánea si no (optimización).
- En **luna llena**, espigas tienen reflejo lunar plateado (detalle puramente atmosférico).
- En **amanecer**, dorado cinematográfico + niebla baja.

### 8.8 Etapa 7 — Cosecha

**Prerequisitos:** cultivo en stage maduro (último productivo), maquinaria/herramienta.

**Métodos:**

| Cultivo | Método | Capacidad |
|---|---|---|
| Trigo, cebada, avena, centeno | **Cosechadora** + cabezal cereal | Depósito grande, 1-2 pasadas/campo |
| Maíz | Cosechadora + cabezal maíz (intercambiable — sistema implementos) | Depósito grande |
| Patata | **Sacador de patatas** (tractor + implemento): excava y eleva, patatas caen en remolque al lado | Remolque |
| Tomate, pimiento, pepino | **Manual con cesto**: animación de coger y meter. El cultivo pierde frutos del modelo 3D progresivamente | Cesto, varios viajes |
| Lechuga, col | **Manual con cuchillo**: corte en base, modelo de hoja entera al inventario | Cesta |
| Espinaca | **Manual con cizalla**: corte rápido, animación más fluida | Cesta |
| Cebolla, ajo | **Tractor pequeño con desherrador** + recogida manual posterior | Combinado |
| Girasol (oleada 2) | Cosechadora + cabezal girasol | Depósito |

**Wooow details críticos:**
- **Cosechadora deja rastro físico** en el campo: shader del cultivo cambia de "alto y dorado" a "rastrojo bajo" en la franja por donde pasó.
- Polvo y partículas de cáscara visibles en cosecha de cereales.
- Pájaros vuelan asustados al iniciarse la cosecha.
- Cesto manual se llena visualmente (modelo 3D con stages de llenado).
- Animación de limpiarse la frente con dorso de la mano (gesto humano sutil — el detalle).
- Sonido de cosechadora cambia con la carga del depósito.
- **Cosecha al amanecer** (configurable): iluminación dorada cinematográfica + niebla baja + bonus +5 calidad ("first light").

**Variables afectadas:**
- `harvest_timing`: cosechar en stage 5 = score 100. Stage 4 (temprana) = -20. Stage 6 sobremadura = -30 + plagas potenciales.

### 8.9 Etapa 8 — Descarga (la pieza icónica)

> *"Nadie en FiveM ha hecho esta animación. Cuando salga, va a ser referencia."*

**Cosechadora descarga grano:**
1. Cosechadora llega al silo o remolque.
2. Activa brazo de descarga (tubo lateral telescópico real).
3. **Chorro físico de grano** sale del tubo, cae al silo. Partículas + sonido específico de grano cayendo.
4. Tiempo proporcional al volumen.
5. Indicador del silo se va llenando (ver §10).

**Camión cisterna descarga en silo:**
- Manguera flexible que se conecta físicamente entre boca del camión y entrada del silo.
- Soplador audible (silos modernos descargan con presión).

**Cesto manual a almacén:**
- Empleado lleva cestos al almacén. Animación de cargar dos cestos en remolque pequeño / quad / a mano.
- Llega al almacén refrigerado, abre puerta (animación), apila cajas en estantería (animación de apilar).

**Wooow:** la animación de descarga de grano es **el screenshot de venta** del producto. Hay que clavarla.

### 8.10 Etapa 9 — Almacenamiento

Ver §10 (sistema de almacenamiento).

Resumen:
- **Cereales** → silos exteriores (capacidad enorme).
- **Hortalizas frescas** → cámara frigorífica.
- **Tubérculos / bulbos** → almacén seco oscuro.
- Cada uno tiene **tiempo de vida** (degradación).

### 8.11 Etapa 10 — Mantenimiento de maquinaria (paralelo, continuo)

**Sistema:**
- Cada vehículo tiene `condition` (0-100).
- Cada uso baja la condición (uso intensivo baja más rápido).
- A condición <40%: eficiencia -25%, riesgo de avería.
- A condición 0%: **avería visible** (humo del capó, motor calado). Vehículo inoperativo hasta reparación.

**Reparación:**

| Tipo | Dónde | Quién | Coste |
|---|---|---|---|
| **Mantenimiento rutinario** | Banco mecánico de granja | Empleado con permiso | Repuestos baratos |
| **Reparación menor** | Banco mecánico de granja | Empleado o dueño | Repuestos medios |
| **Reparación mayor** | Taller externo (futuro nodo Mecánico Admirals — gancho económico) | Mecánico externo | Caro |

**Acciones físicas en banco:**
- Vehículo entra al granero, aparca en zona mantenimiento.
- Animaciones: apertura capó, uso de llaves (props), sonidos mecánicos.
- Tablet muestra "diagnóstico" (qué piezas).
- Tarda X minutos (configurable, no instantáneo).

**Wooow:** humo, chispas en mecánico mayor, herramientas físicas que el jugador agarra. Aceite manchando suelo si descuidado.

**Hook económico futuro:** Admirals Mecánico recibe contratos automáticos de Granja para reparaciones mayores. Esto es lo que hace el ecosistema valioso a medida que crece.

---

## 9. Maquinaria y flota

### 9.1 Filosofía

> **GTA V nativo tuneado primero. Custom donde haga falta para diferenciar y donde lo nativo no exista.**

Esto da arranque rápido al primer producto sin esperar al equipo 3D para una flota completa. Pero **toda maquinaria visible lleva livery Admirals** (vinilos, marca, accesorios), por mínima que sea, para que se vea propia.

### 9.2 Inventario completo de maquinaria (primer lanzamiento)

| # | Vehículo / herramienta | Origen | Tuneo Admirals | Función primaria |
|---|---|---|---|---|
| 1 | **Tractor grande** | GTA V `tractor` tuneado | Livery, luz LED, faro de trabajo, cabina insonorizada | Arado, fertilizado, cosechadora arrastrada |
| 2 | **Tractor mediano** | GTA V `tractor2` tuneado | Livery, accesorios | Tubérculos, transporte interno |
| 3 | **Tractor pequeño / utility** | Custom propio (oleada 1 si el equipo 3D puede; si no, GTA V variant) | — | Parcelas hortícolas, transporte ligero |
| 4 | **Cosechadora cereales** | GTA V `combine` / `combine2` tuneado | Livery + cabezal intercambiable | Trigo, cebada, avena, centeno |
| 5 | **Cabezal de maíz** (implemento) | Custom propio | — | Se monta en cosechadora |
| 6 | **Cabezal de girasol** (oleada 2) | Custom propio | — | Se monta en cosechadora |
| 7 | **Sembradora cereales** (remolque) | Custom propio | — | Se arrastra detrás de tractor grande |
| 8 | **Sembradora hortalizas** (remolque pequeño) | Custom propio | — | Tractor mediano/pequeño |
| 9 | **Sembradora patatas** (remolque) | Custom propio | — | Tractor mediano |
| 10 | **Sacador de patatas** (implemento) | Custom propio | — | Tractor mediano |
| 11 | **Arado de vertedera** (implemento) | Custom propio | — | Tractor grande |
| 12 | **Cultivador** (implemento) | Custom propio | — | Tractor pequeño/mediano |
| 13 | **Surcador** (implemento) | Custom propio | — | Tractor mediano |
| 14 | **Fertilizadora** (remolque difusor) | Custom propio | — | Tractor grande |
| 15 | **Fumigadora** (remolque tanque pulverizador) | Custom propio | — | Tractor mediano |
| 16 | **Cisterna de riego** (remolque) | Custom propio | — | Tractor grande |
| 17 | **Camión de transporte** | GTA V `mule` o `phantom` tuneado | Livery, refrigerado para perecederos | Llevar producto al molino/distribución |
| 18 | **Camioneta pickup** | GTA V `bison` tuneado | Livery | Movilidad rápida del dueño/gerente por la finca |
| 19 | **Quad** | GTA V nativo | Livery | Inspección rápida de campos |
| 20 | **Montacargas (forklift)** | GTA V `forklift` | Livery | Manejo de palets en zona de carga |
| 21 | **Mochila pulverizadora** (item) | Custom prop | — | Plagas en parcelas pequeñas e invernaderos |
| 22 | **Carros/cestos** (props) | Custom props | — | Transporte manual de cosecha hortícola |

> **Total:** ~14 vehículos + ~8 implementos/props. La flota se siente real.

### 9.3 Sistema de implementos intercambiables

**Innovación clave:** los tractores no tienen un implemento fijo. El jugador conecta/desconecta físicamente:

- En el granero: el tractor para. El jugador baja. Se acerca al implemento (target physical). Animación de **enganche con pasador** (3-5 seg). Implemento queda anclado al tractor.
- Para cambiar: animación inversa. El implemento queda en el suelo del granero. Se elige otro.
- **Wooow:** poder ver visualmente "tractor con arado" vs "tractor con sembradora" vs "tractor con fertilizadora" — todo el mismo vehículo base, transformado.
- Implementos compatibles con su tractor: el sistema avisa si intenta enganchar uno incompatible.

### 9.4 Combustible y autosuficiencia

- **Cada vehículo consume combustible** (compatible con resource de combustible del servidor o uno propio si no hay).
- **Dispensador propio en granero**: la granja es autosuficiente. El dueño compra combustible al por mayor (camión cisterna NPC entrega periódicamente — futuro hook con vertical Energía).
- **Empleados pueden repostar** sin ir a gasolinera externa (eficiencia operativa).
- **Si el dispensador queda vacío:** los vehículos no pueden trabajar. Es responsabilidad del gerente reponer.

### 9.5 Licencias para conducir maquinaria

> Sistema premium que añade profundidad.

- **Licencia básica** (gratuita, automática) — permite conducir tractor pequeño y quad.
- **Licencia agrícola estándar** — coste pequeño en Tienda Admirals + mini-curso de 5 minutos (animación + checkpoint físico). Permite tractor grande, sembradora, fertilizadora.
- **Licencia de cosechadora** — coste medio + curso. Solo con esto se puede operar la cosechadora.
- **Licencia de transporte profesional** — para conducir el camión grande con remolques.

**Gameplay implication:** un empleado nuevo puede sembrar pero no cosechar. El dueño debe pagarle la licencia o contratar un cosechador especializado. Esto **crea jerarquías profesionales naturales** y justifica salarios diferentes.

Las licencias se gestionan desde la **Tablet → Tienda Admirals → Certificaciones**.

### 9.6 Garaje y dispensador propio

- Garaje del granero: capacidad ~12 vehículos + zona implementos.
- Cada vehículo tiene su **slot asignado** (mismo lugar siempre — orden naval).
- **Bandera/luz indicadora** en cada slot: verde = vehículo aparcado y operativo. Amarilla = en uso. Roja = avería pendiente.
- **Dispensador combustible**: surtidor físico estilo gasolinera, animación de manguera + boquilla.
- **Banco de mecánico**: zona específica con elevador hidráulico (animación de subir/bajar vehículo), banco de herramientas, lavabo (sí — el detalle).

---

## 10. Sistema de almacenamiento

### 10.1 Silos de grano (cereales)

- **3 unidades** cilíndricas metálicas exteriores. Altura 12m, diámetro 4m.
- **Capacidad por silo:** 2,000 kg de grano (configurable).
- **Indicador físico exterior:** banda lateral con shader que se rellena (de 0% a 100%) según contenido. **Wooow.**
- **Tipo de grano almacenado:** cada silo se asigna a un tipo (silo 1 = trigo, silo 2 = cebada, silo 3 = maíz). Mezclar tipos contamina la calidad.
- **Acceso de descarga:** boca superior (cosechadora) y boca inferior (camión cisterna que se lleva el grano).
- **Auditoría:** la Tablet muestra historial de entradas/salidas de cada silo.

### 10.2 Cámara frigorífica (perecederos)

- **1 unidad** dentro de un edificio refrigerado (10x10m).
- **Estanterías visibles** con cajas apiladas (modelos 3D).
- **Capacidad:** 500 kg total, distribuida entre tipos.
- **Climatización:** consume energía continua (factura mensual). Sin energía → degradación acelerada.
- **Cultivos almacenados:** tomate, pimiento, pepino, lechuga, col, espinaca.
- **Wooow:** vaho de aire frío al abrir puerta, luz fría azulada interior, sonido de motor compresor de fondo.

### 10.3 Almacén seco (tubérculos y bulbos)

- **1 unidad** dentro de un edificio oscuro y ventilado.
- **Tarima/pallet system** con sacos apilados.
- **Capacidad:** 1,500 kg total.
- **Cultivos:** patata, cebolla, ajo.
- **Curing rooms** — para ajos y cebollas, sub-zona donde se "curan" durante 1-2 días in-game antes de estar listos para venta premium. **Cura adecuada = +1 nivel de calidad.**

### 10.4 Almacén de semillas y suministros

- Estanterías ordenadas con sacos etiquetados de cada cultivo (común y premium).
- Palets con fertilizante (cada tipo).
- Garrafas de fitosanitarios (tratamiento de plagas).
- Compartimento de **planteles** (lechuga, tomate, etc.) — pequeñas bandejas con planteles vivos visibles.
- **Tablet muestra inventario en tiempo real** desde aquí (target → "Ver inventario almacén").
- Reposición: por compra a NPC proveedor o futuro nodo "Cooperativa Agrícola Admirals".

### 10.5 Tiempo de vida (degradación)

| Tipo de almacén | Producto | Tiempo a -1 nivel calidad | Tiempo a pérdida total |
|---|---|---|---|
| Silo grano | Cereales | 7 días in-game | 21 días |
| Cámara frigorífica | Hortalizas frescas | 3 días | 10 días |
| Cámara frigorífica | Hojas (lechuga, espinaca) | 1.5 días | 5 días |
| Almacén seco | Patata, cebolla, ajo | 14 días | 60 días |

**Implicación:** el dueño no puede acumular hortalizas frescas indefinidamente. Hay presión natural para vender pronto = ecosistema económico vivo.

### 10.6 Capacidades resumen

| Espacio | Capacidad | Cuello de botella natural |
|---|---|---|
| Silos cereales (×3) | 6,000 kg total | Forces sale or transport |
| Cámara frigorífica | 500 kg | Frescos rotan rápido |
| Almacén seco | 1,500 kg | Patatas/bulbos pueden esperar |
| Almacén semillas | ~200 sacos / N planteles | Compras planificadas |

Capacidades configurables por servidor en `config.lua`.

---

## 11. Sistema de Empresa "Granja Admirals"

### 11.1 Estructura

> Cada granja es una **empresa registrada en el ecosistema Admirals**, con cuentas, empleados y reputación propios. Todo se gestiona desde la Tablet.

**Atributos de la empresa:**
- Nombre comercial (definido por el dueño al fundar).
- Logo/marca (slot opcional — futura personalización).
- Sede (la granja física que posee).
- Activos (parcelas, vehículos, almacén, dinero en caja, dinero en banco).
- Reputación (0-100, sube con calidad de producto y cumplimiento de contratos, baja con incumplimientos).
- Historial financiero completo.
- Empleados activos.

### 11.2 Roles detallados con permisos

| Permiso | Dueño | Gerente | Empleado | Temporal |
|---|---|---|---|---|
| Ver datos de la empresa (Tablet) | ✅ Total | ✅ Operativo | ✅ Su tarea | ❌ |
| Modificar nombre/logo empresa | ✅ | ❌ | ❌ | ❌ |
| Acceso a caja física | ✅ | ✅ | ❌ | ❌ |
| Transferencias bancarias | ✅ | Limitadas (config) | ❌ | ❌ |
| Contratar/despedir empleados | ✅ | ✅ | ❌ | ❌ |
| Fijar salarios | ✅ | ✅ (rango definido por dueño) | ❌ | ❌ |
| Asignar tareas (Manager Panel) | ✅ | ✅ | ❌ | ❌ |
| Comprar suministros | ✅ | ✅ | Limitado (config) | ❌ |
| Vender producto | ✅ | ✅ | ✅ | ❌ |
| Operar maquinaria | ✅ (con licencia) | ✅ (con licencia) | ✅ (con licencia + permiso) | ✅ Solo asignado |
| Cosechar | ✅ | ✅ | ✅ | ✅ |
| Sembrar / regar / mantener | ✅ | ✅ | ✅ | Solo lo asignado |
| Acceder a libro contable | ✅ Total | ✅ Operativo (sin sueldos altos) | ❌ | ❌ |
| Firmar contratos B2B | ✅ | ✅ (con límite de monto) | ❌ | ❌ |
| Vender la empresa | ✅ | ❌ | ❌ | ❌ |

### 11.3 Salarios y nóminas

**Modelos disponibles:**

| Modelo | Cómo funciona | Para quién |
|---|---|---|
| **Salario fijo periódico** | X$ cada N horas in-game | Empleados estables |
| **Pago por tarea** | X$ por cada cosecha entregada / cada hectárea sembrada / etc. | Empleados temporales o por productividad |
| **Comisión sobre venta** | X% del valor del producto vendido | Tendero, transportista freelance |
| **Mixto** | Base + comisión | Gerente |

**Procesamiento:**
- **Automático:** la empresa paga sola en intervalos definidos. Si la caja no llega, alerta en Tablet.
- **Manual:** el dueño paga uno a uno desde el Manager Panel (animación de transferencia + sonido satisfactorio en Tablet).

### 11.4 Contratos B2B

Acuerdos formales entre empresas (granja ↔ molino, granja ↔ restaurante, etc.).

**Tipos de contrato:**

| Tipo | Descripción |
|---|---|
| **Suministro recurrente** | "Te entrego N kg de trigo cada semana al precio P$" |
| **Compra puntual** | "Te compro este lote concreto a precio P$" |
| **Exclusividad** | "No vendo a tu competencia durante X tiempo, a cambio de precio premium" |
| **Calidad mínima** | "Solo te pago si la calidad es ≥ A. Si es B o menor, descuento o devolución" |

**Estado del contrato:**
- `Pending` — propuesto, esperando firma.
- `Active` — vigente, con entregas pendientes/en curso.
- `Fulfilled` — completado.
- `Breached` — incumplido (penalización en reputación).

**Firma física:** el contrato existe como documento PDF dentro de la app **Notas & Contratos** de la Tablet. Ambas partes firman digitalmente (animación de teclear nombre + huella digital). **Wooow:** el contrato firmado se imprime en una impresora real del despacho del dueño (animación de impresora trabajando).

### 11.5 Caja física vs cuenta empresarial

> **Decisión de diseño importante:** la empresa tiene **dos pools de dinero**, distintos.

| Pool | Dónde vive | Acceso | Uso típico |
|---|---|---|---|
| **Caja física** | Caja fuerte en oficina (modelo 3D, animación de abrir, billetes apilados visibles) | Quien tenga llave física + permiso | Pagos rápidos (combustible, contratación temporal, gastos menores) |
| **Cuenta empresarial** | Banco (app Banca de Tablet) | Permisos digitales | Transferencias, contratos B2B, salarios |

**Wooow:** abrir la caja fuerte muestra los billetes físicos apilados. Cantidad visible = no es "número en menu". Los robos de la granja (evento extremo) afectan a la **caja física**, no a la cuenta bancaria. **Esto crea decisión estratégica de cuánto efectivo mantener.**

### 11.6 Auditoría y libro contable

Cada movimiento (ingreso, gasto, transferencia, salario, contrato) queda registrado en el **libro contable digital** dentro de la Tablet (app Empresa → Contabilidad).

**Vistas disponibles:**
- Por día / semana / mes / año.
- Por categoría (ingresos por venta, costes de producción, salarios, mantenimiento, etc.).
- Por empleado (cuánto cuesta cada uno, cuánto produce).
- Por parcela (rentabilidad por campo individual).
- Gráficas (la Tablet renderiza gráficas reales — ver §12).

**Exportación:** el dueño puede generar un "informe trimestral" — PDF que se imprime físicamente en el despacho, con cifras + gráficas. Apto para mostrar a inversores RP o vender la empresa con datos reales.

### 11.7 Empleado temporal — el contrato por tarea

> *Decisión calificada como "muy creativa" en sesión de diseño.*

Este es el rol más innovador. Permite a la granja contratar gente para **una tarea específica**, sin alta como empleado fijo.

**Cómo funciona:**

1. Dueño/gerente publica oferta desde Tablet → Manager Panel → Ofertas: *"Cosechar parcela hortícola 2 — pago 500$ — duración estimada 30 min"*.
2. La oferta aparece en la app Mercado de la Tablet de **cualquier jugador del servidor** (que tenga la app instalada/activa con su flag de "buscando trabajo").
3. Un jugador acepta la oferta. Recibe ubicación + descripción.
4. Llega a la granja, ficha (lector de tarjeta provisional). Se le asigna acceso temporal a la parcela y herramientas necesarias.
5. Realiza la tarea. El sistema detecta finalización (parcela cosechada al 100%).
6. **Pago automático** transferido a su cuenta. Acceso temporal revocado.
7. Reputación del temporal sube (+1 trabajo bien hecho). Reputación de la empresa baja si maltrata al temporal (no paga, no asigna bien).

**Ventajas:**
- Permite a jugadores casuales **probar la granja** sin compromiso.
- Permite a la granja escalar puntualmente (cosecha urgente, dueño solo).
- Crea un **mercado laboral activo** en el servidor — algo que ningún competidor tiene.

---

## 12. Integración con la Tablet — Manager Panel del granjero

> El Manager Panel es **la cabina de mando** del dueño/gerente de la granja. No es una pantalla más — es donde se decide la estrategia, donde se ven los resultados, donde se toman las decisiones que distinguen al granjero novato del veterano.

### 12.1 Vistas del Manager Panel (5 dashboards)

#### 12.1.1 Vista "Operations" (Operaciones — la que más se usa)

**Layout:** mapa cenital de la granja a la izquierda + panel de tareas a la derecha.

- **Mapa cenital interactivo:** muestra cada parcela con código de color según estado:
  - Gris = `fallow` (libre).
  - Marrón = `prepared` (arada).
  - Verde claro = sembrada, en crecimiento temprano.
  - Verde intenso = crecimiento medio.
  - Dorado = madura, lista para cosecha.
  - Rojo = problema (plaga detectada, sin riego prolongado, etc.).
- **Click en parcela** → detalle: cultivo, stage, calidad estimada, días para cosecha, alertas.
- **Panel de tareas:**
  - Tareas pendientes hoy (regar parcela 3, fumigar invernadero, etc.).
  - Tareas asignadas a empleados (con foto + nombre + estado).
  - Botón "Asignar tarea" → drag-and-drop a empleado.
- **Indicador climático:** estación actual + previsión 3 días (si seasons activado).

#### 12.1.2 Vista "Personnel" (Personal)

- Lista de empleados (foto, rol, licencias, salario, productividad %, eficiencia, antigüedad).
- Por empleado: historial de tareas + calidad media de su trabajo.
- Acciones: asignar tarea, modificar salario, ascender (empleado → gerente), despedir.
- **Métrica destacada:** "Costo / Producción ratio" por empleado — quién es rentable, quién no.
- **Sub-tab Ofertas Temporales:** crear/editar/cerrar ofertas de tarea para temporales (§11.7).

#### 12.1.3 Vista "Finance" (Finanzas)

- Cuadro de mandos con números clave hoy / semana / mes:
  - Ingresos
  - Costes (desglose: salarios, suministros, mantenimiento, energía)
  - Beneficio neto
  - Caja física vs cuenta bancaria
- **Gráficas reales** (no decorativas):
  - Línea de ingresos / costes / beneficio.
  - Barras de rentabilidad por parcela.
  - Pie chart de distribución de gastos.
- **Alertas financieras:** "Caja insuficiente para nóminas del viernes", "Factura de luz pendiente".

#### 12.1.4 Vista "Inventory" (Inventario)

- Estado de los **silos** (% lleno, calidad media, batches dentro).
- Estado de **cámara frigorífica** (% lleno + tiempo de vida restante por lote).
- Estado de **almacén seco** (lo mismo).
- Estado de **almacén de semillas** (qué hay, qué se va a agotar pronto).
- **Alertas de degradación:** "Lote tomate B-2025-145 caduca en 2 días — vender o procesar".

#### 12.1.5 Vista "Strategic" (Estrategia)

- **Planificación de ciclos:** calendario in-game con qué parcela está sembrada con qué, ventana óptima de cosecha, próximo barbecho recomendado.
- **Sugerencias del sistema** (motor heurístico simple):
  - "Parcela 4 lleva 5 ciclos sin barbecho — calidad bajará si sigues. Recomendación: 1 ciclo descanso."
  - "Tu inventario de cebada premium es bajo. Demanda actual del molino X es alta. Plantar 2 parcelas?"
- **Reputación de la empresa** y cómo evoluciona.
- **Contratos B2B** activos y propuestos.
- **Vista comparativa** vs otras granjas del servidor (anonimizado por defecto, ranking de producción).

### 12.2 Datos en tiempo real

> Toda la información de la Tablet **se actualiza en vivo**. Si un empleado termina una cosecha, el silo se llena en la vista Inventory inmediatamente.

Mecanismo técnico (referencia para arquitectura): canal de eventos `admirals:granja:state_change` que se publica cuando algo cambia (parcela, almacén, empleado, finanzas). La Tablet suscribe y re-renderiza.

### 12.3 Acciones desde la Tablet (sin moverte de la oficina)

| Acción | Vía Tablet posible? | Por qué |
|---|---|---|
| Asignar tarea a empleado | ✅ | Decisión administrativa |
| Activar aspersores remotos | ✅ | Acción técnica con interruptor real |
| Pagar nómina | ✅ | Transferencia bancaria |
| Firmar contrato B2B | ✅ | Documento digital |
| Comprar suministros (NPC proveedor) | ✅ | Pedido remoto (camión NPC entrega) |
| Sembrar / arar / cosechar | ❌ **Acción física obligatoria** | Pilar 1 |
| Reparar maquinaria | ❌ **Físico** | Pilar 1 |
| Coger billetes de caja física | ❌ **Físico** (ir a la oficina) | Pilar 1 |

**Regla:** todo lo administrativo en Tablet, todo lo productivo es físico en el mundo. La Tablet **no sustituye al trabajo**, lo organiza.

### 12.4 Notificaciones específicas del granjero

Push notifications con sonido distintivo según prioridad:

| Tipo | Prioridad | Ejemplo |
|---|---|---|
| 🔴 Crítica | Sonido fuerte | "Plaga detectada en parcela 3. Daño 30% si no se trata en 24h." |
| 🟡 Media | Sonido medio | "Riego de parcela 5 fuera de ventana óptima. Calidad -10 si no se riega en 1h." |
| 🟢 Informativa | Bip suave | "Cosecha de parcela 2 lista. Calidad estimada: A." |
| 💰 Financiera | Sonido de moneda | "Pago de nómina ejecutado. Caja: 12,400$." |
| 📋 Contractual | Sonido de papel | "Molino Pedro propone contrato suministro recurrente trigo." |
| 🌦️ Meteorológica | Sonido viento | "Tormenta entrante en 30 min. Cubrir cultivos sensibles." |

---

## 13. Casos extremos y eventos

> Estos son los **estados no felices**. Diseñarlos bien es lo que distingue Admirals: el sistema no se rompe, reacciona.

### 13.1 Sin riego prolongado

- Tras N tics sin riego (configurable), el cultivo entra en `stressed`.
- Visual: hojas amarillentas, modelo de planta más mustio.
- 2× tiempo en stress sin solución → cultivo `dead`.
- Cultivo muerto: se debe limpiar la parcela (animación manual o tractor) antes de volver a sembrar. Pérdida de inversión.

### 13.2 Lluvia (positiva y negativa)

- **Positiva:** sustituye riego, ahorra coste, +5 calidad si llueve durante crecimiento medio.
- **Negativa durante cosecha:** -20% rendimiento del grano expuesto. Notificación: *"Lluvia inminente — recoger cosecha en 15 min para evitar daño."*
- Los empleados pueden continuar trabajando bajo lluvia con animación de empapados (textura mojada, gotas en pelo) — **wooow detail**.

### 13.3 Plagas masivas

- Evento extremo: 2+ parcelas afectadas simultáneamente.
- Notificación urgente, alarma acústica en Tablet.
- Si no se trata en ventana, cascada — toda una zona de la granja se ve afectada.
- **Mitigación:** contratar fumigación intensiva (NPC servicio externo de plagas — coste alto pero rápido).

### 13.4 Robo de cosecha

> ⏳ **Fuera del MVP. Llega como upgrade en oleada 2.**
>
> Razón: añade complejidad de seguridad, NPCs hostiles e inmersión que puede chocar con servidores RP no-CPS. Mejor lanzar el sistema base puro y añadir esta capa después con sistema de seguridad bien diseñado.

**Diseño previsto (oleada 2):**
- Evento estocástico raro: NPCs ladrones intentan llevarse stock de almacén o cosecha lista en campo.
- **Mitigación:** sistema de seguridad (cámaras, alarmas, perro guardián), patrullas de empleados, contrato con seguridad privada NPC.
- **Activación:** opcional on/off por servidor. Los robos solo afectan a la **caja física** (no a la cuenta bancaria) y a producto físicamente vulnerable.

### 13.5 Maquinaria averiada en mitad de cosecha

- Cosechadora se rompe a 50% del campo. Animación visible (humo, motor calado).
- Alarma en Tablet del dueño.
- Opciones:
  - Reparar in-situ (si hay piezas y mecánico, +tiempo).
  - Llevar al banco mecánico de la granja con tractor (anclar y arrastrar — animación física).
  - Llamar a taller externo (caro).
- Mientras: la cosecha pendiente sigue degradándose si la lluvia llega.

### 13.6 Empleado abandona trabajo

- Empleado con tarea asignada se desconecta o no aparece. Sistema detecta inactividad.
- Tras X minutos sin progreso, alerta al gerente: *"Empleado Juan no progresa en su tarea. Reasignar?"*
- Reasignación a otro empleado o conversión a oferta temporal.

### 13.7 Almacenamiento desbordado

- Silo lleno y cosechadora intentando descargar: **se detiene en el campo con depósito lleno**. Notificación: *"Silos llenos. Vender stock o liberar capacidad antes de seguir cosechando."*
- Esto fuerza decisión: vender rápido aunque baje el precio, o esperar mejor demanda con la cosecha parada.

### 13.8 Estanque de agua vacío

- Si el dueño no llena el estanque (o no se rellena con lluvia), **los aspersores no funcionan, la cisterna no se carga**.
- Solución: instalar bomba conectada a red de agua municipal (coste alto), o esperar lluvia, o comprar agua a NPC proveedor.

### 13.9 Empresa quiebra

- Si la cuenta empresarial entra en negativo durante N días in-game:
  - Empleados dejan de cobrar → empiezan a abandonar.
  - Suministros no se reponen → producción se para.
  - **Notificación crítica al dueño:** "Inminente quiebra. 3 días para regularizar."
- Si no se regulariza: la empresa entra en **administración del servidor** (NPC). El jugador pierde la propiedad. Recuperable (con pago de deudas + tarifa) en una notaría NPC.

---

## 14. Detalles Wooow consolidados — separados por responsabilidad

### 14.1 Filosofía de reparto: dónde nace cada wooow

> **Regla fundacional Admirals:**
> El equipo **3D** entrega el **asset sólido, funcional, con la idea creativa core visible**. Nada de pedirles micro-detalles atmosféricos que pueden generar problemas de rendimiento o de pipeline en FiveM.
>
> El equipo **de programación** añade el **shimmer**: shaders, partículas, transiciones, lighting dinámico, post-procesado, lógica visual reactiva. **Aquí no tenemos límite** — el código es nuestra fuerza.
>
> El equipo **de animación** + scripting entregan los **gestos humanos** que dan vida al mundo.
>
> El equipo **de audio** entrega la **capa sonora coherente**.
>
> Cada item de las listas siguientes está marcado por su responsable. Si un item depende de varios, se marca con doble responsable y se especifica qué hace cada uno.

### 14.2 Wooow vía 3D (responsabilidad equipo 3D — asset core con idea wooow)

> El equipo 3D entrega el modelo con la **idea creativa visible en el modelo**. Lo demás es código.

- [ ] **3D** — Cosechadora con **brazo de descarga telescópico funcional** (rig animable).
- [ ] **3D** — Silo con **boca de carga superior + boca de descarga inferior** + escalera lateral practicable.
- [ ] **3D** — **Stages físicos de crecimiento** de cada cultivo (modelos por stage — `~5-7` por cultivo).
- [ ] **3D** — Saco/cesto/caja con **stages físicos de llenado** (3-4 modelos: vacío, medio, casi lleno, lleno).
- [ ] **3D** — Cultivo de cosecha que **pierde frutos progresivamente** (variantes 100%/66%/33%/0% del modelo).
- [ ] **3D** — Aspersor giratorio con **rig animable** (cabezal que rota).
- [ ] **3D** — Caja fuerte con **animación abrir + interior visible con billetes apilados**.
- [ ] **3D** — Cabina del tractor/cosechadora **detallada por dentro** (volante, panel, asiento) — solo si merece tuneo, no obligatorio si nativo basta.
- [ ] **3D** — **Implementos intercambiables** modelados con sistema de enganche visible (pasador, anclaje).
- [ ] **3D** — Tablet **modelo físico** con pantalla operable (la app va por código).
- [ ] **3D** — Impresora de oficina con **rig animable** (papel saliendo).
- [ ] **3D** — Lector de tarjeta con **luz LED operable** (modelo simple, lógica por código).
- [ ] **3D** — Banderas/luces de slot en garaje (props simples + emisivo).
- [ ] **3D** — Variantes de textura por estado (cultivo sano vs amarillento por plaga) — entrega 2-3 variantes por cultivo afectable.

### 14.3 Wooow vía código (responsabilidad programación — el shimmer)

> Aquí está nuestra ventaja. Sin límite.

- [ ] **CÓDIGO** — Shader de viento sobre cultivos altos (vegetación se mueve, sincronizada con sonido ambiente).
- [ ] **CÓDIGO** — Shader/decal de "rastro de cosechadora" en el campo (mowed vs not-mowed).
- [ ] **CÓDIGO** — Partículas de polvo detrás del tractor al arar.
- [ ] **CÓDIGO** — Partículas de agua de aspersores + condicional de **arcoíris** según ángulo solar.
- [ ] **CÓDIGO** — Niebla matinal scriptada (post-process + tiempo del día).
- [ ] **CÓDIGO** — Shader de **indicador de nivel del silo** (banda lateral que se rellena reactiva al `fill_level`).
- [ ] **CÓDIGO** — Partículas de gránulos de fertilizante volando del difusor.
- [ ] **CÓDIGO** — Partículas de niebla de pulverización (fumigadora).
- [ ] **CÓDIGO** — Vaho de aire frío al abrir cámara frigorífica (partículas + post local).
- [ ] **CÓDIGO** — Lighting dorado cinematográfico de amanecer (post + time-of-day shader).
- [ ] **CÓDIGO** — Spawn de pájaros asustados al iniciar cosecha (lógica + nativo `CREATE_PED`).
- [ ] **CÓDIGO** — Reflejo lunar plateado en espigas (luz emisiva + shader condicional).
- [ ] **CÓDIGO** — Swap dinámico de modelos (cultivo por stage, saco por nivel, caja por llenado, cultivo por sano/enfermo).
- [ ] **CÓDIGO** — Lluvia hacía hojas/cuerpo de empleados (shader wet + partículas).
- [ ] **CÓDIGO** — Estado de las luces de slot del garaje (verde/amarilla/roja según `vehicle.state`).
- [ ] **CÓDIGO** — Chorro de grano cayendo en descarga (partículas + sonido + tiempo proporcional).
- [ ] **CÓDIGO** — Tablet con animación de docking al monitor (script de cámara + UI swap).

### 14.4 Wooow vía animación + scripting

> Animaciones humanas que dan vida al mundo. Trigger via código, asset via animator/3D.

- [ ] Cargar saco al hombro con peso real (postura encorvada).
- [ ] Esparcir semilla con la mano.
- [ ] Cortar lechuga con cuchillo en base.
- [ ] Cortar espinaca con cizalla (más rápido).
- [ ] Recoger tomate con dos manos.
- [ ] Apilar cajas en estantería.
- [ ] Cubrir parcela con malla anti-helada (despliegue manual).
- [ ] Enganchar implemento al tractor (pasador).
- [ ] Repostar combustible (boquilla + manguera).
- [ ] Abrir capó + manejo de llaves.
- [ ] Subir/bajar elevador hidráulico.
- [ ] Fichar con tarjeta.
- [ ] Limpiarse las manos / la frente con el dorso.
- [ ] Beber de cantimplora (idle).
- [ ] Conducción manual del tractor con manos al volante.
- [ ] Firmar contrato (teclear nombre + huella digital en Tablet).
- [ ] Contar billetes (animación al sacar de caja fuerte).

### 14.5 Wooow vía audio (responsabilidad equipo sonido)

- [ ] Sonido del tractor variando según implemento.
- [ ] Cosechadora idle vs cosechando vs depósito lleno.
- [ ] Aspersor "tch-tch-tch".
- [ ] Manguera "shhhh".
- [ ] Soplador de descarga del silo.
- [ ] Chorro de grano cayendo (granular largo).
- [ ] Compresor de cámara frigorífica de fondo.
- [ ] Notificaciones específicas de Tablet (crítica / financiera / contractual / meteorológica / informativa).
- [ ] Bip del lector de tarjeta.
- [ ] Impresora trabajando.
- [ ] Lluvia diferenciada por superficie (metal del granero, cristal del invernadero, hierba).
- [ ] Pájaros mañana tranquila + bandada asustada.
- [ ] Viento moviendo trigo (sincronizado con shader).
- [ ] Silencio del invierno (ausencia de fauna + viento frío).

---

## 15. Lista completa de assets 3D requeridos (briefing equipo 3D)

### 15.0 Scope del equipo 3D — qué pedimos y qué NO

> **Filosofía Admirals (regla de oro para el brief 3D):**
>
> 1. **GTA V nativo siempre que sea aceptable.** Tractor, cosechadora, camión, pickup, quad, forklift → nativos tuneados. Solo si lo nativo no transmite la idea Admirals, hacemos custom.
> 2. **Custom solo cuando el asset NO existe en GTA V** (sembradoras, fertilizadoras, fumigadoras, sacador de patatas, cabezales intercambiables) **o cuando el modelo nativo rompe la marca** (raro).
> 3. **Pedimos al equipo 3D el asset funcional con la idea wooow CORE.** No pedimos micro-detalles atmosféricos (niebla, viento sobre vegetación, partículas, lighting, post-procesado) — eso lo añade el código.
> 4. **Cuando algo merece custom, lo merece de verdad.** El equipo 3D ha demostrado que en 6h hace una cisterna calidad lanzamiento. Confianza total — pero siempre con brief claro y compacto.
> 5. **Prioridad MVP de oleada 1 < 30 vehículos/MLOs.** Lo mínimo para que el sistema cierre con calidad. Lo extra va en oleadas siguientes.
>
> Esta lista marca: ID + asset + **origen** (nativo / tuneo / custom) + prioridad + oleada.

### 15.1 MLO de la Granja Admirals

| ID | Asset | Prioridad | Oleada |
|---|---|---|---|
| MLO-01 | **Casa principal 2 plantas** (vestíbulo, salón con chimenea, cocina, aseo, despacho dueño con dock de Tablet, dormitorio, sala de juntas) | Alta | 1 |
| MLO-02 | **Granero / parque de maquinaria** (capacidad ~12 vehículos, banco mecánico, dispensador combustible, banderas indicadoras) | Alta | 1 |
| MLO-03 | **Vestuario empleados** (taquillas numeradas, lector de tarjeta) | Alta | 1 |
| MLO-04 | **Almacén de semillas y suministros** (estanterías, palets, planteles vivos) | Alta | 1 |
| MLO-05 | **Almacén seco** para tubérculos/bulbos (con sub-zona curing room) | Alta | 1 |
| MLO-06 | **Cámara frigorífica** (estanterías, luz fría, vaho) | Alta | 1 |
| MLO-07 | **Invernadero túnel** (plástico, arcos) | Alta | 1 |
| MLO-08 | **Invernadero industrial cristal** (paneles vidrio, automatización visible, riego por goteo) | Alta | 1 |
| MLO-09 | **Zona de carga** (rampas, marcas viales, puente-grúa) | Media | 1 |
| MLO-10 | **Portón automático de entrada** | Media | 1 |

### 15.2 Estructuras exteriores

| ID | Asset | Prioridad | Oleada |
|---|---|---|---|
| EXT-01 | **Silo metálico** (×3) con shader de nivel exterior, escalera lateral, bocas superior/inferior | Alta | 1 |
| EXT-02 | **Estanque/depósito de agua** con agua animada | Media | 1 |
| EXT-03 | **Aspersores fijos** (modelo + animación giratoria + partículas + arcoíris shader) | Alta | 1 |
| EXT-04 | **Sistema de riego goteo** (tubos visibles en invernaderos) | Media | 1 |
| EXT-05 | **Malla anti-helada** (prop desplegable) | Baja | 1 |
| EXT-06 | **Malla anti-granizo** | Baja | 2 |
| EXT-07 | **Cerca/valla de la finca** (modelo modular para perímetro) | Media | 1 |

### 15.3 Vehículos y maquinaria

| ID | Asset | Origen | Oleada |
|---|---|---|---|
| VEH-01 | Tractor grande tuneado (livery Admirals + faro de trabajo) | GTA V tuneo | 1 |
| VEH-02 | Tractor mediano tuneado | GTA V tuneo | 1 |
| VEH-03 | Tractor pequeño / utility | Custom (o GTA V variant) | 1 |
| VEH-04 | Cosechadora cereales (livery) | GTA V tuneo | 1 |
| VEH-05 | Cabezal de maíz intercambiable | Custom propio | 1 |
| VEH-06 | Cabezal de girasol | Custom propio | 2 |
| VEH-07 | Sembradora cereales (remolque) | Custom propio | 1 |
| VEH-08 | Sembradora hortalizas (remolque pequeño) | Custom propio | 1 |
| VEH-09 | Sembradora patatas | Custom propio | 1 |
| VEH-10 | Sacador de patatas (implemento) | Custom propio | 1 |
| VEH-11 | Arado de vertedera | Custom propio | 1 |
| VEH-12 | Cultivador | Custom propio | 1 |
| VEH-13 | Surcador | Custom propio | 1 |
| VEH-14 | Fertilizadora (remolque difusor) | Custom propio | 1 |
| VEH-15 | Fumigadora (remolque pulverizador) | Custom propio | 1 |
| VEH-16 | Cisterna de riego | Custom propio | 1 |
| VEH-17 | Camión transporte (livery refrigerado) | GTA V tuneo | 1 |
| VEH-18 | Pickup (livery) | GTA V tuneo | 1 |
| VEH-19 | Quad (livery) | GTA V nativo | 1 |
| VEH-20 | Forklift (livery) | GTA V nativo | 1 |

### 15.4 Cultivos — modelos por stage

> **Crítico para el wooow.** Cada cultivo de oleada 1 necesita 5-7 stages distintos modelados.

| Cultivo | Stages | Variante premium | Total modelos |
|---|---|---|---|
| Trigo | 6 (vacío, brote, joven, medio, maduro con shader viento, rastrojo) | sí (modelo ligeramente distinto) | 12 |
| Cebada | 6 | sí | 12 |
| Maíz | 6 (con shader viento en stages altos) | sí | 12 |
| Tomate | 6 (plantel, mata media, mata adulta con flores, verde, rojo, post-cosecha) | sí | 12 |
| Pimiento | 6 | sí | 12 |
| Pepino | 6 | sí | 12 |
| Lechuga | 5 | sí | 10 |
| Col | 5 | sí | 10 |
| Espinaca | 5 | sí | 10 |
| Cebolla | 5 | sí | 10 |
| Ajo | 5 | sí | 10 |
| Patata | 5 (no se ven los frutos hasta cosecha) | sí | 10 |

> **Total cultivos oleada 1:** ~132 modelos 3D de stages. Crítico priorizar trigo / tomate / lechuga primero (los icónicos).

### 15.5 Props in-game

| ID | Prop | Prioridad |
|---|---|---|
| PROP-01 | Saco de semilla (4 stages: lleno, medio, cuarto, vacío) × cada cultivo | Alta |
| PROP-02 | Caja/cesto de cosecha (4 stages de llenado) | Alta |
| PROP-03 | Saco de fertilizante (gránulos visibles) | Alta |
| PROP-04 | Garrafa de fitosanitario | Media |
| PROP-05 | Plantel en bandeja (caja con planteles vivos) | Alta |
| PROP-06 | Mochila pulverizadora | Media |
| PROP-07 | Cuchillo de cosecha (lechuga, col) | Alta |
| PROP-08 | Cizalla (espinaca) | Alta |
| PROP-09 | Azada manual | Alta |
| PROP-10 | Rastrillo | Media |
| PROP-11 | Carro/carretilla de mano | Alta |
| PROP-12 | Caja de almacén apilable | Alta |
| PROP-13 | Palet con sacos de fertilizante | Media |
| PROP-14 | Tablero de herramientas en granero | Media |
| PROP-15 | Llaves mecánico (set) | Media |
| PROP-16 | Elevador hidráulico (banco mecánico) | Media |
| PROP-17 | Caja fuerte (animación abrir + billetes apilados) | Alta |
| PROP-18 | Lector de tarjeta del vestuario | Media |
| PROP-19 | Tarjeta de empleado (item) | Media |
| PROP-20 | Impresora de oficina (con animación) | Media |
| PROP-21 | Documento contrato (formato físico, PDF impreso) | Media |
| PROP-22 | Sello de calidad dorado/plateado/etc para sacos/cajas | Alta |
| PROP-23 | Bandera/luz indicadora de slot de garaje | Baja |
| PROP-24 | Indicador de nivel del silo (shader animado) | Alta |
| PROP-25 | Estiércol (saco/montón) | Baja |
| PROP-26 | Cantimplora (idle prop) | Baja |
| PROP-27 | Manguera de riego manual | Media |
| PROP-28 | Regadera | Baja |

### 15.6 Decoración y dressing

- Mecedoras del porche.
- Mapa enmarcado de la propiedad.
- Decantador de whisky decorativo.
- Cuadros temáticos rurales en las paredes.
- Plantas decorativas en la oficina.
- Reloj de pared antiguo.
- Tablero de avisos en vestuario.
- Aceite manchando suelo del banco mecánico.
- Cubos, mangueras enrolladas, props rurales en general.

---

## 16. Lista de animaciones requeridas

### 16.1 Por etapa del ciclo

| Etapa | Animaciones |
|---|---|
| Preparación tierra | Subir tractor, conducir, animación interna de manos al volante, baja del tractor |
| Siembra | Cargar saco al hombro (postura encorvada), andar con saco, esparcir semilla con mano, agacharse a plantar plantel |
| Riego | Activar interruptor aspersores (props), conectar manguera a cisterna, manejar manguera manual con regadera |
| Fertilización | Esparcir gránulos manualmente, controlar fertilizadora desde tractor |
| Plagas | Mochila pulverizadora (postura cargada), accionar rociador |
| Cosecha cereales | Manejar cosechadora, accionar brazo de descarga |
| Cosecha tomate/pimiento | Recoger con dos manos y meter en cesto |
| Cosecha lechuga | Cortar con cuchillo en base, meter hoja entera |
| Cosecha espinaca | Cortar con cizalla (rápido) |
| Cosecha tubérculo | Manejar sacador (tractor) |
| Descarga grano | Maniobra cosechadora, brazo de descarga, partículas de grano |
| Apilar cajas | Cargar caja, llevarla, apilar en estantería |

### 16.2 Animaciones de gestión

- Sacar Tablet del bolsillo / guardarla.
- Teclear / scroll en Tablet.
- Recibir tarjeta / pasar por lector (fichaje).
- Firmar contrato (animación de teclear nombre + huella).
- Abrir caja fuerte (manija + apertura).
- Coger billetes (animación de contar).
- Tablet docking en monitor del despacho.

### 16.3 Animaciones de mantenimiento

- Abrir capó.
- Manejar llave inglesa / destornillador (props).
- Subir vehículo en elevador.
- Repostar combustible (boquilla + manguera).
- Engrase (engrasador como prop).

### 16.4 Animaciones humanas de inmersión

- Limpiarse la frente con dorso de la mano.
- Limpiarse las manos con trapo.
- Beber de cantimplora.
- Estirarse / desperezarse al fichar.
- Trabajar bajo lluvia (ligera variación de postura).
- Conversar entre empleados (idle de pareja).

---

## 17. Lista de sonidos requeridos

### 17.1 Maquinaria

- Motor tractor idle / acelerando / cargado.
- Motor cosechadora idle / cosechando / depósito lleno.
- Motor camión.
- Motor quad.
- Motor de invernadero (climatización) — zumbido bajo continuo.
- Compresor de cámara frigorífica.
- Soplador de descarga de silo.
- Bomba de agua del estanque.
- Aspersor "tch-tch-tch".

### 17.2 Acciones

- Arar tierra (motor cargado + tierra removida).
- Cosechar cereal (corte + ventilación interna de cosechadora).
- Chorro de grano cayendo (largo, granular).
- Manguera de agua "shhh".
- Esparcir gránulos de fertilizante.
- Niebla de fumigación (aerosol).
- Cortar lechuga con cuchillo (corte vegetal limpio).
- Cortar espinaca con cizalla.
- Recoger tomate (suave, vegetal).
- Cargar saco al hombro (telita + esfuerzo humano).
- Apilar cajas (madera/cartón impactando).
- Enganchar implemento (pasador metálico).
- Repostar (boquilla + flujo de combustible).
- Abrir/cerrar capó (metal).
- Abrir caja fuerte (manija mecánica + bisagra).
- Contar billetes (papel + clic-clic).

### 17.3 Tablet

- Boot / arranque.
- Notificación crítica (alerta urgente).
- Notificación financiera (moneda).
- Notificación contractual (papel/sello).
- Notificación meteorológica (viento sutil).
- Notificación informativa (bip suave).
- Tap UI.
- Swipe entre vistas.
- Confirmación de acción.
- Error.
- Animación de impresora (motor + papel saliendo).

### 17.4 Ambiente

- Pájaros de mañana en el campo.
- Viento moviendo trigo (sonido vegetal sutil sincronizado con shader).
- Lluvia en metal del granero (distinta a lluvia en hierba).
- Lluvia en cristal del invernadero industrial.
- Tormenta lejana (truenos).
- Bandada de pájaros volando (cuando se asustan en cosecha).
- Insectos en verano (zumbido sutil).
- Silencio del invierno (viento frío + casi nada más).
- Crepitar de chimenea (en casa principal).

### 17.5 Vestuario / oficina

- Bip del lector de tarjeta.
- Apertura de taquilla.
- Tic-tac del reloj de pared (idle).

---

## 18. Anti-patrones específicos del nodo Granja

> Lo que **JAMÁS** vamos a hacer en este nodo, aunque la competencia lo haga.

- ❌ **Menú de "Cosechar campo"** que da items sin animación física.
- ❌ **Click en spot mágico** que aparece grano en el inventario.
- ❌ **Productos sin calidad** (todo igual, todo sale igual).
- ❌ **Crecimiento basado en "tiempo de cooldown"** sin representación visual.
- ❌ **Empresa = solo "boss menu"** (rompe el Pilar 5: la Tablet es el panel real).
- ❌ **Contratos B2B = un menú de selección** sin documento físico.
- ❌ **Sin sistema de empleados real** (solo "trabajos" individuales tipo job script).
- ❌ **Maquinaria comprada en menú** sin entregarla físicamente.
- ❌ **Reparación instantánea** con "click + pago".
- ❌ **Inventario abstracto** ("tienes 500 trigos") sin sacos físicos.
- ❌ **Misma granja replicada infinitas veces** sin diferenciación.
- ❌ **Plagas que se "tratan" con un click** sin la fumigación visible.
- ❌ **Estaciones decorativas** (cambia la luz del cielo pero no afecta gameplay).
- ❌ **Gráficas falsas** en el Manager Panel (renders estáticos sin datos reales).
- ❌ **Productos que no caducan** (almacén infinito sin presión).

---

## 19. Casos de uso narrativos extendidos

### 19.1 Caso A — Marcos, dueño solo

> Marcos lleva la granja él solo. Es lunes por la mañana. Saca la Tablet del bolsillo, abre el Manager Panel, vista Operations.
>
> Ve que la parcela 3 (lechuga) está en stage 4, lista en 6 horas. La parcela 1 (trigo) en stage 5, hay que cosechar hoy. La parcela 4 está en barbecho — la Tablet sugiere plantar maíz porque es verano y el molino paga bien.
>
> Va al granero, engancha la cosechadora con cabezal de cereal. Sale al campo. Cosecha durante 25 minutos — al amanecer, luz dorada. Ve pájaros volar al iniciar. La cosechadora deja rastro físico.
>
> Acerca la cosechadora al silo. Activa el brazo de descarga. Chorro físico de grano cae al silo. El indicador del silo sube de 30% a 75%. Calidad del lote: A (78/100) — riego perfecto, pero estación verano-tardía bajó un poco la nota.
>
> Recibe push: *"Molino Pedro propone contrato suministro recurrente trigo 200 kg/semana a 2.5$/kg con prima de calidad +0.5$ por A o S."* Marcos acepta desde la Tablet. Anima la firma digital. Su impresora del despacho imprime una copia física. Suena.
>
> Va a la oficina. Ve sus billetes en la caja fuerte (4,200$). Abre el libro contable: gastos del mes 6,500$, ingresos previstos 12,000$, beneficio neto +5,500$.
>
> Publica una oferta temporal: *"Cosechar parcela 3 lechuga, pago 400$, hoy"*. En 10 minutos un jugador acepta. Marcos lo ve llegar al portón en directo desde la Tablet.

### 19.2 Caso B — El Equipo de Lucía (5 personas)

> Lucía es dueña de una granja-imperio. Tiene a 4 jugadores empleados:
> - Pablo (gerente, salario fijo + comisión).
> - María (granjera, especialista en hortalizas, salario fijo).
> - Tomás (cosechador, licencia de cosechadora, comisión por hectárea).
> - Diego (transportista, licencia de transporte, salario fijo + km).
>
> Lucía abre Manager Panel → Personnel. Ve eficiencia de cada uno. Pablo asigna tareas del día desde su propia Tablet (gerente). María recibe push: "Sembrar parcela 4 con tomate premium, plantel listo en almacén."
>
> Tomás llega, ficha con tarjeta. Va al granero. Coge la cosechadora. Cosecha trigo en parcela 1 mientras María planta tomate en parcela 4. Ambas tareas en paralelo, ambas progresan en la Tablet en tiempo real.
>
> Diego está cargando el camión refrigerado con cajas de tomate de un lote anterior. Va a entregar al restaurante "La Plaza" con un contrato premium activo (calidad mínima A, paga bien).
>
> Lucía está en la oficina. Ve los gráficos de las gráficas reales: ingresos día 4,200$, costes 1,800$, beneficio 2,400$. Está satisfecha. Firma un nuevo contrato con un supermercado.

### 19.3 Caso C — Servidor RP serio personalizando

> El servidor "WhitelistCity" compra Admirals. Los admins:
> - Cambian la duración de estación a 24h reales (modo Realista).
> - Activan robos (eventos de seguridad, coherente con su lore).
> - Configuran el ciclo de trigo a 90 minutos (más realista para su RP).
> - Limitan a 3 granjas activas simultáneas en el servidor (escasez RP).
> - Reducen el % de bonus aleatorio de cosecha a 1% (RP duro).
>
> El resultado: la economía es lenta, las granjas son negocios serios, los granjeros de WhitelistCity son personajes con peso. Y el script Admirals **soporta todas estas configuraciones sin tocar código**.

---

## 20. Roadmap de oleadas

### Oleada 1 — Lanzamiento

**Cultivos completamente jugables:**
- Cereales: Trigo, Cebada, Maíz.
- Hortalizas frutales: Tomate, Pimiento, Pepino.
- Hojas: Lechuga, Col, Espinaca.
- Bulbos: Cebolla, Ajo.
- Tubérculos: Patata.

**Sistemas:**
- Todos los sistemas (estaciones, calidad, plagas, fertilización, riego múltiple, mantenimiento, empresa, manager panel, contratos B2B, empleados temporales).

**Maquinaria:**
- Toda la flota descrita en §9 (con tuneo Admirals donde aplique).

**MLO:**
- Granja Admirals prefab única completa, con 6 campos + 4 parcelas + 2 invernaderos + silos + cámara + almacén seco + casa + oficina + granero + vestuario.

**Tablet:**
- App Empresa + Manager Panel del granjero + Mercado + Logística + Mensajes + Banca + Notas&Contratos + Tienda Admirals (apps mínimas para que el sistema cierre).

### Oleada 2 — Update gratis tras 2-3 meses

- Cultivos añadidos: Centeno, Avena, Girasol, Caña de azúcar.
- Cabezal de girasol (intercambiable en cosechadora).
- Sistema de **compostaje casero** (residuos vegetales → compost premium).
- Eventos meteorológicos extendidos (granizo con malla anti-granizo premium).
- Sistema de **rotación inteligente** sugerida por la Tablet con histórico.
- **Sistema de robos + seguridad** (§13.4): cámaras, alarmas, perro guardián, contrato con seguridad privada NPC. Opcional por servidor.

### Oleada 3 — Update tras 6 meses

- Cultivos añadidos: Mostaza, especias aromáticas (orégano, albahaca, romero, tomillo).
- ⭐ **Drones agrícolas** (idea del fundador) — flota aérea Admirals con múltiples roles:
  - **Drone fumigador:** niebla de tratamiento desde el aire, cobertura rápida, reducción tiempos.
  - **Drone de monitorización:** sobrevuelo de campos, detección automática de plagas y zonas con problemas → notificación push en Tablet con foto cenital del campo afectado.
  - **Drone de siembra de precisión:** sembrado en zonas difíciles (parcelas en pendiente, zonas con hueco entre cultivos altos).
  - Pilotaje desde la Tablet (app **Drones**) o manual con mando.
  - Licencia de piloto requerida (sistema §9.5 extendido).
- **Cooperativa Agrícola Admirals** (NPC nodo de mercado mayorista — alternativa a vender uno por uno).
- **Compra/venta de empresas** entre jugadores (sistema completo de notaría, valoración automática, escritura).
- **Sistema de exportación** (camión hacia "puerto" para vender a otros servidores ficticios — más precio).

### Hooks para verticales futuras

- **Cuando salga "Distribución hortícola":** todas las hortalizas del almacén frigorífico encuentran demanda real downstream.
- **Cuando salga "Restaurantes / Fast Food":** el tomate, lechuga, patata, etc. tienen demanda directa de cocinas. Los contratos B2B se multiplican.
- **Cuando salga "Mecánico Admirals":** las reparaciones mayores se subcontratan automáticamente. Los mecánicos ganan dinero con la granja.
- **Cuando salga "Energía / Gasolinera":** el dispensador de la granja se abastece desde un nodo Admirals real.
- **Cuando salga "Banca / Inversiones":** la cuenta empresarial puede generar intereses, pedir préstamos, invertir excedentes.

> Cada vertical futura **multiplica el valor** de la Granja sin tocar su código. Esa es la magia del ecosistema.

---

## 21. Estado del documento

- **Versión:** 1.1 (firmado).
- **Próxima revisión:** evolución según oleadas 2-4 (cultivos adicionales, ganadería).
- **Documentos derivados pendientes:**
  - `02_sonar_tablet.md` — diseño completo de la Tablet (con full delegación creativa).
  - `03_node_mill.md` — Molino.
  - `04_node_bakery.md` — Panadería.
  - `05_node_retail.md` — Retail.
  - `economy/01_economic_model.md` — números exactos (precios, salarios, márgenes).
  - `technical/01_architecture.md` — arquitectura técnica.

---

*"A field is not a resource — it is a soldier under the Admiral's command."*
