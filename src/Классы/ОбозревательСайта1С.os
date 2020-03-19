// ----------------------------------------------------------
// This Source Code Form is subject to the terms of the
// Mozilla Public License, v.2.0. If a copy of the MPL
// was not distributed with this file, You can obtain one
// at http://mozilla.org/MPL/2.0/.
// ----------------------------------------------------------
//
// Реализация взаимодействия с сайтом 1С на основе обработки:
// https://infostart.ru/public/255881/
//
// ----------------------------------------------------------

#Использовать asserts
#Использовать semver

#Область ПеременныеМодуля

Перем Лог;

Перем СервисАвторизации;
Перем СервисРелизов;
Перем СтраницаСпискаРелизов;

Перем ШаблонСтрокиРегистрации;
Перем ШаблонПоискаСтрокиРегистрации;
Перем ШаблонПоискаКонфигураций;
Перем ШаблонПоискаВерсий;
Перем ШаблонПоискаАдресаСтраницыЗагрузки;
Перем ШаблонПоискаСсылкиДляЗагрузки;
Перем ШаблонПоискаПутиКФайлуВАдресе;

Перем ИмяПользователя;
Перем ПарольПользователя;
Перем ИдСеанса;

#КонецОбласти // ПеременныеМодуля

#Область ПрограммныйИнтерфейс

// Функция - получает список версий приложения с сайта 1С
//
// Параметры:
//  Фильтр          - Строка,           - регулярное выражение или массив регулярных выражений
//                    Массив(Строка)      для поиска нужных приложений по имени
//
// Возвращаемое значение:
//  Массив(Структура)  - массив описаний ссылок для загрузки
//   * Имя                - Строка  - имя приложения
//   * Путь               - Строка  - относительный путь к странице приложения
//
Функция ПолучитьСписокПриложений(Знач Фильтр = Неопределено) Экспорт
	
	СтраницаКонфигураций = ПолучитьСтраницуСайта(СервисРелизов, СтраницаСпискаРелизов);
	
	Совпадения = НайтиСовпаденияВТексте(СтраницаКонфигураций, ШаблонПоискаКонфигураций);
	
	СписокКонфигураций = Новый Массив();
	Если Совпадения.Количество() > 0 Тогда
		Для Каждого ТекСовпадение Из Совпадения Цикл
			Если ТекСовпадение.Группы.Количество() < 3 Тогда
				Продолжить;
			КонецЕсли;

			ТекИмя = ТекСовпадение.Группы[2].Значение;

			Если НЕ СоответствуетФильтру(ТекИмя, Фильтр) Тогда
				Продолжить;
			КонецЕсли;

			ТекКонфигурация = Новый Структура("Имя, Путь, Версия, Дата, Идентификатор");
			ТекКонфигурация.Имя           = ТекИмя;
			ТекКонфигурация.Путь          = ТекСовпадение.Группы[1].Значение;
			ТекКонфигурация.Идентификатор = ТекСовпадение.Группы[3].Значение;
			ТекКонфигурация.Версия        = ТекСовпадение.Группы[4].Значение;
			ТекКонфигурация.Дата          = ДатаИзСтроки(ТекСовпадение.Группы[5].Значение);

			СписокКонфигураций.Добавить(ТекКонфигурация);
		КонецЦикла;
	КонецЕсли;
	
	Возврат СписокКонфигураций;
	
КонецФункции // ПолучитьСписокПриложений()

