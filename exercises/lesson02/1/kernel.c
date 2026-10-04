#include "printf.h"
#include "utils.h"
#include "mini_uart.h"

void kernel_main(unsigned int el3_state, unsigned int el2_state, unsigned int el1_state)
{
	uart_init();
	init_printf(0, putc);
	printf("Exception level transitions: %d, %d, %d \r\n", el3_state, el2_state, el1_state);

	while (1) {
		uart_send(uart_recv());
	}
}
