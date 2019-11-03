HEADER(mapdb,`
  ENRU(`Векторные карты в Mapsoft2 (2019-11-03)')
')

<p>В данный момент поддержка векторных карт в mapsoft находится
в состоянии разработки. Еще не все сделано, возможны любые изменения.

<!--#################################################################-->

<hr><h3>Формат MapDB для хранения карт и интерфейс в mapsoft2</h3>

MapDB - формат для хранения векторных карт в mapsoft2. Он представляет из
себя директорию с несколькими базами данных BerkleyDB:

<ul>
<li> mapinfo.db -- информация о карте
<li> geohash.db -- данные для гео-индексации
<li> objects.db -- информация об объектах
<li> labels.db  -- информация о подписях объектов
</ul>


<p>Кроме того, в этой же директории могут находиться разные дополнительные
файлы, например, конфигурационный файл для изготовления растровых
картинок.

<p>В данный момент никакого окружения BerkleyDB не создается, каждый файл
является независимой базой данных, одновременно работать с базой данный
может только одна программа. В будущем при необходимости можно будет
делать окружение с блокировками, логами, транзакциями... В базах данных
используются только дефолтные функции сравнения ключей, поэтому все
утилиты для работы с базами BerkleyDB (db_load/db_dump и т.п.) должны
работать.

<p>В базах данных mapinfo.db, objects.db, labels.db используется целый
32-битный ключ и произвольные данные в качестве значения. В этих данных
может быть запакована достаточно сложная структура. При это используется
упаковка данных в стиле RIFF: 4-символьный тэг ("crds", "name" и т.п.),
4-байтовое число - длина данных в байтах, данные. Для текстовых данных
(название объекта, комментарии и т.п.) используется кодировка UTF8.

<div class="c_api">
<p>В mapsoft2 карта представляется классом MapDB (см. modules/mapdb/mapdb.h).

<p><tt>  MapDB::MapDB(std::string name, bool create)</tt> -- Конструктор.
Открыть карту в директории с именем name. Если create=true, то
отсутствующие db-файлы будут созданы заново.
</div>

<!--########################-->
<h4>База данных mapinfo.db</h4>

База данных с 4-байтовым целочисленным ключем для хранения различной
информации о карте. В данный момент поддерживаются следующие ключи:

<ul>

<li>0. Версия формата MapDB, целое число записанное в виде строки.
Сейчас, пока формат еще активно разрабатывается и меняется, это "0".

<p>При открытии карты проверяется ее версия. Если версия карты не
установлена (например, база данных создается заново) то устанавливается
актуальное значение (зашитое в программе). Если версия карты новее, чем
это значение, то возникает ошибка.

<li>1. Название карты (строка). Устанавливается пользователем,
может иметь любое значение.

<li>2. Граница карты. Многоугольник с несколькими сегментами (объект
dMultiLine) упакованный в стиле RIFF с тэгом "crds" для каждого
сегмента. Сегмент состоит из пар координат (lon1,lat1,
lon2,lat2,...), Координаты - градусы в системе WGS84, умноженные на 1e7 и
округленные к ближайшему 4-байтовому целому числу. Граница карты
может быть установлена пользователем и иметь любое значение (в частности,
быть пустой).


</ul>

<p>Есть ощущение, что поле границы карты может быть ненужным (и пока оно
нигде не используется). Границу можно хранить в конфигурационном файле
для изготовления растровых картинок и использовать разные границы для
разных картинок изготовленных из одной карты. То же самое - с именем
карты.

<div class="c_api">
<p>Функции для работы с информацией о карте:

<p><tt>uint32_t MapDB::get_map_version() const;</tt> -- получить версию карты
версии.

<p><tt>  std::string MapDB::get_map_name()</tt> -- получить имя карты

<p><tt>  void MapDB::set_map_name(const std::string & name)</tt> -- изменить имя карты.

<p><tt>  dMultiLine MapDB::get_map_brd()</tt> -- получить границу карты

<p><tt>  void MapDB::set_map_brd(const dMultiLine & b) -- установить границу карты
<div>

<!--########################-->
<h4>База данных geohash.db</h2>

<p>База данных для геоиндексации. Ключ базы состоит из классификации и
типа объекта (целое беззнаковое число, 32 бита) и строки _GEOHASH_.
Значение - идентификатор объекта. Ключи могут повторяться.
Данные должны быть синхронизованы с координатами в базе данных
objects.db.

<p>Одному объекту соответствует до четырех записей, при этом исключаются
слишком короткие геохэши для небольших объектов, попавших на границы деления.


<!--########################-->
<h4>База данных objects.db</h2>

<p>Информация об объектах. Ключ - идентификатор объекта (беззнаковое
32-битовое целое число), значение - структура со следующими полями:

<ul>

<li>Классификация и тип объекта, 32-битное целое число. Биты 0..13 не
используются, биты 14 и 15 используются для классификации объекта
(поддерживаются значения: 0-точка, 1-линия, 2-многоугольник). Биты 16..31
(два последних байта) - собственно, тип объекта.

<p>Все остальные поля - необязательны. Они запакованы в стиле RIFF в
произвольном порядке.

<li>Наклон объекта представлен в виде 4-байтового целого числа, в
единицах 1/1000 градуса. Запакован с тэгом "angl". Может относиться к
любому объекту, хотя обычно используется для точек и показывает, как
следует ориентировать знак, изображающий эту точку. В данный момент
наклон считается от "верха карты". То есть, если рисовать карту в разных
проекциях, объекты с наклоном 0 всегда будут ориентированы вверх.
Возможно, следует отсчитывать наклон от географического севера. В даный
момент отсутствие информации о наклоне объекта эквивалентно наклону 0.
Возможно, следует различать эти значения.

<li>Ориентация объекта (используется для линий) представленна в виде
4-байтового целого числа: 1 - прямая, 2 - обратная, 0 - не определена.
Запаковано с тэгом "dir ". Может относиться к любому объекту, хотя обычно
используется для линий и многоугольников и показывает, как следует
ориентировать дополнительные штрихи на линии. Отсутствие информации об
ориентации эквивалентно значению 0. Возможно, от этого поля следует
отказаться. Возможно, надо использовать только два значения
"прямая"/"обратная".

<li>Название объекта, строка, запакованая
с тэгом "name". То, что должно отображаться на карте.

<li>Комментарий к объекту, строка, запакованая с тэгом "comm". На карте
не показывается.

<li>Тэги объекта, произвольное число строк, запакованных с тэгами "tags".
Могут быть использованы для маркировки некоторой части объектов. Например,
при импорте перевалов из каталога перевалов все они маркируются неким тэгом.
При обновлении старые объекты с этим тэгом удаляются и добавляются новые
(Тут, кстати, будет важна перепривязка подписей!)

<li>Координаты. Многосегментная линия, закодированная в строку также, как
поле границы карты в базе данных mapinfo.db с тэгами "crds". При
обновлении координат объекта также должна обновляться база
геоиндексации.

</ul>

<p> С точки зрения базы данных никакой разницы между точками, линиями и
площадными объектами нет. Различается только тип объекта. В данный момент
не слишком хорошо определено, как должен обрабатываться точечный объект,
содержащий несколько координат. Вероятно, все они должны быть
нарисованы с одними и теми же параметрами. Объекты не могут быть пустыми
(не содержать координат). Такой запрет связан с невозможностью разместить
такой объект в базе geohash.db, и, соответственно, невозможностью получить
его тип с помощью <tt>get_etypes()</tt>.

<div class="c_api">
<p>В mapsoft2 объект представлен классом MapDBObj (см. modules/mapdb/mapdb.h).
Для него определены операции сравнения, конструктор с некими дефолтными
значениями, функции для запаковки/распаковки объекта при хранении в базе
данных.

<p>Карта имеет следующие функции для работы с объектами (эти функции
используют базу данных objects.db для чтения/записи информации об
объектах и базу данных geohash.db для работы с геоиндексацией, обеспечивая их
синхронизацию):

<p><tt>  uint32_t MapDB::add(const MapDBObj & o)</tt> -- добавить новый объект
на карту, вернуть его идентификатор. Идентификатор получается добавлением
единицы к самому большому идентификатору данной карты (или 0, если карта
пуста). При переполнении возникает ошибка. При попытке положить пустой объект
(без координат) возникает ошибка.

<p><tt>  void MapDB::put(uint32_t id, const MapDBObj & o)</tt> --
перезаписать объект с заданным идентификатором. Если объект не
существует, возникает ошибка. При попытке записать пустой объект
(без координат) возникает ошибка.

<p><tt>  void MapDB::del(uint32_t id)</tt> -- удалить объект с заданным
идентификатором. Если объект не существует, возникает ошибка.

<p><tt>  std::set<uint32_t> find(MapDBObjClass cl, uint16_t type,
  const dRect & range) </tt> -- найти идентификаторы объектов
заданного типа, которые попадают в заданный диапазон координат.
Параметр cl может принимать следующие значения: 0 or MAPDB_POINT,
1 or MAPDB_LINE, 2 or MAPDB_POLYGON.

<p><tt>  std::set<uint32_t> find(int etype, const dRect & range) </tt> --
то же самое, но используется 32-битный тип, <tt>etype = (cl&lt;&lt;16) +
type</tt>.

<p><tt>  std::set<uint32_t> get_etypes() </tt> -- Получить множество всех
типов объектов в базе данных. Возвращаются 32-битные типы (последние два
байта - 16-битный тип, биты 14 и 15 - классификация объекта: точка,
линия, площадной объект).
</div>

<p>Таким образом, база данных имеет функции для быстрого выбора объектов,
имеющих заданный тип и попадающих в заданный диапазон координат. При дальнейшей
обработке этих объектов имеет смысл проверять 

<!--########################-->
<h4>База данных labels.db</h2>

<p>Подписи к объектам. Ключ - ID объекта (разрешено
дублирование ключа), значение - структура с некоторыми полями (пока не
сделано).

<p>TODO: отвязка от объекта.

<!--#################################################################-->
<!--#################################################################-->
<hr><h3>Программа ms3mapdb для работы с векторными картами</h3>


<p>Для произведения разных операций с векторными картами используется
программа ms3mapdb:

<p><tt><pre>
$ ms2mapdb (-h|--help|--pod)
$ ms2mapdb <action> (-h|--help)
$ ms2mapdb <action> [<action arguments and options>]
</pre></tt>

<p>Операции:

<ul>
<li><tt>import_mp</tt> -- загрузить карту в формате MP
<li><tt>export_mp</tt> -- сохранить карту в формате MP
<li><tt>import_vmap</tt> -- загрузить карту в формате VMAP
<li><tt>export_vmap</tt> -- сохранить карту в формате VMAP
<li><tt>render</tt> -- получить изображение карты
</ul>

TODO: добавление отдельных объектов; удаление объектов по тэгу или типу,
удаление всех объектов; создание новой карты.

<!--#################################################################-->
<!--#################################################################-->
<hr><h3>Формат MP</h3>

<!--########################-->
<h4>Поддержка формата MP в mapsoft2</h4>

<p>Описание формата: cGPSmapper-UsrMan-v02.4.pdf (найти в интернете!)

<p>В mapsoft2 карта представляется классом MP, а объект - классом MPObj
(см. modules/mp/mp.h) Поддерживается чтение и запись карты в MP-файл.
Читаются и записываются:

<p>Заголовок файла, секция [IMG ID], включая комментарии, находящиеся
перед этой секцией. Внутри секции может находиться большое число разных
параметров, записанных в виде &lt;ключ&gt;=&lt;значение&gt; Часть
параметров читаются в соответствующие поля структуры MP и проверяются.
Остальные хранятся в виде текстовых строк в объект типа Opt. Таким
образом, при чтении и записи файла пaрaметры, даже нестандартные, не
должны теряться (но если файл импортируется в MapDB, то почти все -
теряется). Если читаются несколько файлов MP, то используется заголовок
от последнего файла, а все объекты объединяются.

<p>Точечные, линейные и площадные объекты, секции [POI], [POLYLINE],
[POLYGON], включая комментарии, находящиеся перед этими секциями. При
чтении понимаются старые названия секций [RNG*]. Остальные секции не
читаются. В каждом объекте читаются параметры Type, Label, EndLevel,
Direction, Data* или Origin*. Данные могут находиться в разных слоях,
объявленных в заголовке. TODO: читать/записывать все поля, в том
числе - нестандартные, использующиеся в mapsoft1.

<p>Параметр заголовка CodePage (если он присутствует) используется для
преобразования текстовых строк: имени карты (Name), комментариев и всех
неизвестных параметров. Значение должно соответствовать windows codepage,
по умолчанию: 1251 (возможно, следует заменить на что-то более нейтральное).


<!--########################-->
<hr><h4>Импорт и экспорт карт в формате MP</h4>

<p>Для импорта карты из формата MP ("Польский" формат) в формат MapDB
используется метод <tt>MapDB::import_mp<tt> или программа
ms2mapdb.

<p><tt> void MapDB::import_mp(const string & mp_file, const Opt & opts)</tt>

<p><tt> $ ms2mapdb import_mp &lt;mapdb_folder&gt; &lt;mp_file&gt; &lt;options&gt;</tt>

<p>Параметр <tt>--config &lt;file&gt;</tt> задает конфигурационный файл.
При использовании конфигурационного файла объекты по умолчанию не
импортируются, все нужные правила надо явно указать в файле. Если же
конфигурационный файл не используется, то все объекты импортируются с
сохранением типов. В дополнение к конфигурационному файлу можно
использовать параметры командной строки (они имеют приоретет). В
конфигурационном файле допустимы комментарии (начинающиеся с символа #),
пустые строки, одинарные и двойные кавычки, символ \ для защиты
специальных символов. Могут использоваться следующие команды:

<ul>

<li><tt>(point|line|area) &lt;in_type&gt; [&lt;out_type&gt;]</tt> --
преобразовать точечные, линейные, площадные объекты с типом in_type в тип
out_type. Значение in_type=0 соответствует объектам любого типа. Значение
out_type=0 (или отсутствие этого аргумента) означает, что тип объекта не
меняется. Из нескольких строчек, относящихся к одному объекту приоритет
имеет первая. Например, строчка <tt>line 0x10 0x11</tt> означает, что
линии с типом 0x10 преобразуются в линии с типом 0x11. Следующая линия
<tt>line 0</tt> означает, что все остальные линии преобразуются без
изменения типа. Правила преобразования типов можно также задать с помощью
параметров командной строки: --cnv_points, --cnv_lines, --cnv_areas.
Аргумент этих команд - json-массив из пар чисел, например
[[10,10],[0,0]]. Шестнадцатеричные числа можно записывать в виде строк
[["0x16","0xA"]. Параметры командной строки имеют приоритет над
конфигурационным файлом.

<li><tt>level &lt;N&gt;</tt> -- брать данные, соответствующие определенному
уровню детализации. Соответствующий параметр командной строки: --data_level.

</ul>


<p>Для экспорта карты из MapDB в формат MP используется метод
export_mp или вызов программы ms2mapdb:

<p><tt> void MapDB::export_mp(const string & mp_file, const Opt & opts)</tt>

<p><tt> $ ms2mapdb export_mp &lt;mapdb_folder&gt; &lt;mp_file&gt; &lt;options&gt;</tt>

<p>Использование параметров командной строки и конфигурационного файл аналогично
импорту карт. Допустимые команды:

<ul>

<li><tt>(point|line|area) &lt;in_type&gt; [&lt;out_type&gt;]</tt> --
см. import_mp.

<li><tt>codepage &lt;value&gt;</tt> -- установить кодировку MP-файла
(windows codepage). Соответствующий параметр командной строки:
--codepage.

<li><tt>name &lt;value&gt;</tt> -- Установить имя MP-файла.
Соответствующий параметр командной строки: --name.

<li><tt>id &lt;value&gt;</tt> -- Установить ID MP-файла. Соответствующий
параметр командной строки: --id.

</ul>

<!--#################################################################-->
<!--#################################################################-->
<hr><h3>Формат VMAP</h3>

VMAP - текстовый формат хранения векторнных карт, использующийся в
mapsoft1.

<p>Для импорта карты из MapDB в формат VMAP используется метод
export_vmap или вызов программы ms2mapdb:

<p><tt> void MapDB::export_vmap(const string & vmap_file, const Opt & opts)</tt>

<p><tt> $ ms2mapdb export_vmap &lt;mapdb_folder&gt; &lt;vmap_file&gt; &lt;options&gt;</tt>

<p>Использование параметров командной строки и конфигурационного файл аналогично
импорту карт в формате MP. Допустимые команды:

<ul>

<li><tt>(point|line|area) &lt;in_type&gt; [&lt;out_type&gt;]</tt> --
см. import_mз.

</ul>

<p>Для экспорта карты из MapDB в формат VMAP используется метод
export_vmap или вызов программы ms2mapdb:

<p><tt> void MapDB::export_vmap(const string & vmap_file, const Opt & opts)</tt>

<p><tt> $ ms2mapdb export_vmap &lt;mapdb_folder&gt; &lt;vmap_file&gt; &lt;options&gt;</tt>

<p>Использование параметров командной строки и конфигурационного файл аналогично
экспорту карт в формате MP. Допустимые команды:

<ul>

<li><tt>(point|line|area) &lt;in_type&gt; [&lt;out_type&gt;]</tt> --
см. import_mp.

</ul>

<!--#################################################################-->
<!--#################################################################-->
<hr><h3>Рендер изображения карты</h3>

<p>Для получения изображение карты можно использовать команду командной строки:

<p><tt> $ ms2mapdb render &lt;mapdb_folder&gt; &lt;output_file&gt; &lt;options&gt;</tt>

<p>Конфигурационный файл передается через параметр --config. По умолчанию
используется файл render.cfg в директории MapDB.

<p>Кроме того, изображение карты можно смотреть в программе ms2view, передав
директорию с картой через параметр командной строки --mapdb и название
конфигурационного файла через параметр --mapdb_config.

<h4>Формат конфигурационного файла и порядок рисования карты</h4>

<p>Рисование карты выполняется в виде последовательности "шагов" (drawing
steps). Каждый шаг описан в конфигурационном файле и содержит набор
свойств (feature). Также, конфигурационный файл может содержать команды,
не являющиеся шагами рисования. Пример конфигурационного файла: data/render.cfg

Формат описания шагов рисования:
<pre><tt>
    (point|line|area) &lt;type&gt; &lt;feature&gt; &lt;options&gt; ...
    + &lt;feature&gt; &lt;options&gt; ...
    + &lt;feature&gt; &lt;options&gt; ...
    ...
    map &lt;feature&gt; &lt;options&gt; ...
    + &lt;feature&gt; &lt;options&gt; ...
    + &lt;feature&gt; &lt;options&gt; ...
    ...
</tt></pre>

<p>Шаги point, line, area описывают рисование линейного, точечного, площадного
объекта с типом &lt;type&gt;. Шаг map описывает рисование на всей площади карты
(можно нарисовать одноцветную подложку, но можно делать и более хитрые
вещи). TODO: шаг для рисования границы.

<p>Свойства:
<ul>

<li><tt> stroke &lt;width&gt; &lt;color&gt; </tt> -- Нарисовать контур объекта
линией заданной толщины и цвета. Применимо к шагам point, line, area.

<li><tt> fill &lt;color&gt; </tt> -- Заливка заданным цветом. Применимо
к шагам line, area, map.

<li><tt> patt &lt;image file&gt; &lt;scale&gt; </tt> --  Заливка площади
заданной картинкой. Применимо к шагам line, area, map. Картинка - в любом
растровом формате, поддержтиваемом mapsoft2: png, gif, tiff, jpeg.
TODO: векторные форматы типа svg, pdf...

<li><tt> img  &lt;image file&gt; &lt;scale&gt; </tt> -- Рисование
изображения. Применимо к шагам point, area (в этом случае картинка
рисуется в центре площади).

<li><tt> smooth &lt;distance&gt; </tt> -- Использовать закругленные
линии с заданным размером закругления. Применимо к шагам line, area,
используется совместно со свойствами stroke, fill, patt.

<li><tt> dash &lt;len1&gt; ... </tt> -- Использовать штриховые линии.
Параметры задают длины штрихов и промежутков между ними, так как это
принято в библиотеке Cairo. (Если параметр один - длины штрихов и
промежутков равны, если параметров более одного - они задают чередование
длин штрихов и промежутков между ними). Применимо к шагам line, area,
используется совместно со свойством stroke.

<li><tt> cap round|butt|square </tt> -- Описывает, как рисовать
окончание линии. Применимо к шагам point, line, area, используется
совместно со свойством stroke. По умолчанию - round.

<li><tt> join round|miter </tt> -- Описывает, как рисовать
стыки сегментов линий. Применимо к шагам point, line, area, используется
совместно со свойством stroke. По умолчанию - round.

<li><tt> operator &lt;op&gt; </tt> -- Установить оператор рисования.
Возможные значения: clear, source, over, in, out, atop, dest,
dest_over, dest_in, dest_out, dest_atop, xor, add, saturate
(см. WWW(https://www.cairographics.org/operators/)). Значение по умолчанию -
over. Применимо к шагам point, line, area, map.

<li><tt> name  &lt;name&gt; </tt> -- Объявить название шага (для показа в
интерфейсе). По умолчанию название составляется из типа шага и типа объекта,
напрмер "line 0x25".

<li><tt> group &lt;name&gt; </tt> -- Название группы для данного шага.
Группа может включать несколько шагов.

<li><tt> move_to area|line &lt;type&gt; &lt;max_distance&gt; </tt> --
Сдвинуть объект к ближайшему линейному объекту или ближайшей границе
площадного объекта типа type, но не далее max_distance.
Применимо к шагам типа point. TODO: несколько типов!

<li><tt> rotate_to area|line &lt;type&gt; &lt;max_distance&gt; </tt> --
То же, что и move_to, но объект также поворачивается по направлению
линии.

<li>TODO: штрихи (на заборах, мостах и т.п.)

</ul>

<p>Дополнительные команды, которые могут встречаться в конфигурационном файле:

<p> Установить "естественную" привязку карты:
<pre><tt>
set_ref file &lt;filename&gt;
set_ref nom &lt;name&gt; &lt;dpi&gt;
</tt></pre>

<p>В первом случае привязка читается из файла (сейчас поддерживаются
только OziExplorer map-файлы), во втором задается в виде имени советского
номенклатурного листа (например, j42-010) и разрешения картинки (в точках
на дюйм, например 300). Использовуется "расширенный формат" номенклатурных
названий, допускающий одиночные листы (например r36-010) и "диапазоны" листов
(например j42-040.3x3 -- блок из девяти одиночных листов).

<p>При рисовании карты может использоваться любая привязка (например, во
вьюере можно менять масштаб карты). "Естественная" привязка выбирается по
умолчанию, кроме того, она задает характерные размеры объектов (толщины
линий, величину картинок и т.п.). Этого, впрочем, пока не сделано, сейчас
толщины линий и т.п. всегда фиксированы.

<h4>TODO - чего пока не хватает</h4>

<p>Рисование границы карты (контур, обрезка объектов, заливка). Возможно,
делать в шаге рисования типа map.

<p>Установка границы карты через конфигурационный файл (чтобы можно было
использовать разную границу для разных картинок). Возможно, использовать
границу из файла привязки.

<p>Рисование дополнительных штрихов (газопроводы, ЛЭП, заборы, мосты).

<p>Сдвиг и поворот объектов к ближайшей линии. Разрешить использовать
несколько типов объектов. Сделать включение/выключение этого свойства
в интерфейсе.

<p>Возможно, задавать типы объектов в виде одного слова: line:0x23,
point:0x456 и т.п.

<p>Перемасштабирование толщин линий и т.п. при рисовании.

<p>Более разверyтый интерфейс команды ms2mapdr render: параметры для
задания привязки и масштаба линий, исключения заданных групп шагов
рисования и т.п.

