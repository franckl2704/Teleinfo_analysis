########################################################################
############               TELEINFO ANALYSIS                ############
########################################################################
# Auteur: Franck LARTIGUE                                              #
#                                                                      #
# Besoin:                                                              #
#         extraire les données venanta de mon compteur electrique et   #
#         pouvoir les enregistrer et les envoyer vers un moyen         #
#         d'analyse (DB + graphique, EmonCMS, Domoticz, ...)           #
#                                                                      #
# Developpements supplementaires :                                     #
#         J'ai fait un script qui permet d'analyser tous les types     #
#         d'abonnement (base, HCHP, EJP, Tempo)                        #
#         du coup le script est un petit peu une usine a gaz :(        #
#                                                                      #
#                                                                      #
#To do:                                                                #
#         Verifier la partie Tempo et EJP                              #
#         Envoi vers EmonCMS                                           #
#         Envoi vers Mysql                                             #
#                                                                      #
#                                                                      #
#                                                                      #
#                                                                      #
#Requirement:                                                          #
#            bc                                                        #
#                                                                      #
#                                                                      #
########################################################################
#Log:
#2015 02 19 10 15 - ajout historique trame pour debugging
#
#2015 02 19 11 23 - remplacement des tail par des head: si la trame est imcomplete on obtient un valeur imcomplete ... avec head on a quasi aucun risque car si la trame est imcomplete c est l entete de la lign equi est imcomplete et donc non pris en compte pour la recherche de la valeur
#
#2015 02 19 11 59 - adps=`cat $file.trame | grep ADPS | head -n 1 | cut -f2 -d' '` # pas fonctionnel seul car la valeur n'apparait dans la trame que si necessaire
#
#2015 02 19 12 22 - check sur la presence de adps avant de faire la recherche
#
#
#
########################################################################


#!/bin/bash

####################################
###### Importation Variables  ######
####################################
. /var/Teleinfo_analysis/Teleinfo_analysis.cfg

####################################
###### Variables et captures  ######
####################################
#what time is it ?
NOW=$(date +"%Y-%m-%d,%T")
timestamp=$(date +"%Y%m%d%H%M%S")
unixtimestamp=$(date +"%s")

#capture trame teleinfo
timeout 3 cat /dev/ttyUSB11 1> $file.trame
if [ $debug -eq 1 ]; then cp $file.trame $file.trame.history_to_delete.$timestamp ; fi

####################################
######    Valeurs communes    ######
####################################
#Adresse du compteur
adco=`cat $file.trame | grep ADCO | head -n 1 | cut -f2 -d' '`
#Intensite souscrite
isousc=`cat $file.trame | grep ISOUSC | head -n 1 | cut -f2 -d' '`
#intensite instantannee
iinst=`cat $file.trame | grep IINST | head -n 1 | cut -f2 -d' '`
#avertissement de depassement
if grep -q "ADPS" $file.trame
then
        adps=`cat $file.trame | grep ADPS | head -n 1 | cut -f2 -d' '`
        echo "Depassement de puissance :" $adps
else
        adps=0
        echo "pas de depassement de puissance"
fi
#intensite max appele
imax=`cat $file.trame | grep IMAX | head -n 1 | cut -f2 -d' '`
#puissance apparente
papp=`cat $file.trame | grep PAPP | head -n 1 | cut -f2 -d' '`
#Mot d etat du compteur
motdetat=`cat $file.trame | grep DETAT | head -n 1 | cut -f2 -d' '`


####################################
## Valeurs specifiques abonnement ##
####################################
#option tarifaire
optarif=`cat $file.trame | grep OPTARIF | head -n 1 | cut -f2 -d' '`

case $optarif in
"base")
#base
        #index base
        echo "Abonnement base"
        base=`cat $file.trame | grep BASE | head -n 1 | cut -f2 -d' '`
        echo "Index = " $base
        file_for_log=$file.$optarif.log;;
"HC..")
#HPHC
        echo "abonnement HCHP"
        #Index Option heure creuse
        hchc=`cat $file.trame | grep HCHC | head -n 1 | cut -f2 -d' '`
        echo "Index heures creuses = " $hchc
        hchp=`cat $file.trame | grep HCHP | head -n 1 | cut -f2 -d' '`
        echo "Index heures pleines = " $hchp
        #Horraire HCHP
        hhphc=`cat $file.trame | grep HHPHC | head -n 1 | cut -f2 -d' '`
        case $hhphc in
                "A") echo "Horraire HCHP A";;
                "C") echo "Horraire HCHP C";;
                "D") echo "Horraire HCHP D";;
                "E") echo "Horraire HCHP E";;
                "Y") echo "Horraire HCHP Y";;
                "*") echo "erreur HHPHC";;
        esac
        optarif="HC"
        file_for_log=$file.$optarif.log;;
