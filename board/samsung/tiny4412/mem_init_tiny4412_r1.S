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

#ifdef CONFIG_CLK_BUS_DMC_200_400
#define MCLK_400
#else
#define MCLK_330
#endif

#define DRAM_USES_CS1		0

	.globl mem_ctrl_asm_init_r1
mem_ctrl_asm_init_r1:

	/* Async bridge configuration at CPU_core:
	 * 1: half_sync
	 * 0: full_sync */
	ldr	r0, =0x10010350
	mov	r1, #1
	str	r1, [r0]


/*****************************************************************/
/*DREX0***********************************************************/
/*****************************************************************/

	ldr	r0, =APB_DMC_0_BASE

	ldr	r1, =0xe0000086
	str	r1, [r0, #DMC_PHYCONTROL1]

	ldr	r1, =0xE3854C03
	str	r1, [r0, #DMC_PHYZQCONTROL]

	mov	r2, #0x100000
1:	subs	r2, r2, #1
	bne	1b

	ldr	r1, =0xe000008e
	str	r1, [r0, #DMC_PHYCONTROL1]
	ldr	r1, =0xe0000086
	str	r1, [r0, #DMC_PHYCONTROL1]

	ldr	r1, =0x71101008
	str	r1, [r0, #DMC_PHYCONTROL0]
	ldr	r1, =0x7110100A
	str	r1, [r0, #DMC_PHYCONTROL0]

	ldr	r1, =0xe0000086
	str	r1, [r0, #DMC_PHYCONTROL1]
	ldr	r1, =0x7110100B
	str	r1, [r0, #DMC_PHYCONTROL0]

	ldr	r1, =0x00000000
	str	r1, [r0, #DMC_PHYCONTROL2]

	ldr	r1, =0x0FFF301A
	str	r1, [r0, #DMC_CONCONTROL]
	ldr	r1, =0x00302640
	str	r1, [r0, #DMC_MEMCONTROL]

	ldr	r1, =0x40c01333
	str	r1, [r0, #DMC_MEMCONFIG0]
	ldr	r1, =0x80e01323
	str	r1, [r0, #DMC_MEMCONFIG1]

#ifdef CONFIG_IV_SIZE
	ldr	r1, =(0x80000000 | CONFIG_IV_SIZE)
#else
	ldr	r1, =0x08
#endif
	str	r1, [r0, #DMC_IVCONTROL]

	ldr	r1, =0xff000000
	str	r1, [r0, #DMC_PRECHCONFIG]

	ldr	r1, =0x000000BB
	str	r1, [r0, #DMC_TIMINGAREF] @TimingAref

#ifdef MCLK_330
	ldr	r1, =0x6a45548d
	str	r1, [r0, #DMC_TIMINGROW]
	ldr	r1, =0x45430506
	str	r1, [r0, #DMC_TIMINGDATA]
	ldr	r1, =0x46000A3c
	str	r1, [r0, #DMC_TIMINGPOWER]
#endif
#ifdef MCLK_400
	ldr	r1, =0x7a46654f
	str	r1, [r0, #DMC_TIMINGROW] @TimingRow
	ldr	r1, =0x46400506
	str	r1, [r0, #DMC_TIMINGDATA] @TimingData
	ldr	r1, =0x52000a3c
	str	r1, [r0, #DMC_TIMINGPOWER] @TimingPower
#endif

	/* chip 0 */
	ldr	r1, =0x07000000
	str	r1, [r0, #DMC_DIRECTCMD]

	mov	r2, #0x100000
2:	subs	r2, r2, #1
	bne	2b

	ldr	r1, =0x00020000
	str	r1, [r0, #DMC_DIRECTCMD]
	ldr	r1, =0x00030000
	str	r1, [r0, #DMC_DIRECTCMD]
	ldr	r1, =0x00010002
	str	r1, [r0, #DMC_DIRECTCMD]
	ldr	r1, =0x00000328
	str	r1, [r0, #DMC_DIRECTCMD]

	mov	r2, #0x100000
3:	subs	r2, r2, #1
	bne	3b

	ldr	r1, =0x0a000000
	str	r1, [r0, #DMC_DIRECTCMD]

	mov	r2, #0x100000
4:	subs	r2, r2, #1
	bne	4b

#if DRAM_USES_CS1
	/* chip 1 */
	ldr	r1, =0x07100000
	str	r1, [r0, #DMC_DIRECTCMD]

	mov	r2, #0x100000
5:	subs	r2, r2, #1
	bne	5b

	ldr	r1, =0x00120000
	str	r1, [r0, #DMC_DIRECTCMD]
	ldr	r1, =0x00130000
	str	r1, [r0, #DMC_DIRECTCMD]
	ldr	r1, =0x00110002
	str	r1, [r0, #DMC_DIRECTCMD]
	ldr	r1, =0x00100328
	str	r1, [r0, #DMC_DIRECTCMD]

	mov	r2, #0x100000
6:	subs	r2, r2, #1
	bne	6b

	ldr	r1, =0x0a100000
	str	r1, [r0, #DMC_DIRECTCMD]

	mov	r2, #0x100000
7:	subs	r2, r2, #1
	bne	7b
#endif

	ldr	r1, =0xe000008e
	str	r1, [r0, #DMC_PHYCONTROL1]
	ldr	r1, =0xe0000086
	str	r1, [r0, #DMC_PHYCONTROL1]

	mov	r2, #0x100000
8:	subs	r2, r2, #1
	bne	8b


/*****************************************************************/
/*DREX1***********************************************************/
/*****************************************************************/

	ldr	r0, =APB_DMC_1_BASE

	ldr	r1, =0xe0000086
	str	r1, [r0, #DMC_PHYCONTROL1]

	ldr	r1, =0xE3854C03
	str	r1, [r0, #DMC_PHYZQCONTROL]

	mov	r2, #0x100000
1:	subs	r2, r2, #1
	bne	1b

	ldr	r1, =0xe000008e
	str	r1, [r0, #DMC_PHYCONTROL1]
	ldr	r1, =0xe0000086
	str	r1, [r0, #DMC_PHYCONTROL1]

	ldr	r1, =0x71101008
	str	r1, [r0, #DMC_PHYCONTROL0]
	ldr	r1, =0x7110100A
	str	r1, [r0, #DMC_PHYCONTROL0]

	ldr	r1, =0xe0000086
	str	r1, [r0, #DMC_PHYCONTROL1]
	ldr	r1, =0x7110100B
	str	r1, [r0, #DMC_PHYCONTROL0]

	ldr	r1, =0x00000000
	str	r1, [r0, #DMC_PHYCONTROL2]

	ldr	r1, =0x0FFF301A
	str	r1, [r0, #DMC_CONCONTROL]
	ldr	r1, =0x00302640
	str	r1, [r0, #DMC_MEMCONTROL]

	ldr	r1, =0x40c01333			@Interleaved?
	str	r1, [r0, #DMC_MEMCONFIG0]
	ldr	r1, =0x80e01323
	str	r1, [r0, #DMC_MEMCONFIG1]

#ifdef CONFIG_IV_SIZE
	ldr	r1, =(0x80000000 | CONFIG_IV_SIZE)
#else
	ldr	r1, =0x08
#endif
	str	r1, [r0, #DMC_IVCONTROL]

	ldr	r1, =0xff000000
	str	r1, [r0, #DMC_PRECHCONFIG]

	ldr	r1, =0x000000BB
	str	r1, [r0, #DMC_TIMINGAREF] @TimingAref

#ifdef MCLK_330
	ldr	r1, =0x6a45548d
	str	r1, [r0, #DMC_TIMINGROW]
	ldr	r1, =0x45430506
	str	r1, [r0, #DMC_TIMINGDATA]
	ldr	r1, =0x46000A3c
	str	r1, [r0, #DMC_TIMINGPOWER]
#endif
#ifdef MCLK_400
	ldr	r1, =0x7a46654f
	str	r1, [r0, #DMC_TIMINGROW] @TimingRow
	ldr	r1, =0x46400506
	str	r1, [r0, #DMC_TIMINGDATA] @TimingData
	ldr	r1, =0x52000a3c
	str	r1, [r0, #DMC_TIMINGPOWER] @TimingPower
#endif

	/* chip 0 */
	ldr	r1, =0x07000000
	str	r1, [r0, #DMC_DIRECTCMD]

	mov	r2, #0x100000
2:	subs	r2, r2, #1
	bne	2b

	ldr	r1, =0x00020000
	str	r1, [r0, #DMC_DIRECTCMD]
	ldr	r1, =0x00030000
	str	r1, [r0, #DMC_DIRECTCMD]
	ldr	r1, =0x00010002
	str	r1, [r0, #DMC_DIRECTCMD]
	ldr	r1, =0x00000328
	str	r1, [r0, #DMC_DIRECTCMD]

	mov	r2, #0x100000
3:	subs	r2, r2, #1
	bne	3b

	ldr	r1, =0x0a000000
	str	r1, [r0, #DMC_DIRECTCMD]

	mov	r2, #0x100000
4:	subs	r2, r2, #1
	bne	4b

#if DRAM_USES_CS1
	/* chip 1 */
	ldr	r1, =0x07100000
	str	r1, [r0, #DMC_DIRECTCMD]

	mov	r2, #0x100000
5:	subs	r2, r2, #1
	bne	5b

	ldr	r1, =0x00120000
	str	r1, [r0, #DMC_DIRECTCMD]
	ldr	r1, =0x00130000
	str	r1, [r0, #DMC_DIRECTCMD]
	ldr	r1, =0x00110002
	str	r1, [r0, #DMC_DIRECTCMD]
	ldr	r1, =0x00100328
	str	r1, [r0, #DMC_DIRECTCMD]

	mov	r2, #0x100000
6:	subs	r2, r2, #1
	bne	6b

	ldr	r1, =0x0a100000
	str	r1, [r0, #DMC_DIRECTCMD]

	mov	r2, #0x100000
7:	subs	r2, r2, #1
	bne	7b
#endif

	ldr	r1, =0xe000008e
	str	r1, [r0, #DMC_PHYCONTROL1]
	ldr	r1, =0xe0000086
	str	r1, [r0, #DMC_PHYCONTROL1]

	mov	r2, #0x100000
8:	subs	r2, r2, #1
	bne	8b


/*****************************************************************/
/*Finalize********************************************************/
/*****************************************************************/

	ldr	r0, =APB_DMC_0_BASE
	ldr	r1, =0x0FFF303A
	str	r1, [r0, #DMC_CONCONTROL]

	ldr	r0, =APB_DMC_1_BASE
	ldr	r1, =0x0FFF303A
	str	r1, [r0, #DMC_CONCONTROL]

	mov	pc, lr

