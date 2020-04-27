# Ares rariteter en må passe på

Husk at det interne nettet 10.10.0.0/16 også må åpnes for port 5432 i tillegg til 157.249.0.0/16 og 10.99.0.0/16 ( utviklingsserverne skal ha lesetilgang ).

# Basis installasjon av databasen

Logg først inn som ubuntu-bruker på serveren der du skal installere databasen, deretter:
```
wget -O installdb https://gitlab.met.no/obs/stinfosys/raw/master/database/installdb
source installdb
```

# 2 Gb system
```
wget -O 2GBsystem https://gitlab.met.no/obs/stinfosys/raw/master/database/2GBsystem
source 2GBsystem
```

# 4 Gb system
```
wget -O 4GBsystem https://gitlab.met.no/obs/stinfosys/raw/master/database/4GBsystem
source 4GBsystem
```

# 8 Gb system
```
wget -O 8GBsystem https://gitlab.met.no/obs/stinfosys/raw/master/database/8GBsystem
source 8GBsystem
```

# Master & arkivering
## ubuntu bruker
```
sudo -u postgres mkdir -pv /var/lib/postgresql/.ssh
sudo cp -pv .ssh/authorized_keys /var/lib/postgresql/.ssh
sudo chown postgres:postgres /var/lib/postgresql/.ssh/authorized_keys 
```

## Først noen tilpasninger som postgres bruker

Logg deg inn som postgres bruker:
```
ssh-keygen -t rsa
cd .ssh
emacs id_rsa.pub
```

Kopier innholdet av denne id_rsa.pub over til target serverne .ssh/authorized_keys, postgres brukeren.

Deretter til slutt:
```
mkdir etc
mkdir log
mkdir bin
cd bin
wget -O set_recovery.sh https://gitlab.met.no/obs/stinfosys/raw/master/database/set_recovery.sh
wget -O set_new.sh https://gitlab.met.no/obs/stinfosys/raw/master/database/set_new.sh
wget -O test_OK_set_recovery.sh https://gitlab.met.no/obs/stinfosys/raw/master/database/test_OK_set_recovery.sh
wget -O test_is_in_recovery.sh https://gitlab.met.no/obs/stinfosys/raw/master/database/test_is_in_recovery.sh
```

## ubuntu bruker

En ting er å arkivere i seg selv, men hovedpoenget her er distribusjon til andre utenfor brannmuren: Sett miljøvariabelen ARCHIVE_COMMAND til hvordan du ønsker at arkiveringen skal være. eks. 
```
ARCHIVE_COMMAND="test ! -f /home/ubuntu/archivedir/%f && rsync -av %p 157.249.177.173:/var/lib/postgresql/9.6/main/pg_xlog/%f && rsync -av %p 157.249.177.28:/var/lib/postgresql/9.6/main/pg_xlog/%f" 
```
```
wget -O archive_base https://gitlab.met.no/obs/stinfosys/raw/master/database/archive_base
source archive_base
cat archive_base
```

max_wal_senders og wal_keep_segments kan det jo kanskje være aktuelt å endre på.
 
```
max_wal_senders = 3		# max number of walsender processes
# 				# (change requires restart)
wal_keep_segments = 
```

## Sikkerhet i forhold til at /var/lib/postgresql/9.6/main/pg_xlog skal svømme over
```
cd /var/lib/postgresql/
mkdir bin
cd bin
wget -O overflow_pg_xlog.sh https://gitlab.met.no/obs/stinfosys/raw/master/database/overflow_pg_xlog.sh
```
Deretter må du putte dette inn som en cronjobb: 
```
10,40 * * * * /var/lib/postgresql/bin/overflow_pg_xlog.sh
```

#Standby server
##ubuntu bruker

For å komme direkte inn som postgres bruker:
```
sudo -u postgres mkdir -pv /var/lib/postgresql/.ssh
sudo cp -pv .ssh/authorized_keys /var/lib/postgresql/.ssh
sudo chown postgres:postgres /var/lib/postgresql/.ssh/authorized_keys 
```
For å modifisere postgresql.conf til standby:
```
wget -O standby_base https://gitlab.met.no/obs/stinfosys/raw/master/database/standby_base
source standby_base
```

## fra egen maskin


Tilgang fra master til $target (dersom id_rsa.pub til master er kopiert først til egen maskin):
```
~/stinfodb_pub$ scp id_rsa.pub postgres@$target:
```

