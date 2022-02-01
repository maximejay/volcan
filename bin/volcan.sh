#!/bin/bash
#Scrip permettant de monter un systeme de fichier accésible par ftp uniquement
#Auteurs:
#Didier Organde (didier.organde@hydris-hydrologie.fr)
#Maxime Jay-Allemand (maxime.jay-allemand@hydris-hydrologie.fr)
#13/01/2022
#Version 1.1

#Installation des paquets nécessaires
#sudo apt install curlftpfs sshfs libfuse2 zenity


#source default
CONFIG="${HOME}/.volcan"

#identification des CONFIGurations enregistrées

last_conf=$(ls $CONFIG | grep "ftp_settings" | grep -E -o "[0-9]*" | sort -n -r | head -n 1)
next_conf=$((last_conf+1))

fun_optionsyad(){
    liste_conf=$(ls $CONFIG | grep "ftp_settings")
    optionsyad=""
    #i=1
    for filename in $liste_conf
    do
        indice=$(echo $filename | grep  -E -o "[0-9]*")
        source $CONFIG/$filename
        optionsyad="$optionsyad FALSE $indice $user_distant@$adresse_serveur:$repertoire_distant"
        #i=$(($i+1))
    done
    adresse_serveur=""
    user_distant=""
    password=""
    repertoire_distant=""
    repertoir_local=""
    serveur_type=""
}
fun_optionsyad

#echo $optionsyad
#echo $liste_conf


#Utilisation en ligne de commande
until [ $# = 0 ]
do
cmd_line="true"
case $1 in
    -user)
    shift
    user_distant=$1
    shift
    ;;
    -pwd)
    shift
    password=${1}
    shift
    ;;
    -remote_dir)
    shift
    repertoire_distant=${1}
    shift
    ;;
    -local_dir)
    shift
    repertoir_local=${1}
    shift
    ;;
    -adresse)
    shift
    adresse_serveur=${1}
    shift
    ;;
    -ftp_protocol)
    shift
    ftp_serveur_type="FALSE"
    shift
    ;;
    -ssh_protocol)
    shift
    ssh_serveur_type="FALSE"
    shift
    ;;
    *)
    echo "Mauvais argument "$1
    exit 1
    ;;
esac
done

# echo "yad --title='Configurations enregistrées' --width 800 --height 200 --text-align='center' --list --radiolist --column='Sélectionné' --column='config' $optionsyad"
    
#utiliser yad avec une liste et 3 bouttons : new connexion, select, remove
if [[ ! -z $liste_conf ]] && [[ -z $cmd_line ]];
then
    supprimer=1
    until [ $supprimer = 0 ] ;
    do
        retour=$(yad --title="Configurations enregistrées" --width 800 --height 200 --text-align="center" --list --radiolist --column="Sélectionné" --column="numéro" --column="adresse" $optionsyad --button="Nouveau:30" --button="Selectionner:40" --button="supprimer:50" ; echo $?);code_retour=$?
       
        NF=$(echo $retour | awk 'BEGIN {FS="|" } {print NF }')
        echo $NF
        if [[ $NF -eq 4 ]];
        then
            bool=$(echo $retour | awk 'BEGIN {FS="|" } { print $1 }')
            item=$(echo $retour | awk 'BEGIN {FS="|" } { print $2 }')
            adresse=$(echo $retour | awk 'BEGIN {FS="|" } { print $3 }')
            code_retour=$(echo $retour | awk 'BEGIN {FS="|" } { print $4 }' | awk '{ print $1 }') #prevent space
        else
            code_retour=$(echo $retour | awk '{ print $1 }')
        fi
        
        #echo $bool
        #echo $item
        #echo $adresse
        #echo $code_retour
        
        case $code_retour in
            30)
                supprimer=0
            ;;
            40)
                supprimer=0
                if [ "$bool" = "TRUE" ] ; then
                    source $CONFIG/ftp_settings_${item}.txt
                fi
            ;;
            50)
                supprimer=1
                if [ "$bool" = "TRUE" ] ; then
                    rm $CONFIG/ftp_settings_${item}.txt
                    liste_conf=$(ls $CONFIG | grep "ftp_settings")
                    fun_optionsyad
                fi
                if [ -z $liste_conf ];
                then
                    supprimer=0
                fi
            ;;
            252)
                supprimer=0
                exit
            ;;
            *)
                supprimer=0
                echo "?????"
                exit
            ;;
        esac
        
    done
fi

#echo $adresse_serveur $user_distant $password $repertoire_distant $repertoir_local $serveur_type


