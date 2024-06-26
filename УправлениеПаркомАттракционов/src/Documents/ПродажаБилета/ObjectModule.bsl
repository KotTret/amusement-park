#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда

#Область ПрограммныйИнтерфейс

// Код процедур и функций

#КонецОбласти

#Область ОбработчикиСобытий

Процедура ОбработкаПроведения(Отказ, Режим)
	Движения.Продажи.Записывать = Истина;
	Движения.АктивныеПосещения.Записывать = Истина;
	
	Запрос = Новый Запрос;
	
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	ПродажаБилетаПродажи.Номенклатура.ВидАттракциона КАК ВидАттракциона,
	|	ПродажаБилетаПродажи.Сумма,
	|	ПродажаБилетаПродажи.Номенклатура.КоличествоПосещений * ПродажаБилетаПродажи.Количество КАК КоличествоПосещений
	|ИЗ
	|	Документ.ПродажаБилета.Продажи КАК ПродажаБилетаПродажи
	|ГДЕ
	|	ПродажаБилетаПродажи.Ссылка = &Ссылка";
	
	Запрос.УстановитьПараметр("Ссылка", Ссылка);
	
	Выборка = Запрос.Выполнить().Выбрать();
	
	Пока Выборка.Следующий() Цикл
	// регистр АктивныеПосещения
	Движение = Движения.АктивныеПосещения.Добавить();
	Движение.Период = Дата;
	Движение.ВидДвижения = ВидДвиженияНакопления.Приход;
	Движение.Основание = Ссылка;
	Движение.ВидАттракциона = Выборка.ВидАттракциона;
	Движение.КоличествоПосещений = Выборка.КоличествоПосещений;

	// регистр Продажи
	Движение = Движения.Продажи.Добавить();
	Движение.Период = Дата;
	Движение.ВидАттракциона = Выборка.ВидАттракциона;
	Движение.Клиент = Клиент;
	Движение.Сумма = Выборка.Сумма;
			
	КонецЦикла;	
	
	НачислитьСписатьБонусныеБаллы(Отказ);

КонецПроцедуры


Процедура ОбработкаПроверкиЗаполнения(Отказ, ПроверяемыеРеквизиты)
	МаксимальнаяДоля = Константы.МаксимальнаяДоляОплатыБаллами.Получить();

	СуммаПродажи = Продажи.Итог("Сумма");
	Если БаллыКСписанию <> 0 Тогда
		Если БаллыКСписанию > СуммаПродажи Тогда
			Сообщение = Новый СообщениеПользователю;
			Сообщение.Текст = "Списываемые баллы не должны превышать сумму билета";
			Сообщение.Поле = "БаллыКСписанию";
			Сообщение.Сообщить();
		КонецЕсли;

		Если УдалитьЦена <> 0 Тогда
			Доля = БаллыКСписанию / СуммаПродажи * 100;
			Если Доля > МаксимальнаяДоля Тогда
				Сообщение = Новый СообщениеПользователю;
				Сообщение.Текст = СтрШаблон("Доля списываемых баллов больше допустимой (%1%%)", МаксимальнаяДоля);
				Сообщение.Поле = "БаллыКСписанию";
				Сообщение.Сообщить();
			КонецЕсли;
		КонецЕсли;
		Если Не ЗначениеЗаполнено(Клиент) Тогда
			Отказ = Истина;
			Сообщение = Новый СообщениеПользователю;
			Сообщение.Текст = "Для списания Баллов необходимо указать Клиента";
			Сообщение.Поле = "Клиент";
			Сообщение.Сообщить();
		КонецЕсли;
	КонецЕсли;
КонецПроцедуры
#КонецОбласти

#Область СлужебныйПрограммныйИнтерфейс

