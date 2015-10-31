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
#include <asm/arch/cpu.h>
#include <asm/arch/gpio.h>

unsigned int OmPin;

DECLARE_GLOBAL_DATA_PTR;
extern int nr_dram_banks;
unsigned int second_boot_info = 0xffffffff;

/* ------------------------------------------------------------------------- */
#ifdef CONFIG_SMC911X
#define SMC9115_Tacs	(0x0)	// 0clk		address set-up
#define SMC9115_Tcos	(0x4)	// 4clk		chip selection set-up
#define SMC9115_Tacc	(0xe)	// 14clk	access cycle
#define SMC9115_Tcoh	(0x1)	// 1clk		chip selection hold
#define SMC9115_Tah	(0x4)	// 4clk		address holding time
#define SMC9115_Tacp	(0x6)	// 6clk		page mode access cycle
#define SMC9115_PMC	(0x0)	// normal(1data)page mode configuration

#define SROM_DATA16_WIDTH(x)	(1<<((x*4)+0))
#define SROM_WAIT_ENABLE(x)	(1<<((x*4)+1))
#define SROM_BYTE_ENABLE(x)	(1<<((x*4)+2))

/*
 * Miscellaneous platform dependent initialisations
 */
static void smc9115_pre_init(void)
{
	unsigned int cs1;
	/* gpio configuration */
	writel(0x00220020, 0x11000000 + 0x120);
	writel(0x00002222, 0x11000000 + 0x140);

	/* 16 Bit bus width */
	writel(0x22222222, 0x11000000 + 0x180);
	writel(0x0000FFFF, 0x11000000 + 0x188);
	writel(0x22222222, 0x11000000 + 0x1C0);
	writel(0x0000FFFF, 0x11000000 + 0x1C8);
	writel(0x22222222, 0x11000000 + 0x1E0);
	writel(0x0000FFFF, 0x11000000 + 0x1E8);

	/* SROM BANK1 */
	cs1 = SROM_BW_REG & ~(0xF<<4);
	cs1 |= ((1 << 0) |
			(0 << 2) |
			(1 << 3)) << 4;

	SROM_BW_REG = cs1;

	/* set timing for nCS1 suitable for ethernet chip */
	SROM_BC1_REG = ( (0x1 << 0) |
			(0x9 << 4) |
			(0xc << 8) |
			(0x1 << 12) |
			(0x6 << 16) |
			(0x1 << 24) |
			(0x1 << 28) );
}
#endif

int board_get_hwrev(void)
{
	return (__REG(0x110002C4) >> 5);
}

int board_init(void)
{
	char bl1_version[9] = {0};

#ifdef CONFIG_HAS_PMIC
	u8 read_id;
	u8 read_vol_arm;
	u8 read_vol_int;
	u8 read_vol_g3d;
	u8 read_vol_mif;
	u8 buck1_ctrl;
	u8 buck2_ctrl;
	u8 buck3_ctrl;
	u8 buck4_ctrl;
	u8 ldo14_ctrl;

	IIC0_ERead(0xcc, 0, &read_id);
	if (read_id == 0x77) {
		IIC0_ERead(0xcc, 0x19, &read_vol_arm);
		IIC0_ERead(0xcc, 0x22, &read_vol_int);
		IIC0_ERead(0xcc, 0x2B, &read_vol_g3d);
		//IIC0_ERead(0xcc, 0x2D, &read_vol_mif);
		IIC0_ERead(0xcc, 0x18, &buck1_ctrl);
		IIC0_ERead(0xcc, 0x21, &buck2_ctrl);
		IIC0_ERead(0xcc, 0x2A, &buck3_ctrl);
		//IIC0_ERead(0xcc, 0x2C, &buck4_ctrl);
		IIC0_ERead(0xcc, 0x48, &ldo14_ctrl);

		printf("vol_arm: %X\n", read_vol_arm);
		printf("vol_int: %X\n", read_vol_int);
		printf("vol_g3d: %X\n", read_vol_g3d);
		printf("buck1_ctrl: %X\n", buck1_ctrl);
		printf("buck2_ctrl: %X\n", buck2_ctrl);
		printf("buck3_ctrl: %X\n", buck3_ctrl);
		printf("ldo14_ctrl: %X\n", ldo14_ctrl);
	} else {
		IIC0_ERead(0x12, 0x14, &read_vol_arm);
		IIC0_ERead(0x12, 0x1E, &read_vol_int);
		IIC0_ERead(0x12, 0x28, &read_vol_g3d);
		IIC0_ERead(0x12, 0x11, &read_vol_mif);
		IIC0_ERead(0x12, 0x10, &buck1_ctrl);
		IIC0_ERead(0x12, 0x12, &buck2_ctrl);
		IIC0_ERead(0x12, 0x1C, &buck3_ctrl);
		IIC0_ERead(0x12, 0x26, &buck4_ctrl);

		printf("vol_arm: %X\n", read_vol_arm);
		printf("vol_int: %X\n", read_vol_int);
		printf("vol_g3d: %X\n", read_vol_g3d);
		printf("vol_mif: %X\n", read_vol_mif);
		printf("buck1_ctrl: %X\n", buck1_ctrl);
		printf("buck2_ctrl: %X\n", buck2_ctrl);
		printf("buck3_ctrl: %X\n", buck3_ctrl);
		printf("buck4_ctrl: %X\n", buck4_ctrl);
	}
#else
	/* fixed voltage */
#define VDDM_F(vm)				(#vm)
#define SHOW_FIXED_VDD(lab, a)	printf("%s: %s\n", lab, VDDM_F(a))

	printf("\n");
	SHOW_FIXED_VDD("vdd_arm", CONFIG_PM_VDD_ARM);
	SHOW_FIXED_VDD("vdd_int", CONFIG_PM_VDD_INT);
	SHOW_FIXED_VDD("vdd_mif", CONFIG_PM_VDD_MIF);
#endif

	/* display BL1 version */
#ifdef CONFIG_TRUSTZONE
	printf("\nBL1 version:  N/A (TrustZone Enabled BSP)\n");
#else
	strncpy(&bl1_version[0], (char *)0x02022fc8, 8);
	printf("\nBL1 version:  %s\n", &bl1_version[0]);
#endif
	
#ifdef CONFIG_SMC911X
	smc9115_pre_init();
#endif

#ifdef CONFIG_TINY4412A
	gd->bd->bi_arch_number = MACH_TYPE_TINY4412;
#else
	if (((PRO_ID & 0x300) >> 8) == 2)
		gd->bd->bi_arch_number = MACH_TYPE_C210;
	else
		gd->bd->bi_arch_number = MACH_TYPE_V310;
#endif

	gd->bd->bi_boot_params = (PHYS_SDRAM_1+0x100);

   	OmPin = INF_REG3_REG;
	printf("\n\nChecking Boot Mode ...");
	if (OmPin == BOOT_ONENAND) {
		printf(" OneNand\n");
	} else if (OmPin == BOOT_NAND) {
		printf(" NAND\n");
	} else if (OmPin == BOOT_MMCSD) {
		printf(" SDMMC\n");
	} else if (OmPin == BOOT_EMMC) {
		printf(" EMMC4.3\n");
	} else if (OmPin == BOOT_EMMC_4_4) {
		printf(" EMMC4.41\n");
	}

	return 0;
}