#Entrée une nouvelle Configuration
if [[ -z $adresse_serveur ]] || [[ -z $user_distant ]] || [[ -z $password ]] || [[ -z $repertoire_distant ]] || [[ -z $repertoir_local ]] || [[ -z $ssh_serveur_type ]] || [[ -z $ftp_serveur_type ]] ;
then
    echo "Options manquantes : -user * -pwd * -remote_dir * -local_dir *"
    
    cfgpass=$(yad --title "Nouvelle connexion - Montage d'un repertoire distant (curlftp/sshfs)" --width 800 --height 300 --text-align="center" \
    --form \
    --field="Adresse du serveur":TEXT \
    --field="Nom de l'utilisateur":TEXT \
    --field="Repertoire distant":TEXT \
    --field="Repertoire local (point de montage)":TEXT \
    --field="Mot de passe":TEXT \
    --field="Protocole ftp":CHK \
    --field="Protocole ssh/sftp":CHK \
    --separator="|")
    
    #Si on clique sur le bouton Annuler
    if [ "$?" -eq 1 ] || [ "$?" -eq 252 ] ; then
        #On quitte le script
        exit
    fi
    #Sinon on continue
    #On peut récupérer les valeurs des différents champs de cette façon :
    adresse_serveur=$(echo "$cfgpass" | cut -d "|" -f1) #Nom de l'utilisateur
    user_distant=$(echo "$cfgpass" | cut -d "|" -f2) #Nom de l'utilisateur
    repertoire_distant=$(echo "$cfgpass" | cut -d "|" -f3)
    repertoir_local=$(echo "$cfgpass" | cut -d "|" -f4)
    password=$(echo "$cfgpass" | cut -d "|" -f5)
    ftp_serveur_type=$(echo "$cfgpass" | cut -d "|" -f6)
    ssh_serveur_type=$(echo "$cfgpass" | cut -d "|" -f7)
    
    if [[ -z $adresse_serveur ]] || [[ -z $user_distant ]] || [[ -z $password ]] || [[ -z $repertoire_distant ]] || [[ -z $repertoir_local ]] || [[ -z $ssh_serveur_type ]] || [[ -z $ftp_serveur_type ]] ;
    then
        exit
    fi
    
    New_CONFIG="true"
fi


#Traitement du repertoir local :
if [[ -z $repertoir_local ]];
then
    echo "Le nom du répertoire local doit être spécifié."
    yad --text "Le nom du répertoire local doit être spécifié." --text-align=center
    exit
fi

if [[ -d $repertoir_local ]] ;
then
    #test si il est vide
    if [ "$(ls -A $repertoir_local)" ]; then
        #il n'est pas vide, on exit
        echo "Le répertoire local doit être un répertoire vide !"
        yad --text "Le répertoire local doit être un répertoire vide !" --text-align=center
        exit
    fi
else
    #sinon on crée le repertoir dans /home/user/RemoteDirectory/
    repertoir_local=$HOME"/RemoteDirectory/"${repertoir_local}
    echo "Le point de montage est :"$repertoir_local
    mkdir -p $repertoir_local
fi


# Mount - exchange username, password and example.com:

#connexion et montage du repertoir distant FTP
if [[ "${ftp_serveur_type}" == "TRUE" ]];
then
    echo "Tentative de connexion"
    curlftpfs -o allow_other,user=${user_distant}:${password} ${adresse_serveur}:${repertoire_distant} ${repertoir_local}
    
    if [ $? -eq 0 ]; then
        connexion="YES"
    else
        connexion="NO"
    fi
fi

#connexion et montage du repertoir distant ssh/sftp
if [[ "${ssh_serveur_type}" == "TRUE" ]];
then
    echo "Tentative de connexion: sshfs ${user_distant}@${adresse_serveur}:${repertoire_distant} ${repertoir_local}"
    echo "$password" | sshfs ${user_distant}@${adresse_serveur}:${repertoire_distant} ${repertoir_local} -o password_stdin
    
    if [ $? -eq 0 ]; then
        connexion="YES"
    else
        connexion="NO"
    fi
fi


#SI connexion réussie alors on stocke la CONFIGuration
if [ "$connexion" = "YES" ] && [ "${New_CONFIG}" = "true" ] ; then
    echo "repertoir_local=$repertoir_local" > $CONFIG/ftp_settings_${next_conf}.txt
    echo "user_distant=$user_distant" >> $CONFIG/ftp_settings_${next_conf}.txt
    echo "adresse_serveur=$adresse_serveur" >> $CONFIG/ftp_settings_${next_conf}.txt
    echo "repertoire_distant=$repertoire_distant" >> $CONFIG/ftp_settings_${next_conf}.txt
    echo "password=$password" >> $CONFIG/ftp_settings_${next_conf}.txt
    echo "ftp_serveur_type=$ftp_serveur_type" >> $CONFIG/ftp_settings_${next_conf}.txt
    echo "ssh_serveur_type=$ssh_serveur_type" >> $CONFIG/ftp_settings_${next_conf}.txt
fi
if  [ "$connexion" = "NO" ]; then
    echo "Connexion échouée..."
    #rm $CONFIG/ftp_settings_${next_conf}.txt
    yad --text "Echec de la connexion" --text-align=center
fi



