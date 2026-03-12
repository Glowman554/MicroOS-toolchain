set -e

INITRD=https://filething.toxicfox.de/files/717eb60f-c773-408f-991a-a2e06175af4d.saf
KERNEL=https://filething.toxicfox.de/files/15dfe784-82ca-4b5f-8d0a-3087dcc89663.elf
SYMBOLS=https://filething.toxicfox.de/files/bc0ee3e4-dbfd-4543-84f4-c8c912292897.syms

mkdir -p inject
(
    cd inject
    
    if [ ! -d "saf" ]; then
        git clone https://github.com/chocabloc/saf.git --depth=1 ./saf
        make -C saf
    fi

    if [ ! -f "original.saf" ]; then
        wget -O original.saf $INITRD
    fi

    if [ -d "extracted" ]; then
        rm -rf extracted
    fi

    ./saf/saf-extract original.saf extracted
    (
        cd extracted
        cp ../../output/* . -r
    )
    ./saf/saf-make extracted modified.saf
)

# Build bootable ISO
BUILD_DIR=/tmp/microos_build
if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
fi

CDROM_BASE=https://raw.githubusercontent.com/Glowman554/WebsiteV3/master/microos/cdrom
if [ ! -d "inject/cdrom" ]; then
    mkdir -p inject/cdrom/boot/limine
    mkdir -p inject/cdrom/EFI/BOOT
    curl -sSL "$CDROM_BASE/limine.cfg"                    -o inject/cdrom/limine.cfg
    curl -sSL "$CDROM_BASE/zap-light16.psf"               -o inject/cdrom/zap-light16.psf
    curl -sSL "$CDROM_BASE/boot/limine/limine-cd.bin"     -o inject/cdrom/boot/limine/limine-cd.bin
    curl -sSL "$CDROM_BASE/boot/limine/limine-cd-efi.bin" -o inject/cdrom/boot/limine/limine-cd-efi.bin
    curl -sSL "$CDROM_BASE/boot/limine/limine.sys"        -o inject/cdrom/boot/limine/limine.sys
    curl -sSL "$CDROM_BASE/EFI/BOOT/BOOTIA32.EFI"         -o inject/cdrom/EFI/BOOT/BOOTIA32.EFI
    curl -sSL "$CDROM_BASE/EFI/BOOT/BOOTX64.EFI"          -o inject/cdrom/EFI/BOOT/BOOTX64.EFI
fi

mkdir -p "$BUILD_DIR"
cp -r inject/cdrom/* "$BUILD_DIR"

curl -sSL "$KERNEL" -o "$BUILD_DIR/mckrnl.elf"
curl -sSL "$SYMBOLS" -o "$BUILD_DIR/mckrnl.syms"
cp inject/modified.saf "$BUILD_DIR/initrd.saf"

xorriso -as mkisofs -R -r -J -b boot/limine/limine-cd.bin \
    -no-emul-boot -boot-load-size 4 -boot-info-table -hfsplus \
    -apm-block-size 2048 --efi-boot boot/limine/limine-cd-efi.bin \
    -efi-boot-part --efi-boot-image --protective-msdos-label \
    "$BUILD_DIR" -o microos.iso

echo "ISO created: microos.iso"