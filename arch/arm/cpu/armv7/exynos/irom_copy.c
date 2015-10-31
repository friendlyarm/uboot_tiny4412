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

#include <common.h>
#include <asm/arch/movi_partition.h>

#ifdef CONFIG_SECURE_BOOT
#include "UBOOT_SB20_S5PC210S.h"
#endif

extern ulong movi_read(int dev, ulong start, lbaint_t blkcnt, void *dst);
extern ulong movi_write(int dev, ulong start, lbaint_t blkcnt, void *src);

typedef u32 (*copy_sd_mmc_to_mem) \
	(u32 start_block, u32 block_count, u32* dest_addr);

#define ISRAM_ADDRESS	0x02020000
#define SECURE_CONTEXT_BASE 0x02023000
#define EXTERNAL_FUNC_ADDRESS	(ISRAM_ADDRESS + 0x0030)
#define EXT_eMMC43_BL2_ByCPU_ADDRESS	(EXTERNAL_FUNC_ADDRESS + 0x4)
#define MSH_ReadFromFIFO_eMMC_ADDRESS	(EXTERNAL_FUNC_ADDRESS + 0x14)
#define MSH_EndBootOp_eMMC_ADDRESS	(EXTERNAL_FUNC_ADDRESS + 0x18)
#define LoadImageFromUsb_ADDRESS	(EXTERNAL_FUNC_ADDRESS + 0x40)

#define SDMMC_ReadBlocks_eMMC_ByCPU(uNumOfBlks, uDstAddr)	\
	(((void(*)(u32, u32*))(*((u32 *)EXT_eMMC43_BL2_ByCPU_ADDRESS)))(uNumOfBlks, uDstAddr))

#define SDMMC_ReadBlocks(uStartBlk, uNumOfBlks, uDstAddr)	\
	(((void(*)(u32, u32, u32*))(*((u32 *)EXTERNAL_FUNC_ADDRESS)))(uStartBlk, uNumOfBlks, uDstAddr))

#define LoadImageFromUsb()	\
	(((void(*)())(*((u32 *)LoadImageFromUsb_ADDRESS)))())

#if defined (CONFIG_EXYNOS4212) || defined (CONFIG_ARCH_EXYNOS5)
typedef u32 (*MSH_ReadFromFIFO_eMMC)(u32 uNumOfBlks, u32 *uDstAddr);
#else
typedef u32 (*MSH_ReadFromFIFO_eMMC)(u32 RxWaterMark,
				u32 uNumOfBlks, u32 *uDstAddr);
#endif
typedef u32 (*MSH_EndBootOp_eMMC)(void);

#ifdef CONFIG_CORTEXA5_ENABLE
void * uboot_memcpy(void * dest,const void *src,size_t count)
{
	char *tmp = (char *) dest, *s = (char *) src;

	while (count--)
		*tmp++ = *s++;

	return dest;
}
#endif

#ifdef CONFIG_RAM_TEST
extern void uart_asm_putc(int c);
extern void uart_asm_putx(int x);

#define MT_START	0x40000000
#define MT_LEN		0x10000000

void uboot_mem_test(void)
{
	unsigned int *p;
	int i;

	/* show dram config */
	p = (unsigned int *) 0x10600000;
	for (i = 0; i < 0x100/4; i++, p++) {
		if (!(i & 0xf)) {
			uart_asm_putc('\r');
			uart_asm_putc('\n');
		}
		uart_asm_putx(*p);
		uart_asm_putc('.');
	}
	p = (unsigned int *) 0x10610000;
	for (i = 0; i < 0x100/4; i++, p++) {
		if (!(i & 0xf)) {
			uart_asm_putc('\r');
			uart_asm_putc('\n');
		}
		uart_asm_putx(*p);
		uart_asm_putc('.');
	}

	uart_asm_putc('\r');
	uart_asm_putc('\n');

	uart_asm_putc('L');
	uart_asm_putc('e');
	uart_asm_putc('n');
	uart_asm_putc(':');
	uart_asm_putc(' ');
	uart_asm_putx(MT_LEN);

	uart_asm_putc('\r');
	uart_asm_putc('\n');
	uart_asm_putc('W');

	/* writing */
	p = (unsigned int *) MT_START;
	for (i = 0; i < MT_LEN/4; i++, p++) {
		*p = i+0x5a000000;
		if (!(i & 0xfffff)) {
			uart_asm_putc('.');
		}
	}

	uart_asm_putc('\r');
	uart_asm_putc('\n');
	uart_asm_putc('R');

	/* read and verify */
	p = (unsigned int *) MT_START;
	for (i = 0; i < MT_LEN/4; i++, p++) {
		if (*p != (i+0x5a000000)) {
			uart_asm_putc('X');
			uart_asm_putx(i);
			uart_asm_putx(p);
			if (i > 4) {
				uart_asm_putx(*(p-4));
				uart_asm_putx(*(p-3));
				uart_asm_putx(*(p-2));
				uart_asm_putx(*(p-1));
			}
			uart_asm_putx(*p);
			uart_asm_putx(*(p+1));
			uart_asm_putx(*(p+2));
			uart_asm_putx(*(p+3));
			uart_asm_putx(*(p+4));
			break;
		}

		if (!(i & 0xfffff)) {
			uart_asm_putc('.');
		}
	}

	uart_asm_putc('\r');
	uart_asm_putc('\n');
	uart_asm_putc('>');

#if 0
	/* dump memory */
	p = (unsigned int *) MT_START;
	for (i = 0; i < 0x200; i++, p++) {
		if (!(i & 0xf)) {
			uart_asm_putc('\r');
			uart_asm_putc('\n');
		}
		uart_asm_putx(*p);
		uart_asm_putc('.');
	}

	uart_asm_putc('\r');
	uart_asm_putc('\n');
#endif
}
#endif

