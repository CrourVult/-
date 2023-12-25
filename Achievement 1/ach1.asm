; AVR Assembler Code ��� Atmega8
.def temp = r16
.def baudrate = r17

; ������������� USART
USART_Init:
    ldi temp, 0x06             ; ��������� �������� ������
    out UBRRH, temp
    ldi temp, 0x00
    out UBRRL, temp
    ldi temp, (1<<RXEN)|(1<<TXEN) ; ��������� ��������� � �����������
    out UCSRB, temp
    ldi temp, (1<<URSEL)|(3<<UCSZ0) ; ����������� �����, 8 ��� ������, ��� �������� ��������, 1 ����-���
    out UCSRC, temp
    ret

; �������� ������ � USART
USART_Transmit:
    ; r24 = ����� ������
    ldi r25, 0x00
    tx_loop:
        lpm temp, Z+
        tst temp
        breq tx_end
        out UDR, temp
        tx_delay:
            sbis UCSRA, UDRE
            rjmp tx_delay
        rjmp tx_loop
    tx_end:
    ret

; ��������� ��� ���������� �������
.equ TIMER1_INTERVAL = 62500
.equ TIMER2_INTERVAL = 125000
.equ TIMER1_STR = "ping\r\n"
.equ TIMER2_STR = "pong\r\n"

; ������������� ������� 1 ��� ��������� TIMER1_INTERVAL
Timer1_Init:
    ldi temp, high(TIMER1_INTERVAL)  ; �������� �������� �����
    out OCR1AH, temp
    ldi temp, low(TIMER1_INTERVAL)   ; �������� �������� �����
    out OCR1AL, temp
    ldi temp, (1<<WGM12)            ; ����� CTC (��������� � OCR1A)
    out TCCR1B, temp
    ldi temp, (1<<OCIE1A)           ; ���������� ���������� �� ���������� � OCR1A
    out TIMSK, temp
    ret

; ������������� ������� 2 ��� ��������� TIMER2_INTERVAL
; ����������� ������ �������������, ��� � ��� ������� 1

; ����������� ���������� ��� ��������
Timer1_Compare_Match:
    ; ��� ��� �������� "ping\r\n" ����� USART
    ldi ZH, high(TIMER1_STR)
    ldi ZL, low(TIMER1_STR)
    rcall USART_Transmit
    reti

Timer2_Compare_Match:
    ; ��� ��� �������� "pong\r\n" ����� USART
    ldi ZH, high(TIMER2_STR)
    ldi ZL, low(TIMER2_STR)
    rcall USART_Transmit
    reti

; �������� ����
main:
    rcall USART_Init
    rcall Timer1_Init
    rcall Timer2_Init
    sei ; ��������� ����������
    loop:
        nop ; ������ ����, ������ ����������� � �����������
        rjmp loop
