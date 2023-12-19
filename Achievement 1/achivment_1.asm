.include "m8def.inc"

; Определение констант
.equ F_CPU = 1000000 ; Частота микроконтроллера (1 МГц)
.equ BAUD = 9600 ; Скорость передачи данных для USART
.equ TIMER1_INTERVAL = 1000 ; Интервал для таймера 1 (в миллисекундах)
.equ TIMER2_INTERVAL = 2000 ; Интервал для таймера 2 (в миллисекундах)

; Определение строк
TIMER1_STR:	.db "ping", 0 ; Строка для таймера 1
TIMER2_STR:	.db "pong", 0 ; Строка для таймера 2

; Регистры
.def temp = r16 ; Временный регистр
.def timer1_high = r17 ; Регистр для хранения старшего байта интервала таймера 1
.def timer1_low = r18 ; Регистр для хранения младшего байта интервала таймера 1
.def timer2 = r19 ; Регистр для хранения интервала таймера 2

; Флаги
.def timer1_updated = r20 ; Флаг обновления интервала таймера 1
.def timer2_updated = r21 ; Флаг обновления интервала таймера 2

; Указатели
.def str_ptr = r22 ; Указатель на строку
.def str_len = r23 ; Длина строки

; Прерывание таймера 1
.org OVF1addr
rjmp TIMER1_ISR

; Прерывание таймера 2
.org OVF2addr
rjmp TIMER2_ISR

; Инициализация USART
init_usart:
	ldi temp, low(-(F_CPU/(BAUD*16))) ; Рассчет скорости передачи данных
	sts UBRRH, temp ; Установка значения в регистр UBRRH
	ldi temp, low(-(F_CPU/(BAUD*16)))
	sts UBRRL, temp ; Установка значения в регистр UBRRL
	ldi temp, (1<<RXEN)|(1<<TXEN) ; Включение приемника и передатчика USART
	sts UCSRB, temp
	ldi temp, (1<<UCSZ1)|(1<<UCSZ0) ; Установка формата данных (8 бит, 1 стоп-бит)
	sts UCSRC, temp
	ret

; Функция передачи символа через USART
transmit_char:
	sts UDR, temp ; Передача данных
loop_until_bit_is_set:
	sbis UCSRA, UDRE ; Проверка, готово ли устройство к передаче новых данных
	rjmp loop_until_bit_is_set ; Если не готово, ждем
	ret

; Функция передачи строки через USART
transmit_string:
	ldi str_ptr, 0 ; Инициализация указателя на строку
next_char:
	ld temp, Z+ ; Загрузка символа из строки
	cp temp, 0 ; Проверка на конец строки (нулевой символ)
	breq end_transmit ; Если нулевой символ, завершаем передачу
	call transmit_char ; Передача символа через USART
	rjmp next_char ; Переход к следующему символу
end_transmit:
	ret

; Инициализация таймеров
init_timers:
	ldi temp, (1<<TOIE1)|(1<<TOIE2) ; Разрешение прерывания от таймеров 1 и 2
	sts TIMSK, temp ; Установка бита разрешения прерывания
	ldi temp, (1<<CS10) ; Установка предделителя таймеров (без предделителя)
	sts TCCR1B, temp ; Установка бита старшего байта TCCR1B
	sts TCCR2, temp ; Установка бита старшего байта TCCR2
	ret

; Функция изменения значения таймера 1
set_timer1_interval:
	lds timer1_low, Z+ ; Загрузка младшего байта интервала таймера 1
	lds timer1_high, Z+ ; Загрузка старшего байта интервала таймера 1
	ldi timer1_updated, 1 ; Установка флага обновления интервала таймера 1
	ret

; Функция изменения значения таймера 2
set_timer2_interval:
	lds timer2, Z+ ; Загрузка значения интервала таймера 2
	ldi timer2_updated, 1 ; Установка флага обновления интервала таймера 2
	ret

; Функция перезапуска таймеров
restart_timers:
	ldi temp, (1<<TOV1) ; Сброс флага переполнения таймера 1
	sts TIFR, temp
	ldi temp, (1<<TOV2) ; Сброс флага переполнения таймера 2
	sts TIFR, temp
	ret

; Функция изменения строки для таймера 1
set_timer1_string:
	ldi str_ptr, 0 ; Установка указателя на строку
	ldi str_len, 0 ; Установка длины строки
next_char1:
	lds temp, Z+ ; Загрузка символа из строки
	cp temp, 0 ; Проверка на конец строки (нулевой символ)
	breq end_set_timer1_string ; Если нулевой символ, завершаем чтение
	sts TIMER1_STR + str_len, temp ; Сохранение символа в строке TIMER1_STR
	inc str_len ; Увеличение длины строки
	rjmp next_char1 ; Переход к следующему символу