## postgres bruker
```
cat .ssh/authorized_keys  id_rsa.pub > .ssh/authorized_keys2
mv .ssh/authorized_keys2 .ssh/authorized_keys
```
Putt følgende i filen recovery.conf som er i katalogen ~/9.6/main:
```
standby_mode = 'on'
restore_command = 'cp /var/lib/postgresql/9.6/main/pg_xlog/%f %p'
archive_cleanup_command = 'pg_archivecleanup /var/lib/postgresql/9.6/main/pg_xlog %r'
```

# Tilgang
#### Gjør
Sett passord for stinfosys-brukeren:
```
sudo -u postgres psql -c "ALTER USER stinfosys WITH PASSWORD 'Dette skal ikke alle vite'"
```
#### Gjøres en gang per prosjekt
Det holder ikke bare å sette 'listen_addresses' til å lytte på alle i postgresql.conf, vi må også åpne opp porten 5432 til den ( virtuelle ) maskinen dersom ikke dette er gjort i fra før.
På ares.met.no gjøres det slik: Access & Security –> Security Groups –> Manage Rules –> Add Rule
På how.met.no gjøres det slik: Access & Security –> Manage Rules –> Add Rule
( dette gjøres bare en gang per prosjekt og ikke for hver virtuelle maskin en starter ). 

#### Forklaring pg_hba.conf
 Viktige verdier i pg_hba.conf fila er linjer som begynner med host:
kommenterer ut med # første linjen for IPv4 local connections

Legg så til følgende linjer til pg_hba.conf. (Config nedenfor fungerer med PostgreSQL 9.6. Husk å endre navn og dato.): 

```
# Local additions for stinfosys
host    all         stinfosys   127.0.0.1/32     trust
host    all         pstinfosys  127.0.0.1/32     trust
host    all         metapi      157.249.0.0/16   md5
host    all         metapi      10.99.0.0/16     md5
host    all         pstinfosys  157.249.0.0/16   md5
host    all         pstinfosys  10.99.0.0/16     md5
# below is for testing
host    all         stinfosys   10.99.0.0/16     md5
# below is for production
# host    all       stinfosys   157.249.X.Y/32   md5
```

# Test & praktisk tilrettelegging
#### Test
```
sudo -u postgres psql -d stinfosys
\q
```
Tilgang fra egen maskin:
```
psql -h <ipadresse eller navn på maskin i DNS> -d stinfosys -U stinfosys                 
```
Eksempel:
```
psql -h 10.99.X.Y -d stinfosys -U stinfosys
```
Dersom ikke postgresql klienten på din egen maskin er installert:
```
sudo apt-get -y install postgresql-client
```

#### Praktisk tilrettelegging

Det kan være praktisk å ha systembrukeren stinfosys:
```
sudo adduser --disabled-password --gecos "" --home /home/stinfosys stinfosys
```
Emacs er en gammel og kjær editor som det tar tid å installere:
```
sudo apt-get -y install emacs
```

# Bygge opp databasen
## Bygge opp databasen fra annen database
### Bygge opp ved hjelp av direkte kopiering fra annen database
#### Direkte kopiering av eksisterende drifts-database
```
$ pg_dump -h stinfosys.met.no stinfosys > stinfosys-prodb.out
$ psql -d stinfosys -U stinfosys -f stinfosys-prodb.out
```
#### Direkte kopiering av eksisterende test-database
```
$ pg_dump -h <virtuell server> stinfosys > stinfosys-testdb.out
$ psql -d stinfosys -U stinfosys -f stinfosys-testdb.out
```
### Bygge opp databasen fra backup
Backupfila blir generert av en cron-jobb som kjøres jevnlig (se crontab dokumentasjonen nedenfor.)
``` 
$ cd $HOME/db_backup
$ scp stinfosys.<nyeste versjon>.gz 'til kontorpc'
```
Kopierer koden over til annen maskin dersom en ønsker det og tar: 
```
$ gunzip stinfosys.*.gz
```
Dersom en har installert en stinfosys systembruker på databasen og en installerer filen fra databasen:
```
$ sudo -u stinfosys psql -d stinfosys < stinfosys.*
```
I alle andre tilfeller:
```
$ psql -h localhost -d stinfosys -U stinfosys < stinfosys.*
```

## Bygge opp databasen fra schema + innlegging av data
### Installasjon av databaseskjema

Databaseskjema finnes i git.
```
$ wget https://gitlab.met.no/obs/stinfosys/raw/master/database/stinfosys_schema.sql
$ sudo -u postgres psql --dbname=stinfosys -f stinfosys_schema.sql
```
Etter at databaseschema er installert så har en en tom database. Den trenger å fylles med innhold. Da er det 3 situasjoner vi kan stå overfor.

