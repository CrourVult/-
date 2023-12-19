.include "m8def.inc"

; Определение констант
.equ F_CPU = 1000000 
.equ BAUD = 9600 
.equ TIMER1_INTERVAL = 1000 
.equ TIMER2_INTERVAL = 2000 
; Определение строк
TIMER1_STR:	.db "ping", 0 
TIMER2_STR:	.db "pong", 0 

; Регистры
.def temp = r16 

; Прерывание таймера 1
.org OVF1addr
rjmp TIMER1_ISR

; Прерывание таймера 2
.org OVF2addr
rjmp TIMER2_ISR

; Инициализация USART
init_usart:
	ldi temp, low(-(F_CPU/(BAUD*16))) 
	sts UBRRH, temp 
	ldi temp, low(-(F_CPU/(BAUD*16)))
	sts UBRRL, temp 
	ldi temp, (1<<RXEN)|(1<<TXEN) 
	sts UCSRB, temp
	ldi temp, (1<<UCSZ1)|(1<<UCSZ0) 
	sts UCSRC, temp
	ret

; Функция передачи символа через USART
transmit_char:
	sts UDR, temp 
loop_until_bit_is_set:
	sbis UCSRA, UDRE 
	rjmp loop_until_bit_is_set 
	ret

; Функция передачи строки через USART
transmit_string:
	ldi temp, 0 
next_char:
	ld temp, X 
	inc X 
	brne transmit_char 
	ret

; Инициализация таймеров
init_timers:
	ldi temp, (1<<TOIE1)|(1<<TOIE2) 
	sts TIMSK, temp
	ldi temp, (1<<CS10) 
	sts TCCR1B, temp 
	sts TCCR2, temp 
	ret

; Функция изменения значения таймера 1
set_timer1_interval:
	movw r24, TIMER1_INTERVAL 
	sts OCR1AH, r25 
	sts OCR1AL, r24 
	ret

; Функция изменения значения таймера 2
set_timer2_interval:
	movw r24, TIMER2_INTERVAL
	sts OCR2, r24 
	ret

; Функция перезапуска таймеров
restart_timers:
	ldi temp, (1<<TOV1) 
	sts TIFR, temp
	ldi temp, (1<<TOV2) 
	sts TIFR, temp
	ret

; Функция изменения строки для таймера 1
set_timer1_string:
	ldi ZH, high(TIMER1_STR) 
	ldi ZL, low(TIMER1_STR)
	ret

; Функция изменения строки для таймера 2
set_timer2_string:
	ldi ZH, high(TIMER2_STR) 
	ldi ZL, low(TIMER2_STR)
	ret

; Прерывание таймера 1
TIMER1_ISR:
	call transmit_string 
	call restart_timers 
	reti 

; Прерывание таймера 2
TIMER2_ISR:
	call transmit_string 
	call restart_timers 
	reti 

; Вектор сброса
.org 0x0000
rjmp main

main:
	; Инициализация
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp

	call init_usart 
	call init_timers 

	; Бесконечный цикл
loop:
	; Обработка команд через USART
	lds temp, UDR 
	cpse temp, '1' 
	rjmp set_timer1_interval 
	cpse temp, '2' 
	rjmp set_timer2