// Функция - получает список версий приложения с сайта 1С
//
// Параметры:
//  АдресРесурса    - Строка            - расположение страницы версий на сервере
//  Фильтр          - Строка,           - регулярное выражение или массив регулярных выражений
//                    Массив(Строка)      для поиска нужных версий по номеру
//
// Возвращаемое значение:
//  Массив(Структура)    - массив описаний ссылок для загрузки
//   * Версия                - Строка  - номер версии
//   * Дата                  - Дата    - дата версии
//   * Путь                  - Строка  - относительный путь к странице версии
//   * ВерсииДляОбновления   - Массив  - список версий для обновления
//
Функция ПолучитьВерсииПриложения(Знач АдресРесурса,
                                 Знач Фильтр = Неопределено,
                                 Знач НачальнаяДата = '00010101000000',
                                 Знач КонечнаяДата = '00010101000000') Экспорт
	
	СтраницаВерсий = ПолучитьСтраницуСайта(СервисРелизов, АдресРесурса);
	
	Совпадения = НайтиСовпаденияВТексте(СтраницаВерсий, ШаблонПоискаВерсий);

	СписокВерсий = Новый Массив();
	Если Совпадения.Количество() > 0 Тогда
		Для Каждого ТекСовпадение Из Совпадения Цикл
			Если ТекСовпадение.Группы.Количество() < 3 Тогда
				Продолжить;
			КонецЕсли;

			ТекНомерВерсии = ТекСовпадение.Группы[2].Значение;
			ТекДатаВерсии  = ДатаИзСтроки(ТекСовпадение.Группы[4].Значение);

			Если НЕ СоответствуетФильтру(ТекНомерВерсии, Фильтр) Тогда
				Продолжить;
			КонецЕсли;

			Если (ЗначениеЗаполнено(НачальнаяДата) И ТекДатаВерсии < НачальнаяДата)
			 ИЛИ (ЗначениеЗаполнено(КонечнаяДата) И ТекДатаВерсии > КонечнаяДата) Тогда
				Продолжить;
			КонецЕсли;

			ТекВерсия = Новый Структура("Версия, Дата, Путь, ВерсииДляОбновления");
			ТекВерсия.Версия              = ТекНомерВерсии;
			ТекВерсия.Дата                = ТекДатаВерсии;
			ТекВерсия.Путь                = ТекСовпадение.Группы[1].Значение;
			ТекВерсия.ВерсииДляОбновления = СтрРазделить(ТекСовпадение.Группы[6].Значение, ",", Ложь);

			СортироватьВерсии(ТекВерсия.ВерсииДляОбновления, "Убыв");
			
			СписокВерсий.Добавить(ТекВерсия);
		КонецЦикла;
	КонецЕсли;
	
	СортироватьОписанияВерсийПоДате(СписокВерсий);

	Возврат СписокВерсий;
	
КонецФункции // ПолучитьВерсииПриложения()

// Функция - проверяет наличие ссылок для загрузки с сайта 1С
//
// Параметры:
//  АдресРесурса    - Строка            - расположение страницы загрузок на сервере
//  Фильтр          - Строка,           - регулярное выражение или массив регулярных выражений
//                    Массив(Строка)      для поиска ссылки на загрузку по заголовку
//
// Возвращаемое значение:
//  Булево          - Истина - есть ссылки, удовлетворяющие фильтру;
//                    Ложь - в противном случае
//
Функция ЕстьСсылкаДляЗагрузки(Знач АдресРесурса = "", Знач Фильтр = Неопределено) Экспорт

	СписокСсылок = ПолучитьСсылкиДляЗагрузки(АдресРесурса, Фильтр);

	Возврат (СписокСсылок.Количество() > 0);

КонецФункции // ЕстьСсылкаДляЗагрузки()

// Функция - получает список ссылок для загрузки с сайта 1С
//
// Параметры:
//  АдресРесурса    - Строка            - расположение страницы загрузок на сервере
//  Фильтр          - Строка,           - регулярное выражение или массив регулярных выражений
//                    Массив(Строка)      для поиска ссылки на загрузку по заголовку
//
// Возвращаемое значение:
//  Массив(Структура) - массив описаний ссылок для загрузки
//   * Имя               - Строка - заголовок ссылки
//   * Путь              - Строка - относительный путь на сайте 1С
//   * ПутьДляЗагрузки   - Строка - путь для скачивания файла
//   * ИмяФайла          - Строка - имя загружаемого файла
//
Функция ПолучитьСсылкиДляЗагрузки(Знач АдресРесурса = "", Знач Фильтр = Неопределено) Экспорт
	
	СтраницаВерсии = ПолучитьСтраницуСайта(СервисРелизов, АдресРесурса);

	Совпадения = НайтиСовпаденияВТексте(СтраницаВерсии, ШаблонПоискаАдресаСтраницыЗагрузки);

	СписокСсылок = Новый Массив();
	Если Совпадения.Количество() > 0 Тогда

		Для Каждого ТекСовпадение Из Совпадения Цикл

			Если ТекСовпадение.Группы.Количество() < 3 Тогда
				Продолжить;
			КонецЕсли;

			ТекИмя = ТекСовпадение.Группы[2].Значение;
			ТекСсылка = ТекСовпадение.Группы[1].Значение;
			ОписаниеФайла = ФайлИзАдреса(ТекСсылка);

			Если НЕ СоответствуетФильтру(ТекИмя, Фильтр) Тогда
				Продолжить;
			КонецЕсли;

			СтраницаЗагрузки = ПолучитьСтраницуСайта(СервисРелизов, ТекСсылка);
			
			СовпаденияДляЗагрузки = НайтиСовпаденияВТексте(СтраницаЗагрузки, ШаблонПоискаСсылкиДляЗагрузки);
			
			Если СовпаденияДляЗагрузки.Количество() = 0 Тогда
				Продолжить;
			КонецЕсли;

			ТекВерсия = Новый Структура("Имя, Путь, ПутьДляЗагрузки, ИмяФайла");
			ТекВерсия.Имя             = ТекИмя;
			ТекВерсия.Путь            = ТекСсылка;
			ТекВерсия.ПутьДляЗагрузки = СовпаденияДляЗагрузки[0].Группы[2].Значение;
			ТекВерсия.ИмяФайла        = ОписаниеФайла.Имя;
			СписокСсылок.Добавить(ТекВерсия);

		КонецЦикла;
	КонецЕсли;

	Возврат СписокСсылок;

