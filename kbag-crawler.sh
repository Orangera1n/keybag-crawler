#!/bin/zsh

# Copyright 2023, Nick Botticelli. <nick.s.botticelli@gmail.com>
# This fork has been made by Ellie Firebloom (elliefirebloom@gmail.com)

#
# This file is part of kbag-crawler.
#
# kbag-crawler is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# kbag-crawler is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with kbag-crawler. If not, see <http://www.gnu.org/licenses/>.

#
# kbag-crawler
# kbag-crawler.sh v0.2.0
#

# Fail-fast
#set -e

DEVICE=$1
BCFG=$2
OUTPUT=$3
if [ "$4" = 'all' ]; then
LINKS=$(curl --silent "https://api.ipsw.me/v4/device/${DEVICE}" | jq ".firmwares[] .url" | tr -d '"')
else;
IPSW=$4
LINK=$IPSW
LINKS=$IPSW
fi
DECRYPTOR=$5
# Create initial output file
./jq -n --arg device "$DEVICE" '{"device": $device}' > $OUTPUT

#while read link
while IFS= read -r link
do
    BUILDNUM=$(echo $link | sed -E 's/.*_([^_]+)_Restore\.ipsw/\1/')

    ./pzb -g 'Firmware/all_flash/LLB.'$BCFG'.RELEASE.im4p' "$link" > /dev/null
    ./pzb -g 'Firmware/all_flash/iBoot.'$BCFG'.RELEASE.im4p' "$link" > /dev/null
    ./pzb -g 'Firmware/dfu/iBEC.'$BCFG'.RELEASE.im4p' "$link" > /dev/null
    ./pzb -g 'Firmware/dfu/iBSS.'$BCFG'.RELEASE.im4p' "$link" > /dev/null
    if [ "$DECRYPTOR" = 'anya' ]; then
    ILLB_KB=$(./img4 -b -i 'LLB.'$BCFG'.RELEASE.im4p' | awk 'NR==2')
    IBOT_KB=$(./img4 -b -i 'iBoot.'$BCFG'.RELEASE.im4p' | awk 'NR==2')
    IBEC_KB=$(./img4 -b -i 'iBEC.'$BCFG'.RELEASE.im4p' | awk 'NR==2')
    IBSS_KB=$(./img4 -b -i 'iBSS.'$BCFG'.RELEASE.im4p' | awk 'NR==2')
    else;
    ILLB_KB=$(./img4 -b -i 'LLB.'$BCFG'.RELEASE.im4p' | awk 'NR==1')
    IBOT_KB=$(./img4 -b -i 'iBoot.'$BCFG'.RELEASE.im4p' | awk 'NR==1')
    IBEC_KB=$(./img4 -b -i 'iBEC.'$BCFG'.RELEASE.im4p' | awk 'NR==1')
    IBSS_KB=$(./img4 -b -i 'iBSS.'$BCFG'.RELEASE.im4p' | awk 'NR==1')
    fi
    # Decrypt keybags (Anya)
    # Note: Must initialize Anya device before running kbag-crawler
    if [ "$DECRYPTOR" = 'anya' ]; then
    ANYA="./anyactl"
    ILLB_DKB=$($ANYA -k $ILLB_KB | awk 'NR==2')
    IBOT_DKB=$($ANYA -k $IBOT_KB | awk 'NR==2')
    IBEC_DKB=$($ANYA -k $IBEC_KB | awk 'NR==2')
    IBSS_DKB=$($ANYA -k $IBSS_KB | awk 'NR==2')
    else;
    gaster="./gaster"
    ILLB_DKB=$($gaster -k $ILLB_KB | awk 'NR==2')
    IBOT_DKB=$($gaster -k $IBOT_KB | awk 'NR==2')
    IBEC_DKB=$($gaster -k $IBEC_KB | awk 'NR==2')
    IBSS_DKB=$($gaster -k $IBSS_KB | awk 'NR==2')

    # Verify keybags
    ./img4 -k $ILLB_DKB -i 'LLB.'$BCFG'.RELEASE.im4p' -o 'ILLB.dec' > /dev/null
    ./img4 -k $IBOT_DKB -i 'iBoot.'$BCFG'.RELEASE.im4p' -o 'IBOT.dec' > /dev/null
    ./img4 -k $IBEC_DKB -i 'iBEC.'$BCFG'.RELEASE.im4p' -o 'IBEC.dec' > /dev/null
    ./img4 -k $IBSS_DKB -i 'iBSS.'$BCFG'.RELEASE.im4p' -o 'IBSS.dec' > /dev/null
    
    strings 'ILLB.dec' | grep 'Apple Mobile Device' > /dev/null
    ILLB_CHECK=$?
    strings 'IBOT.dec' | grep 'Apple Mobile Device' > /dev/null
    IBOT_CHECK=$?
    strings 'iBEC.dec' | grep 'Apple Mobile Device' > /dev/null
    IBEC_CHECK=$?
    strings 'iBSS.dec' | grep 'Apple Mobile Device' > /dev/null
    IBSS_CHECK=$?
    
    if [ $ILLB_CHECK -ne 0 ] || [ $IBOT_CHECK -ne 0 ] || [ $IBEC_CHECK -ne 0 ] || [ $IBSS_CHECK -ne 0 ]
    then
        echo "Unable to verify output for buildnum $BUILDNUM!"
        echo "ILLB: $ILLB_CHECK"
        echo "IBEC: $IBEC_CHECK"
        echo "IBOT: $IBOT_CHECK"
        echo "IBSS: $IBSS_CHECK"
        exit 1
    fi
    
    mv $OUTPUT ${OUTPUT}_tmp
    
    # Output result into JSON file
    ./jq \
      --arg buildnum $BUILDNUM \
      --arg illb_dkb $ILLB_DKB \
      --arg ibot_dkb $IBOT_DKB \
      --arg ibec_dkb $IBEC_DKB \
      --arg ibss_dkb $IBSS_DKB \
      '.keybags += [{ "buildnum": $buildnum, "illb": $illb_dkb, "ibot": $ibot_dkb, "ibec": $ibec_dkb, "ibss": $ibss_dkb }]' \
      ${OUTPUT}_tmp > $OUTPUT
    
    find ./ -type f -iname '*.im4p' -delete
    find ./ -type f -iname '*.dec' -delete
    rm -f ${OUTPUT}_tmp
    
    echo "Finished $BUILDNUM"
done <<< "$LINKS"
