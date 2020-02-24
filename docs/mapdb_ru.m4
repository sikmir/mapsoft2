HEADER(mapdb,`
  Векторные карты в Mapsoft2 (2020-02-15)
')

define(RENDER_EXAMPLE, `
<div style="border-style:solid; border-width:0.5;
            margin:3px; padding: 3px; color: black;
            font-family:monospace; white-space:pre">
<img src=$1/render$2.png align=right>
include($1/render$2.cfg)
</div><br>')


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

<p>В базах данных mapinfo.db, objects.db используется целый
32-битный ключ и произвольные данные в качестве значения. В этих данных
может быть запакована достаточно сложная структура. При это используется
упаковка данных в стиле RIFF: 4-символьный тэг ("crds", "name" и т.п.),
4-байтовое число - длина данных в байтах, данные. Для текстовых данных
(название объекта, комментарии и т.п.) используется кодировка UTF8.

<div class="c_api">
<p>В mapsoft2 карта представляется классом MapDB (см. modules/mapdb/mapdb.h).

<p><tt>  MapDB::MapDB(std::string name, bool create = false)</tt> --
Конструктор. Если create==false, то открывает существующую карту,
находящуюся в директории name (если карты не существует, возникает ошибка).
Иначе - создать карту в директории name (директория при необходимости создается,
если какие-то базы данных существуют - возникает ошибка).

<p><tt>  static void delete_db(std::string name)</tt> -- Функция для
удаления всех баз данных, относящихся к карте.


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

<p><tt>  void MapDB::set_map_brd(const dMultiLine & b)</tt> -- установить границу карты
<div>

<!--########################-->
<h4>База данных geohash.db</h2>

<p>База данных для геоиндексации. Ключ базы состоит из типа объекта
(целое беззнаковое число, 32 бита) и строки _GEOHASH_. Значение -
идентификатор объекта. Ключи могут повторяться. Обычно для объекта
создается до четырех записей, при этом исключаются слишком короткие
геохэши для небольших объектов, попавших на границы деления. Данные
должны быть синхронизованы с координатами в базе данных objects.db.


<!--########################-->
<h4>База данных objects.db</h2>

<p>Информация об объектах. Ключ - идентификатор объекта (беззнаковое
32-битовое целое число), значение - структура со следующими полями:

<ul>

<li>Тип объекта, 32-битное целое число. Старший байт - классификации
объекта (0-точка, 1-линия, 2-многоугольник, 3-текст), второй байт не
используется, два младших байта - собственно тип объекта (то же, что тип
в MP).

<p>Все остальные поля - необязательны. Они запакованы в стиле RIFF в
произвольном порядке.

<li>Наклон объекта представлен в виде 4-байтового вещественного числа, в
градусах. Запакован с тэгом "angl". Отсчитывается от географического
севера по часовой стрелке. Наклон влияет не на координаты объекта, а на
текст и разные картинки, которые с объектом связаны. Отсутствие
информации о наклоне или значение NaN означает, что картинки будут
ориентирован на верх карты.

<li>Масштаб объекта представлен в виде 4-байтового вещественного числа.
Запакован с тэгом "scle". Должен влиять на размер линий, картинок, текста
объекта при рисовании (пока это не реализовано).

<li>Выравнивание. Один байт, запакованный с тэгом "algn". Возможные значения:
(0..8: SW,W,NW,N,NE,E,SE,S,C), отсутствующее значение эквивалентно SW(0). Имеет смысл
для текстовых объектов.

<li>Название объекта, строка, запакованая
с тэгом "name". То, что должно отображаться на карте.

<li>Комментарий к объекту, строка, запакованая с тэгом "comm". На карте
не показывается.

<li>Тэги объекта, произвольное число строк, запакованных с тэгами "tags".
Могут быть использованы для маркировки некоторой части объектов. Например,
при импорте перевалов из каталога перевалов все они маркируются неким тэгом.
При обновлении старые объекты с этим тэгом удаляются и добавляются новые
(Тут, кстати, будет важна перепривязка подписей!)

<li>Зависимые объекты, беззнаковые 4-байтовые числа, каждое из которых
запаковано с тэгом "chld" (ID объектов в базе objects.db). Таким образом
объект может быть связан со своими подписями.

<li>Координаты. Многосегментная линия, закодированная в строку также, как
поле границы карты в базе данных mapinfo.db с тэгами "crds" для каждого
сегмента. Сегмент состоит из пар координат (lon1,lat1, lon2,lat2,...),
Координаты - градусы в системе WGS84, умноженные на 1e7 и округленные к
ближайшему 4-байтовому целому числу. При обновлении координат объекта
также должна обновляться база геоиндексации.

<p>TODO: сделать ли идентификатор 64-битным? Или вообще произвольной длины
(16,32,64 бита) - для экономии размера базы?

</ul>

<p> С точки зрения базы данных никакой разницы между точками, линиями,
площадными и текстовыми объектами нет. Различается только тип объекта. В данный момент
не слишком хорошо определено, как должен обрабатываться точечный или
текстовый объект, содержащий несколько координат. Должна
ли использоваться только первая точка или все точки? Должны ли линии в
текстовом объекте использоваться для рисования текста вдоль кривого контура?

<p>Объекты не могут быть пустыми (не содержать координат). Такой запрет
связан с невозможностью разместить такой объект в базе geohash.db.

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
существует, он создается. При попытке записать пустой объект
(без координат) возникает ошибка.

<p><tt>  MapDBObj MapDB::get(const uint32_t id)</tt> --
прочитать объект с заданным идентификатором.

<p><tt>  void MapDB::del(uint32_t id)</tt> -- удалить объект с заданным
идентификатором. Если объект не существует, возникает ошибка.

<p><tt>  std::set<uint32_t> find(MapDBObjClass cl, uint16_t tnum,   const
dRect & range) </tt> -- найти идентификаторы объектов заданного типа,
которые попадают в заданный диапазон координат. Параметр cl может
принимать следующие значения: 0 or MAPDB_POINT, 1 or MAPDB_LINE, 2 or
MAPDB_POLYGON, tnum - 16-битный номер типа.

<p><tt>  std::set<uint32_t> find(int type, const dRect & range) </tt> --
то же самое, но используется 32-битный тип. Функции find позволяет быстро
выбрать все объекты, которые могут попасть (но не обязательно попадают) в
заданный диапазон координат. При выполнении каких-то медленных операция с
объектами может иметь смысл дополнительно проверить попадание объекта в
нужный диапазон.

<p><tt>  std::set<uint32_t> get_types() </tt> -- Получить множество всех
типов объектов в базе данных. Возвращаются 32-битные типы.
</div>


<!--#################################################################-->
<!--#################################################################-->
<hr><h3>Программа ms2mapdb для работы с векторными картами</h3>


<p>Для произведения разных операций с векторными картами используется
программа ms2mapdb:

<p><tt><pre>
$ ms2mapdb (-h|--help|--pod)
$ ms2mapdb <action> (-h|--help)
$ ms2mapdb <action> [<action arguments and options>]
</pre></tt>

<p>Операции (actions):

<ul>
<li><tt>create</tt> -- создать новую карту
<li><tt>delete</tt> -- удалить все базы данных, относящиеся к карте
<li><tt>add_obj</tt> -- добавить новый объект
<li><tt>import_mp</tt> -- загрузить карту в формате MP
<li><tt>export_mp</tt> -- сохранить карту в формате MP
<li><tt>import_vmap</tt> -- загрузить карту в формате VMAP
<li><tt>export_vmap</tt> -- сохранить карту в формате VMAP
<li><tt>render</tt> -- получить изображение карты
</ul>

TODO: удаление объектов по id, тэгу или типу, удаление всех объектов;
импорт/экспорт в геоданные

<!--#################################################################-->
<!--#################################################################-->
<hr><h3>Формат MP ("Польский формат")</h3>

<!--########################-->
<h4>Поддержка формата MP в mapsoft2</h4>

<p>Описание формата:
WWW(`http://magex.sourceforge.net/doc/cGPSmapper-UsrMan-v02.4.pdf')

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
Data* или Origin*. Данные могут находиться в разных слоях,
объявленных в заголовке. TODO: читать/записывать все поля, в том
числе - нестандартные, использующиеся в mapsoft1.

<p>Параметр заголовка CodePage (если он присутствует) используется для
преобразования текстовых строк: имени карты (Name), комментариев и всех
неизвестных параметров. Значение должно соответствовать windows codepage,
по умолчанию: 1251 (возможно, следует заменить на что-то более нейтральное).

<p>При чтении объектов поддерживается нестандартный параметр Direction,
который был использован в mapsoft1. Если Direction==2, то координаты
линий объекта сохраняются в обратном порядке. При записи параметр Direction
не используется.

<!--########################-->
<hr><h4>Импорт и экспорт карт в формате MP</h4>

<p>Для импорта карты из формата MP в формат MapDB
используется метод <tt>MapDB::import_mp</tt> или программа
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
import_vmap или вызов программы ms2mapdb:

<p><tt> void MapDB::import_vmap(const string & vmap_file, const Opt & opts)</tt>

<p><tt> $ ms2mapdb import_vmap &lt;mapdb_folder&gt; &lt;vmap_file&gt; &lt;options&gt;</tt>

<p>Параметр <tt>--config &lt;file&gt;</tt> задает конфигурационный файл.
В конфигурационном файле допустимы комментарии (начинающиеся с символа
`#'), пустые строки, одинарные и двойные кавычки, символ \ для защиты
специальных символов. Могут использоваться следующие команды:

<ul>

<li><tt>(point|line|area):&lt;in_type&gt;
(point|line|area):&lt;out_type&gt; [text:&lt;label_type&gt;]</tt> --
преобразовать точечные, линейные, площадные объекты с типом in_type в тип
out_type, их подписи преобразовать в текстовые объекты с типом
label_type. Если третий аргумент отсутствует, то текстовые объекты не
создаются. Вместо второго аргумента можно использовать "-", в этом случае
тип объекта не меняется.

<li><tt>unknown_types (skip|convert|warning|error)</tt> -- определить,
что надо делать с типами, которые не заданы явно в конфигурационном
файле. skip - молча пропускать, convert - преобразовывать с сохранением
типа, warning - пропускать и писать предупреждение, error - выдать ошибку
и прекратить преобразование. Значение по умолчанию - convert. Если
используется convert и преобразуется неизвестный тип, то подписи
преобразуются в текстовые объекты с типом 1.

</ul>


<p>Для экспорта карты из MapDB в формат VMAP используется метод
export_vmap или вызов программы ms2mapdb:

<p><tt> void MapDB::export_vmap(const string & vmap_file, const Opt & opts)</tt>

<p><tt> $ ms2mapdb export_vmap &lt;mapdb_folder&gt; &lt;vmap_file&gt; &lt;options&gt;</tt>

<p>Использование параметров командной строки и конфигурационного файл аналогично
экспорту карт в формате MP. Допустимые команды:

<ul>

<li><tt>(point|line|area):&lt;in_type&gt; (point|line|area):&lt;out_type&gt; --
преобразовать точечные, линейные, площадные объекты с типом in_type в тип
out_type. Вместо второго аргумента можно использовать "-", в этом случае
тип объекта не меняется.

<li><tt>unknown_types (skip|convert|warning|error)</tt> --
определить, что надо делать с типами, которые не заданы явно в конфигурационном
файле. skip - молча пропускать, convert - преобразовывать с сохранением
типа, warning - пропускать и писать предупреждение, error - выдать ошибку
и прекратить преобразование. Значение по умолчанию - convert.

</ul>

<!--#################################################################-->
<!--#################################################################-->
<hr><h3>Рендер изображения карты</h3>

<p>Для получения изображение карты можно использовать команду командной строки:

<p><tt> $ ms2mapdb render &lt;mapdb_folder&gt; &lt;options&gt;</tt>

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
    (point|line|area|text):&lt;tnum&gt; &lt;feature&gt; &lt;options&gt; ...
    + &lt;feature&gt; &lt;options&gt; ...
    + &lt;feature&gt; &lt;options&gt; ...
    ...
    (map|brd) &lt;feature&gt; &lt;options&gt; ...
    + &lt;feature&gt; &lt;options&gt; ...
    + &lt;feature&gt; &lt;options&gt; ...
    ...
</tt></pre>

<p>Шаги point, line, area описывают рисование линейного, точечного, площадного
объекта с номером типа &lt;tnum&gt;. Шаг map описывает рисование на всей площади карты
(можно нарисовать одноцветную подложку, но можно делать и более хитрые
вещи), Шаг brd описывает рисование границы и закрашивание области вне ее.

<p>Свойства (features):
<ul>

<li><tt> stroke &lt;width&gt; &lt;color&gt; </tt> -- Нарисовать контур
объекта линией заданной толщины и цвета. Применимо к шагам point, line,
area, text, brd. Цвет всегда задается в виде 32-битного числа с прозрачностью
(0xFF000000 - черный, 0xFFFF0000 - красный, 0x80FFFFFF - белый
полупрозрачный и т.п.). Для текстового объекта линией обводятся контуры букв.

<li><tt> fill &lt;color&gt; </tt> -- Заливка заданным цветом. Применимо
к шагам line, area, map, text, brd. Для текстового объекта заливка применяется
к контурам букв. Результат немного отличается от использования стандартной
функции рендера текста (см. свойство write ниже).

<li><tt> font &lt;size&gt; &lt;font pattern&gt;</tt> -- Установить шрифт
для рисования текстовых объектов. "font pattern" задается в терминах библиотеки
fontconfig, какая-то информация есть тут:
<br>WWW(`https://www.freedesktop.org/software/fontconfig/fontconfig-devel/x19.html')
<br>WWW(`https://www.freedesktop.org/software/fontconfig/fontconfig-user.html')
<br>WWW(`https://wiki.archlinux.org/index.php/Font_configuration')

<li><tt> write &lt;color&gt; </tt> -- Нарисовать текстовый объект заданным цветом.

RENDER_EXAMPLE(render_examples, 01)
RENDER_EXAMPLE(render_examples, 14)
RENDER_EXAMPLE(render_examples, 07)

<li><tt> patt &lt;image file&gt; &lt;scale&gt; &lt;dx&gt; &lt;dy&gt;
</tt> --  Заливка площади заданной картинкой. Применимо к шагам line,
area, text, map, brd. Картинка - в любом растровом формате, поддержтиваемом
mapsoft2: png, gif, tiff, jpeg. Путь к картинке должен быть указан
относительно места, где лежит конфигурационный файл. Параметр scale -
масштаб картинки, dx и dy - сдвиг картинки (в единицах размера картинки).
По умолчанию картинка выравнивается по центру. Если dx=dy=-0.5, то
выравнивание будет сделано по левому-нижнему углу. ля текстового объекта
заливка применяется к контурам букв.

TODO: векторные форматы типа svg, pdf...

<li><tt> img  &lt;image file&gt; &lt;scale&gt; &lt;dx&gt; &lt;dy&gt;</tt>
-- Рисование изображения. Применимо к шагам point, area (в этом случае
картинка рисуется в центре площади). Картинка задается так же, как и в
свойстве patt.

<li><tt> img_filter &lt;fltgt;</tt> -- Установить фильтр растровых
изображений. Применимо к шагам point, area, text, map, brd, используется совместно
со свойствами img и patt. Возможные значение: fast, good, best, nearest,
bilinear
(см. WWW(`https://www.cairographics.org/manual/cairo-cairo-pattern-t.html`#'cairo-filter-t'))

RENDER_EXAMPLE(render_examples, 08)
RENDER_EXAMPLE(render_examples, 09)
RENDER_EXAMPLE(render_examples, 10)

<li><tt> smooth &lt;distance&gt; </tt> -- Использовать закругленные
линии с заданным размером закругления. Применимо к шагам line, area, brd,
используется совместно со свойствами stroke, fill, patt.

<li><tt> dash &lt;len1&gt; ... </tt> -- Использовать штриховые линии.
Параметры задают длины штрихов и промежутков между ними, так как это
принято в библиотеке Cairo. (Если параметр один - длины штрихов и
промежутков равны, если параметров более одного - они задают чередование
длин штрихов и промежутков между ними). Применимо к шагам line, area, text, brd
используется совместно со свойством stroke.

<li><tt> cap round|butt|square </tt> -- Описывает, как рисовать
окончание линии. Применимо к шагам line, area, text, brd, используется
совместно со свойством stroke. По умолчанию - round.

<li><tt> join round|miter </tt> -- Описывает, как рисовать
стыки сегментов линий. Применимо к шагам line, area, text, brd, используется
совместно со свойством stroke. По умолчанию - round.

RENDER_EXAMPLE(render_examples, 02)
RENDER_EXAMPLE(render_examples, 03)
RENDER_EXAMPLE(render_examples, 04)
RENDER_EXAMPLE(render_examples, 05)

<li><tt> operator &lt;op&gt; </tt> -- Установить оператор рисования.
Возможные значения: clear, source, over, in, out, atop, dest,
dest_over, dest_in, dest_out, dest_atop, xor, add, saturate
(см. WWW(https://www.cairographics.org/operators/)). Значение по умолчанию -
over. Применимо к шагам point, line, area, text, map, brd.

RENDER_EXAMPLE(render_examples, 06)

<li><tt> lines &lt;lines&gt; ... </tt> -- Вместо самого объекта рисовать
дополнительные линии, привязанные к каким-то местам объекта (см. свойство
draw_pos). Аргументы - одно- или многосегментные линии в виде
json-массивов: [[x1,y1],[x2,y2]]... Для рисования линий используются те
же свойства, что и для рисования самого объекта (stroke, fill, cap,
smooth и т.д.). Для линейных и площадных объектов координты ориентированы
по направлению объекта: x вдоль линии, y - перпендикулярно, вправо от нее.
Для точечных объектов x вправо, y - вниз. На ориентацию так же влияет
свойство rotate и параметр наклон объекта.

<li><tt> circles &lt;circle&gt; ... </tt> -- Вместо самого объекта
рисовать дополнительные окружности, привязанные к каким-то местам объекта
(см. свойство draw_pos). Аргументы - параметры окружностей в виде
трехэлементных json-массивов: [x,y,r]. Для рисования окружностей
используются те же свойства, что и для рисования самого объекта (stroke,
fill, cap, smooth и т.д.). Координты ориентированы по направлению
объекта: x вдоль линии, y - перпендикулярно, вправо от нее.  На
ориентацию так же влияет свойство rotate и параметр наклон объекта.

<li><tt>draw_pos (point|begin|end) </tt>
<li><tt>draw_pos (dist|edist) &lt;dist&gt; [&lt;dist_b&gt;] [&lt;dist_e&gt;]</tt>
-- Место рисования элементов lines и circles: point -- в каждом узле
объекта (значение по умолчанию и единственное возможное значение для
точечных объектов); begin/end -- в начальной/конечной точке; dist, edist
-- периодически вдоль объекта, на заданном расстоянии друг от друга; При
этом параметры &lt;dist&gt; &lt;dist_b&gt; &lt;dist_e&gt; задают период,
начальное и конечное расстояние. Значения по умолчанию:
&lt;dist_b&gt;=&lt;dist&gt;/2,  &lt;dist_e&gt;= &lt;dist_b&gt;. Если
второй параметр имеет значение dist, то начальное расстояние и период
отсчитывюаются точно, а конечное расстояние получается не менее &lt;dist_e&gt;.
Если edist -- то период подстраивается так, чтобы конечное расстояние было
равно в точности &lt;dist_e&gt;.

RENDER_EXAMPLE(render_examples, 11)

<li><tt> move_to &lt;max_distance&gt; (area|line):&lt;tnum&gt;  </tt> --
Сдвинуть точечный объект к ближайшему линейному объекту или ближайшей границе
площадного объекта типа type, но не далее max_distance.
Применимо к шагам типа point.

<li><tt> rotate_to &lt;max_distance&gt; (area|line):&lt;tnum&gt; </tt> --
То же, что и move_to, но картинка объекта также поворачивается по направлению
линии.

<li><tt> rotate &lt;angle,deg&gt; </tt> --
Повернуть картинку объекта или текст на фиксированный угол (градусы, по часовой стрелке).
Добавляется к собственным поворотам объекта или повороту с помощью свойства rotate_to.
Свойство применимо к шагам point, line, area, text. См ниже раздел про повороты объектов.

RENDER_EXAMPLE(render_examples, 12)

<li><tt> sel_range &lt;width&gt; &lt;color&gt; </tt> -- Нарисовать
предполагаемый диапазон объекта, по которому он выбирается из базы
данных. Для расчета диапазона используются остальные правила рисования
(например, stroke с ненулевой толщиной линии увеличивает диапазон на
толщину линии, картинка - на диагональный размер картинки и т.п.)
Для поиска текста используется параметр max_text_size (см.ниже).

RENDER_EXAMPLE(render_examples, 13)

<li><tt> pix_align &lt;(0|1)&gt; </tt> -- Округлять координаты текста
к целым пикселам. Похоже, что этот параметр не очень нужен, если правильно
настроен hinting шрифта. Применимо к шагу типа text.

<li><tt> name  &lt;name&gt; </tt> -- Объявить название шага (для показа в
интерфейсе). По умолчанию название составляется из типа объекта,
напрмер "line:0x25".

<li><tt> group &lt;name&gt; </tt> -- Название группы для данного шага.
Группа может включать несколько шагов.



</ul>

<p>В одном шаге рисования могут присутствовать несколько свойств. На
каждом шаге рисование происходит в следующем порядке:

<ul>

<li>Определяется диапазон, в котором надо искать объекты. На него влияют
свойства, которые приводят к сдвигу объектов или созданию картинки
конечного размера: stroke, img, patt, move_to, rotate_to.
Для текстовых объектов используется некий фиксированный размер
(по умолчанию 1024 точки -- TODO: сделать настраиваемым!)

<li>Если шаг имеет тип point, line, area, text, то выбираются соответствующие
объекты в нужном диапазоне.

<li>Если присутствует свойство sel_range, то рисуются прямоугольники
вокруг объектов.

<li>Настраивается оператор рисования (свойство operator), настраивается
шрифт (свойство font).

<li>Если присутствуют свойства stroke, fill, patt, то строится "путь"
рисования (path).

<li>Выполняется заливка картинкой (свойство patt).

<li>Выполняется заливка цветом (свойство fill).

<li>Выполняется рисование контура (свойство stroke). При этом
настраиваются параметры рисования, соответствующие свойствам dash, cap,
join.

<li>Выполняется рисование картинок (свойство img).

<li>Выполняется рисование текста (свойство write).
</ul>

<p>Если хочется использовать другой порядок (например, сперва контур,
потом заливку, потом паттерн) - придется сделать несколько последовательных
шагов рисования.

<p>Дополнительные команды, которые могут встречаться в конфигурационном файле:

<ul>

<li><tt> set_ref file &lt;filename&gt; </tt> -- установить "естественную"
привязку карты из файла (сейчас поддерживаются только файлы OziExplorer).


<li><tt> set_ref nom &lt;name&gt; &lt;dpi&gt;</tt> -- установить "естественную"
привязку карты по советскому номенклатурному листу.

<li><tt> max_text_size  &lt;number&gt;</tt> -- изменить максимальный размер текста
(в точках). Этот параметр используется при поиске текстовых объектов на карте.
Значение по умолчанию - 1024 точки.

<li><tt> define &lt;name&gt; &lt;definition&gt;</tt> -- переопределить
некое слово. В последующем файле все слова &lt;name&gt; будут заменены на
&lt;definition&gt;. Замена производится один раз, заменяются только целые
слова.

<li>

</ul>

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

<p>Масштабирование объектов (толщины линий, картинки и т.п.). И глобально,
и в зависимости от параметра scale в объекте.

<p>Возможность отключать в интерфейсе свойства move_to, rotate_to, а,
может, и любые свойства.

<p>Более разверyтый интерфейс команды ms2mapdr render: параметры для
задания привязки и масштаба линий, исключения заданных групп шагов
рисования и т.п.

<p>Включение других файлов при чтении конфигурационного файла.

<!--#################################################################-->
<hr><h3>Наклон объектов и подписей</h3>

<p>Объекты имеют параметр "наклон" (angle). Наклон применяется только к
тексту, растровым картинкам или картинкам, нарисованным с помощью свойств
lines и circles, но не к координатам объекта. Наклон может отсутствовать,
в этом случае картинка объекта ориентируется на верх карты. Если наклон
задан, то он отсчитывается от географического севера, по часовой
стрелке.

<p>Свойство рисования rotate_to ориентирует картинку объекта по указанной линии,
игнорируя его собственный наклон.

<p>Свойство рисования rotate добавляет к наклону (собственному или
возникшему из-за использования rotate_to) фиксированный угол (в градусах,
по часовой стрелке).

<p>В формате VMAP параметр наклон объектов и текста определялся
весьма странно: <tt>angle = atan2(dlat, dlon)</tt>, где отрезок с
координатами (dlat, dlon) определяет направление объекта в географических
координатах. Поскольку координаты имеют разных масштаб по lat и lon, эта
величина сильно отличается от настоящего угла поворота. При
экспорте/импорте объектов из vmap наклоны объектов пересчитываются. Надо
ли делать так при работе с MP (куда такие наклоны тоже попадали) -
непонятно. Можно, наверное, сделать специальный параметр в
конфигурационных файлах для импорта/экспорта...

RENDER_EXAMPLE(render_ex_ang, 1)
RENDER_EXAMPLE(render_ex_ang, 2)
RENDER_EXAMPLE(render_ex_ang, 3)
RENDER_EXAMPLE(render_ex_ang, 4)
RENDER_EXAMPLE(render_ex_ang, 5)
