/*
* Lab_2.asm
* Creacion: 12/2/26
* Autor: Javier Medina - 22124
* Descripcion: LAB_2: Botones y Timer0
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"
.dseg
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)
.cseg
.org 0x00
/****************************************/
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16
//=====================================================================
// CONFIGURACIÓN MCU
SETUP:

    // PRESCALER  = 1 MHz
    LDI		R16, (1 << CLKPCE)
    STS		CLKPR, R16
    LDI		R16, 0b00000100
    STS		CLKPR, R16

    // PULL-UP BOTONES
    LDI		R16,0b00000101		// PC0 Y PC2
    OUT		PORTC,R16

    // INPUTS Y OUTPUTS
    LDI		R16,0b00010000
    OUT		DDRC,R16			// INPUTS Y OUTPUTS PUERTO C
    LDI		R16,0b11111111
    OUT		DDRD,R16			// INPUTS Y OUTPUTS PUERTO D
    LDI		R16,0b00101111
    OUT		DDRB,R16			// INPUTS Y OUTPUTS PUERTO B

    // LIMPIEZA REGISTROS
    CLR		R16
    CLR		R17             
    CLR		R18            
    CLR		R19             
    CLR		R20
    CLR		R21
    CLR		R22             
    CLR		R23             

//=====================================================================
// TABLA DISPLAY 7 SEG
Tabla_display: .DB 0x3F,0x30,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71

    LDI		ZH,HIGH (Tabla_display << 1)
    LDI		ZL,LOW (Tabla_display << 1)
    LPM		R18,Z							
    RCALL	DISPLAY

    DEC		R23									// CONTADOR ALARMA

// TIMER0
    CLR		R16
    OUT		TCCR0A,R16						// MODO NORMAL
    LDI		R16,(1 << CS02)|(1 << CS00)
    OUT		TCCR0B,R16						// PRESCALER = 1024
    LDI		R16,98
    OUT		TCNT0,R16

//======================== LOOP =========================
MAIN_LOOP:

    IN		R16,PINC         // LEER BOTONES
    RCALL	DELAY			// ANTIRREBOTE

    SBRS	R16,PC0        // BOTON INCREMENTAR
    RJMP	INC_DISP

    SBRS	R16,PC2        // BOTON DECREMENTAR
    RJMP	DEC_DISP

    // LOGICA TIMER0
    IN		R16,TIFR0
    SBRS	R16,TOV0
    RJMP	MAIN_LOOP

    LDI		R16,98
    OUT		TCNT0,R16
    SBI		TIFR0,TOV0

    // CONTADOR DE CICLOS
    CPI		R22,9
    BREQ	CARRY
    INC		R22
    RJMP	MAIN_LOOP

CARRY:
    INC		R17             // AUMENTO CONTADOR BINARIO
    CLR		R22
    RJMP	LEDS

//=====================================================================
// SALIDAS LEDS
LEDS:

    SBRS	R17,0
    CBI		PORTB,PB0
    SBRC	R17,0
    SBI		PORTB,PB0

    SBRS	R17,1
    CBI		PORTB,PB1
    SBRC	R17,1
    SBI		PORTB,PB1

    SBRS	R17,2
    CBI		PORTB,PB2
    SBRC	R17,2
    SBI		PORTB,PB2

    SBRS	R17,3
    CBI		PORTB,PB3
    SBRC	R17,3
    SBI		PORTB,PB3

    RCALL	ALARMA        // VERIFICA COINCIDENCIA CON DISPLAY
    RJMP	MAIN_LOOP

//=====================================================================
// SALIDAS DISPLAY
DISPLAY:

    SBRS	R18,0
    CBI		PORTD,PD2
    SBRC	R18,0
    SBI		PORTD,PD2

    SBRS	R18,1
    CBI		PORTD,PD3
    SBRC	R18,1
    SBI		PORTD,PD3

    SBRS	R18,2
    CBI		PORTD,PD4
    SBRC	R18,2
    SBI		PORTD,PD4

    SBRS	R18,3
    CBI		PORTD,PD5
    SBRC	R18,3
    SBI		PORTD,PD5

    SBRS	R18,4
    CBI		PORTD,PD6
    SBRC	R18,4
    SBI		PORTD,PD6

    SBRS	R18,5
    CBI		PORTD,PD7
    SBRC	R18,5
    SBI		PORTD,PD7

    SBRS	R18,6
    CBI		PORTC,PC4
    SBRC	R18,6
    SBI		PORTC,PC4
    RET

//=====================================================================
// INCREMENTAR DISPLAY
INC_DISP:
    CPI		R18,0x71        // SI ESTA EN F SE REGRESA A 0
    BREQ	NUM_F

    IN		R16,PINC
    SBRC	R16,PC0
    INC		ZL              // INCREMENTA A SIG. VALOR EN TABLA
    SBRC	R16,PC0
    INC		R23             // CONTADOR ALARMA
    SBRC	R16,PC0
    RJMP	ACTUALIZAR
    RJMP	INC_DISP

NUM_F:
    LDI		ZL,LOW (Tabla_display << 1)
    DEC		ZL
    LPM		R18,Z
    CLR		R23
    RJMP	ACTUALIZAR

//=====================================================================
// DECREMENTAR DISPLAY

DEC_DISP:

    CPI		R18,0x3F        // SI ESTA EN 0 REGRESA A F
    BREQ	NUM_0

    IN		R16,PINC
    SBRC	R16,PC2
    DEC		ZL
    SBRC	R16,PC2
    DEC		R23
    SBRC	R16,PC2
    RJMP	ACTUALIZAR
    RJMP	DEC_DISP

NUM_0:
    LDI		R20,0x10
    ADD		ZL,R20
    ADD		R23,R20

ACTUALIZAR:
    LPM		R18,Z
    RCALL	DISPLAY
    RJMP	MAIN_LOOP

//=====================================================================
// COMPARACIÓN PARA ACTIVAR ALARMA

ALARMA:
    CP		R17,R23
    BREQ	ALARMA1
    RET

ALARMA1:
    CLR		R17
    SBIS	PORTB,PB5
    RJMP	ENCENDER
    RJMP	APAGAR

ENCENDER:
    SBI		PORTB,PB5       // LED ENCENDIDO
    RET
APAGAR:
    CBI		PORTB,PB5       // LED APAGADO
    RET

//=====================================================================
// DELAY

Delay:
    LDI		R19,100
D1: DEC		R19
    BRNE	D1
    RET