* Dataene skal hentes fra en relasjonsdatabase som har akkurat det samme schema, innkludert med fremmednøkler fullt anvendt. Den andre databasen er den eneste datakilden. I dette tilfellet så kan en likeså godt kopiere hele databasen direkte over. Dette er beskrevet før under overskriften: «Bygge opp ved hjelp av direkte kopiering fra annen database».
*  Dataene skal hentes fra en relasjonsdatabase som har akkurat samme tabellstruktur som den forrige databasen, men databasen som dataene skal hentes i fra mangler fremmednøkler. I tillegg så skal en eller flere av dataene hentes i fra git i stedet for. De dataene må på forhånd sørges for at har riktig tabellstruktur. Dataene som skal hentes fra den andre databasen må hentes for en og en tabell om gangen. Se nedenfor hvordan en dumper enkelttabeller og importerer dem i en relasjonsdatabase med fremmednøkler.
* Dataene hentes i fra vilkårlige konverteringsrutiner fra en annen database. Dette ligger utenfor denne dokumentasjonens virkeområde, vennligst se under konverteringsrutiner.

#### Dump av enkelttabeller + import av data ved hjelp av dbtools
###### Dump av enkelttabeller

Da er det to tabellister det er interessant å forholde seg til:

* Ta utgangspunkt i forholdet mellom de dokumenterte tabellnavnene og de tabellnavnene som finnes i databasen.
```
$ ssh stinfosys@stinfosys-dev
$ cd $HOME/src/terjeer/stinfosys/src/db_tools
$ ./table_list_stinfosys_schema > tablelist_doc 
$ ./tabledumparg.sh hostname tablelist_doc
```
* Den andre er å ta utgangspunkt i de faktiske tabellene som finnes på den databasen en skal hente data i fra. Gå inn på hosten du skal hente data fra og gjør følgende kommando:
```
$ ssh stinfosys@hostname
$ psql  -q -t -c "\dt"|cut -f2 -d\| > tablelist_hostname
$ scp tablelist_hostname stinfosys@stinfosys:~/src/terjeer/stinfosys/src/db_tools
```
```
$ ssh stinfosys@stinfosys
$ cd $HOME/src/terjeer/stinfosys/src/db_tools  
$ ./tabledumparg.sh hostname tablelist_hostname
```

###### Import av data ved hjelp av dbtools

Dataene fra databasen kan importeres for en og en tabell av gangen. Dette må imidlertid gjøres i riktig rekkefølge, der en for tabeller uten fremmednøkler legger inn data først. Filen tablelist_doc er et godt utgangspunkt der, der en begynner ovenfra og ned.
```
$ cd $HOME/src/terjeer/stinfosys/src/db_tools
$ cat README
```
Les spesielt om insert_table.pl som er et script for å legge inn data for en og en tabell om gangen.

###### Sekvenstellerne
```
Etter importen må sekvenstellerne settes:

    $psql
    stinfosys=# select nextval('equipment_nr_seq');
    stinfosys=# select setval('equipment_nr_seq', NNNNN, false);
                                              der NNNNN angir resultatet av forrige sql-kommando
    stinfosys=# select nextval('contract_nr_seq');
    stinfosys=# select setval('contract_nr_seq', NNNNN, false);
    stinfosys=# select nextval('organisationid_list_nr_seq');
    stinfosys=# select setval('organisationid_list_nr_seq', NNNNN, false);
```

# Drift som jevnlig vedlikehold og forebygging
## Basis kommandoer

En må kunne starte og stoppe databaseclusteret:
```
sudo -u postgres pg_ctlcluster 9.6 main start
sudo -u postgres pg_ctlcluster 9.6 main stop
```

## Driftsovervåking/monitorering
#### Driftsovervåking/monitorering vha av cronjob + mail

Cronjobb som monitorerer:
<code>
50 2,13 * * * /home/stinfosys/bin/dbdrift/dbdrift.sh
</code>

Dette består av to typer aktiviteter: 
* følge med på innkommende advarsler på mail, se nedenfor.
* sette opp filteret på sin mailklient til å kunne filtrere mail .
    

Hvilke advarsler gis:

* advarsel når diskplassen igjen er mindre enn 80%
* advarsel at det sannsynligvis er for mange postmastere,\\ dette er et symptom på feil, men som regel er grensen satt for lavt. Systemet må sjekkes \\ om det er korrumpert og om vi står foran en ukontrollert økning i antall postmastere.
* advarsel at det er for få postmastere, databasen er sannsynligvis nede

## Servicerutine
Det er nødvendig at denne cronjobben kjører jevnlig:
<code>
20 17 * * *     $HOME/bin/dbdrift/stinfosys_dbservice_cron
</code>

