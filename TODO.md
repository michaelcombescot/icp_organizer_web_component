a changer après réflexion:
- dans le coordinateur, penser à cache les principaux pour les indexes et les buckets plutôt que de tout recalculer à chaque fois.
- AJOUTER UN system inspect PARTOUT
- ajouter un registry canister, c'est lui qui aura les infos sur les indexes, et c'est lui qui sera appelé par le front pour reucp les indexes
- changer le système pour prévenir les buckets/canisters qu'il y a un petit nouveau en event et plus en polling depuis les indexes/buckets
- remettre les indexes en dynamique, il n'y a que 2 canisters persistants => le coordinateur et le registry
- modifier les map de buckets dans l'index pour fonctionner avec des arrays a la place, et sauvegarder un id local et un index de bucket plutot que le principal por économiser de la place en mémoire
- repenser l'architecture maintenant que je connais les perfs d'aller lire en mémoire vs une DB
- réfléchir au multi step update, et la meilleure façon de corriger les soucis (probablement avec un système d'erreur et de retry tant que c'est pas o, ça semble le plus clean)



to know:
mémoire totale d'un canister 500GiB => 536870912000 bytes
principal = 29 bytes

Type Motoko	    Valeur                  Exemple	Taille Mémoire (Bytes)	Commentaire
Nat	            0 à 127	                1	                            Très compact pour les petits nombres.
Nat	            1 000 (ID standard)	    2	                            Variable.
Nat	            1654654987 (Timestamp)	5	                            Variable.
Nat64	        N'importe quel nombre	8	                            Recommandé pour les IDs/Index.
Bool	        true / false	        1	
Principal	    aaaaa-aa...	            30(29 + 1 taille)               Généralement 29 bytes + 1 byte de taille.
Text	        "Hello"	                5(1 byte/char)
Text	        "Héllo"	                6	                            Le 'é' prend 2 bytes.
Text	        "2000 chars"	        ~2005	                        Comptez en moyenne 1 octet par char latin + quelques bytes de longueur