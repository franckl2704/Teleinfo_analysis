# TELEINFO_ANALYSIS


Besoin:                                                             
       extraire les données venant de mon compteur electrique et    
       pouvoir les enregistrer et les envoyer vers un moyen         
       d'analyse (DB + graphique, EmonCMS, Domoticz, ...)           
                                                                    
Developpements supplementaires :                                    
       J'ai fait un script qui permet d'analyser tous les types     
       d'abonnement (base, HCHP, EJP, Tempo)                        
       du coup le script est un petit peu une usine a gaz :(        
                                                                    
                                                                    
To do:                                                              
       Verifier la partie Tempo et EJP                              
       Envoi vers EmonCMS                                           
       Envoi vers Mysql                                             
                                                                    
                                                                    
                                                                    
                                                                    
Requirement:                                                        
          bc                                                        
                                                                    
                                                                    
#######################################################################
Log:
2015 02 19 10 15 - ajout historique trame pour debugging

2015 02 19 11 23 - remplacement des tail par des head: si la trame est imcomplete on obtient un valeur imcomplete ... vec head on a quasi aucun risque car si la trame est imcomplete c est l entete de la lign equi est imcomplete et donc on pris en compte pour la recherche de la valeur

2015 02 19 11 59 - adps=`cat $file.trame | grep ADPS | head -n 1 | cut -f2 -d' '` # pas fonctionnel seul car la valeur n'apparait dans la trame que si necessaire

2015 02 19 12 22 - check sur la presence de adps avant de faire la recherche



#######################################################################


Teleinfo_analysis installation instruction

Create log and working folder:
sudo mkdir /var/Teleinfo_analysis/

Change permissions:
sudo chown pi /var/Teleinfo_analysis/

Create config file:
vim /var/Teleinfo_analysis/Teleinfo_analysis.cfg

paste:
	#path for log
	file="/var/Teleinfo_analysis//teleinfo" #le .log sera ajouter automatiquement
	#EmonCMS
	APIKEY="" #METTRE_ICI_SON_API_KEY_ECRITURE
	URLBASE="http://emoncms.org/input/post.json?"
	EMONCMS_NODE=6
	#DB, ...

	#DEBUG
	debug=0

Add the script to crontab


