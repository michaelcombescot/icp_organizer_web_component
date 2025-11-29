- avant toute chose, réfléchir à comment gérer une liste ou associé pour pouvoir avoir les helpers de contact d'api gérer eux mêmes le pop d'erreur => MAP ?
- faire l'index et le modèle de données.
- index => check que le recup free bucket est clean



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