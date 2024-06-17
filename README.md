# Welcome to kbag-crawler

This project was a fork of nick's variant, but made it so you could choose the ipsw URL and boardconfig, and not have it do every fucking ipsw.

requirements:
1. dev fused device in anya mode (https://github.com/NyanSatan/Anya) (checkm8 support should be added shortly)
  
2. img4lib, pzb, and anyactl in the same dir (in an update, they will be downloaded automaticlly)
   
3. common sense

# how to use:

./kbag-crawler <device> <boardconfig without AP part (sometimes you have to pzb -l the ipsw to see it tho, as its not awlays that)> <output file> <ipswurl (put "all" in if you want all kbags for that device decrypted)>

EXAMPLE:

./kbag-crawler.sh iPhone13,4 D54p 12promaxkeys.json https://updates.cdn-apple.com/2022SummerFCS/fullrestores/012-53121/781B38B9-5A72-4F6D-AA98-ADB074F000DC/iPhone13,4_15.6.1_19G82_Restore.ipsw 

This script would be grabbing all the AP keys for the iphone 12 pro max for iOS 15.6.1
EXAMPLe 2:

,/kbag-crawler.sh iPad11,6 ipad11b ipad8keys.json all

This command will grab all the keys for the ipad 8th gen 