"EJP.")
#EJP
        echo "Abonnement EJP"
        #Index option EJP
        ejphn=`cat $file.trame | grep EJPHN | head -n 1 | cut -f2 -d' '`
        echo "Index EJP heures normales = " $ejphn
        ejphpm=`cat $file.trame | grep EJPHPM | head -n 1 | cut -f2 -d' '`
        echo "Index heures de pointe mobile = " $ejphm
        #Preavis debut EJP 30 minutes
        pejp=`cat $file.trame | grep PEJP | head -n 1 | cut -f2 -d' '`
        if [ $pejp -eq 30 ]; then
                echo "Preavis EJP 30 minutes en cours"
        else
                echo "Preavis EJP " $pejp
        fi
        optarif="EJP"
        file_for_log=$file.$optarif.log;;
"BBR*") #a verifier
###### La partie abonnement TEMPO est a verifier entierement ... ######
#Tempo
        echo "Abonnement Tempo"
        #Index option tempo
        bbrhcjb=`cat $file.trame | grep BBRHCJB | head -n 1 | cut -f2 -d' '`
        echo "Index heures creuses jours bleus = " $bbrhcjb
        bbrhpjb=`cat $file.trame | grep BBRHPJB | head -n 1 | cut -f2 -d' '`
        echo "Index heures pleines jours bleus = " $bbrhpjb
        bbrhcjw=`cat $file.trame | grep BBRHCJW | head -n 1 | cut -f2 -d' '`
        echo "Index heures creuses jours blancs = " $bbrhcjw
        bbrhpjw=`cat $file.trame | grep BBRHPJW | head -n 1 | cut -f2 -d' '`
        echo "Index heures pleines jours blancs = " $bbrhpjw
        bbrhcjr=`cat $file.trame | grep BBRHCJR | head -n 1 | cut -f2 -d' '`
        echo "Index heures creuses jours rouges = " $bbrhcjr
        bbrhpjr=`cat $file.trame | grep BBRHPJR | head -n 1 | cut -f2 -d' '`
        echo "Index heures pleines jours rouges = " $bbrhpjr
        #couleur du lendemain
        demain=`cat $file.trame | grep DEMAIN | head -n 1 | cut -f2 -d' '`
        case $demain in
                "BLEU") echo "demain jour bleu";;
                "BLAN") echo "demain jour blanc";;
                "ROUG") echo "demain jour rouge";;
        esac
        file_for_log=$file.$optarif.log;;
########################################################################
*)
        echo "error - code OPTARIF inconnu"
        exit 91;;
esac

#periode tarifaire en cours
ptec=`cat $file.trame | grep PTEC | head -n 1 | cut -f2 -d' '`
echo $ptec
case $ptec in
        "TH..") period="Toutes les Heures"
                ptec="TH";;
        "HC..") period="Heures Creuses"
                ptec="HC";;
        "HP..") period="Heures Pleines"
                ptec="HP";;
        "HN..") period="Heures Normales"
                ptec="HN";;
        "PM..") period="Heures de Pointe Mobile"
                ptec="PM";;
        "HCJB") period="Heures Creuses Jours Bleus";;
        "HCJW") period="Heures Creuses Jours Blancs (White)";;
        "HCJR") period="Heures Creuses Jours Rouges";;
        "HPJR") period="Heures Pleines Jours Bleus";;
        "HPJW") period="Heures Pleines Jours Blancs (White)";;
        "HPJR") period="Heures Pleines Jours Rouges";;
esac
echo "Periode tarifaire en cours: " $ptec


####################################
######   preparation donnees  ######
####################################

##### creation du header du CSV #####
if [ -f "$file_for_log" ]
then
        echo "new values added to " $file_for_log
else
        echo "log file created and completed with values : " $file_for_log
        #File header creation
        header_debut="Date,Heure,Timestamp,Adresse du compteur,Intensite souscrite,intensite instantannee,avertissement de depassement,intensite max appele,puissance apparente,Mot d etat du compteur,"
#header op
case $optarif in
"base")
        #index base
        header_op="base";;
