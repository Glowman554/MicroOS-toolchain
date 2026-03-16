set -e

source tools/filething.sh

UPLOAD_SERVER="https://filething.toxicfox.de"
UPLOAD_AUTH_TOKEN="$MICROOS_UPLOAD_TOKEN"
BASE=network

response=$(curl -sS "https://toxicfox.de/api/v1/microos/info/$BASE")



INITRD=$(echo "$response" | jq -r '.data.initrd')
KERNEL=$(echo "$response" | jq -r '.data.kernel')
SYMBOLS=$(echo "$response" | jq -r '.data.symbols')

echo "INITRD: $INITRD"
echo "KERNEL: $KERNEL"
echo "SYMBOLS: $SYMBOLS"

bash inject.sh $INITRD

response=$(upload_file "inject/modified.saf")

curl -sS -X POST "https://toxicfox.de/api/v1/microos/build" \
    -H "Content-Type: application/json" \
    -H "Authentication: $MICROOS_BUILD_TOKEN" \
    -d "{\"preset\":\"ports\",\"kernel\":\"$KERNEL\",\"symbols\":\"$SYMBOLS\",\"initrd\":\"$response\"}"