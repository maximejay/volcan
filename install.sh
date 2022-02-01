#!/bin/bash
##Script d'installation de volcan
#Installation sur Ubuntu 20.04
#Auteurs:
#Didier Organde (didier.organde@hydris-hydrologie.fr)
#Maxime Jay-Allemand (maxime.jay-allemand@hydris-hydrologie.fr)
#18/12/2021
#Version 0.1

#Installation des paquets nécéssaire au fonctionnement de volcan
echo " --- Installation des dépendances..."
echo ""

#dépendances libgdal-dev libshp-dev cmake build-essential git
#installation depuis les dépôts officiels
sudo apt install curlftpfs sshfs libfuse2 yad

echo ""
echo " --- Installation des dépendances terminées."

echo ""

#creation du répertoire de config + binaire (intallation local dans $HOME)

echo " --- Création du dossier de configuration ${HOME}/.volcan"
CONFIG="${HOME}/.volcan"
if [ -d ${CONFIG} ];
then
    echo "* ${CONFIG} existe déja."
else
    echo "* ${CONFIG} n'existe pas."
    mkdir ${CONFIG}
    echo "* * ${CONFIG} à été créé."
fi


echo " --- Copie des exécutables volcan dans ${HOME}/.volcan/bin/."
cp -r ./bin ${CONFIG}/.

echo " --- Modification des permissions des fichiers exécutables"

chmod +x ${CONFIG}/bin/volcan.sh


echo " --- Copie des lanceurs et icons "
cp -r ./icons ${CONFIG}/. 
cp ./lanceurs/volcan.desktop $HOME/.local/share/applications/.
sed -i "s/USER/${USER}/g" $HOME/.local/share/applications/volcan.desktop

echo " --- Modification du .bashrc..."
echo " ------Export et ajoute le dossier ${HOME}/.volcan/bin/. à la variable d'environnement PATH"

#fait une copie du bashrc
if [ ! -e ${HOME}/.bashrc_backup_volcan ]
then
    cp ${HOME}/.bashrc ${HOME}/.bashrc_backup_volcan
fi

#Test si l'install à déja été effectuée
smash=$(grep -o -i "smash" ${HOME}/.bashrc)
if [ -z "${smash}" ]
then
    #Export le path
    echo "#volcan program :" >> ${HOME}/.bashrc
    echo 'export PATH=~/.volcan/bin/:$PATH' >> ${HOME}/.bashrc
fi 

echo "Installation de Volcan terminée !"





