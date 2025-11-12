#!/system/bin/sh
# Toggle spoofVendingSdk in PlayIntegrityFix/Fork config (prop or json)
# Priority: custom.pif.prop > custom.pif.json

BASE_DIR="/data/adb/modules/playintegrityfix"
PROP_FILE="$BASE_DIR/custom.pif.prop"
JSON_FILE="$BASE_DIR/custom.pif.json"

# Detect config file (prop takes priority)
if [ -f "$PROP_FILE" ]; then
    TARGET_FILE="$PROP_FILE"
    FORMAT="prop"
elif [ -f "$JSON_FILE" ]; then
    TARGET_FILE="$JSON_FILE"
    FORMAT="json"
else
    echo -e "\n[!] No custom.pif.prop or custom.pif.json found in $BASE_DIR"
    exit 1
fi

echo ""
echo "[ Current Advanced Settings ($FORMAT) ]"
echo ""

# Show current advanced settings
if [ "$FORMAT" = "prop" ]; then
    grep -E "^(spoof(Build|Props|Provider|Signature|VendingSdk)|verboseLogs)=" "$TARGET_FILE"
else
    grep -E '"(spoofBuild|spoofProps|spoofProvider|spoofSignature|spoofVendingSdk|verboseLogs)"' "$TARGET_FILE" \
    | sed 's/[", ]//g' | sed 's/:/=/g'
fi

# Extract current spoofVendingSdk value
if [ "$FORMAT" = "prop" ]; then
    CURRENT=$(grep -E "^spoofVendingSdk=" "$TARGET_FILE" | cut -d= -f2)
else
    CURRENT=$(grep -oE '"spoofVendingSdk": *"([01])"' "$TARGET_FILE" | grep -oE '[01]')
fi
[ -z "$CURRENT" ] && CURRENT="0"

# Determine new value
[ "$CURRENT" = "1" ] && NEW="0" || NEW="1"

echo ""
echo "Setting spoofVendingSdk to '$NEW'..."
echo "    Restarting Google Play services and Play Store..."

# Apply the change
if [ "$FORMAT" = "prop" ]; then
    sed -i "s/^spoofVendingSdk=.*/spoofVendingSdk=$NEW/" "$TARGET_FILE"
else
    sed -i "s/\"spoofVendingSdk\": *\"[01]\"/\"spoofVendingSdk\": \"$NEW\"/" "$TARGET_FILE"
fi

# Restart key services
su -c "killall -v com.google.android.gms.unstable" >/dev/null 2>&1
su -c "killall -v com.android.vending" >/dev/null 2>&1

# Verify result
if [ "$FORMAT" = "prop" ]; then
    AFTER=$(grep -E "^spoofVendingSdk=" "$TARGET_FILE" | cut -d= -f2)
else
    AFTER=$(grep -oE '"spoofVendingSdk": *"([01])"' "$TARGET_FILE" | grep -oE '[01]')
fi
[ -z "$AFTER" ] && AFTER="$NEW"

# Choose icon
if [ "$AFTER" = "0" ]; then
    ICON="✅"
else
    ICON="⚠️"
fi

echo "✅  Done. Changes should be active."
echo "    Verifying file content:"
echo ""
echo "    $ICON spoofVendingSdk=$AFTER"

# Optional countdown delay for KernelSU/APatch auto-close (10s)
if [ "$KSU" = "true" -o "$APATCH" = "true" ] && \
   [ "$KSU_NEXT" != "true" ] && [ "$WKSU" != "true" ] && [ "$MMRL" != "true" ]; then
    echo
    echo "Closing dialog in 5 seconds..."
    sleep 1
    for i in 4 3 2 1; do
        printf "                  %d ...\n" "$i"
        sleep 1
    done
    echo "                  ✅"
    echo
fi
