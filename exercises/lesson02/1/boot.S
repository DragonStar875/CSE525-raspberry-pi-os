#include "arm/sysregs.h"

#include "mm.h"

.section ".text.boot"

.globl _start
_start:
	mrs	x0, mpidr_el1		
	and	x0, x0,#0xFF		// Check processor id
	cbz	x0, master		// Hang for all non-primary CPU
	b	proc_hang

proc_hang: 
	b 	proc_hang

master:
	//Check and store the current EL
	mrs	x19, CurrentEL
	lsr	x19, x19, #2

	// Configure security settings while in EL3 (EL2 in secure AArch64 and EL1 in non-secure)
	ldr	x0, =SCR_VALUE
	msr	scr_el3, x0

	// Set target level for eret to EL2 rather than EL1
	ldr	x0, =0x3C9
	msr	spsr_el3, x0

	// Make entry target EL2 rather than EL1, since we want to step throught the levels
	adr	x0, el2_entry
	msr	elr_el3, x0

	eret                    // Sets EL (dropping from 3 to 2)

el2_entry:
	mrs	x20, CurrentEL
	lsr	x20, x20, #2

	// Configures execution state for EL1 (even though we are not using a hyypervisor)
	ldr	x0, =HCR_VALUE
	msr	hcr_el2, x0

	// Enable EL1 accesss to physical timers (necessary to specify since we are 
	// setting up EL2, even though we are not operating in it). Taken from the Linux EL2 initalization doc.
	mrs	x0, cnthctl_el2
	orr	x0, x0, #3
	msr	cnthctl_el2, x0
	msr	cntvoff_el2, xzr

	// Disable coprocessor traps to EL2
	msr	cptr_el2, xzr

	// Set target level for eret to EL1
	ldr	x0, =0x3C5
	msr	spsr_el2, x0

	adr	x0, el1_entry
	msr	elr_el2, x0

	eret                    // Final EL set to EL1

el1_entry:
	mrs	x21, CurrentEL
	lsr	x21, x21, #2

	// Disable the MMU as in the original boot.S for Lesson 2
	ldr	x0, =SCTLR_VALUE_MMU_DISABLED
	msr	sctlr_el1, x0			

	adr	x0, bss_begin
	adr	x1, bss_end
	sub	x1, x1, x0
	bl 	memzero

	mov	sp, #LOW_MEMORY
	
	// Move EL states to be kernel_main arguments
    mov     x0, x19             // EL3 state
    mov     x1, x20             // EL2 state
    mov     x2, x21             // EL1 state
	
	bl	kernel_main
	b 	proc_hang		// should never come here