int dram_init(void)
{
	//gd->ram_size = get_ram_size((long *)PHYS_SDRAM_1, PHYS_SDRAM_1_SIZE);
	
	return 0;
}

void dram_init_banksize(void)
{
	nr_dram_banks = CONFIG_NR_DRAM_BANKS;

	gd->bd->bi_dram[0].start = PHYS_SDRAM_1;
	gd->bd->bi_dram[0].size = PHYS_SDRAM_1_SIZE;
	gd->bd->bi_dram[1].start = PHYS_SDRAM_2;
	gd->bd->bi_dram[1].size = PHYS_SDRAM_2_SIZE;
	gd->bd->bi_dram[2].start = PHYS_SDRAM_3;
	gd->bd->bi_dram[2].size = PHYS_SDRAM_3_SIZE;
	gd->bd->bi_dram[3].start = PHYS_SDRAM_4;
	gd->bd->bi_dram[3].size = PHYS_SDRAM_4_SIZE;

	gd->bd->bi_dram[4].start = PHYS_SDRAM_5;
	gd->bd->bi_dram[4].size = PHYS_SDRAM_5_SIZE;
	gd->bd->bi_dram[5].start = PHYS_SDRAM_6;
	gd->bd->bi_dram[5].size = PHYS_SDRAM_6_SIZE;
	gd->bd->bi_dram[6].start = PHYS_SDRAM_7;
	gd->bd->bi_dram[6].size = PHYS_SDRAM_7_SIZE;
	gd->bd->bi_dram[7].start = PHYS_SDRAM_8;
	gd->bd->bi_dram[7].size = PHYS_SDRAM_8_SIZE;

	if (board_get_hwrev() == 0x2) {
		nr_dram_banks = 8;
	}

#ifdef CONFIG_TRUSTZONE
	gd->bd->bi_dram[nr_dram_banks - 1].size -= CONFIG_TRUSTZONE_RESERVED_DRAM;
	if (nr_dram_banks > 4) {
		/* 0x7ff00000~0x7fffffff is *NOT* writeable */
		gd->bd->bi_dram[3].size -= CONFIG_TRUSTZONE_RESERVED_DRAM;
	}
#endif
}

int board_eth_init(bd_t *bis)
{
	int ret = 0;
#ifdef CONFIG_SMC911X
	ret = smc911x_initialize(0, CONFIG_SMC911X_BASE);
#endif
	return ret;
}

#ifdef CONFIG_DISPLAY_BOARDINFO
int checkboard(void)
{
	printf("Board:\t%s\n", CONFIG_BOARD_NAME);
	
	return 0;
}
#endif

int board_late_init (void)
{
#ifdef CONFIG_UPDATE_SOLUTION
	GPIO_Init();
	GPIO_SetFunctionEach(eGPIO_X0, eGPIO_0, 0);
	GPIO_SetPullUpDownEach(eGPIO_X0, eGPIO_0, 0);

	udelay(10);
	if (GPIO_GetDataEach(eGPIO_X0, eGPIO_0) == EINT0_pressed
			|| second_boot_info == 1)
	{
		setenv ("bootcmd", CONFIG_BOOTCOMMAND2);
	}
#endif
	return 0;
}

int board_mmc_init(bd_t *bis)
{
#ifdef CONFIG_S3C_HSMMC
	setup_hsmmc_clock();
	setup_hsmmc_cfg_gpio();

	if (OmPin == BOOT_EMMC_4_4 || OmPin == BOOT_EMMC) {
#ifdef CONFIG_S5PC210
		smdk_s5p_mshc_init();
#endif
		smdk_s3c_hsmmc_init();
	} else {
		smdk_s3c_hsmmc_init();
#ifdef CONFIG_S5PC210
		smdk_s5p_mshc_init();
#endif
	}
#endif
	return 0;
}

#ifdef CONFIG_ENABLE_MMU
ulong virt_to_phy_s5pv310(ulong addr)
{
	if ((0xc0000000 <= addr) && (addr < 0xe0000000)) {
		return (addr - 0xc0000000 + 0x40000000);
	}

	return addr;
}
#endif