## Backuprutine
1 cronjobb:
<code>
15 15 * * *     $HOME/bin/db_backup/backup.sh
</code>

# Drift som brannslukking: Databasen har stoppet å fungere eller det går veldig treigt

## Før en legger tilbake backup: Prøv dette
* Er disken full?
* Har service rutinen '/home/stinfosys/bin/stinfosys_dbservice_cron' sluttet å fungere?

### Dersom service rutinen '/home/stinfosys/bin/stinfosys_dbservice_cron' ikke lenger fungerer
* Stopp dataoverføringen til stinfosys
* Prøv å kjøre de enkelte elementene i /home/stinfosys/bin/stinfosys_dbservice_cron langs kommandolinjen

#### Dersom 'FULL VACUUM ANALYZE' ikke fungerer
En har sannsynligvis for lite plass. 

Nå kan en teste om det går
```
$ FULL VACUUM ANALYZE kv2klima
$ FULL VACUUM ANALYZE
```

## Legge tilbake backup som er OK
 Forutsetter at det finnes en tom stinfosys database som er opprettet.

```
$ cd /home/stinfosys/db_backup Finn siste backup ( siste backup er den med dato nærmest nåtiden.)

$ gunzip siste_backup.gz
$ psql stinfosys < siste_backup
```
 eks.
```
$ gunzip stinfosys.2006-08-14.gz 
$ psql stinfosys < stinfosys.2006-08-14
```
Advarsel: Det er ikke alltid siste backup er den riktige å bruke,
se vurderinger av backup nedenfor 

### Vurderinger av backup
Finn siste backup som er OK
Kriterier for OK:
* backupen må være hel.
* siste backup som ikke er mye kraftig mindre/større enn forrige backup.
* backupen hentes fra før tidspunktet som databasen begynte å oppføre seg underlig.

Eksempler på underlig oppførsel eller årsaker til det:
* mange psql demoner genereres tilsynelatende uten grunn.
* disken har gått full.

### Opprydding når disken har gått full eller krasjet ====
Er det fullstenfig diskkrasj må en installere systemet på nytt

Har disken gått full har en 4 valg:

    * Få mere diskplass
    * Slette unødvendige filer, sannsynligvis ikke noe særlig langvarig løsning for vårt system,
      men det kan gi verdifullt pusterom
    * flytte hele systemet til ny maskin/bruker
    * flytte databasen til ny maskin/bruker, husk at der cgi-scriptene er må en endre i fila stinfosys.conf: \\
<code>
$ 'vim eller emacs' $HOME/etc/stinfosys.conf 
</code>
Rediger verdiene i fila stinfosys.conf hvor den nye databasen ligger

# Sette opp filteret på sin mailklient for å overvåke databasen
I motsetning til alt annet øverst så gjøres dette på din egen datamaskin.

### Ny Google mail løsning
Finn tannhjulet øverst i høyre hjørnet, det viser innstillinger nå du plasserer museperen over. Trykk ned og velg 'Innstillinger' fra menyen. Velg deretter filtre og blokkerte adresser. Når man er logget inn som seg selv i mailsystemet så kan en også bare trykke på linken under for å komme til riktig sted: 

https://mail.google.com/mail/u/0/#settings/filters

Deretter så er det bare søkekriteriet som er viktig:
<code>
from:Cron subject:(minpost.pl OR dbdrift.sh OR backup)
</code>

Gir det for mye annet så kan en prøve dette:
<code>
from:'Cron <stinfosys@stinfosys>' subject:(minpost.pl OR dbdrift.sh OR backup)
</code>

# Export av databasen

Spesielt gjennom en brannmur til en ekstern verden kan ting bli vanskelig.
#### Dette utføres på stinfosys master databasen

Det finnes et script som eksporterer til en ekstern verden og som kan konfigureres: Dette er avhengig av å kunne sende mail til web for å se om det går bra.
```
sudo apt-get install mailutils
```
Deretter:
```
sudo -u postgres -i
ssh-keygen # Press "ENTER" to all of the prompts that follow.
mkdir bin etc log
cd bin
wget -O distribute_stinfosys_rsync.sh https://gitlab.met.no/obs/stinfosys/raw/master/database/distribute_stinfosys_rsync.sh
head -n 25 distribute_stinfosys_rsync.sh
cd $HOME/etc
```
EDIT the conf files distribute_stinfosys_rsync.conf_staging and distribute_stinfosys_rsync.conf_prod

