# EMSafe Calibre — Sistema de diseño (v1.0.0)

Documento compartido por `Front-End_` (Angular) y `Mobile_App` (Flutter). La fuente única de las
decisiones visuales es **`design-tokens/emsafe.tokens.json`**, idéntico en ambos repositorios.

## 1. Concepto

**Industrial Precision + Enterprise Technology.** La interfaz se comporta como un instrumento de
medición: superficies sobrias, filetes de 1 px, cifras en tipografía monoespaciada y una **regla
graduada** como firma visual (bajo encabezados, en barras de dosis y medidores). El color se reserva
para el estado; la marca (índigo "flux") marca la interacción y el cobre distingue lo editorial y lo
generado por IA.

### Principios
1. **Instrumento, no decoración.** Cada elemento gráfico comunica una lectura, un estado o una acción.
2. **Filetes antes que tarjetas.** Se separa con líneas y tiras de lecturas; las tarjetas son la excepción.
3. **Las cifras primero.** Valores en IBM Plex Mono con cifras tabulares y la unidad siempre visible.
4. **Disciplina de señal.** Verde = seguro, amarillo = advertencia, rojo = peligro/excedido. Nunca solo
   color: siempre etiqueta + icono o texto.
5. **Honestidad del dato.** En vivo, sin actualizar, sin conexión, sincronizando y pendiente de
   confirmación se representan de forma explícita. Una orden al enchufe no se muestra ejecutada hasta
   la confirmación del Edge. EMSafe no se presenta como instrumento certificado.
6. **IA identificable.** Todo contenido generado por IA lleva el acento cobre y la etiqueta "IA".

## 2. Color

| Rol | Claro | Oscuro | Uso |
|---|---|---|---|
| `primary` (Flux) | `#3D35C4` | `#9C96FF` | Interacción, selección, foco |
| `chrome` (Grafito) | `#14171C` | `#090B0E` | Navegación (rail web, barra inferior móvil): siempre oscuro |
| `chrome-accent` | `#A9A4FF` | `#A9A4FF` | Ítem activo sobre el cromo |
| `accent` (Cobre) | `#A3541F` | `#E08C55` | Índices editoriales, contenido de IA |
| `bg` / `surface` / `surface-overlay` | `#F2F3F5` / `#FFF` / `#FFF` | `#0D0F13` / `#14171C` / `#20252C` | Fondo, superficie, capas |
| `border` / `border-strong` | `#DDE0E5` / `#B9BFC9` | `#272C34` / `#3A414C` | Filetes |
| `text` / `-secondary` / `-tertiary` / `-disabled` | `#12151A` … `#A3AAB5` | `#ECEEF1` … `#535A66` | Jerarquía de texto |
| `safe` (+`-signal`, `-subtle`, `-border`) | `#17784A` | `#56C98D` | Seguro / en línea |
| `warning` | `#855F00` · señal `#E0A800` | `#F0C33C` · señal `#E8B21C` | Advertencia / dato sin actualizar |
| `danger` | `#B3261E` · señal `#DC3B2F` | `#FF7A6E` · señal `#F0544A` | Peligro; **excedido = relleno sólido** (`critical`) |
| `info` | `#1F5C96` | `#7DB2E8` | Información, en proceso |
| `live` | `#087A8C` | `#4FD0E2` | Tiempo real, sincronización |
| `offline` | `#8A919D` | `#6C7380` | Sin conexión |
| `chart-1…5` | índigo, cian, cobre, acero, azul | — | Series de gráficos (no de estado) |

Cada estado tiene cuatro variantes: texto (`safe`), señal (`safe-signal`), fondo (`safe-subtle`) y
borde (`safe-border`). El logotipo oficial conserva su cian original (`#3FE3EC`) solo en la marca.

### Conectividad y frescura
| Estado | Indicador |
|---|---|
| En vivo | punto verde con anillo animado |
| En línea | punto verde |
| Sin actualizar (stale) | aro amarillo hueco |
| Sincronizando | punto cian intermitente |
| Pendiente de confirmación | aro índigo discontinuo |
| Sin conexión | punto gris + texto atenuado |

## 3. Tipografía

| Familia | Uso |
|---|---|
| **Barlow Semi Condensed** (500/600/700) | Títulos, antetítulos en mayúsculas, etiquetas de navegación agrupada |
| **IBM Plex Sans** (400/500/600) | Texto, formularios, botones, tablas |
| **IBM Plex Mono** (400/500/600) | Métricas, identificadores, fechas, unidades, etiquetas de estado |

Escala (px · interlineado): `display 44/48` · `h1 32/38` · `h2 24/30` · `h3 20/26` · `h4 17/22` ·
`eyebrow 12/16 (+1.4 tracking, mayúsculas)` · `label 13/18` · `body-lg 16/24` · `body 14/21` ·
`body-sm 13/19` · `caption 12/16` · `metric-xl 44/48` · `metric-lg 30/34` · `metric-md 20/26` ·
`mono 13/18` · `mono-sm 11/14`. Las métricas usan cifras tabulares y cero barrado. En web la escala
se expresa en `rem` para respetar la preferencia de tamaño (S/M/L). Fuentes locales: web con
`@fontsource/*` (empaquetadas en el build), móvil con TTF en `assets/fonts` (OFL).

