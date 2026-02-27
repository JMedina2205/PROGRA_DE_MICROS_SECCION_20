/*
* PRELAB3.asm
*
* Creado: 19/02/26
* Autor : Javier Medina - 22124
* Descripción: PRELAB3
*/
/****************************************/
// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P
.dseg
.org    SRAM_START
//variable_name:     .byte   1   // Memory alocation for variable_name:     .byte   (byte size)
.cseg
.org 0x0000
	JMP START
.org PCI1addr
	JMP ISR_PCINT1
.org OVF0addr
	JMP	ISR_TIMER0_OVF
 /****************************************/
// Configuración de la pila
START:
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16
/****************************************/
// Configuracion MCU
SETUP:
    CLI		// DESHABILITO INTERRUPCIONES GLOBALES

	// CONFIG. PRESCALER
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16				// HABILITAR PRESCALER
	LDI		R16, (1 << CLKPS2)
	STS		CLKPR, R16				// PRESCALER A 16 F_cpu = 1MHz

	// CONFIG. ENTRADAS/SALIDAS
	LDI		R16, 0b00001111			// LEDS
	OUT		DDRB, R16

	LDI		R16, 0b00010000			// BOTONES & DISPLAY (G)
	OUT		DDRC, R16

	LDI		R16, 0b11111111			// DISPLAY (A-F)
	OUT		DDRD, R16

	// PULL-UPS BOTONES
	LDI		R16, 0b00000101			// PC0 Y PC2
	OUT		PORTC, R16

	// HABILITAR INTERRUPCIONES PCIE1
	LDI		R16, (1 << PCIE1)		// PUERTO C
	STS		PCICR, R16
	LDI		R16, (1 << PCINT8) | (1 << PCINT10)		//PC0 Y PC2
	STS		PCMSK1, R16

	// HABILITAR INTERRUPCIONES TOIE0
	LDI		R16, (1 << TOIE0)
	STS		TIMSK0, R16


	// LIMPIEZA REGSITROS
	CLR		R17
	CLR		R18
	CLR		R19
	CLR		R21
	CLR		R22
	CLR		R23

	SEI		// HABILITANDO INTERRUPCIONES GLOBALES

/****************************************/
// TABLA DISPLAY 7 SEG
Tabla_display: .DB 0x3F,0x30,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71

    LDI		ZH,HIGH (Tabla_display << 1)
    LDI		ZL,LOW (Tabla_display << 1)
    LPM		R18,Z							
    RCALL	DISPLAY

// CONFIG. TIMER0
	OUT		TCCR0A, R16				//	MODO NORMAL

	LDI		R16,  (1 << CS00)	| (1 << CS02)		//	PRESCALER = 1024
	OUT		TCCR0B, R16
	LDI		R16, 10
	OUT		TCNT0, R16

/****************************************/
// Loop Infinito
MAIN_LOOP:
    RJMP    MAIN_LOOP
/****************************************/
// NON-Interrupt subroutines

// SALIDAS LEDS
LEDS:
	SBRS	R17, 0
	CBI		PORTB, PB0
	SBRC	R17, 0
	SBI		PORTB, PB0

	SBRS	R17, 1
	CBI		PORTB, PB1
	SBRC	R17, 1
	SBI		PORTB, PB1

	SBRS	R17, 2
	CBI		PORTB, PB2
	SBRC	R17, 2
	SBI		PORTB, PB2

	SBRS	R17, 3
	CBI		PORTB, PB3
	SBRC	R17, 3
	SBI		PORTB, PB3

	RET

//	SALIDAS DISPLAY
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
/****************************************/
// CONTADOR BINARIO
// INCREMENTAR CONTADOR
INCREMENTAR:
	INC		R17
	CPI		R17, 0x10		// CUANDO LLEGUE A 16 EL CONTADOR
	BREQ	TOPE_SUPERIOR
	RJMP	LEDS

TOPE_SUPERIOR:
	CLR		R17
	RJMP	LEDS

// DECREMENTAR CONTADOR
DECREMENTAR:
	DEC		R17
	CPI		R17, 0xFF		// CUANDO BAJA DE 0 EL CONTADOR
	BREQ	TOPE_INFERIOR
	RJMP	LEDS

TOPE_INFERIOR:
	LDI		R17, 0x0F		// REGRESA A 15
	RJMP	LEDS
/****************************************/
// CONTADOR DISPLAY
CONT_DISP:
    CPI		R18,0x71        // SI ESTA EN F SE REGRESA A 0
    BREQ	NUM_F

    INC		ZL              // INCREMENTA A SIG. VALOR EN TABLA
    RJMP	ACTUALIZAR
    RJMP	CONT_DISP

NUM_F:
    LDI		ZL,LOW (Tabla_display << 1)
    DEC		ZL
    LPM		R18,Z
    CLR		R23
    RJMP	ACTUALIZAR

ACTUALIZAR:
    LPM		R18,Z
    RJMP	DISPLAY

/****************************************/
// Interrupt routines

// INTERRUPCION BOTONES CONTADOR
ISR_PCINT1:
	IN		R19, PINC	

	SBRS	R19, PC0
	CALL	INCREMENTAR

	SBRS	R19, PC2
	CALL	DECREMENTAR
	RETI

//	INTERRUPCION  DISPLAY
ISR_TIMER0_OVF:
	CALL	CONT_DISP
	RETI

/****************************************/
