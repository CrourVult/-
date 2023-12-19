.include "m8def.inc"

; ����������� ��������
.equ F_CPU = 1000000  
.equ BAUD = 9600 
.equ TIMER1_INTERVAL = 1000 
.equ TIMER2_INTERVAL = 2000

; ����������� �����
TIMER1_STR:	.db "ping", 0
TIMER2_STR:	.db "pong", 0 

; ��������
.def temp = r16 ;
.def timer1_high = r17
.def timer1_low = r18 
.def timer2 = r19 

; �����
.def timer1_updated = r20 
.def timer2_updated = r21

; ���������
.def str_ptr = r22 
.def str_len = r23 

; ���������� ������� 1
.org OVF1addr
rjmp TIMER1_ISR

; ���������� ������� 2
.org OVF2addr
rjmp TIMER2_ISR

; ������������� USART
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

; ������� �������� ������� ����� USART
transmit_char:
	sts UDR, temp 
loop_until_bit_is_set:
	sbis UCSRA, UDRE 
	rjmp loop_until_bit_is_set 
	ret

; ������� �������� ������ ����� USART
transmit_string:
	ldi str_ptr, 0 
next_char:
	ld temp, Z+
	cp temp, 0 
	breq end_transmit 
	call transmit_char 
	rjmp next_char
end_transmit:
	ret

; ������������� ��������
init_timers:
	ldi temp, (1<<TOIE1)|(1<<TOIE2)
	sts TIMSK, temp 
	ldi temp, (1<<CS10) 
	sts TCCR1B, temp 
	sts TCCR2, temp 
	ret

; ������� ��������� �������� ������� 1
set_timer1_interval:
	lds timer1_low, Z+
	lds timer1_high, Z+ 
	ldi timer1_updated, 1 
	ret

; ������� ��������� �������� ������� 2
set_timer2_interval:
	lds timer2, Z+ 
	ldi timer2_updated, 1
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
	ldi str_ptr, 0
	ldi str_len, 0 
next_char1:
	lds temp, Z+ 
	cp temp, 0 
	breq end_set_timer1_string 
	sts TIMER1_STR + str_len, temp
	inc str_len 
	rjmp next_char1 