## 4. Espaciado, grid y dimensiones

- Escala: `0, 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64` (tokens `space-0…11`).
- Breakpoints: `sm 600`, `md 900`, `lg 1200`, `xl 1440`.
- Web: grid de 12 columnas (`.ems-grid`, `span-*`), contenido máx. 1440 px, formularios 760–1080 px.
- Controles: 32 / 40 / 48 px. Área táctil mínima 48 px. Rail 248 px (68 compacto), barra superior 60 px,
  barra inferior móvil 68 px + safe area.

## 5. Superficies y profundidad

Radios `xs 2 · sm 4 · md 6 · lg 10` (solo hojas inferiores) · `pill` solo para interruptores y puntos.
Bordes `hairline 1`, `strong 2`, `rail 3` (riel de estado). Elevación: 0 en superficies, `1` para
segmentos activos, `2` para popovers, `3` para modales y toasts. Modales con velo (`scrim`).
Patrones: **tira de lecturas** (`.ems-readouts`, celdas separadas por filetes), **hoja de formulario**
(`.ems-sheet`, secciones numeradas), **registro** (filas con riel de severidad), **banda de estado**.

## 6. Iconografía

Una sola familia: **Phosphor, estilo Regular (outline)**, en web (`@phosphor-icons/web`, clases `ph`)
y móvil (fuente vendorizada `assets/fonts/Phosphor-Regular.ttf` + `lib/design_system/ems_icons.g.dart`;
el paquete `phosphor_flutter` no compila con el SDK actual). Sin emojis ni iconos rellenos mezclados.
Mapa de servicios: Instalación `plugs-connected`, Mantenimiento `wrench`, Recolección `package`.

## 7. Motion

Duraciones `instant 80`, `fast 120`, `base 180`, `slow 260` ms; curvas `standard (0.2,0,0,1)`,
`enter (0,0,0,1)`, `exit (0.4,0,1,1)`. Usos: aparición de modales (fade + 8 px), barras de progreso,
indicador de pestaña, pulso del estado "en vivo". Con `prefers-reduced-motion` / "reducir animaciones"
las animaciones se anulan.

## 8. Componentes

| Componente | Web (Angular) | Móvil (Flutter) | Variantes / estados |
|---|---|---|---|
| Botón | `.ems-btn` | `FilledButton` / `OutlinedButton` / `TextButton` (tema) | primary, secondary, ghost, subtle, danger, danger-ghost; sm/md/lg; icono; disabled; cargando |
| Campo / select / textarea / búsqueda / fecha | `.ems-field`, `.ems-input`, `.ems-select`, `.ems-textarea`, `.ems-search`, `input[type=date]` | `InputDecorationTheme` | foco, inválido, deshabilitado, ayuda, error |
| Contraseña | `.ems-password` | `_FieldBlock` (login) | visible / oculta |
| Checkbox / radio / switch | `.ems-check`, `.ems-radio`, `.ems-switch` | temas de Checkbox / Switch | — |
| Pestañas / segmentado | `.ems-tabs`, `.ems-segmented` | — | activo |
| Navegación | `NavRail` (agrupada, compacta), `Topbar` | `Stage3BottomNav` | activo, drawer |
| Breadcrumb | `.ems-breadcrumb`, `.ems-page-head__eyebrow` | — | — |
| Encabezado de página | `<ems-page-header>` | `Etapa3Shell` | antetítulo + índice + regla graduada |
| Etiqueta de estado | `.ems-tag--{safe,warning,danger,critical,info,live,primary,accent}` | `EmsTag` | con marca o icono |
| Conectividad | `.ems-signal--{live,online,stale,syncing,pending,offline}` | `EmsSignal` | — |
| Contador | `.ems-count` | — | danger, primary |
| Panel / sección | `.ems-panel`, `.ems-section` | `EmsPanel`, `GlassPanel`, `EmsSectionHeader` | con riel |
| Lectura / KPI | `.ems-readouts` + `.ems-readout` | `EmsReadout`, `MetricTile` | safe/warning/danger/primary |
| Tabla | `.ems-table` + `.ems-toolbar` + `<ems-pager>` | listas con filetes | orden, búsqueda, filtros, paginación, acciones por fila |
| Gráficos | ApexCharts con `chartTokens()` | `TrendCard`, medidores | leyenda, unidad, tooltip, vacío |
| Medidor / barra de dosis | `.ems-dosebar`, `.ems-progress` | `ExposureGauge`, `LiveReadingHero`, `EmsDoseBar` | advertencia, límite |
| Aviso | `.ems-banner--*` (incluye `--ai`) | `EmsBanner`, `ExposureStatusBand` | — |
| Toast | `<app-toast>` | `SnackBarTheme` | success, warning, error, info |
| Modal / diálogo | `.ems-backdrop` + `.ems-modal` | `DialogTheme` | lg, alertdialog |
| Bottom sheet | — | `BottomSheetTheme` | — |
| Menú / popover / tooltip | `.ems-popover`, `.ems-menu__item`, `[data-tooltip]` | `TooltipTheme` | — |
| Esqueleto / carga | `.ems-skeleton`, `.ems-loading`, `.ems-progress--indeterminate` | `EmsSkeleton`, `Etapa3Loading` | — |
| Vacío / error / sin conexión / sin permiso | `<ems-empty-state kind>` | `EmsEmptyState(kind)` | — |
| IA | `.ems-banner--ai`, `.pill--accent` | `EmsAiBadge` | — |
| Marca | `<ems-brand-mark>` | `EmsBrandMark` | con/sin logotipo |