КонецФункции // ПолучитьСсылкиДляЗагрузки()

// Процедура - загружает указанный файл с сайта 1С
//
// Параметры:
//  АдресИсточника             - Строка      - URI файла на сервере
//  ПутьКФайлуДляСохранения    - Строка      - путь к файлу для сохранения
//
Процедура ЗагрузитьФайл(АдресИсточника, Знач ПутьКФайлуДляСохранения) Экспорт
	
	СтруктураАдреса = СтруктураURI(АдресИсточника);
	
	Сервер = СтрШаблон("%1://%2", СтруктураАдреса.Схема, СтруктураАдреса.Хост);
	
	ИдСеансаЗагрузки = Авторизация(Сервер, ИмяПользователя, ПарольПользователя, СтруктураАдреса.ПутьНаСервере);

	Соединение = Новый HTTPСоединение(Сервер, , , , , 20);
	Соединение.РазрешитьАвтоматическоеПеренаправление = Истина;

	Запрос = ЗапросКСайту(АдресИсточника);
	Запрос.Заголовки.Вставить("Cookie", ИдСеансаЗагрузки);

	Лог.Отладка("Загрузка файла: Начало загрузки файла по адресу ""%1/%2""", Сервер, АдресИсточника);
	
	Ответ = Соединение.Получить(Запрос);

	ДанныеФайла = Ответ.ПолучитьТелоКакДвоичныеДанные();
	ДанныеФайла.Записать(ПутьКФайлуДляСохранения);

	Лог.Отладка("Загрузка файла: Загружен файл ""%1""", ПутьКФайлуДляСохранения);
	
КонецПроцедуры // ЗагрузитьФайл()