// Код процедур и функций

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Процедура НачислитьСписатьБонусныеБаллы(Отказ)
	
	Движения.БонусныеБаллыКлиентов.Записывать = Истина;
	Если НЕ ЗначениеЗаполнено(Клиент) Тогда
		Возврат;
	КонецЕсли;
	
	СуммаПокупокКлиента = СуммаПокупокКлиента();
	
	ДоляНакапливаемыхБаллов = ДоляНакапливаемыхБаллов(СуммаПокупокКлиента);
	
	БаллыНакопления = СуммаДокумента * ДоляНакапливаемыхБаллов / 100;
	
	Если БаллыНакопления <> 0 Тогда
		Движение = Движения.БонусныеБаллыКлиентов.ДобавитьПриход();
		Движение.Период = Дата;
		Движение.Клиент = Клиент;
		Движение.Сумма = БаллыНакопления;
		
	КонецЕсли;
	
	Если БаллыКСписанию <> 0 Тогда
		Движение = Движения.БонусныеБаллыКлиентов.ДобавитьРасход();
		Движение.Период = Дата;
		Движение.Клиент = Клиент;
		Движение.Сумма = БаллыКСписанию;
	КонецЕсли;
	
	Движения.БонусныеБаллыКлиентов.Записать();

	
	Запрос = Новый Запрос;
	Запрос.Текст =
		"ВЫБРАТЬ
		|	БонусныеБаллыКлиентовОстатки.СуммаОстаток КАК СуммаОстаток
		|ИЗ
		|	РегистрНакопления.БонусныеБаллыКлиентов.Остатки(&Период, Клиент = &Клиент) КАК БонусныеБаллыКлиентовОстатки
		|ГДЕ
		|	БонусныеБаллыКлиентовОстатки.СуммаОстаток < 0";
	
	Запрос.УстановитьПараметр("Клиент", Клиент);
	Запрос.УстановитьПараметр("Период", Новый Граница (МоментВремени(), ВидГраницы.Включая));
	
	РезультатЗапроса = Запрос.Выполнить();
	
	Выборка = РезультатЗапроса.Выбрать();
	Если Выборка.Следующий() Тогда
		Отказ = Истина;
		Сообщение = Новый СообщениеПользователю;
		Сообщение.Текст = СтрШаблон("Не Хватает баллов для списания, на балансе %1",
			 Выборка.СуммаОстаток + БаллыКСписанию);
		Сообщение.УстановитьДанные(ЭтотОбъект);
		Сообщение.Поле = "БаллыКСписанию";
		Сообщение.Сообщить();
	КонецЕсли;
	
	
КонецПроцедуры

Функция СуммаПокупокКлиента()
	
	Запрос = Новый Запрос;
	Запрос.Текст =
		"ВЫБРАТЬ
		|	ПродажиОбороты.СуммаОборот
		|ИЗ
		|	РегистрНакопления.Продажи.Обороты(, &КонецПериода,, Клиент = &Клиент) КАК ПродажиОбороты";
	
	Запрос.УстановитьПараметр("КонецПериода", Новый Граница(МоментВремени(), ВидГраницы.Исключая));
	Запрос.УстановитьПараметр("Клиент", Клиент);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	Выборка = РезультатЗапроса.Выбрать();
	
	Если Выборка.Следующий() Тогда
		Возврат Выборка.СуммаОборот;
	КонецЕсли;
	
	Возврат 0;
	
КонецФункции

Функция ДоляНакапливаемыхБаллов(СуммаПокупокКлиента)
	
	Запрос = Новый Запрос;
	Запрос.Текст =
		"ВЫБРАТЬ
		|	ШкалаБонуснойПрограммыДиапазоны.ПроцентНакопления
		|ИЗ
		|	РегистрСведений.АктуальнаяШкалаБонуснойПрограммы.СрезПоследних(&Период,) КАК
		|		АктуальнаяШкалаБонуснойПрограммыСрезПоследних
		|		ЛЕВОЕ СОЕДИНЕНИЕ Документ.ШкалаБонуснойПрограммы.Диапазоны КАК ШкалаБонуснойПрограммыДиапазоны
		|		ПО АктуальнаяШкалаБонуснойПрограммыСрезПоследних.Шкала = ШкалаБонуснойПрограммыДиапазоны.Ссылка.Ссылка
		|ГДЕ
		|	ШкалаБонуснойПрограммыДиапазоны.НижняяГраница <= &СуммаПокупок
		|	И (ШкалаБонуснойПрограммыДиапазоны.ВерхняяГраница > &СуммаПокупок
		|	ИЛИ ШкалаБонуснойПрограммыДиапазоны.ВерхняяГраница = 0)";
	
	Запрос.УстановитьПараметр("СуммаПокупок", СуммаПокупокКлиента);
	Запрос.УстановитьПараметр("СуммыПокупок", СуммаПокупокКлиента);
	Запрос.УстановитьПараметр("Период",  Новый Граница(МоментВремени()));
	
	РезультатЗапроса = Запрос.Выполнить();
	
	Выборка = РезультатЗапроса.Выбрать();
	
	Если Выборка.Следующий() Тогда
		Возврат Выборка.ПроцентНакопления;
	КонецЕсли;
	
	Возврат 0;

КонецФункции

#КонецОбласти

#Область Инициализация

#КонецОбласти

#КонецЕсли