## 9. Uso

### Angular
- Tokens: `npm run tokens` genera `src/styles/_tokens.scss` (variables `--ems-*`, tema claro en `:root`
  y oscuro en `:root.theme-dark`) y `_tokens-maps.scss`. `npm run tokens:check` verifica que estén al día.
- En componentes: `@use 'styles/mixins' as ems;` → `@include ems.type(h3)`, `ems.up(md)`, `ems.tone(safe)`,
  `ems.scale-rule()`, `ems.panel`. Nunca valores hex sueltos: siempre `var(--ems-*)`.
- Componentes compartidos en `src/app/shared/ui` (`PageHeader`, `EmptyState`, `Pager`, `BrandMark`) y
  clases globales `.ems-*` en `src/styles/_components.scss`.
- Gráficos: `chartTokens()`, `axisLabels()`, `gridOptions()` de `core/utils/chart-theme.ts`.

### Flutter
- Tokens: `dart run tool/generate_tokens.dart` genera `lib/design_system/ems_tokens.g.dart`
  (`emsLight`/`emsDark`, `EmsLightColors`/`EmsDarkColors` const, `EmsSpace`, `EmsRadius`, `EmsTypeScale`…).
  `test/design_tokens_test.dart` falla si el código no coincide con el JSON.
- `import 'package:emsafe_app/design_system/design_system.dart';` → `context.ems.primary`,
  `context.type.h2`, widgets `Ems*`, iconos `PhosphorIconsRegular.*`.
- Tema: `EmsThemeData.light()` / `.dark()` (la app usa oscuro por defecto).

## 10. Reglas para nuevas pantallas

1. Cambiar un valor visual = editar el JSON, regenerar en ambos repos y copiar el archivo al otro repo.
2. No introducir colores, fuentes, radios o sombras fuera de los tokens.
3. Todo estado de exposición se muestra con color + etiqueta + icono; advertencia y excedido son distintos.
4. Toda pantalla contempla carga, vacío, error, sin conexión y dato desactualizado.
5. Contenido de IA siempre con el acento cobre y su etiqueta; los cálculos deterministas nunca lo usan.
6. Preferir filetes, tiras de lecturas y hojas numeradas antes que tarjetas repetidas.
7. Áreas táctiles ≥ 48 px en móvil; foco visible y etiquetas accesibles en web.

## Patrones móviles (segunda iteración)

Ampliación de EMSafe Calibre para el pulgar. Mismos tokens; no es un sistema paralelo.

| Componente | Archivo | Uso |
|---|---|---|
| `EmsPage` / `EmsPageHeader` | `ems_mobile.dart` | Página empujada: volver, antetítulo, título y regla graduada; acción fija inferior y deslizar para recargar |
| `EmsButton` | `ems_mobile.dart` | primary / secondary / ghost / danger, con estado de carga |
| `EmsField` | `ems_mobile.dart` | Etiqueta superior, ayuda de formato, error en línea, validación al escribir |
| `EmsSegmented`, `EmsStepProgress` | `ems_mobile.dart` | Rangos y filtros; progreso de flujos por pasos |
| `EmsGroup`, `EmsRow`, `EmsKeyValue`, `EmsExpandable` | `ems_mobile.dart` | Fichas con filete; datos técnicos plegados |
| `showEmsSheet`, `showEmsConfirm` | `ems_mobile.dart` | Hojas inferiores y confirmaciones con tono |
| `EmsRangeChart`, `EmsSparkBars`, `EmsChartLegend` | `ems_charts.dart` | Barras verticales por tramo (mín–máx), huecos huecos, selección táctil |

### Gráficos en tres niveles
1. **Resumen** (`MeasurementOverview`): 24 H / 7 D / 30 D (o la jornada), rango, última lectura, promedio, recuento y "Ver todos los datos".
2. **Histórico** (`ReadingHistoryScreen`): 7 días / 30 días / todo, navegación por día, 24 tramos horarios, días vacíos agrupados.
3. **Detalle de lectura**: hogar (nivel, escala, captura, sensor) y dosímetro (captura vs. recepción, sincronización tardía).

Reglas: un tramo sin lecturas se dibuja hueco, nunca como cero; el campo instantáneo (µT) no se mezcla con la dosis acumulada (µT·s, %); las barras rayadas marcan lecturas sincronizadas tarde.