// Функция - выполняет авторизацию на сайте 1С и возвращает идентификатор сеанса
//
// Параметры:
//  Сервер              - Строка      - адрес сервера
//  Имя                 - Строка      - имя пользователя
//  Пароль              - Строка      - пароль пользователя
//  АдресРесурса        - Строка      - расположение ресурса на сервере
//
// Возвращаемое значение:
//  Строка     - текст полученной страницы
//
Функция Авторизация(Знач Сервер, Знач Имя, Знач Пароль, Знач АдресРесурса = "") Экспорт
	
	ИмяПользователя = Имя;
	ПарольПользователя = Пароль;

	КодПереадресации = 302;

	СоединениеРегистрации = Новый HTTPСоединение(СервисАвторизации, , , , , 20);
	СоединениеРегистрации.РазрешитьАвтоматическоеПеренаправление = Ложь;

	СоединениеЦелевое = Новый HTTPСоединение(Сервер, , , , , 20);
	СоединениеЦелевое.РазрешитьАвтоматическоеПеренаправление = Ложь;
	
	// Запрос 1
	ЗапросПолучение = ЗапросКСайту();
	ЗапросПолучение.АдресРесурса = АдресРесурса;
	
	// Ответ 1 - переадресация на страницу регистрации
	ОтветПереадресация = СоединениеЦелевое.Получить(ЗапросПолучение);
	НовыйИдСеанса = ОтветПереадресация.Заголовки.Получить("Set-Cookie");
	НовыйИдСеанса = Лев(НовыйИдСеанса, Найти(НовыйИдСеанса, ";") - 1);

	Лог.Отладка("Авторизация: Получен ответ от ресурса ""%1/%2"", переадресация -> ""%3""",
	            Сервер,
	            ЗапросПолучение.АдресРесурса,
	            ОтветПереадресация.Заголовки.Получить("Location"));
	
	// Запрос 2 - переходим на страницу регистрации
	ЗапросПолучение.АдресРесурса = СтрЗаменить(ОтветПереадресация.Заголовки.Получить("Location"), СервисАвторизации, "");
	
	// Ответ 2 - получение строки регистрации
	ОтветРегистрация = СоединениеРегистрации.Получить(ЗапросПолучение);
	ТелоОтвета = ОтветРегистрация.ПолучитьТелоКакСтроку();
	СтрокаРегистрации = ПолучитьСтрокуРегистрации(ТелоОтвета, ИмяПользователя, ПарольПользователя);

	Лог.Отладка("Авторизация: Получена строка регистрации от ресурса ""%1/%2"": ""%3""",
	            СервисАвторизации,
	            ЗапросПолучение.АдресРесурса,
	            СтрокаРегистрации);
	
	// Запрос 3 - выполнение регистрации
	ЗапросОбработка = ЗапросКСайту("/login");
	ЗапросОбработка.Заголовки.Вставить("Content-Type", "application/x-www-form-urlencoded");
	ЗапросОбработка.Заголовки.Вставить("Cookie", НовыйИдСеанса + "; i18next=ru-RU");
	ЗапросОбработка.УстановитьТелоИзСтроки(СтрокаРегистрации);

	// Ответ 3 - проверка успешности регистрации
	ОтветПроверка = СоединениеРегистрации.ОтправитьДляОбработки(ЗапросОбработка);
	
	Утверждения.ПроверитьРавенство(ОтветПроверка.КодСостояния,
	                               КодПереадресации,
	                               "Код переадресации не соответствует ожидаемому!");
	
	Лог.Отладка("Авторизация: Получен ответ от ресурса ""%1/%2"", переадресация -> ""%3""",
	            СервисАвторизации,
	            ЗапросОбработка.АдресРесурса,
	            ОтветПроверка.Заголовки.Получить("Location"));
	
	// Запрос 4 - переход на целевую страницу
	ЗапросПолучение.АдресРесурса = СтрЗаменить(ОтветПроверка.Заголовки.Получить("Location"), Сервер, "");
	ЗапросПолучение.Заголовки.Вставить("Cookie", НовыйИдСеанса);
	
	СоединениеЦелевое.Получить(ЗапросПолучение);
	
	Лог.Отладка("Авторизация: Получен ответ от ресурса ""%1/%2"", ID сеанса: ""%3""",
	            Сервер,
	            ЗапросПолучение.АдресРесурса,
	            НовыйИдСеанса);
	
	Возврат НовыйИдСеанса;
	
КонецФункции // Авторизация()

#КонецОбласти // ПрограммныйИнтерфейс

#Область РаботаСсайтом

// Функция - получает строку регистрации на основе данных страницы авторизации
//
// Параметры:
//  Текст            - Строка      - текст страницы авторизации
//  Имя              - Строка      - имя пользователя
//  Пароль           - Строка      - пароль пользователя
//
// Возвращаемое значение:
//  Строка     - строка регистрации на сайте
//
Функция ПолучитьСтрокуРегистрации(Знач Текст, Знач Имя, Знач Пароль)
	
	Совпадения = НайтиСовпаденияВТексте(Текст, ШаблонПоискаСтрокиРегистрации);

	execution = "";
	Если Совпадения.Количество() > 0 Тогда
		execution = Совпадения[0].Группы[1].Значение;
	КонецЕсли;

	СтрокаРегистрации = СтрШаблон(ШаблонСтрокиРегистрации, Имя, Пароль, execution);
				
	Возврат СтрокаРегистрации;
	
КонецФункции // ПолучитьСтрокуРегистрации()

// Функция - получает страницу с сайта
//
// Параметры:
//  Сервер                          - Строка      - адрес сервера
//  АдресРесурса                    - Строка      - расположение ресурса на сервере
//  ИдСеанса                        - Строка      - идентификатор текущего сеанса
//  АвтоматическоеПеренаправление   - Булево      - Истина - будет выполняться автоматическое перенаправление
//                                                           при соответствующем ответе сервера
//                                                  Ложь - перенаправление выполняться не будет
//
// Возвращаемое значение:
//  Строка     - текст полученной страницы
//
Функция ПолучитьСтраницуСайта(Знач Сервер, Знач АдресРесурса, Знач АвтоматическоеПеренаправление = Ложь)
	
	Соединение = Новый HTTPСоединение(Сервер, , , , , 20);
	Соединение.РазрешитьАвтоматическоеПеренаправление = АвтоматическоеПеренаправление;

	Запрос = ЗапросКСайту(АдресРесурса);
	Запрос.Заголовки.Вставить("Cookie", ИдСеанса);
	
	Ответ = Соединение.Получить(Запрос);

	Лог.Отладка("Получена страница сайта ""%1/%2""", Сервер, АдресРесурса);

	Возврат Ответ.ПолучитьТелоКакСтроку();