void movi_uboot_copy(void)
{
#ifdef CONFIG_RAM_TEST
	uboot_mem_test();
#endif

#ifdef CONFIG_CORTEXA5_ENABLE
	SDMMC_ReadBlocks(MOVI_UBOOT_POS, MOVI_UBOOT_BLKCNT, 0x40000000);
#endif
	SDMMC_ReadBlocks(MOVI_UBOOT_POS, MOVI_UBOOT_BLKCNT, CONFIG_PHY_UBOOT_BASE);

#ifdef CONFIG_SECURE_BOOT
	if (Check_Signature((SB20_CONTEXT *)SECURE_CONTEXT_BASE,
				(unsigned char*)CONFIG_PHY_UBOOT_BASE, PART_SIZE_UBOOT-256,
				(unsigned char*)(CONFIG_PHY_UBOOT_BASE+PART_SIZE_UBOOT-256), 256) != 0)
	{
		while(1);
	}
#endif
}

void usb_device_copy(void)
{
	LoadImageFromUsb();
}

void emmc_uboot_copy(void)
{
	SDMMC_ReadBlocks_eMMC_ByCPU(MOVI_UBOOT_BLKCNT, CONFIG_PHY_UBOOT_BASE);
}

void emmc_4_4_uboot_copy(void)
{
	MSH_ReadFromFIFO_eMMC bl2_copy =
		(MSH_ReadFromFIFO_eMMC) (*(u32 *) (MSH_ReadFromFIFO_eMMC_ADDRESS));

#if defined (CONFIG_EXYNOS4212) || defined (CONFIG_ARCH_EXYNOS5)
	bl2_copy(MOVI_UBOOT_BLKCNT, CONFIG_PHY_UBOOT_BASE);

#ifdef CONFIG_CORTEXA5_ENABLE
	uboot_memcpy(0x40000000, CONFIG_PHY_UBOOT_BASE, PART_SIZE_UBOOT);
#endif

#else
	bl2_copy(0x10, MOVI_UBOOT_BLKCNT, CONFIG_PHY_UBOOT_BASE);
#endif

#ifdef CONFIG_SECURE_BOOT
	if (Check_Signature((SB20_CONTEXT *)SECURE_CONTEXT_BASE,
				(unsigned char*)CONFIG_PHY_UBOOT_BASE, PART_SIZE_UBOOT-256, 
				(unsigned char*)(CONFIG_PHY_UBOOT_BASE+PART_SIZE_UBOOT-256), 256) != 0)
	{
		while(1);
	}
#endif

}

void emmc_4_4_endbootOp_eMMC(void)
{
	MSH_EndBootOp_eMMC bl2_copy =
		(MSH_EndBootOp_eMMC) (*(u32 *) (MSH_EndBootOp_eMMC_ADDRESS));

	bl2_copy();
}

void movi_write_env(ulong addr)
{
	movi_write(0, raw_area_control.image[4].start_blk,
			raw_area_control.image[4].used_blk, addr);
}

void movi_read_env(ulong addr)
{
	movi_read(0, raw_area_control.image[4].start_blk,
			raw_area_control.image[4].used_blk, addr);
}

void movi_write_bl1(ulong addr, int dev_num)
{
	int i;
	ulong checksum;
	ulong src;
	ulong tmp;

	src = addr;

	for (i = 0, checksum = 0;i < (14 * 1024) - 4;i++) {
		checksum += *(u8*)addr++;
	}

	tmp = *(ulong*)addr;
	*(ulong*)addr = checksum;

	movi_write(dev_num, raw_area_control.image[1].start_blk,
			raw_area_control.image[1].used_blk, src);

	*(ulong*)addr = tmp;
}

