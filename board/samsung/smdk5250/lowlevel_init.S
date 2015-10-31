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
#include <version.h>
#include <asm/arch/cpu.h>
#include <asm/arch/s5p_nand.h>

#include "smdk5250_val.h"

_TEXT_BASE:
	.word	CONFIG_SYS_TEXT_BASE

	.globl cache_init
cache_init:
	mov pc, lr

	.globl lowlevel_init
lowlevel_init:

	/* use iROM stack in bl2 */
	ldr	sp, =0x02050000
	push {lr}

	/* TZPC1_DECPROT1Set */
	ldr    r0, =0x10110810
	mov    r1, #0xF     	/* [DBGEN, NIDEN, SPIDEN, SPNIDEN] = [1,1,1,1] */
	str    r1, [r0]
	dsb
	isb
	sev

	/* PS-Hold high */
	ldr	r0, =0x1004330c
	ldr	r1, [r0]
	orr	r1, r1, #0x100
	str	r1, [r0]

	/* check reset status  */
	ldr     r0, =(INF_REG_BASE + INF_REG1_OFFSET)
	ldr     r1, [r0]

	/* Sleep wakeup reset */
	ldr	r2, =S5P_CHECK_SLEEP
	cmp	r1, r2
	beq	wakeup_reset

        /* During sleep/wakeup or AFTR mode, pmic_init function is not available
	 * and it causes delays. So except for sleep/wakeup and AFTR mode,
	 * the below function is needed
	 */
#ifdef CONFIG_PM
#ifdef CONFIG_S5M8767
	bl	pmic8767_init
#else
	bl	pmic_init
#endif
#endif
	bl	uart_asm_init

	bl	read_om

	/* when we already run in ram, we don't need to relocate U-Boot.
	 * and actually, memory controller must be configured before U-Boot
	 * is running in ram.
	 */
	ldr	r0, =0xff000fff
	bic	r1, pc, r0		/* r0 <- current base addr of code */
	ldr	r2, _TEXT_BASE	/* r1 <- original base addr in ram */
	bic	r2, r2, r0		/* r0 <- current base addr of code */
	cmp	r1, r2			/* compare r0, r1 */
	beq	after_copy		/* r0 == r1 then skip sdram init and u-boot.bin loading */

	/* init system clock */
	bl	system_clock_init

	/* Memory initialize */
	bl	mem_ctrl_asm_init

	bl	tzpc_init

	b	load_uboot

after_copy:

#ifdef CONFIG_ENABLE_MMU
	bl	enable_mmu