КонецФункции // ПолучитьСтраницуСайта()

#КонецОбласти // РаботаСсайтом

#Область СлужебныеПроцедурыИФункции

// Функция - создает и возвращает HTTP-запрос со стандартными заголовками
//
// Параметры:
//  АдресРесурса       - Строка      - адрес ресурса на сайте
//
// Возвращаемое значение:
//  HTTPЗапрос         - HTTP-запрос со стандартными заголовками
//
Функция ЗапросКСайту(АдресРесурса = "")

	Запрос = Новый HTTPЗапрос;
	Запрос.Заголовки.Вставить("User-Agent", "oscript");
	Запрос.Заголовки.Вставить("Connection", "keep-alive");
	Запрос.АдресРесурса = АдресРесурса;

	Возврат Запрос;

КонецФункции // ЗапросКСайту()

// Функция - ищет совпадения в тексте по указанному регулярному выражению
//
// Параметры:
//  Текст             - Строка      - текст, вкотором выполняется поиск
//  Шаблон            - Строка      - регулярное выражение
//
// Возвращаемое значение:
//  КоллекцияСовпаденийРегулярногоВыражения     - найденные совпадения
//
Функция НайтиСовпаденияВТексте(Текст, Шаблон)

	РВ = Новый РегулярноеВыражение(Шаблон);
	Возврат РВ.НайтиСовпадения(Текст);

КонецФункции // НайтиСовпаденияВТексте()

