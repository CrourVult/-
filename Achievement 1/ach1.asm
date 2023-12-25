; AVR Assembler Code для Atmega8
.def temp = r16
.def baudrate = r17

; Инициализация USART
USART_Init:
    ldi temp, 0x06             ; Настройка скорости обмена
    out UBRRH, temp
    ldi temp, 0x00
    out UBRRL, temp
    ldi temp, (1<<RXEN)|(1<<TXEN) ; Включение приемника и передатчика
    out UCSRB, temp
    ldi temp, (1<<URSEL)|(3<<UCSZ0) ; Асинхронный режим, 8 бит данных, без контроля четности, 1 стоп-бит
    out UCSRC, temp
    ret

; Отправка строки в USART
USART_Transmit:
    ; r24 = адрес строки
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

; Константы для интервалов таймера
.equ TIMER1_INTERVAL = 62500
.equ TIMER2_INTERVAL = 125000
.equ TIMER1_STR = "ping\r\n"
.equ TIMER2_STR = "pong\r\n"

; Инициализация Таймера 1 для интервала TIMER1_INTERVAL
Timer1_Init:
    ldi temp, high(TIMER1_INTERVAL)  ; Загрузка старшего байта
    out OCR1AH, temp
    ldi temp, low(TIMER1_INTERVAL)   ; Загрузка младшего байта
    out OCR1AL, temp
    ldi temp, (1<<WGM12)            ; Режим CTC (сравнение с OCR1A)
    out TCCR1B, temp
    ldi temp, (1<<OCIE1A)           ; Разрешение прерывания по совпадению с OCR1A
    out TIMSK, temp
    ret

; Инициализация Таймера 2 для интервала TIMER2_INTERVAL
; Аналогичная логика инициализации, как и для Таймера 1

; Обработчики прерываний для таймеров
Timer1_Compare_Match:
    ; Код для отправки "ping\r\n" через USART
    ldi ZH, high(TIMER1_STR)
    ldi ZL, low(TIMER1_STR)
    rcall USART_Transmit
    reti

Timer2_Compare_Match:
    ; Код для отправки "pong\r\n" через USART
    ldi ZH, high(TIMER2_STR)
    ldi ZL, low(TIMER2_STR)
    rcall USART_Transmit
    reti

; Основной цикл
main:
    rcall USART_Init
    rcall Timer1_Init
    rcall Timer2_Init
    sei ; Включение прерываний
    loop:
        nop ; Пустой цикл, работа выполняется в прерываниях
        rjmp loop
