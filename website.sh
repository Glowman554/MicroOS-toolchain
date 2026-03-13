set -e

source tools/filething.sh

UPLOAD_SERVER="https://filething.toxicfox.de"
UPLOAD_AUTH_TOKEN="$MICROOS_UPLOAD_TOKEN"

INITRD=https://filething.toxicfox.de/files/384c795c-68f0-4d65-9ab9-4568f54c0a21.saf
KERNEL=https://filething.toxicfox.de/files/034c0e85-e46c-400f-842a-465e55b50da4.elf
SYMBOLS=https://filething.toxicfox.de/files/1a24effb-eb08-4f31-944b-16d5669b301a.syms

bash inject.sh $INITRD

response=$(upload_file "inject/modified.saf")

curl -sS -X POST "https://toxicfox.de/api/v1/microos/build" \
    -H "Content-Type: application/json" \
    -H "Authentication: $MICROOS_BUILD_TOKEN" \
    -d "{\"preset\":\"ports\",\"kernel\":\"$KERNEL\",\"symbols\":\"$SYMBOLS\",\"initrd\":\"$response\"}"