// Функция - выделяет имя файла из полного адреса файла
//
// Параметры:
//  АдресФайла    - Строка            - полный адрес файла
//
// Возвращаемое значение:
//  Строка        - имя файла
//
Функция ФайлИзАдреса(Знач АдресФайла)

	ОписаниеФайла = Новый Структура("ПолноеИмя, ЧастиПути, Путь, Имя");
	ОписаниеФайла.ПолноеИмя = "";
	ОписаниеФайла.ЧастиПути = Новый Массив();
	ОписаниеФайла.Путь      = "";
	ОписаниеФайла.Имя       = "";

	Совпадения = НайтиСовпаденияВТексте(АдресФайла, ШаблонПоискаПутиКФайлуВАдресе);

	Если Совпадения.Количество() = 0 Тогда
		Возврат ОписаниеФайла;
	КонецЕсли;

	ОписаниеФайла.ПолноеИмя = Совпадения[0].Группы[1].Значение;

	ОписаниеФайла.ЧастиПути = СтрРазделить(ОписаниеФайла.ПолноеИмя, "\");

	Для й = 0 По ОписаниеФайла.ЧастиПути.ВГраница() - 1 Цикл
		ОписаниеФайла.Путь = ОписаниеФайла.Путь
		                   + ?(ОписаниеФайла.Путь = "", "", "\")
		                   + ОписаниеФайла.ЧастиПути[й];
	КонецЦикла;

	ОписаниеФайла.Имя = ОписаниеФайла.ЧастиПути[ОписаниеФайла.ЧастиПути.ВГраница()];

	Возврат ОписаниеФайла;

КонецФункции // ФайлИзАдреса()

// Функция - проверяет соответствие строки указанному фильтру
//
// Параметры:
//  Значение      - Строка            - проверяемая строка
//  Фильтр        - Строка,           - регулярное выражение или массив регулярных выражений
//                  Массив(Строка)
//
// Возвращаемое значение:
//  Булево        - Истина - строка соответствует фильтру
//                  Ложь - в противном случае
//
Функция СоответствуетФильтру(Знач Значение, Знач Фильтр)

	Если Фильтр = Неопределено Тогда
		Возврат Истина;
	КонецЕсли;

	МассивФильтров = Новый Массив();

	Если ТипЗнч(Фильтр) = Тип("Строка") Тогда
		МассивФильтров.Добавить(Фильтр);
	ИначеЕсли ТипЗнч(Фильтр) = Тип("Массив") И Фильтр.Количество() > 0 Тогда
		МассивФильтров = Фильтр;
	Иначе
		Возврат Истина;
	КонецЕсли;

	СоответствуетФильтру = Ложь;

	Для Каждого ТекФильтр Из МассивФильтров Цикл
		
		Если НЕ ТипЗнч(ТекФильтр) = Тип("Строка") Тогда
			Продолжить;
		КонецЕсли;

		Совпадения = НайтиСовпаденияВТексте(Значение, ТекФильтр);
	
		Если Совпадения.Количество() > 0 Тогда
			СоответствуетФильтру = Истина;
			Прервать;
		КонецЕсли;

	КонецЦикла;

	Возврат СоответствуетФильтру;

КонецФункции // СоответствуетФильтру()

// Функция - разбирает строку URI на составные части и возвращает в виде структуры.
// На основе RFC 3986.
// утащено из https://its.1c.ru/db/metod8dev#content:5574:hdoc, таже есть в БСП
//
// Параметры:
//  СтрокаURI - Строка - ссылка на ресурс в формате:
//                       <схема>://<логин>:<пароль>@<хост>:<порт>/<путь>?<параметры>#<якорь>.
//
// Возвращаемое значение:
//  Структура - составные части URI согласно формату:
//   * Схема         - Строка - схема из URI.
//   * Логин         - Строка - логин из URI.
//   * Пароль        - Строка - пароль из URI.
//   * ИмяСервера    - Строка - часть <хост>:<порт> из URI.
//   * Хост          - Строка - хост из URI.
//   * Порт          - Строка - порт из URI.
//   * ПутьНаСервере - Строка - часть <путь>?<параметры>#<якорь> из URI.
//
Функция СтруктураURI(Знач СтрокаURI) Экспорт
	
	СтрокаURI = СокрЛП(СтрокаURI);
	
	// схема
	Схема = "";
	Разделитель = "://";
	Позиция = Найти(СтрокаURI, Разделитель);
	Если Позиция > 0 Тогда
		Схема = НРег(Лев(СтрокаURI, Позиция - 1));
		СтрокаURI = Сред(СтрокаURI, Позиция + СтрДлина(Разделитель));
	КонецЕсли;

	// строка соединения и путь на сервере
	СтрокаСоединения = СтрокаURI;
	ПутьНаСервере = "";
	Позиция = Найти(СтрокаСоединения, "/");
	Если Позиция > 0 Тогда
		ПутьНаСервере = Сред(СтрокаСоединения, Позиция + 1);
		СтрокаСоединения = Лев(СтрокаСоединения, Позиция - 1);
	КонецЕсли;
		
	// информация пользователя и имя сервера
	СтрокаАвторизации = "";
	ИмяСервера = СтрокаСоединения;
	Позиция = Найти(СтрокаСоединения, "@");
	Если Позиция > 0 Тогда
		СтрокаАвторизации = Лев(СтрокаСоединения, Позиция - 1);
		ИмяСервера = Сред(СтрокаСоединения, Позиция + 1);
	КонецЕсли;
	
	// логин и пароль
	Логин = СтрокаАвторизации;
	Пароль = "";
	Позиция = Найти(СтрокаАвторизации, ":");
	Если Позиция > 0 Тогда
		Логин = Лев(СтрокаАвторизации, Позиция - 1);
		Пароль = Сред(СтрокаАвторизации, Позиция + 1);
	КонецЕсли;
	
	// хост и порт
	Хост = ИмяСервера;
	Порт = "";
	Позиция = Найти(ИмяСервера, ":");
	Если Позиция > 0 Тогда
		Хост = Лев(ИмяСервера, Позиция - 1);
		Порт = Сред(ИмяСервера, Позиция + 1);
	КонецЕсли;
	
	Результат = Новый Структура;
	Результат.Вставить("Схема", Схема);
	Результат.Вставить("Логин", Логин);
	Результат.Вставить("Пароль", Пароль);
	Результат.Вставить("ИмяСервера", ИмяСервера);
	Результат.Вставить("Хост", Хост);
	Результат.Вставить("Порт", ?(Порт <> "", Число(Порт), Неопределено));
	Результат.Вставить("ПутьНаСервере", ПутьНаСервере);
	
	Возврат Результат;
	
КонецФункции // СтруктураURI()

// Функция - преобразует строковое значение даты в формате "дд.мм.гг" или "дд.мм.гггг" в дату
//
// Параметры:
//	ДатаСтрокой     - Строка     - дата в формате "дд.мм.гг" или "дд.мм.гггг"
//
// Возвращаемое значение:
//	Дата     - преобразованное значение
//
Функция ДатаИзСтроки(Знач ДатаСтрокой)

	ВремЧастиДаты = СтрРазделить(ДатаСтрокой, ".");

	КоличествоЧастейДаты = 3;

	Если ВремЧастиДаты.Количество() < КоличествоЧастейДаты Тогда
		Возврат '00010101000000';
	КонецЕсли;

	Попытка
		Если СтрДлина(ВремЧастиДаты[2]) = 4 Тогда
			Возврат Дата(СтрШаблон("%1%2%3%4", ВремЧастиДаты[2], ВремЧастиДаты[1], ВремЧастиДаты[0], "000000"));
		ИначеЕсли СтрДлина(ВремЧастиДаты[2]) = 2 Тогда
			Возврат Дата(СтрШаблон("20%1%2%3%4", ВремЧастиДаты[2], ВремЧастиДаты[1], ВремЧастиДаты[0], "000000"));
		Иначе
			Возврат '00010101000000';
		КонецЕсли;
	Исключение
		Возврат '00010101000000';
	КонецПопытки;

КонецФункции // ДатаИзСтроки()

// Процедура - сортирует массив описаний версий по номерам версий согласно соглашению SEMVER
//
// Параметры:
//	МассивВерсий     - Массив(Строка)     - массив номеров версий
//	Порядок          - Строка             - принимает значение "ВОЗР" или "УБЫВ"
//
Процедура СортироватьВерсии(МассивВерсий, Порядок = "ВОЗР")

	МажорныеВерсии = Новый Соответствие();
	МассивМажорныхВерсий = Новый Массив();
	Для й = 0 По МассивВерсий.ВГраница() Цикл
		МажорнаяВерсия = СокрЛП(Лев(МассивВерсий[й], СтрНайти(МассивВерсий[й], ".") - 1)) + ".0.0";
		Если МажорныеВерсии[МажорнаяВерсия] = Неопределено Тогда
			МажорныеВерсии.Вставить(МажорнаяВерсия, Новый Массив());
			МассивМажорныхВерсий.Добавить(МажорнаяВерсия);
		КонецЕсли;
		МажорныеВерсии[МажорнаяВерсия].Добавить(Сред(МассивВерсий[й], СтрНайти(МассивВерсий[й], ".") + 1));
	КонецЦикла;

	Версии.СортироватьВерсии(МассивМажорныхВерсий, Порядок);

	МассивВерсий = Новый Массив();

	Для Каждого ТекВерсия Из МассивМажорныхВерсий Цикл
		МинорныеВерсии = МажорныеВерсии[ТекВерсия];
		Версии.СортироватьВерсии(МинорныеВерсии, Порядок);
		Для Каждого ТекЗначение Из МинорныеВерсии Цикл
			МажорнаяВерсия = СокрЛП(Лев(ТекВерсия, СтрНайти(ТекВерсия, ".") - 1));
			МассивВерсий.Добавить(СтрШаблон("%1.%2", МажорнаяВерсия, ТекЗначение));
		КонецЦикла;
	КонецЦикла;

КонецПроцедуры // СортироватьОписанияВерсийПоНомеру()

// Процедура - сортирует массив описаний версий по номерам версий согласно соглашению SEMVER
//
// Параметры:
//	ОписанияВерсий         - Массив(Структура)   - массив описаний версий для сортировки
//      * Версия               - Строка              - номер версии
//      * Дата                 - Дата                - дата версии
//      * Путь                 - Строка              - относительный путь к странице версии
//      * ВерсииДляОбновления  - Массив              - список версий для обновления
//	Порядок                - Строка              - принимает значение "ВОЗР" или "УБЫВ"
//
Процедура СортироватьОписанияВерсийПоНомеру(ОписанияВерсий, Порядок = "ВОЗР")

	СоответствиеОписаний = Новый Соответствие();

	МассивВерсий = Новый Массив();

	Для Каждого ТекОписание Из ОписанияВерсий Цикл
		СоответствиеОписаний.Вставить(ТекОписание.Версия, ТекОписание);
		МассивВерсий.Добавить(ТекОписание.Версия);
	КонецЦикла;

	Версии.СортироватьВерсии(МассивВерсий, Порядок);

	ОписанияВерсий = Новый Массив();

	Для Каждого ТекВерсия Из МассивВерсий Цикл
		ОписанияВерсий.Добавить(СоответствиеОписаний[ТекВерсия]);
	КонецЦикла;

КонецПроцедуры // СортироватьОписанияВерсийПоНомеру()

// Процедура - сортирует массив описаний версий по датам версий
//
// Параметры:
//	ОписанияВерсий         - Массив(Структура)   - массив описаний версий для сортировки
//      * Версия               - Строка              - номер версии
//      * Дата                 - Дата                - дата версии
//      * Путь                 - Строка              - относительный путь к странице версии
//      * ВерсииДляОбновления  - Массив              - список версий для обновления
//	Порядок                - Строка              - принимает значение "ВОЗР" или "УБЫВ"
//
Процедура СортироватьОписанияВерсийПоДате(ОписанияВерсий, Порядок = "ВОЗР")

	ТабДляСортировки =  Новый ТаблицаЗначений();
	ТабДляСортировки.Колонки.Добавить("Дата");
	ТабДляСортировки.Колонки.Добавить("ОписаниеВерсии");

	Для Каждого ТекОписание Из ОписанияВерсий Цикл
		НоваяСтрока = ТабДляСортировки.Добавить();
		НоваяСтрока.Дата           = ТекОписание.Дата;
		НоваяСтрока.ОписаниеВерсии = ТекОписание;
	КонецЦикла;

	ТабДляСортировки.Сортировать(СокрЛП(СтрШаблон("Дата %1", Порядок)));

	ОписанияВерсий = ТабДляСортировки.ВыгрузитьКолонку("ОписаниеВерсии");

КонецПроцедуры // СортироватьОписанияВерсийПоДате()

#КонецОбласти // СлужебныеПроцедурыИФункции

#Область Инициализация

Процедура ПриСозданииОбъекта(Знач Имя, Знач Пароль)

	ИмяПользователя = Имя;
	ПарольПользователя = Пароль;

	Лог = ПараметрыПриложения.Лог();
	
	Инициализация();
	
	ИдСеанса = Авторизация(СервисРелизов, ИмяПользователя, ПарольПользователя, СтраницаСпискаРелизов);

КонецПроцедуры // ПриСозданииОбъекта()

// Процедура - инициализирует константы модуля
//
Процедура Инициализация()
	
	СервисАвторизации = "https://login.1c.ru";

	СервисРелизов = "https://releases.1c.ru";
	СтраницаСпискаРелизов = "/total";

	ШаблонСтрокиРегистрации = "inviteCode=&username=%1&password=%2&execution=%3"
	                        + "&_eventId=submit&geolocation=&submit=Войти&rememberMe=on";
	
	ШаблонПоискаСтрокиРегистрации = "<input type=""hidden"" name=""execution"" value=""(.*)""\/>"
	                              + "<input type=""hidden"" name=""_eventId""";
	
	ШаблонПоискаКонфигураций = "<td class=""nameColumn"">\s*?<a href=""(.*)"">(.*)<\/a>?(?:\s|.)*"
							 + "?<td class=""versionColumn actualVersionColumn"">\s*"
							 + "?<a href="".*nick=(.*)&ver=(\d(?:\d|\.)*)"">?(?:\s|.)*"
							 + "?<td class=""releaseDate"">(?:\s|.)*?(\d(?:\d|\.)*)";
	
	ШаблонПоискаВерсий = "<td class=""versionColumn"">\s*<a href=""(.*)"">\s*(.*)\s*<\/a>(\s|.)*?"
	                   + "<td class=""dateColumn"">\s*(.*)\s*<\/td>(\s|.)*?"
	                   + "<td class=""version previousVersionsColumn"">\s*(.*)\s*<\/td>";

	ШаблонПоискаАдресаСтраницыЗагрузки = "<div class=""formLine"">\s*<a href=""(.*)"">\s*(.*)\s*<\/a>(\s|.)*?<\/div>";

	ШаблонПоискаСсылкиДляЗагрузки = "<div class=""downloadDist"">(\s|.)*?<a href=""(.*)"">\s*"
	                              + "Скачать дистрибутив\s*<\/a>(\s|.)*?<\/div>";
	
	ШаблонПоискаПутиКФайлуВАдресе = "\?.*path=(.+)(?:\z|&)";

КонецПроцедуры // Инициализация()

#КонецОбласти // Инициализация
