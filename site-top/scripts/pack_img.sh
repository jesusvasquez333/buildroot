#!/bin/sh
echo =========
echo $*
echo =========

# If there are .dtb files then we want to make a uboot
# image for zynq.
if [ -f $1/zynq-zybo.dtb -a -f $1/zynq-zc706.dtb ] ; then
	mkimage  -f - $1/linux.fit <<-"END_OF_FIT"
	/*
	 * Simple U-boot uImage source file containing a single kernel and FDT blob
	 */

	/dts-v1/;

	/ {
		description = "Simple image with single Linux kernel, ramdisk and multiple FDT blobs";
		#address-cells = <1>;

		images {
			kernel@1 {
				description = "Linux kernel";
				data = /incbin/("./output/images/zImage");
				type = "kernel";
				arch = "arm";
				os = "linux";
				compression = "none";
				load = <00000000>;
				entry = <00000000>;
				hash@1 {
					algo = "crc32";
				};
				hash@2 {
					algo = "sha1";
				};
			};
			fdt@1 {
				description = "Flattened Device Tree blob (zc706)";
				data = /incbin/("./output/images/zynq-zc706.dtb");
				type = "flat_dt";
				arch = "arm";
				compression = "none";
				hash@1 {
					algo = "crc32";
				};
				hash@2 {
					algo = "sha1";
				};
			};
			fdt@2 {
				description = "Flattened Device Tree blob (zybo)";
				data = /incbin/("./output/images/zynq-zybo.dtb");
				type = "flat_dt";
				arch = "arm";
				compression = "none";
				hash@1 {
					algo = "crc32";
				};
				hash@2 {
					algo = "sha1";
				};
			};
			ramdisk@1 {
				description = "buildroot-ramdisk";
				data = /incbin/("./output/images/rootfs.ext2.gz");
				type = "ramdisk";
				arch = "arm";
				os = "linux";
				compression = "gzip";
				load = <00000000>;
				entry = <00000000>;
				hash@1 {
					algo = "sha1";
				};
			};
		};

		configurations {
			default = "conf@1";
			conf@1 {
				description = "Boot Linux kernel with zc706 FDT blob";
				kernel = "kernel@1";
				ramdisk = "ramdisk@1";
				fdt = "fdt@1";
			};

			conf@2 {
				description = "Boot Linux kernel with zybo FDT blob";
				kernel = "kernel@1";
				ramdisk = "ramdisk@1";
				fdt = "fdt@2";
			};

		};

	};
	END_OF_FIT
fi
