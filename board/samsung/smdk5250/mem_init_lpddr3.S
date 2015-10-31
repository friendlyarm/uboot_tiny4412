/*
 * (C) Copyright 2011 Samsung Electronics Co. Ltd
 *
 * See file CREDITS for list of people who contributed to this
 * project.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 */

#include <config.h>
#include <asm/arch/cpu.h>

//#define RD_LVL		1

	.globl mem_ctrl_asm_init
mem_ctrl_asm_init:
	push	{lr}

	/* CLK_DIV_DMC0 on iROM DMC=50MHz for Init DMC */
	ldr	r0, =ELFIN_CLOCK_BASE	@0x1001_0000

	ldr	r1, =0x1
	ldr	r2, =LPDDR3PHY_CTRL
	str	r1, [r0, r2]

	bl	delay

	ldr	r1, =0x0
	ldr	r2, =LPDDR3PHY_CTRL
	str	r1, [r0, r2]

	bl	delay

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, =0x17021A40
	str	r1, [r0, #DMC_PHY_CON0]
	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, =0x17021A40
	str	r1, [r0, #DMC_PHY_CON0]

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, =0x00000F0F
	str	r1, [r0, #DMC_PHY_CON14]
	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, =0x00000F0F
	str	r1, [r0, #DMC_PHY_CON14]

#if defined(MCLK_CDREX_400)
	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, =0x806
	str	r1, [r0, #DMC_PHY_CON42]
	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, =0x806
	str	r1, [r0, #DMC_PHY_CON42]
#elif	defined(MCLK_CDREX_533)
	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, =0x808
	str	r1, [r0, #DMC_PHY_CON42]
	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, =0x808
	str	r1, [r0, #DMC_PHY_CON42]
#endif

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, [r0, #DMC_PHY_CON16]
	ldr	r2, =0x08040000
	ldr	r3, =0xFF17FFFF
	ldr	r4, =0x04400000
	orr	r1, r1, r2
	and	r1, r1, r3
	orr	r1, r1, r4
	str	r1, [r0, #DMC_PHY_CON16]
	orr	r1, r1, #0x4
	str	r1, [r0, #DMC_PHY_CON16]
	orr	r1, r1, #0x2
	str	r1, [r0, #DMC_PHY_CON16]

repeat_phy0_con17:
	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, [r0, #DMC_PHY_CON17]
	and	r1, r1, #0x1
	cmp	r1, #0x1
	bne	repeat_phy0_con17

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, [r0, #DMC_PHY_CON16]
	ldr	r2, =0xFFFBFFFD
	and	r1, r1, r2
	str	r1, [r0, #DMC_PHY_CON16]

	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, [r0, #DMC_PHY_CON16]
	ldr	r2, =0x08040000
	ldr	r3, =0xFF17FFFF
	ldr	r4, =0x04400000
	orr	r1, r1, r2
	and	r1, r1, r3
	orr	r1, r1, r4
	str	r1, [r0, #DMC_PHY_CON16]
	orr	r1, r1, #0x4
	str	r1, [r0, #DMC_PHY_CON16]
	orr	r1, r1, #0x2
	str	r1, [r0, #DMC_PHY_CON16]

repeat_phy1_con17:
	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, [r0, #DMC_PHY_CON17]
	and	r1, r1, #0x1
	cmp	r1, #0x1
	bne	repeat_phy1_con17

	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, [r0, #DMC_PHY_CON16]
	ldr	r2, =0xFFFBFFFD
	and	r1, r1, r2
	str	r1, [r0, #DMC_PHY_CON16]

@set_rd_fetch
	ldr	r0, =DMC_CTRL_BASE
	ldr	r1, [r0, #DMC_CONCONTROL]
	ldr	r2, =0xFFFF8FFF
	ldr	r3, =0x3000
	and	r1, r1, r2
	orr	r1, r1, r3
	str	r1, [r0, #DMC_CONCONTROL]

@dfi_init_start
	ldr	r0, =DMC_CTRL_BASE
	ldr	r1, [r0, #DMC_CONCONTROL]
	ldr	r2, =0xFFFFFFDF
	ldr	r3, =0x10000000
	and	r1, r1, r2
	orr	r1, r1, r3
	str	r1, [r0, #DMC_CONCONTROL]

	bl	delay

	ldr	r0, =DMC_CTRL_BASE
	ldr	r2, =0xEFFFFFFF
	and	r1, r1, r2
	str	r1, [r0, #DMC_CONCONTROL]

	bl	fp_resync

@set_dmc_config
	ldr	r0, =DMC_CTRL_BASE
	ldr	r1, =0x00312700
	str	r1, [r0, #DMC_MEMCONTROL]

	ldr	r1, =0x00001323
	str	r1, [r0, #DMC_MEMCONFIG0]

	ldr	r1, =0x00001323
	str	r1, [r0, #DMC_MEMCONFIG1]

	ldr	r1, =0x004007C0
	str	r1, [r0, #DMC_MEMBASECONFIG0]

	ldr	r1, =0x008007C0
	str	r1, [r0, #DMC_MEMBASECONFIG1]

	ldr	r1, =CONFIG_IV_SIZE
	str	r1, [r0, #DMC_IVCONTROL]

	ldr	r1, =0xFF000000
	str	r1, [r0, #DMC_PRECHCONFIG]

	ldr	r1, =0xFFFF00FF
	str	r1, [r0, #DMC_PWRDNCONFIG]

	ldr	r1, =0x0000005D
	str	r1, [r0, #DMC_TIMINGAREF]

@ set_timing_parameter
#if defined(MCLK_CDREX_800)
	ldr	r1, =0x3449A95C
	str	r1, [r0, #DMC_TIMINGROW]

	ldr	r1, =0x3630560C
	str	r1, [r0, #DMC_TIMINGDATA]

	ldr	r1, =0x50380336
	str	r1, [r0, #DMC_TIMINGPOWER]
#elif defined(MCLK_CDREX_667)
	ldr	r1, =0x2C48858F
	str	r1, [r0, #DMC_TIMINGROW]

	ldr	r1, =0x3630460A
	str	r1, [r0, #DMC_TIMINGDATA]

	ldr	r1, =0x442F0335
	str	r1, [r0, #DMC_TIMINGPOWER]
#elif defined(MCLK_CDREX_533)
	ldr	r1, =0x2336644C
	str	r1, [r0, #DMC_TIMINGROW]

	ldr	r1, =0x34203408
	str	r1, [r0, #DMC_TIMINGDATA]

	ldr	r1, =0x38260235
	str	r1, [r0, #DMC_TIMINGPOWER]
#elif defined(MCLK_CDREX_400)
	ldr	r1, =0x1A255339
	str	r1, [r0, #DMC_TIMINGROW]

	ldr	r1, =0x23203306
	str	r1, [r0, #DMC_TIMINGDATA]

	ldr	r1, =0x281C0235
	str	r1, [r0, #DMC_TIMINGPOWER]
#endif

@low_freq_op_mode
	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, =0x7F7F7F7F
	str	r1, [r0, #DMC_PHY_CON4]

	bl	delay

	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, =0x7F7F7F7F
	str	r1, [r0, #DMC_PHY_CON4]

	bl	delay

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, =0x7F7F7F7F
	str	r1, [r0, #DMC_PHY_CON6]

	bl	delay

	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, =0x7F7F7F7F
	str	r1, [r0, #DMC_PHY_CON6]

	bl	delay

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, [r0, #DMC_PHY_CON10]
	ldr	r2, =0xFFFFFF00
	ldr	r3, =0x0000007F
	and	r1, r1, r2
	orr	r1, r1, r3
	str	r1, [r0, #DMC_PHY_CON10]

	bl	delay

	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, [r0, #DMC_PHY_CON10]
	ldr	r2, =0xFFFFFF00
	ldr	r3, =0x0000007F
	and	r1, r1, r2
	orr	r1, r1, r3
	str	r1, [r0, #DMC_PHY_CON10]

	bl	delay

@dll_off_forcing
	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, [r0, #DMC_PHY_CON12]
	ldr	r2, =0xFFFF80FF
	ldr	r3, =0x00007F00
	and	r1, r1, r2
	orr	r1, r1, r3
	str	r1, [r0, #DMC_PHY_CON12]

	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, [r0, #DMC_PHY_CON12]
	ldr	r2, =0xFFFF80FF
	ldr	r3, =0x00007F00
	and	r1, r1, r2
	orr	r1, r1, r3
	str	r1, [r0, #DMC_PHY_CON12]

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, [r0, #DMC_PHY_CON12]
	ldr	r2, =0xFFFFFFDF
	and	r1, r1, r2
	str	r1, [r0, #DMC_PHY_CON12]

	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, [r0, #DMC_PHY_CON12]
	ldr	r2, =0xFFFFFFDF
	and	r1, r1, r2
	str	r1, [r0, #DMC_PHY_CON12]

	bl	delay

	bl	fp_resync

	ldr	r0, =DMC_CTRL_BASE
	ldr	r1, =0x00000008
	str	r1, [r0, #DMC_PHYCONTROL0]

	ldr	r0, =DMC_CTRL_BASE
	ldr	r1, =0x00000000
	str	r1, [r0, #DMC_PHYCONTROL0]

@ Direct Command P0 CH0

	ldr	r0, =DMC_CTRL_BASE
	ldr	r1, =0x07000000
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

	ldr	r1, =0x00071C00
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

	ldr	r1, =0x00010BFC
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

#if defined(MCLK_CDREX_400)
@ MCLK_CDREX_400
	ldr	r1, =0x0000060C
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

	ldr	r1, =0x00000814
	str	r1, [r0, #DMC_DIRECTCMD]
#else
	ldr	r1, =0x0000070C
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

	ldr	r1, =0x00000818
	str	r1, [r0, #DMC_DIRECTCMD]
#endif

	bl	delay

	ldr	r1, =0x00000C04
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay


@ Direct Command P0 CH1

	ldr	r0, =DMC_CTRL_BASE
	ldr	r1, =0x07100000
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

	ldr	r1, =0x00171C00
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

	ldr	r1, =0x00110BFC
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

#if defined(MCLK_CDREX_400)
@ MCLK_CDREX_400
	ldr	r1, =0x0010060C
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

	ldr	r1, =0x00100814
	str	r1, [r0, #DMC_DIRECTCMD]
#else
	ldr	r1, =0x0010070C
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

	ldr	r1, =0x00100818
	str	r1, [r0, #DMC_DIRECTCMD]
#endif

	bl	delay

	ldr	r1, =0x00100C04
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

@ Direct Command P1 CH0

	ldr	r0, =DMC_CTRL_BASE
	ldr	r1, =0x17000000
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

	ldr	r1, =0x10071C00
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

	ldr	r1, =0x10010BFC
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

#if defined(MCLK_CDREX_400)
@ MCLK_CDREX_400
	ldr	r1, =0x1000060C
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

	ldr	r1, =0x10000814
	str	r1, [r0, #DMC_DIRECTCMD]
#else
	ldr	r1, =0x1000070C
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

	ldr	r1, =0x10000818
	str	r1, [r0, #DMC_DIRECTCMD]
#endif

	bl	delay

	ldr	r1, =0x10000C04
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

@ Direct Command P1 CH1

	ldr	r0, =DMC_CTRL_BASE
	ldr	r1, =0x17100000
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

	ldr	r1, =0x10171C00
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

	ldr	r1, =0x10110BFC
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

#if defined(MCLK_CDREX_400)
@ MCLK_CDREX_400
	ldr	r1, =0x1010060C
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

	ldr	r1, =0x10100814
	str	r1, [r0, #DMC_DIRECTCMD]
#else
	ldr	r1, =0x1010070C
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

	ldr	r1, =0x10100818
	str	r1, [r0, #DMC_DIRECTCMD]
#endif

	bl	delay

	ldr	r1, =0x10100C04
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

	ldr	r0, =ELFIN_CLOCK_BASE	@0x1001_0000

#if defined(MCLK_CDREX_667) || defined(MCLK_CDREX_533)
	ldr	r1, =0x00000000
	ldr	r2, =CLK_SRC_CDREX_OFFSET
	str	r1, [r0, r2]
	ldr	r3, =0x00011111
	bl	wait_mux_state
#endif

#if defined(MCLK_CDREX_667)
	ldr	r1, =0x01001141
#elif defined(MCLK_CDREX_533)
	ldr	r1, =0x01001131
#elif defined(MCLK_CDREX_400)
	ldr	r1, =0x10111121
#endif
	ldr	r2, =CLK_DIV_CDREX_OFFSET
	str	r1, [r0, r2]
	ldr	r3, =0x0
	bl	wait_div_state

@ Set MPLL
	ldr	r1, =0x00203800
	ldr	r2, =MPLL_CON1_OFFSET
	str	r1, [r0, r2]
	ldr	r1, =0x80640300
	ldr	r2, =MPLL_CON0_OFFSET
	str	r1, [r0, r2]
	bl	wait_pll_lock

#if defined(MCLK_CDREX_667)
@ Set BPLL
	ldr	r1, =0x00203800
	ldr	r2, =BPLL_CON1_OFFSET
	str	r1, [r0, r2]
	ldr	r1, =0x81850701
	ldr	r2, =BPLL_CON0_OFFSET
	str	r1, [r0, r2]
	bl	wait_pll_lock
#endif

#if defined(MCLK_CDREX_667) || defined(MCLK_CDREX_533)
	ldr	r1, =0x111
	ldr	r2, =CLK_SRC_CDREX_OFFSET
	str	r1, [r0, r2]
	ldr	r3, =0x00011222
	bl	wait_mux_state

#endif

	mov	r2, #0x30000
1:	subs	r2, r2, #1
	bne	1b

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, =0x08080808
	str	r1, [r0, #DMC_PHY_CON4]
	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, =0x08080808
	str	r1, [r0, #DMC_PHY_CON4]

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, =0x08080808
	str	r1, [r0, #DMC_PHY_CON6]
	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, =0x08080808
	str	r1, [r0, #DMC_PHY_CON6]

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, [r0, #DMC_PHY_CON10]
	ldr	r2, =0xFFFFFF00
	ldr	r3, =0x00000008
	and	r1, r1, r2
	orr	r1, r1, r3
	str	r1, [r0, #DMC_PHY_CON10]

	bl	delay

	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, [r0, #DMC_PHY_CON10]
	ldr	r2, =0xFFFFFF00
	ldr	r3, =0x00000008
	and	r1, r1, r2
	orr	r1, r1, r3
	str	r1, [r0, #DMC_PHY_CON10]

	bl	delay

@dll_on_start

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, [r0, #DMC_PHY_CON12]
	ldr	r2, =0xFFFFFF9F
	and	r1, r1, r2
	str	r1, [r0, #DMC_PHY_CON12]
	orr	r1, r1, #0x20
	str	r1, [r0, #DMC_PHY_CON12]

	bl	delay

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, [r0, #DMC_PHY_CON12]
	ldr	r2, =0xFFFFFFBF
	and	r1, r1, r2
	str	r1, [r0, #DMC_PHY_CON12]
	orr	r1, r1, #0x40
	str	r1, [r0, #DMC_PHY_CON12]

	bl	delay

	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, [r0, #DMC_PHY_CON12]
	ldr	r2, =0xFFFFFF9F
	and	r1, r1, r2
	str	r1, [r0, #DMC_PHY_CON12]
	orr	r1, r1, #0x20
	str	r1, [r0, #DMC_PHY_CON12]

	bl	delay

	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, [r0, #DMC_PHY_CON12]
	ldr	r2, =0xFFFFFFBF
	and	r1, r1, r2
	str	r1, [r0, #DMC_PHY_CON12]
	orr	r1, r1, #0x40
	str	r1, [r0, #DMC_PHY_CON12]

	bl	delay


@dfi_init_start
	ldr	r0, =DMC_CTRL_BASE
	ldr	r1, [r0, #DMC_CONCONTROL]
	ldr	r2, =0xFFFFFFDF
	ldr	r3, =0x10000000
	and	r1, r1, r2
	orr	r1, r1, r3
	str	r1, [r0, #DMC_CONCONTROL]

check_phystatus:
	ldr	r0, =DMC_CTRL_BASE
	ldr	r2, [r0, #DMC_PHYSTATUS]
	and	r2, r2, #0xC
	cmp	r2, #0xC
	bne	check_phystatus

	ldr	r2, =0xEFFFFFFF
	and	r1, r1, r2
	str	r1, [r0, #DMC_CONCONTROL]

	bl	fp_resync
	bl	fp_resync

#if defined(RD_LVL)

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, =0x10102D50
	str	r1, [r0, #DMC_PHY_CON12]
	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, =0x10102D50
	str	r1, [r0, #DMC_PHY_CON12]

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, =0x09210001
	str	r1, [r0, #DMC_PHY_CON1]
	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, =0x09210001
	str	r1, [r0, #DMC_PHY_CON1]

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, =0x00000208
	str	r1, [r0, #DMC_PHY_CON22]
	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, =0x00000208
	str	r1, [r0, #DMC_PHY_CON22]

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, =0x17023240
	str	r1, [r0, #DMC_PHY_CON0]
	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, =0x17023240
	str	r1, [r0, #DMC_PHY_CON0]

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, =0x02010004
	str	r1, [r0, #DMC_PHY_CON2]
	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, =0x02010004
	str	r1, [r0, #DMC_PHY_CON2]

	bl	delay

	ldr	r0, =DMC_CTRL_BASE
	ldr	r1, =0x00000002
	str	r1, [r0, #DMC_RDLVL_CONFIG]

	bl	delay

	ldr	r0, =DMC_CTRL_BASE
	ldr	r1, =0x00000000
	str	r1, [r0, #DMC_RDLVL_CONFIG]

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, =0x02012004
	str	r1, [r0, #DMC_PHY_CON2]
	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, =0x02012004
	str	r1, [r0, #DMC_PHY_CON2]

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, =0x10107F70
	str	r1, [r0, #DMC_PHY_CON12]
	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, =0x10107F70
	str	r1, [r0, #DMC_PHY_CON12]

	ldr	r0, =DMC_CTRL_BASE
	ldr	r1, =0x00000008
	str	r1, [r0, #DMC_PHYCONTROL0]

	ldr	r0, =DMC_CTRL_BASE
	ldr	r1, =0x00000000
	str	r1, [r0, #DMC_PHYCONTROL0]

	bl	delay

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, =0x17023200
	str	r1, [r0, #DMC_PHY_CON0]
	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, =0x17023200
	str	r1, [r0, #DMC_PHY_CON0]

#endif

@set_ctrl_at_gate

	ldr	r0, =PHY0_CTRL_BASE
	ldr	r1, [r0, #DMC_PHY_CON0]
	ldr	r2, =0xFFFFFFBF
	and	r1, r1, r2
	str	r1, [r0, #DMC_PHY_CON0]

	ldr	r0, =PHY1_CTRL_BASE
	ldr	r1, [r0, #DMC_PHY_CON0]
	ldr	r2, =0xFFFFFFBF
	and	r1, r1, r2
	str	r1, [r0, #DMC_PHY_CON0]

@ send_precharge_all

	ldr	r0, =DMC_CTRL_BASE
	ldr	r1, =0x01000000
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

	ldr	r0, =DMC_CTRL_BASE
	ldr	r1, =0x01100000
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

	ldr	r0, =DMC_CTRL_BASE
	ldr	r1, =0x11000000
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

	ldr	r0, =DMC_CTRL_BASE
	ldr	r1, =0x11100000
	str	r1, [r0, #DMC_DIRECTCMD]

	bl	delay

@ Start Auto-refresh

	ldr	r0, =DMC_CTRL_BASE
	ldr	r1, [r0, #DMC_CONCONTROL]
	orr	r1, r1, #0x20
	str	r1, [r0, #DMC_CONCONTROL]

	pop	{lr}
	mov	pc, lr

@fp_resync
fp_resync:
	ldr	r0, =DMC_CTRL_BASE
	ldr	r1, [r0, #DMC_PHYCONTROL0]
	orr	r1, r1, #0x8
	str	r1, [r0, #DMC_PHYCONTROL0]
	ldr	r2, =0XFFFFFFF7
	and	r1, r1, r2
	str	r1, [r0, #DMC_PHYCONTROL0]
	mov	pc, lr

delay:
	mov	r2, #0x10000
delayloop:
	subs	r2, r2, #1
	bne	delayloop
	mov	pc, lr

wait_pll_lock:
	ldr	r1, [r0, r2]
	tst	r1, #(1<<29)
	beq	wait_pll_lock
	mov	pc, lr

wait_mux_state:
	add	r2, r2, #0x200
check_mux_state:
	ldr	r1, [r0, r2]
	cmp	r1, r3
	bne	check_mux_state
	mov	pc, lr

wait_div_state:
	add	r2, r2, #0x100
check_div_state:
	ldr	r1, [r0, r2]
	cmp	r1, r3
	bne	check_div_state
	mov	pc, lr
