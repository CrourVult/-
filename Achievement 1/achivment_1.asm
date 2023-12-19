.include "m8def.inc"

; ����������� ��������
.equ F_CPU = 1000000 ; ������� ���������������� (1 ���)
.equ BAUD = 9600 ; �������� �������� ������ ��� USART
.equ TIMER1_INTERVAL = 1000 ; �������� ��� ������� 1 (� �������������)
.equ TIMER2_INTERVAL = 2000 ; �������� ��� ������� 2 (� �������������)

; ����������� �����
TIMER1_STR:	.db "ping", 0 ; ������ ��� ������� 1
TIMER2_STR:	.db "pong", 0 ; ������ ��� ������� 2

; ��������
.def temp = r16 ; ��������� �������

; ���������� ������� 1
.org OVF1addr
rjmp TIMER1_ISR

; ���������� ������� 2
.org OVF2addr
rjmp TIMER2_ISR

; ������������� USART
init_usart:
	ldi temp, low(-(F_CPU/(BAUD*16))) ; ������� �������� �������� ������
	sts UBRRH, temp ; ��������� �������� � ������� UBRRH
	ldi temp, low(-(F_CPU/(BAUD*16)))
	sts UBRRL, temp ; ��������� �������� � ������� UBRRL
	ldi temp, (1<<RXEN)|(1<<TXEN) ; ��������� ��������� � ����������� USART
	sts UCSRB, temp
	ldi temp, (1<<UCSZ1)|(1<<UCSZ0) ; ��������� ������� ������ (8 ���, 1 ����-���)
	sts UCSRC, temp
	ret

; ������� �������� ������� ����� USART
transmit_char:
	sts UDR, temp ; �������� ������
loop_until_bit_is_set:
	sbis UCSRA, UDRE ; ��������, ������ �� ���������� � �������� ����� ������
	rjmp loop_until_bit_is_set ; ���� �� ������, ����
	ret

; ������� �������� ������ ����� USART
transmit_string:
	ldi temp, 0 ; ������������� ��������
next_char:
	ld temp, X ; �������� ������� �� ������
	inc X ; ������� � ���������� �������
	; �������� �� ����� ������ (������� ������)
	brne transmit_char ; ���� �� ������� ������, �������� ���
	ret

; ������������� ��������
init_timers:
	ldi temp, (1<<TOIE1)|(1<<TOIE2) ; ���������� ���������� �� �������� 1 � 2
	sts TIMSK, temp ; ��������� ���� ���������� ����������
	ldi temp, (1<<CS10) ; ��������� ������������ �������� (��� ������������)
	sts TCCR1B, temp ; ��������� ���� �������� ����� TCCR1B
	sts TCCR2, temp ; ��������� ���� �������� ����� TCCR2
	ret

; ������� ��������� �������� ������� 1
set_timer1_interval:
	movw r24, TIMER1_INTERVAL ; �������� �������� TIMER1_INTERVAL � �������� r24 � r25
	sts OCR1AH, r25 ; ��������� �������� ����� OCR1A
	sts OCR1AL, r24 ; ��������� �������� ����� OCR1A
	ret

; ������� ��������� �������� ������� 2
set_timer2_interval:
	movw r24, TIMER2_INTERVAL ; �������� �������� TIMER2_INTERVAL � �������� r24 � r25
	sts OCR2, r24 ; ��������� �������� OCR2
	ret

; ������� ����������� ��������
restart_timers:
	ldi temp, (1<<TOV1) ; ����� ����� ������������ ������� 1
	sts TIFR, temp
	ldi temp, (1<<TOV2) ; ����� ����� ������������ ������� 2
	sts TIFR, temp
	ret

; ������� ��������� ������ ��� ������� 1
set_timer1_string:
	ldi ZH, high(TIMER1_STR) ; ��������� ��������� Z �� ������ TIMER1_STR
	ldi ZL, low(TIMER1_STR)
	ret

; ������� ��������� ������ ��� ������� 2
set_timer2_string:
	ldi ZH, high(TIMER2_STR) ; ��������� ��������� Z �� ������ TIMER2_STR
	ldi ZL, low(TIMER2_STR)
	ret

; ���������� ������� 1
TIMER1_ISR:
	call transmit_string ; �������� ������ ����� USART
	call restart_timers ; ���������� ��������
	reti ; ������� �� ����������

; ���������� ������� 2
TIMER2_ISR:
	call transmit_string ; �������� ������ ����� USART
	call restart_timers ; ���������� ��������
	reti ; ������� �� ����������

; ������ ������
.org 0x0000
rjmp main

main:
	; �������������
	ldi temp, low(RAMEND)
	out SPL, temp
	ldi temp, high(RAMEND)
	out SPH, temp

	call init_usart ; ������������� USART
	call init_timers ; ������������� ��������

	; ����������� ����
loop:
	; ��������� ������ ����� USART
	lds temp, UDR ; ������ ������ �� �������� UDR
	cpse temp, '1' ; ��������� � �������� '1'
	rjmp set_timer1_interval ; ���� �����, ������� � ��������� ��������� ������� 1
	cpse temp, '2' ; ��������� � �������� '2'
	rjmp set_timer2
