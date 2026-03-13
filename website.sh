set -e

source tools/filething.sh

UPLOAD_SERVER="https://filething.toxicfox.de"
UPLOAD_AUTH_TOKEN="$MICROOS_UPLOAD_TOKEN"

INITRD=https://filething.toxicfox.de/files/22d6677c-9d10-4d35-ada2-f562c1a4035e.saf
KERNEL=https://filething.toxicfox.de/files/62e23d28-deb3-4f6c-9725-4165f1a61e55.elf
SYMBOLS=https://filething.toxicfox.de/files/27fda2bd-cd15-4df2-a602-8afa3bca096c.syms

bash inject.sh $INITRD

response=$(upload_file "inject/modified.saf")

curl -sS -X POST "https://toxicfox.de/api/v1/microos/build" \
    -H "Content-Type: application/json" \
    -H "Authentication: $MICROOS_BUILD_TOKEN" \
    -d "{\"preset\":\"ports\",\"kernel\":\"$KERNEL\",\"symbols\":\"$SYMBOLS\",\"initrd\":\"$response\"}"