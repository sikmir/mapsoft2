HEADER(geodata,`Геоданные в Mapsoft2 (2020-01-02)')

define(TT,`<tt>$1</tt>')
define(TB,`<tt><b>$1</b></tt>')
define(TBC,`<tt><b><span color=$1>$2</span></b></tt>')

<h3>Структура геоданных</h3>

<p>Структура геоданных в mapsoft2 (как и в старом mapsoft) может
содержать несколько треков, несколько наборов путевых точек и несколько
наборов карт.

<p>Трек содержит текстовое имя, текстовый комментарий, дополнительные
параметры (ассоциативный массив ключ - значение) и массив точек трека.
Каждая точка трека содержит координаты (lon, lat, alt), время и флаг
начала сегмента. Такая стректура с разбиением треков на сегменты с
помощью расстановки флагов пришла, кажется, из последовательного
протокола передачи данных старых gps-приемников garmin. Она же
используется в формате данных OziExplorer и других старых форматая.

<p>Наборы точек и наборы карт (также, как и треки) содержат текстовое
имя, текстовый комментарий, дополнительные параметры и массив
элементов, путевых точек и карт, соответственно. Такая группировка точек
и карт удобна для использования в графическом интерфейсе: можно загрузить
несколько файлов с точками как отдельные наборы и работать с каждым из
них; можно сгруппировать большое количество карт (например, все
километровки Подмосковья) в один набор и работать только с ним, не
путаясь в длинном списке карт. Операции кэширования картинок во вьюере
оптимизированы для работы с наборами карт, с использованием того факта, что
весь набор всегда показывается как единое целое.

<p>Путевая точка содержит координаты (lon, lat, alt), время, текстовое
имя, текстовый комментарий и набор дополнительных параметров (ключ -
значение). Дополнительные параметры используются, например, при чтании и
записи формата OxiExplorer: вся многочисленная дополнительная информация
о точке сохраняется в виде таких параметров, при записи они попадают в
файл без изменений. При преобразовании из одного формата в другой
некоторые поля могут также сохранятся.

<p>Карта - довольно сложный объект, задающий геодезическую привязку
растровой картинки. В целом он напоминает привязку карты в OziExplorer,
однако содержит различные дополнительные поля, в частности, для поддержки
"плиточных" карт. Такой объект используется в mapsoft2 во всех случаях,
когда надо правильно расположить какое-то изображение на географической
карте, или нарисовать какую-либо карту.

<p> Структура геоданных, в соответствии с файлом TT(geo_data/geo_data.h):

<ul>
<li> TB(`GeoData') -- структура геоданных
  <ul>
  <li>TB(std::list&lt;GeoWptList&gt;) -- списки точек
  <li>TB(std::list&lt;GeoTrk&gt;) -- треки
  <li>TB(std::list&lt;GeoMap&gt;) -- карты
  </ul>
</ul>

<ul>
<li> TB(GeoWptList) -- список точек
  <ul>
  <li>TB(`std::string name, comm') -- имя, комментарий (utf8)
  <li>TB(Opt opts) -- дополнительные параметры (структура TT(Opt) описана в TT(opt/opt.h))
  <li>TB(std::vector&lt;GeoWpt&gt;) -- массив путевых точек
  </ul>
<li> TB(`GeoTrk') -- трек
  <ul>
  <li>TB(`std::string name, comm') -- имя, комментарий (utf8)
  <li>TB(Opt opts) -- дополнительные параметры
  <li>TB(std::vector&lt;GeoTpt&gt;) -- массив точек трека
  </ul>
<li> TB(`GeoMapList') -- список карт
  <ul>
  <li>TB(`std::string name, comm') -- имя, комментарий (utf8)
  <li>TB(Opt opts) -- дополнительные параметры
  <li>TB(std::vector&lt;GeoMap&gt;) -- массив карт
  </ul>
</ul>

<ul>
<li> TB(`GeoWpt') -- путевая точка
  <ul>
  <li>TB(`std::string name, comm') -- имя, комментарий (utf8)
  <li>TB(Opt opts) -- дополнительные параметры
  <li>TB(int64_t) -- Время, миллисекунды от начала 1970 года. Если время не определено, 0.
  <li>TB(dPoint) -- Координаты, TT(`lon, lat, alt'). Широта и долгота в градусах WGS84, высота в
                    метрах над уровнем моря. Если высота не определена, используется значение NaN.
                    Определение структуры TT(dPoint) находится в TT(geom/point.h)
  </ul>
<li> TB(`GeoTpt') -- точка трека
  <ul>
  <li>TB(bool start) -- флаг начала сегмента
  <li>TB(int64_t t) -- Время, аналогично времени в TT(GeoWpt).
  <li>TB(dPoint) -- Координаты, TT(`lon, lat, alt'), аналогично координатам в TT(GeoWpt).
  </ul>
<li> TB(`GeoMap') -- карта
  <ul>
  <li>TB(`std::string name, comm') -- имя, комментарий (utf8)
  <li>TB(`std::map&lt;dPoint,dPoint&gt; ref') -- точки привязки, пары точек, связывающие
    растровые координаты (в пикселах) и географические (в WGS84). Третья координата
    точек (высота) игнорируется.
  <li>TB(`dMultiLine border') -- Граница карты, многосегментная линия в координатах
     карты (пикселах). Определение структуры TT(dMultiLine) находится в TT(geom/multiline.h)
  <li>TB(std::string proj) -- Проекция карты, строчка параметров libproj или
     краткое имя mapsoft2 (нужно бы сделать отдельный текст про преобразование
     координат в mapsoft2!).
  <li>TB(std::string image) -- Название файла с растровым изображением. Для плиточных карт
     используется шаблон, содержащий поля TT(`{x}, {y}, {z}, {q}, {[...]}, {{}, {}}'),
     см TT(`image/image_t.h').
  <li>TB(iPoint image_size) -- Размер картинки в точках. Иногда может быть нулевым (для
     плиточных карт, если картинка недоступна, и т.п.)
  <li>TB(double image_dpi) -- Разрешение картинки, по умолчанию 300dpi. Используется
     редко, в основном для привязки векторных карт.
  <li>TB(bool is_tiled) -- Является ли карта плиточной.
  <li>TB(int tile_size) -- Размер плитки для плиточных карт, по умолчанию 256.
  <li>TB(bool tile_swapy) -- Порядок отсчета плиток для плиточных карт: сверху
     вниз (1) или снизу вверх (0).
  <li>TB(`int tile_minz, tile_maxz') -- Минимальное и максимальное увеличение (параметр z) для
     плиточных карт. По умолчанию - 0 и 18.
  </ul>
</ul>

<h3>Чтение и запись из файлов различных форматов</h3>

<p>При чтении и записи формат файла определяется по его расширению. Кроме
того, можно явно задать формат параметрами TT(--in_fmt) и TT(--out_fmt).
Возможные значения:
<ul>
<li>TB(json) -- GeoJSON, расширение .json,
<li>TB(gu)   -- Garmin Utils, расширение .gu,
<li>TB(gpx)  -- GPX, расширение .gpx,
<li>TB(kml)  -- KML, расширение .kml,
<li>TB(kmz)  -- запакованный KML, расширение .kmz,
<li>TB(ozi)  -- OziExplorer, расширения .wpt, .map, .plt,
<li>TB(zip)  -- архив с данными любых поддерживаемых форматов, только для чтения, расширение .zip.
</ul>

<h4>GPX</h4>

<p>Формат GPX -- стандартный формат gps-приемников garmin, очень
популярный формат для обмена треками и точками. GPX-файл может содержать
в себе произвольное количество треков, точек, а также "маршрутов" (route).

<p>Из файла читаются все треки; все путевые точки помещаются в один
список точек, название которого совпадает с именем файла (без пути и
расширения .gpx); маршруты читаются как дополнительные списки точек. При
записи в файл сохраняются все треки, а все списки точек сливаются в один.
Если же дан параметр "--gpx_write_rte 1", то все списки точек
записываются как отдельные маршруты.

<p>Поле metadata gpx-файла не поддерживается.

<p>Для треков и маршрутов (в формате gpx они устроены похоже) поддерживаются
все основные поля (имя, комментарий), следующие дополнительные поля читаются
в виде дополнительных параметров и при записи в GPX не должны потеряться:

<ul>
<li>gpx_desc -- Text description of route for user. Not sent to GPS.
<li>gpx_src -- Source of data. Included to give user some idea of reliability
                and accuracy of data.
<li>gpx_link -- Links to external information about the route.
<li>gpx_number -- GPS route number.
<li>gpx_type -- Type (classification) of route
</ul>

<p>Полe extension не читаeтся. Было бы полезно извлекать оттуда хотя бы
цвет трека, который иногда закопан там весьма глубоко:
TT(`&lt;extensions&gt;&lt;gpxx:TrackExtension&gt;&lt;gpxx:DisplayColor&gt;Cyan&lt;/gpxx:DisplayColor&gt;&lt;/gpxx:TrackExtension&gt;&lt;/extensions&gt;')

<p>Для путевых точек поддерживаются все основные поля (имя, комментарии,
координаты, высота, время). Следующие поля сохраняются в виде
дополнительных параметров с префиксом gpx_ и при записи обратно в GPX не
должны потеряться:

<ul>
<li>gpx_magvar -- Magnetic variation (in degrees) at the point.
<li>gpx_geoidheight -- Height (in meters) of geoid (mean sea level) above WGS84
<li>gpx_desc  -- A text description of the element. Holds additional information
   about the element intended for the user, not the GPS.
<li>gpx_src -- Source of data. Included to give user some idea of reliability
   and accuracy of data. "Garmin eTrex", "USGS quad Boston North", e.g.
<li>gpx_link -- Link to additional information about the waypoint.
<li>gpx_sym -- Text of GPS symbol name. For interchange with other programs,
   use the exact spelling of the symbol as displayed on the GPS. If the GPS
   abbreviates words, spell them out.
<li>gpx_type -- Type (classification) of the waypoint.
<li>gpx_fix -- Type of GPX fix. (none, 2d, 3d, dgps, pps)
<li>gpx_sat -- Number of satellites used to calculate the GPX fix.
<li>gpx_hdop -- Horizontal dilution of precision.
<li>gpx_vdop -- Vertical dilution of precision.
<li>gpx_pdop -- Position dilution of precision.
<li>gpx_ageofdgpsdata -- Number of seconds since last DGPS update.
<li>gpx_dgpsid -- ID of DGPS station used in differential correction.
</ul>

<p>Поле extension не читается.

<p>Для точек треков читаются/записываются только поля TT(`lat, lon, ele, time').

<p>Параметры, с помощью которых можно управлять записью файла:

<ul>
<li>TB(--xml_compr)     -- Записывать сжатый xml? 1|0, по умолчанию 0. Не уверен,
  что gpx файл, записаный в виде сжатого xml будет понят разными программами.
<li>TB(--xml_indent)    -- Использвать переводы строки и отступы. 1|0, по умолчанию 1;
<li>TB(--xml_ind_str)   -- Отступ, по умолчанию "  ", два пробела;
<li>TB(--xml_qchar)     -- Символ кавычек для xml, по умолчанию ', одиночная кавычка
<li>TB(--gpx_write_rte) -- Сохрянять списки точек, как отдельные маршруты (1) или
  сохранить все точки без разбиения на списки-маршруты (0). По умолчанию 0.


<p>TODO: при чтении выставить имя основного списка точек по имени файла?
При записи всегда сохранять маршруты если списков точек больше одного?

</ul>

<h4>KML и KMZ</h4>

<p>Формат KML - стандартный формат Google Maps. Файл может содержать
сложную структуру каталогов с треками, точками, привязанными картами. KMZ
- запакованная версия. В mapsoft2 поддерживается чтение и запись точек и
треков, но не карт. При этом структура каталогов приводится к структуре
данных mapsoft2, становится плоской.

<p>Списки путевых точек записываются в виде каталогов (KML Folder),
основные поля (имя и комментарий) поддерживаются. При чтении, каталоги,
содержащие хотя бы одну точку, преобразуется в списки точек mapsoft.
Пустые списки точек не могут быть прочитаны из KML-файла. Сами путевые
точки записываются в виде объекта KML Placemark. Все основные параметры
(lon, lat, alt, time, name, comm) поддерживаются.

<p>Треки также записываются в виде объекта KML Placemark. Все основные
параметры треков и их точек поддерживаются, кроме времени, которое
кажется, не поддерживается форматом KML. Кроме того, поддерживаются
открытые/закрытые треки (дополнительный параметр type=open/closed).

<p>При записи файлов используются те же переметры форматирования xml, что и для GPX:
<ul>
<li>TB(--xml_compr)     -- Записывать сжатый xml? 1|0, по умолчанию 0. Не уверен,
  что файл, записаный в виде сжатого xml будет понят разными программами.
  если хочется экономить размер файлов - используйте формат kmz.
<li>TB(--xml_indent)    -- Использвать переводы строки и отступы. 1|0, по умолчанию 1;
<li>TB(--xml_ind_str)   -- Отступ, по умолчанию "  ", два пробела;
<li>TB(--xml_qchar)     -- Символ кавычек для xml, по умолчанию ', одиночная кавычка
</ul>

<p>TODO: Поддержка карт в KML? Надо ли сделать флаг трека
"отрытый/замкнутый" основным параметром (он содержательно используется
при рисовании, поддерживается в KML, Ozi,...)?


<h4>GeoJSON</h4>

<p>Mapsoft2 поддерживает чтение и запись геоданных в формате GeoJSON. В
файле может храниться сложная структура директорий (FeatureCollections) с
различными геометрическими объектами: точками, линиями, многоугольниками.
Поддерживается чтение и запись всей структуры данных mapsoft в файл
GeoJSON. При этом запись разных дополнительных параметров, а также карт
сделана как расширение стандарта GeoJSON, в соответствии с этим
стандартом. В данный момент это единственный формат, в котором можно
хранить структуру данных mapsoft2 без потери информации.

<p>При этом сам формаг GeoJSON поддерживается не полностью:
<ul>
<li>При чтении не сохраняется вложенная структура FeatureCollections,
    она становится "плоской" и приводится к структуре данных mapsoft.
<li>Точки читаются из объектов Point, объекты MultiPoint не поддерживаются.
<li>Треки читаются из объектов LineString, MultiLineString, Polygon, MultiPolygon,
    но записываются всегда в MultiLine. (TODO: записывать замкнутые треки в MultiPolygon).
<li>Объекты GeometryCollection не поддерживаются.
</ul>

<p>Списки точек записываются как директории (FeatureCollection) второго
уровня. При чтении директория любого уровня преобразуется в список точек
в двух случаях: если она содержит хотя бы одну точку, или если она не
содержит точек, треков и карт. Во втором случае создается пустой список
точек. Для имени, комментария и дополнительных параметров списка точек
используются стандартные поля name, cmt и properties.

<p>Треки записываются в директорию первого уровня как объект (Feature) с
многосегментными координатами (MultiLineString), вне зависимости от того,
содержит ли трек один или несколько сегментов. Читаются треки из
директории любого уровня, при этом понимаются одно- и многосегментные
линии (LineString, MultiLineString) и многоугольники (Polygon, MultiPolygon).
Для имени, комментария и дополнительных параметров списка точек используются поля
name, comm и properties.


<p>Координаты путевых точек и точек трека записываются в виде массива
TT(`[lon, lat, alt, time]'). GeoJSON требует наличия только двух первых
элементов, но допускает большее их число и рекомендует, чтобы третьим
элементом была высота. Если время или высота не определены, длина массива
может сокращаться. Если определено время, но не высота, то в качестве
третьего элемента записывается null.

<p>Списки карт записываются как директории второго уровня с
нестандартными полями: TT(ms2maps) для списка карт, TT(ms2maps_name) и
TT(`ms2maps_comm') для имени и комментария, TT(ms2maps_properties) для
дополнительных параметров. Такое расширение сделано из-за того, что
стандарт GeoJSON запрещает создание новых типок, но допускает
нестандартные поля в существующих типах. Для карт не
используются поля name, comm, properties, чтобы в одной директории могли
находиться треки, точки и карты, не мешая друг другу.

<p>Каждый элемент массива TT(ms2maps) содержит объект JSON со следующими полями:
"name", "comm", "proj", "image", "ref", "brd", "image_size", "image_dpi",
"tile_size", "tile_swapy", "is_tiled", "tile_minz", "tile_maxz", "min_scale",
"max_scale", "def_color".

<p>Параметры, с помощью которых можно управлять записью файлов:
<ul>
<li>TT(--json_sort_keys) (default 1) -- Сортировать элеенты json-объектов по названиям
<li>TT(--json_compact) (default 1) -- Записывать компактный json (без пробелов)
<li>TT(--json_indent) (default 0)  -- Использовать отступы
<li>TT(--geo_skip_zt) (default 0) -- Игнорировать высоту и время (TODO: перенести в фильтры?)
</ul>


<h4>OziExplorer</h4>

<p>Программа OziExplorer и ее форматы были очень популярны в нашей
компании до распространения GPX и сайта nakarte. До сих пор (2020) я
храню архивы треков и точек именно в этом виде. Треки, наборы точек и
карты хранятся в отдельных файлах (.plt, .wpt, .map)

<p>Набор путевых точек не поддерживает никаких полей, это просто
контейнер для точек. При чтении файла с точками, набор точек называется
по имени фаайла (без расширения .wpt).

<p>Для путевых точек поддерживаются все основные поля (lon, lat, alt, time, name, comm).
Кроме того, читаются и записываются следующие дополнительные поля:

<ul>
<li>TT(color) -- integer, 0xRRGGBB
<li>TT(bgcolor) -- integer, 0xRRGGBB
<li>TT(ozi_symb) -- integer, 0 to number of symbols in GPS
<li>TT(ozi_map_displ) -- Map Display Format
<li>TT(ozi_pt_dir) -- Pointer Direction
<li>TT(ozi_displ) -- Garmin Display Format
<li>TT(ozi_prox_dist) -- Proximity Distance - 0 is off any other number is valid
<li>TT(ozi_font_size) -- Font Size - in points
<li>TT(ozi_font_style) -- Font Style - 0 is normal, 1 is bold.
<li>TT(ozi_symb_size) -- Symbol Size - 17 is normal size
<li>TT(ozi_prox_pos) -- Proximity Symbol Position
<li>TT(ozi_prox_time) -- Proximity Time
<li>TT(ozi_prox_route) -- Proximity or Route or Both
<li>TT(ozi_file) -- File Attachment Name
<li>TT(ozi_prox_file) -- Proximity File Attachment Name
<li>TT(ozi_prox_symb) -- Proximity Symbol Name
</ul>

<p>Для треков поддерживается поле name, но не comm.
Кроме того, читаются и записываются следующие дополнительные поля:

<ul>
<li>TT(thickness) -- track thickness, integer
<li>TT(color) -- integer, 0xRRGGBB
<li>TT(bgcolor) -- integer, 0xRRGGBB
<li>TT(ozi_skip) -- track skip value - reduces number of track points plotted, usually set to 1
<li>TT(ozi_type) -- track type: 0 - normal, 10 - closed polygon, 20 - Alarm Zone
<li>TT(ozi_fill) -- track fill style: 0 - bsSolid; 1 - bsClear; 2 - bsBdiagonal;
  3 - bsFdiagonal; 4 - bsCross; 5 - bsDiagCross; 6 - bsHorizontal; 7 - bsVertical
</ul>

<p>Для точки трека поддерживаются все поля:
долгота, широта, высота, время, флаг начала сегмента.

<p>В формате OziExplorer каждая привязка карты хранится в отдельном
файле. Соответственно, группировка карт в списки не поддерживаются. При
чтении каждого файла создается отдельный список карт из одного элемента.
(Имя списка дублирует имя карты) При записи все карты из всех списков
записываются в отдельные файлы.

<p>При чтении/записи карт сделано следеющее:
<ul>
<li>Поддерживается небольшой набор систем координат и проекций (можно добавлять).
    Если система координат неизвестна, или же дана опция TT(--ozi_map_wgs 1), то при
    записи карты используется WGS84.
<li>Системы координат, заданные без параметра datum (например, как ellipsoid+shift)
    не поддерживаются.
<li>Перекодирование применяется только к имени карты, но не к названию картинки.
    (кодировка задается опцией TT(--ozi_enc), по умолчанию Windows-1251).
    Поле комментария не поддерживается.
<li>Поддержка точек привязок, записанных в координатах WGS84 или в grid координатах.
    Формат поддерживает до 30 точек приязки. В интерфейсе OziExplorer поддерживалось 4 точки,
    не все программы могут правильно обрабатывать большее количество. Возможно,
    стоит сделать опцию для уменьшения числа точек привязки.
<li>Поддерживается секция Moving Map (MM), граница карты и т.п.
<li>Не поддерживаются секции Map features, Map comments, Attached files, Grids.
</ul>

<p>Параметры, с помощью которых можно управлять чтением/записью файлов:
<ul>
<li>TB(--ozi_enc) -- Кодировка при чтении/записи файлов. По умолчанию Windows-1251.
    Для перекодирования используется библиотека libiconv, список кодировок можно посмотреть
    с  с помощью программы TT(iconv -l).
<li>TB(--ozi_map_grid) -- Записывать точки привязки карты в координатах сетки (default 0)
<li>TB(--ozi_map_wgs)  -- Всегда использовать datum WGS84 для координат карты (default 0)

</ul>


<h4>Garmin Utils</h4>

<p>Очень старый формат, я его много использовал в 1998-1999 годах,
какие-то треки до сих пор у меня так хранятся. Сейчас использовать не
рекомендуется. Файл может содержать несколько безымянных списков точек и
несколько безымянных треков.

<p>Путевые точки записываются в виде строки, разделенный пробелами:
долгота, широта, имя и комментарий. Пробелы в имени заменяются на символ
подчеркивания. (Помните, что garmin gps-12 записывал дату и время точки в
комментарий, а ограничение имени по длине и набору символов было весьма
жестким).

<p>Точки трека записываются в виде строки, разделенный пробелами:
долгота, широта, высота, время, флаг начала сегмента.

<p>Параметры, с помощью которых можно управлять чтением/записью файла:
<ul>
<li>TB(--gu_enc) -- Кодировка при чтении/записи файла. По умолчанию KOI8-R.
    Для перекодирования используется библиотека libiconv, список кодировок можно посмотреть
    с  с помощью программы TT(iconv -l).
</ul>


<h4>Mapsoft XML</h4>

<p>В mapsoft1 геоданные могли быть записаны в странном xml-подобном формате.
Сейчас он не поддерживается.


<h3>Программы для работы с геоданными</h3>

<p>Для преобразования геоданных между разными форматами служит программа
ms2conv (<a href="man/ms2conv.htm">man-страница со всеми
параметрами</a>). Она же может нарисовать геоданные (и не только) в виде
картинке в растровом формате (jpeg, png, gif, tiff) или форматах pdf, ps,
svg.

<p>В программе ms2conv, кроме чтения и записи геоданных реализована их
"фильтрация". Это - разные операции, которые можно выполнить с геоданными
после их чтения:
<ul>
<li>TB(`--skip <arg>') -- Удалить некую часть геоданных. Аргумент - последовательность
  букв, показывающих, что именно надо удалить: W - путевые точки, T - треки, M - карты,
    t - время из точек, z - высоту из точек, b - границы карт.

<li>TB(`--join') -- Объединить все списки точек, треки и списки карт.

<li>TB(`--name <arg>') --  Set name in the first waypoint lists, track, or map list.

<li>TB(`--comm <arg>') --   Set comment in the first waypoint list, track, map list.

<li>TB(`--nom_brd') -- Если название карты является названием советского
номенкларурного листа, то для этой карты устанавливается соответствующая
граница.

<li>TB(`--rescale_maps <arg>') -- Перемасштабировать растровые координаты
в точках привязки карты. Может потребоваться при перемасштабировании.
растровой картинки.

<li>TB(`--shift_maps <arg>') -- Сдвинуть растровые координаты
в точках привязки карты. Может потребоваться при сдвиге растровой картинки
(например, при ее обрезании).

</ul>

<p>Иногда требуется преобразовать трек в текстовую таблицу (например, для
построения графиков высоты и скорости от расстояния и т.п.) Для этого
служит программа ms2xyz (<a href="man/ms2xyz.htm">man-страница со всеми
параметрами</a>).


<h3>Работа с геоданными в программе ms2view</h3>

<p>В программе ms2view в правой части находится панель, показывающая
структуру геоданных. В ней три вкладки: набор списков точек, набор треков,
набор списков карт. Показываются названия соответствующих объектов и
влаги, позволяющие показывать и скрывать их на карте.

<p>Есть три места, откуда можно редактировать геоданные:
<ul>
<li> Меню в правой панели.
<li> Верхнее меню, пункт Edit.
<li> Режим Edit geodata, возможность редактировать геоданные мышкой на карте,
     связанное с геоданными меню.
</ul>