EDIT the «crontab -e» for running distribute_stinfosys_rsync.sh as two cronjobs.
#### Dette utføres på kopi/slave databasen
```
sudo -u postgres -i
mkdir -m 700 .ssh
cd .ssh
EDITOR authorized_keys
```

# Annet/videre lesning
## Ytelses konfigurering
### System ressurser for shared memory

 Postgreql bruker shared memory for å cache data. Default oppsettet i linux er for lite og må økes. Fra http://www.postgresql.org/docs/9.6/static/runtime-config-resource.html «a reasonable starting value for shared_buffers is 25% of the memory in your system».

Men for at dette skal skje må også hardware ressursene økes til 25% ( http://www.postgresql.org/docs/9.6/static/kernel-resources.html ). Nedenfor er en oversikt over endringer som trenger å gjøres for maskiner med forskjellig minne.

For de systemene vi ser på så spiller kernel.shmall liten rolle ( default verdien tilsvarer 8 Gb ). Derfor er det bare kernel.shmmax som må oppdateres i filen /etc/sysctl.d/30-postgresql-shm.conf:

Problemet er at denne matematikken med forholdet mellom det vi putter i kernel.shmmax og verdien til shared_buffers i praksis ikke stemmer 1 til 1. kernel.shmmax ( i byte ) må da være litt større enn verdien vi velger for shared_buffers, eks. for det tilfallet 2 Gb har vi et eksempel fra et virkelig tilfelle.

I nyere systemer ser det ut til at defaultverdien er satt høyt nok for shmmax og shmall slik at dette er ikke noe en trenger å gjøre noe i forhold til lenger, men en bør allikevel sjekke om denne verdien er satt til å være veldig høy:
``` 
sysctl -a | grep kernel.shm
```
### Memory er 16 Gb
``` 
I praksis krav:
kernel.shmmax = 4418265088
``` 

Denne verdien vil ikke få effekt før neste rebooting av systemet, så for at oppdateringen skal tre i kraft umiddelbart utfør kommandoen:
``` 
sysctl -w kernel.shmmax="Min verdi"
``` 
For å sjekke om alt er i orden så kan man gjøre det med:
``` 
sysctl -a | grep kernel.shm
``` 

#### postgresql.conf

Gå til riktig katalog der konfigurasjonsfilene er:
```
cd /etc/postgresql/9.6/main
```
Endre til brukeren postgres:
```
sudo -u postgres -s
```
To tiltak kan gjøres som er uavhengig av hvor mye minne en har:
Gjør
```
sed -i.bak 's/^\(max_connections =\).*/\1 80/' postgresql.conf
sed -i.bak 's/^#log_min_duration_statement =.*/log_min_duration_statement = 1000      # -1 is disabled, 0 logs all statements/' postgresql.conf
grep max_connections postgresql.conf
grep log_min_duration_statement postgresql.conf
```
#### Forklaring

* Reduser antall brukere som kan ha samtidig tilgang til systemet:

max_connections = 80

* Loggfør spørringer som tar mye tid for å se om noen er feil

``` 
log_min_duration_statement = 1000	# -1 is disabled, 0 logs all statements
```

#### Tiltak som kan gjøres som er avhengig av hvor mye minne en har:

Har man mere minne så kan disse størrelsene tilsvarende økes.
#### 8 Gb system
```
sed -i.bak 's/^shared_buffers =.*/shared_buffers = 2GB			# min 128kB/' postgresql.conf
sed -i.bak 's/^#work_mem =.*/work_mem = 16MB        # min 64kB/' postgresql.conf
grep shared_buffers postgresql.conf
grep work_mem postgresql.conf
```

#### 16 Gb system
```
sed -i.bak 's/^shared_buffers =.*/shared_buffers = 4GB			# min 128kB/' postgresql.conf
sed -i.bak 's/^#work_mem =.*/work_mem = 32MB        # min 64kB/' postgresql.conf
grep shared_buffers postgresql.conf
grep work_mem postgresql.conf
```

#### En må stoppe og starte databaseclusteret for at endringer i postgresql.conf skal tre i kraft:
```
pg_ctlcluster 9.6 main stop
pg_ctlcluster 9.6 main start
```

#### Variabler som er minne avhengige og som settes automatisk
```
maintenance_work_mem
effective_cache_size
```

# Debian-måten å administrere databasen på

* /usr/share/doc/postgresql-common/README.Debian.gz
* /usr/share/doc/postgresql-9.6/README.Debian.gz


som følger med installasjon av Debian-pakkene postgresql-common og postgresql-9.6.

Full disk og andre krasjsituasjoner gjør at denne ikke lenger kjører og en må inn med manuell inngripen. 
