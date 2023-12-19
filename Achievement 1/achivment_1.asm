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
	ldi temp, 0 ; Инициализация счетчика
next_char:
	ld temp, X ; Загрузка символа из строки
	inc X ; Переход к следующему символу
	; Проверка на конец строки (нулевой символ)
	brne transmit_char ; Если не нулевой символ, передаем его
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
	movw r24, TIMER1_INTERVAL ; Загрузка значения TIMER1_INTERVAL в регистры r24 и r25
	sts OCR1AH, r25 ; Установка старшего байта OCR1A
	sts OCR1AL, r24 ; Установка младшего байта OCR1A
	ret

; Функция изменения значения таймера 2
set_timer2_interval:
	movw r24, TIMER2_INTERVAL ; Загрузка значения TIMER2_INTERVAL в регистры r24 и r25
	sts OCR2, r24 ; Установка значения OCR2
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
	ldi ZH, high(TIMER1_STR) ; Установка указателя Z на строку TIMER1_STR
	ldi ZL, low(TIMER1_STR)
	ret

; Функция изменения строки для таймера 2
set_timer2_string:
	ldi ZH, high(TIMER2_STR) ; Установка указателя Z на строку TIMER2_STR
	ldi ZL, low(TIMER2_STR)
	ret

; Прерывание таймера 1
TIMER1_ISR:
	call transmit_string ; Передача строки через USART
	call restart_timers ; Перезапуск таймеров
	reti ; Возврат из прерывания

; Прерывание таймера 2
TIMER2_ISR:
	call transmit_string ; Передача строки через USART
	call restart_timers ; Перезапуск таймеров
	reti ; Возврат из прерывания

; Вектор сброса
.org 0x0000
rjmp main

main:
	; Инициализация
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp

	call init_usart ; Инициализация USART
	call init_timers ; Инициализация таймеров

	; Бесконечный цикл
loop:
	; Обработка команд через USART
	lds temp, UDR ; Чтение данных из регистра UDR
	cpse temp, '1' ; Сравнение с символом '1'
	rjmp set_timer1_interval ; Если равно, перейти к установке интервала таймера 1
	cpse temp, '2' ; Сравнение с символом '2'
	rjmp set_timer2