"HC")
        header_op="Index heures creuses,Index heures pleines,Horraire HCHP,";;
"EJP.")
        header_op="Index EJP heures normales,Index heures de pointe mobile,Preavis debut EJP,";;
"BBR*") #a verifier
        header_op="Index heures creuses jours bleus,Index heures pleines jours bleus,Index heures creuses jours blancs,Index heures pleines jours blancs,Index heures creuses jours rouges,Index heures pleines jours rouges,couleur du lendemain,";;
*)
        echo "erreur optarif - erreur 92"
        exit 92;;
esac
#header_fin
header_fin="Periode tarifaire en cours"
#Creation duc fichier et ecriture du header
echo $header_debut$header_op$header_fin > $file_for_log
fi


###### mise en forme des donnees #####
case $optarif in
"base")
        #index base
        result_op=$base","
        BASEWH=`expr $base + 0`        # remove leading zeros
        let "BASEKWH=$BASEWH/1000"     # convert to Kwh
        echo "WH: "$BASEWH
        echo "KWH: "$BASEKWH
        URLDATAOP="base:"$BASEKWH;;
"HC")
        result_op=$hchc","$hchp","$hhphc","
        HCHCKWH=`echo $hchc/1000 | bc`
        HCHPKWH=`echo $hchp/1000 | bc`
        echo "HC KWH: "$HCHCKWH
        echo "HP KWH: "$HCHPKWH
        HCHxKWH=`echo $hchc/1000+$hchp/1000 | bc`
        echo "KWh total: "$HCHxKWH
        URLDATAOP="HCHC:"$HCHCKWH",HCHP:"$HCHPKWH",HHPHC:"$hhphc",KWh:"$HCHxKWH",";;
"EJP.")
        result_op=$ejphn","$ejphpm","$pejp","
        # TO DO: concersion en KWH
        URLDATAOP="EJPHN:"$ejphn",EJPHPM:"$ejphpm",PEJP:"$pejp",";;
"BBR*") #a verifier
        result_op=$bbrhcjb","$bbrhpjb","$bbrhcjw","$bbrhpjw","$bbrhcjr","$bbrhpjr","$demain","
        # TO DO: concersion en KWH
        URLDATAOP="BBRHCJB:"$bbrhcjb",BBRHPJB:"$bbrhpjb",BBRHCJW:"$bbrhcjw",BBRHPJW:"$bbrhpjw\
",BBRHCJR:"$bbrhcjr",BBRHPJR:"$bbrhpjr",DEMAIN:"$demain",";;
*)
        echo "erreur optarif - erreur 93"
        exit 93;;
esac

result_commun=$adco","$isousc","$iinst","$adps","$imax","$papp","$motdetat","
URLDATACOMMUN="ADCO:"$adco",ISOUSC:"$isousc",IINST:"$iinst",ADPS:"$adps",IMAX:"$imax",PAPP:"$papp",MODETAT:"$motdetat","

result_fin=$ptec
URLDATAEND="PTEC:"$ptec

###### ecriture CSV ######
echo $NOW","$timestamp","$unixtimestamp","$result_commun$result_op$result_fin >> $file_for_log

###### envoi EMONCMS ######
URLTIME="time="$unixtimestamp
URLNODE="node="$EMONCMS_NODE
URLSTARTDATA="json={"
URLENDDATA="}"
URLAPIKEY="apikey="$APIKEY
URL=$URLBASE$URLTIME"&"$URLNODE"&"$URLSTARTDATA$URLDATACOMMUN$URLDATAOP$URLDATAEND$URLENDDATA"&"$URLAPIKEY

# echo $URL
echo " "
curl --request GET "$URL" 2> $file_for_log.curl.error.log
echo " "


####################################
######  display HCHP values   ######
####################################
printf "hchp:%1.0f hchc:%1.0f iinst:%1.0f imax:%1.0f papp:%1.0f ptec:%s\n" $hchp $hchc $iinst $imax $papp $ptec

exit 0





# aide memoire:
#Voici des exemples pour obtenir le timestamp de la date et de l'heure courante :
#
#    $ date +%s
#    1314826236
#
#Le timestamp d'une date précise :
#
#    $ date -d "2011-08-31 23:39:36" +%s
#    1314826776
#
#Et enfin, pour convertir un timestamp en date :
#
#    $ date -d @1314826776
#    Wed Aug 31 23:39:36 CEST 2011





