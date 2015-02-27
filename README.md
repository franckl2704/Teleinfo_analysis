#Teleinfo_analysis

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