#endif
	/* store second boot information in u-boot C level variable */
	ldr	r0, =CONFIG_PHY_UBOOT_BASE
	sub	r0, r0, #8
	ldr	r1, [r0]
	ldr	r0, _second_boot_info
	str	r1, [r0]

	/* Print 'K' */
	ldr	r0, =UART_CONSOLE_BASE
	ldr	r1, =0x4b
	str	r1, [r0, #UTXH_OFFSET]

	ldr	r0, _board_init_f
	mov	pc, r0

_board_init_f:
	.word	board_init_f

_second_boot_info:
	.word	second_boot_info


wakeup_reset:

	bl	read_om

	/* If eMMC booting */
	ldr	r0, =INF_REG_BASE
	ldr	r1, [r0, #INF_REG3_OFFSET]
	cmp	r1, #BOOT_EMMC_4_4
	bleq	emmc_4_4_endbootOp_eMMC

	/* check reset status  */
	ldr     r0, =(INF_REG_BASE + INF_REG1_OFFSET)
	ldr     r1, [r0]

	/* If NOT Sleep wakeup reset */
	ldr	r2, =S5P_CHECK_SLEEP
	cmp	r1, r2
	bne	exit_wakeup

	/* MSHC CLKENA Disable */
	ldr	r0, =0x12240010
	ldr	r1, =0x0
	str   	r1, [r0]

	ldr	r0, =0x1224002C
	ldr	r1, =(1<<31|1<<29|1<<21|1<<13);
	str   	r1, [r0]

	/* init system clock */
	bl	system_clock_init

	/* Memory initialize */
	bl	mem_ctrl_asm_init

	/* If eMMC booting */
	/* mmc ch4 devider value change */
	ldr	r0, =INF_REG_BASE
	ldr	r1, [r0, #INF_REG3_OFFSET]
	cmp	r1, #BOOT_EMMC_4_4
	bleq	mmc_ch4_devider_change

	bl	tzpc_init

exit_wakeup:

	/*Load return address and jump to kernel*/
	ldr	r0, =(INF_REG_BASE + INF_REG0_OFFSET)
	ldr	r1, [r0]	/* r1 = physical address of s5pc110_cpu_resume function*/

	mov	pc, r1		/*Jump to kernel */
	nop
	nop


read_om:
	/* Read booting information */
	ldr	r0, =EXYNOS5250_POWER_BASE
	ldr	r1, [r0,#OMR_OFFSET]
	bic	r2, r1, #0xffffffc1

	/* SD/MMC BOOT */
	cmp     r2, #0x4
	moveq   r3, #BOOT_MMCSD

	/* eMMC BOOT */
	cmp	r2, #0x6
	moveq	r3, #BOOT_EMMC

	/* eMMC 4.4 BOOT */
	cmp	r2, #0x8
	moveq	r3, #BOOT_EMMC_4_4
	cmp	r2, #0x28
	moveq	r3, #BOOT_EMMC_4_4

	ldr	r0, =INF_REG_BASE
	str	r3, [r0, #INF_REG3_OFFSET]

	mov	pc, lr

/*
 * uart_asm_init: Initialize UART in asm mode, 115200bps fixed.
 * void uart_asm_init(void)
 */
	.globl	uart_asm_init
uart_asm_init:

	/* set GPIO to enable UART */
	@ GPIO setting for UART for UART0/1/2/3
	ldr	r0, =0x11400000
	ldr	r1, =0x22222222
	str   	r1, [r0]
	ldr	r0, =0x11400020
	ldr	r1, =0x222222
	str   	r1, [r0]

	ldr	r0, =ELFIN_CLOCK_BASE
	ldr	r1, =CLK_SRC_PERIC0_VAL
	ldr	r2, =CLK_SRC_PERIC0_OFFSET
	str	r1, [r0, r2]
	ldr	r1, =CLK_DIV_PERIC0_VAL
	ldr	r2, =CLK_DIV_PERIC0_OFFSET
	str	r1, [r0, r2]

	ldr	r0, =UART_CONSOLE_BASE
	ldr	r1, =0x111
	str	r1, [r0, #UFCON_OFFSET]

	mov	r1, #0x3
	str	r1, [r0, #ULCON_OFFSET]

	ldr	r1, =0x3c5
	str	r1, [r0, #UCON_OFFSET]

	ldr	r1, =UART_UBRDIV_VAL
	str	r1, [r0, #UBRDIV_OFFSET]

	ldr	r1, =UART_UDIVSLOT_VAL
	str	r1, [r0, #UDIVSLOT_OFFSET]

	ldr	r1, =0x4f
	str	r1, [r0, #UTXH_OFFSET]		@'O'

	mov	pc, lr

load_uboot:
	ldr	r0, =INF_REG_BASE
	ldr	r1, [r0, #INF_REG3_OFFSET]
	cmp 	r1, #BOOT_MMCSD
	beq 	mmcsd_boot
	cmp	r1, #BOOT_EMMC
	beq	emmc_boot
	cmp	r1, #BOOT_EMMC_4_4
	beq	emmc_boot_4_4
	cmp     r1, #BOOT_SEC_DEV
	beq     mmcsd_boot

mmcsd_boot:
	ldr	r0, =ELFIN_CLOCK_BASE
	ldr	r2, =CLK_DIV_FSYS2_OFFSET
	ldr	r1, [r0, r2]
	bic	r1, r1, #(0xFF << 8)
	bic	r1, r1, #(0xF)
	orr 	r1, r1, #(0x9<< 8)
	orr 	r1, r1, #0x3
	str	r1, [r0, r2]

	/* check second boot */
	bl	check_second_boot

	bl      movi_uboot_copy

	b       after_copy

emmc_boot:
	ldr	r0, =ELFIN_CLOCK_BASE
	ldr	r2, =CLK_DIV_FSYS1_OFFSET
	ldr	r1, [r0, r2]
	bic	r1, r1, #(0xFF << 8)
	bic	r1, r1, #(0xF)
	orr 	r1, r1, #(0x4<< 8)
	orr 	r1, r1, #0x7
	str 	r1, [r0, r2]

	bl	emmc_uboot_copy
	b	after_copy

emmc_boot_4_4:

	/* check second boot */
	bl	check_second_boot
	/* mmc ch4 devider value change */
	bl	mmc_ch4_devider_change
	/* u-boot image copy from boot partition to DRAM. */
	bl	emmc_4_4_uboot_copy
	/* Exit Boot mood */
	bl	emmc_4_4_endbootOp_eMMC

	b	after_copy

check_om_setting:
	b	check_om_setting

check_second_boot:
	ldr	r0, =0x02020018
	ldr	r1, [r0]
	ldr	r2, =0xFEED0002
	cmp	r1, r2
	beq	check_second_boot_device
	mov	pc, lr

check_second_boot_device:
	/* read second boot device to IROM_DATA_REG0 */
	ldr	r0, =0x10040980
	ldr	r1, [r0]
	ldr	r3, =0x101
        and     r2, r1, r3
	cmp	r2, r3
	beq	mmcsd_second_boot

	ldr	r3, =0x100
	and	r2, r1, r3
	cmp	r2, r3
	beq	usb_device_boot

	b	check_om_setting

mmcsd_second_boot:
	/* store second boot information in DRAM */
	ldr	r0, =CONFIG_PHY_UBOOT_BASE
	sub	r0, r0, #8
	mov	r3, #1
	str	r3, [r0]

	ldr	r0, =ELFIN_CLOCK_BASE
	ldr	r2, =CLK_DIV_FSYS2_OFFSET
	ldr	r1, [r0, r2]
	bic	r1, r1, #(0xFF << 8)
	bic	r1, r1, #(0xF)
	orr 	r1, r1, #(0x9<< 8)
	orr 	r1, r1, #0x3
	str	r1, [r0, r2]

	bl      movi_uboot_copy

	b       after_copy

usb_device_boot:

	mrc	p15, 0, r0, c1, c0, 0
	bic	r0, r0, #0x00000800
	mcr	p15, 0, r0, c1, c0, 0

	bl	usb_device_copy

	mrc	p15, 0, r0, c1, c0, 0
	orr	r0, r0, #0x00000800
	mcr	p15, 0, r0, c1, c0, 0

	/* store boot device in INF_REG3 */
	ldr	r3, =BOOT_USB
	ldr	r0, =INF_REG_BASE
	str	r3, [r0, #INF_REG3_OFFSET]

	b	after_copy

/*
 * Setting TZPC[TrustZone Protection Controller]
 */

tzpc_init:

	ldr	r0, =ELFIN_TZPC0_BASE
	mov	r1, #0x0
	str	r1, [r0]
	mov	r1, #0xff
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	ldr	r0, =ELFIN_TZPC1_BASE
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	ldr	r0, =ELFIN_TZPC2_BASE
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	ldr	r0, =ELFIN_TZPC3_BASE
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	ldr	r0, =ELFIN_TZPC4_BASE
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	ldr	r0, =ELFIN_TZPC5_BASE
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	ldr	r0, =ELFIN_TZPC6_BASE
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	ldr	r0, =ELFIN_TZPC7_BASE
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	ldr	r0, =ELFIN_TZPC8_BASE
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT2SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT3SET_OFFSET]

	ldr	r0, =ELFIN_TZPC9_BASE
	str	r1, [r0, #TZPC_DECPROT0SET_OFFSET]
	str	r1, [r0, #TZPC_DECPROT1SET_OFFSET]

	mov	pc, lr


/*
 * MPLL is Changed from 400MHz to 800MHz.
 * So, MMC CH4 devider need to change.
 */

mmc_ch4_devider_change:
	ldr	r0, =ELFIN_CLOCK_BASE
	ldr	r2, =CLK_DIV_FSYS3_OFFSET
	ldr	r1, [r0, r2]
	bic	r1, r1, #(0xFF << 8)
	bic	r1, r1, #(0xF)
	orr 	r1, r1, #(0x1<< 8)
	orr 	r1, r1, #0x9
	str 	r1, [r0, r2]
	mov	pc, lr

#ifdef CONFIG_ENABLE_MMU
enable_mmu:
	/* enable domain access */
	ldr	r5, =0x0000ffff
	mcr	p15, 0, r5, c3, c0, 0		@load domain access register

	/* Set the TTB register */
	ldr	r0, =mmu_table
	ldr	r1, =CONFIG_PHY_UBOOT_BASE
	ldr	r2, =0xfff00000
	bic	r0, r0, r2
	orr	r1, r0, r1
	mcr	p15, 0, r1, c2, c0, 0

	/* Enable the MMU */
mmu_on:
	mrc	p15, 0, r0, c1, c0, 0
	orr	r0, r0, #1
	mcr	p15, 0, r0, c1, c0, 0
	nop
	nop
	nop
	nop
	mov	pc, lr

/*
 * we assume that cache operation is done before. (eg. cleanup_before_linux())
 * actually, we don't need to do anything about cache if not use d-cache in U-Boot
 * So, in this function we clean only MMU. by scsuh
 *
 * void	theLastJump(void *kernel, int arch_num, uint boot_params);
 */
	.globl	theLastJump
theLastJump:
	mov	r9, r0
	ldr	r3, =0xfff00000
	ldr	r4, =CONFIG_PHY_UBOOT_BASE
	adr	r5, phy_last_jump
	bic	r5, r5, r3
	orr	r5, r5, r4
	mov	pc, r5
phy_last_jump:
	/*
	 * disable MMU stuff
	 */
	mrc	p15, 0, r0, c1, c0, 0
	bic	r0, r0, #0x00002300	/* clear bits 13, 9:8 (--V- --RS) */
	bic	r0, r0, #0x00000087	/* clear bits 7, 2:0 (B--- -CAM) */
	orr	r0, r0, #0x00000002	/* set bit 2 (A) Align */
	orr	r0, r0, #0x00001000	/* set bit 12 (I) I-Cache */
	mcr	p15, 0, r0, c1, c0, 0

	mcr	p15, 0, r0, c8, c7, 0	/* flush v4 TLB */

	mov	r0, #0
	mov	pc, r9

/*
 * MMU Table for SMDKC210
 * 0x0000_0000 -- 0x1FFF_FFFF => A:0x0000_0000 -- 0x1FFF_FFFF
 * 0x2000_0000 -- 0x3FFF_FFFF => Not Allowed
 * 0x4000_0000 -- 0x5FFF_FFFF => A:0x4000_0000 -- 0x5FFF_FFFF
 * 0x6000_0000 -- 0xBFFF_FFFF => Not Allowed
 * 0xC000_0000 -- 0xDFFF_FFFF => A:0x4000_0000 -- 0X5FFF_FFFF
 * 0xE000_0000 -- 0xFFFF_FFFF => Not Allowed
 */

	/* form a first-level section entry */
.macro FL_SECTION_ENTRY base,ap,d,c,b
	.word (\base << 20) | (\ap << 10) | \
	      (\d << 5) | (1<<4) | (\c << 3) | (\b << 2) | (1<<1)
.endm

.section .mmudata, "a"
	.align 14
	// the following alignment creates the mmu table at address 0x4000.
	.globl mmu_table
mmu_table:
	.set __base,0
	// Access for iRAM
	.rept 0x200
	FL_SECTION_ENTRY __base,3,0,0,0
	.set __base,__base+1
	.endr

	// Not Allowed
	.rept 0x400 - 0x200
	.word 0x00000000
	.endr

	.set __base,0x400
	// 512MB for SDRAM with cacheable
	.rept 0xC00 - 0x400
	FL_SECTION_ENTRY __base,3,0,1,1
	.set __base,__base+1
	.endr

	.set __base,0x400
	// 512MB for SDRAM with cacheable
	.rept 0xE00 - 0xC00
	FL_SECTION_ENTRY __base,3,0,1,1
	.set __base,__base+1
	.endr

	// access is not allowed.
	.rept 0x1000 - 0xE00
	.word 0x00000000
	.endr

#endif
