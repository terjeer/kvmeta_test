# Fjerne gamle linux-image
### Install byobu
```
sudo apt-get install byobu
```
### Run periodically
```
purge-old-kernels --keep 3
```

# Fiks ntp timeoffset
https://vitux.com/how-to-install-ntp-server-and-client-on-ubuntu/

### Utfør følgende kommandoer
```
sudo apt-get install ntpdate
sudo ntpdate-debian 
sudo ntpdate ntp.met.no
sudo apt-get install ntp
```

### Editer /etc/ntp.conf
linjene som starter med pool skal fjernes/utkommenteres.\\
Legg til nederst i filen linjene:

```
server ntp1.met.no iburst
server ntp2.met.no iburst
```
  
### Utfør
```
sudo service ntp restart
```

# Dersom du skal ha et produksjonsystem så trenger du å bruke mail, for utvikling/test bør denne ikke utføres
```
sudo apt-get update
sudo apt-get install ssmtp
sudo apt-get install mailutils
```
 
/etc/ssmtp/ssmtp.conf skal redigeres til følgende: 

```
#
# Config file for sSMTP sendmail
#
# The person who gets all mail for userids < 1000
# Make this empty to disable rewriting.
root=terjeer@met.no

# The place where the mail goes. The actual machine name is required no 
# MX records are consulted. Commonly mailhosts are named mail.domain.com
mailhub=smtp.met.no

# Where will the mail seem to come from?
rewriteDomain=stinfocron18.met.no

# The full hostname
hostname=stinfocron18

# Are users allowed to set their own From: address?
# YES - Allow the user to specify their own From: address
# NO - Use the system generated From: address
#FromLineOverride=YES
```

### Dette må testes at det virker og sender mail før en går videre 
  echo "test" | mail -s "test-stinfocron18-mail" $myuser@met.no
### Som regel så trenger en ikke å kunne sende mail i fra utviklings/testmaskiner

# Manglende locales
Får du feilmelding om at det mangler "locales" på den virtuell maskin, så er det for at terminalvinduet ditt tar med seg innstillingene du har på din bærbar eller stasjonære. Rett dette med å generere de locales som mangler på den virtuelle maskinen:
```
apt-get install language-pack-nb-base
locale-gen nb_NO.UTF-8
dpkg-reconfigure locales
```

For å få generert riktig lokale, spesielt dersom en ønsker noe annet enn UTF-8, så må en legge til lokalene i filen /etc/default/locale og logge ut/inn eks.
<code>
LANG="nb_NO.UTF-8"
LC_CTYPE="nb_NO.UTF-8"
LANGUAGE="nb_NO.UTF-8"
LC_ALL="nb_NO.UTF-8"
</code>

# resolv.conf & "How do I configure the search domain correctly?"

edit /etc/systemd/resolved.conf , option Domains= according to docs and then restart systemd-resolved:
```
service systemd-resolved restart
```
https://www.freedesktop.org/software/systemd/man/resolved.conf.html

# SSL & TSL
https://docs.google.com/presentation/d/1WYlke7zNoQ9gjJp3Vcs4hOnecqf2IRg6L8y0Wh2VO2g/edit#slide=id.p17

https://www.digicert.com/csr-ssl-installation/apache-openssl.htm#ssl_certificate_install

https://linuxpropaganda.wordpress.com/2018/07/06/enable-ssl-for-apache2-in-ubuntu-server-18-04/

Etter at man har gjort det grunnleggende og bestilt sertificat får en tilsendt en mail med sertifikat som en downloader, deretter kopierer en denne zip filen til stinfosys_ssl på sin egen maskin. En unzipper og kopierer de 2 aktullle *.crt filene til ubuntu@host.

En logger seg inn på ubuntu@host og har ( i alle fall ) disse filene liggende under /home/ubuntu, her for bionic:
```
DigiCertCA.crt
server.csr
server.key
stinfosys-bionic_met_no.crt
```

Deretter gjør man følgende:
```
sudo chown root:root stinfosys-bionic_met_no.crt DigiCertCA.crt
sudo chmod 0600 stinfosys-bionic_met_no.crt DigiCertCA.crt
sudo mkdir -pv /etc/ssl/stinfosys/
sudo mv server.key /etc/ssl/stinfosys/stinfosys-bionic.met.no.key
sudo mv stinfosys-bionic_met_no.crt DigiCertCA.crt /etc/ssl/stinfosys/
```

Da blir det seendes slik ut:
```
ubuntu@stinfosys-bionic:/etc/ssl/stinfosys$ ls -1
DigiCertCA.crt
stinfosys-bionic_met_no.crt
stinfosys-bionic.met.no.key
```

# Montere stinfosys-lustre-nfs
```
sudo sh -c "echo 'lustre-int-gw-b.met.no:/lustre/storeB/project/met-obs/stinfosys   /vol/stinfosys-lustre-nfs    nfs   _netdev,rw,nolock,hard,rsize=32768,intr,udp,vers=3' >> /etc/fstab"
sudo mkdir -pv /vol/stinfosys-lustre-nfs
sudo mount  /vol/stinfosys-lustre-nfs
sudo ln -s /vol/stinfosys-lustre-nfs /vol/stinfosys
```

# Pakker som må være installert

Følgende Debian pakker være installert på systemet før vi setter i gang med oppsett av databasen.
```
sudo apt update
sudo apt install -y cron
sudo apt install -y nfs-common
sudo apt install -y make git apache2
sudo apt install -y libapache2-mod-authnz-external
sudo apt install -y libtemplate-perl
sudo apt install -y libdbd-pg-perl libdbi-perl
sudo apt install -y ldap-utils
sudo apt install -y postgresql-client-common
sudo apt install -y postgresql-client-10
sudo apt install -y libdate-calc-perl
sudo apt install -y libgeo-coordinates-utm-perl
sudo apt install -y perlmagick
sudo apt install -y libgl1-mesa-glx
sudo apt install -y host vim gedit emacs less
# sudo apt install -y libapache2-modssl
sudo apt install -y libwww-perl
sudo apt install -y libcgi-pm-perl
sudo apt install -y python3-pandas
sudo apt install -y python3-psycopg2
```

Disse pakkene kan være kjekt å ha:
```
sudo apt install libc6-dev gcc-4.6-locales gcc-4.6-doc gcc doc-base glibc-doc manpages-dev
sudo apt install libfile-which-perl libyaml-perl libfile-homedir-perl libdigest-sha-perl libmodule-install-perl
```

### Opprette stinfosys bruker 
#### Gjør:
sudo adduser --disabled-password --gecos "" --home /home/stinfosys stinfosys

#### Gammelt oppsett

Systemet må installeres under en /metno/stinfosys bruker.
```
$ ssh root@stinfosys

# mkdir /metno/
# adduser --home /metno/stinfosys stinfosys
```

Dersom en gjør den feilen å generere katalogen først:
```
# mkdir -pv /metno/stinfosys
```
Da må en reparere dette med å skrive:
```
# chown -R stinfosys:stinfosys
```

### Felles for produksjon og utvikling som ubuntu bruker 
```
sudo -u stinfosys mkdir /home/stinfosys/.ssh 
sudo -u stinfosys chmod 0700 /home/stinfosys/.ssh
sudo cp -pv /home/ubuntu/.ssh/authorized_keys /home/stinfosys/.ssh
sudo chown stinfosys:stinfosys /home/stinfosys/.ssh/authorized_keys
```

### Produksjon

ssh -Y stinfosys@host
```
mkdir -p $HOME/src/
cd $HOME/src
git clone https://gitlab.met.no/obs/stinfosys.git
# Til slutt må en installere systemet:
cd stinfosys
./INSTALL.main
```

### Utvikling
Hovedforskjellen mellom produksjon og utvikling er at vi trenger skrivetilgang til gitlab, vi skal levere kode tilbake.
Forutsetningen for god arbeidsflyt er at stinfosys brukeren har public key for å kunne utvikle derifra.

Dette gjør at vi kan komme rett inn som stinfosys bruker:
```
ssh -YA stinfosys@157.249.169.137
```
  
Vi oppretter en egen katalog per bruker, og sjekker ut fra git i denne.
#### Stinfosys bruker på testserveren
Sett variabelen myuser:
```
  myuser=<myuser>
```

Deretter utfør:
```
mkdir -p $HOME/src/$myuser
cd $HOME/src/$myuser
git clone git@gitlab.met.no:obs/stinfosys.git
# Til slutt må en installere systemet:
cd stinfosys
./INSTALL.main
```

På egen maskin er det også mulig å konfigurere ssh.
#### Gjør på egen maskin
```
cd .ssh
emacs config ( tilsvarende eksempelet under )
```

Et eksempel på dette er under:

```
~/.ssh$ cat config
Host stinfosys-new
  Hostname 10.99.XX.YY
  User ubuntu
  ForwardAgent yes

Host stinfosys-dev
  Hostname 10.99.XX.YY
  User stinfosys
  ForwardAgent yes
```

Dette gjør at vi kan komme rett inn som stinfosys bruker på en mere korfattet og menneskelig måte:
```
ssh -Y stinfosys-dev
```

# Miljøvariabler: Hvordan det er håndtert

### Gjør Felles: 
Er inne som stinfosys bruker:
```
ssh -Y stinfosys@stinfosys
```
  
### Variabelverdier settes 
```
PGHOST=<myhost>
```

### Opprette kataloger
```  
mkdir -pv $HOME/etc
```

### .bashrc
```
  # Miljøvariabler til databasen
  echo "export PGHOST='${PGHOST}'" >> /home/stinfosys/.bashrc
  echo -e "if [ -e ${HOME}/etc/xstinfosys.conf ]; then \n   source ${HOME}/etc/xstinfosys.conf\nelse\n   echo "FATAL: Kan ikke finne ${HOME}/etc/xstinfosys.conf" \nfi"    >> .bashrc
  tail /home/stinfosys/.bashrc
  cp -pv $GIT/etc/xstinfosys.conf $HOME/etc
  source .bashrc
```

### produksjon
```
  PGPASSWD=<mypasswd>
  GIT=$HOME/src/stinfosys
  cp -pv $GIT/etc/stinfosys.conf.drift $HOME/etc/stinfosys.conf
  sed -i.bak "s/^PGPASSWD=.*/PGPASSWD=$PGPASSWD/" $HOME/etc/stinfosys.conf
```

### test
```
  IPHOST=<10.99.XX.YY>
```
Test om variabelen myuser er satt:
```
  echo $myuser  
```
  
Dersom ikke satt:
```
  myuser=<myuser>

  GIT=$HOME/src/$myuser/stinfosys
  cp -pv $GIT/etc/stinfosys.conf.template_dev-vm $HOME/etc/stinfosys.conf
  sed -i.bak "s/IPHOST/$IPHOST/" $HOME/etc/stinfosys.conf
```

### Gjør Felles: sett PGHOST i stinfosys.conf
```
sed -i.bak "s/^PGHOST=.*/PGHOST=$PGHOST/" $HOME/etc/stinfosys.conf
```

### Forklaring
#### .bashrc
Miljøvariabler settes i .bashrc fila.

## Koden nedenfor brukes i shell script
==================================8<--------------------------\\
```
if [ -e ${HOME}/etc/xstinfosys.conf ]; then 
   source ${HOME}/etc/xstinfosys.conf \\ 
else
   echo "FATAL: Kan ikke finne ${HOME}/etc/xstinfosys.conf"
fi 
```
-------------------->8========================================\\

# Oppdatere cron-tabellen til å håndtere serviceskript for drift av databasen og noe produktgenerering
### Gjør:
```
cd $GIT/crontab
crontab crontab.drift
```

# Oppsett av Apache2 webserveren
### stinfosys bruker:
#### Drift
```
cp $GIT/etc/stinfosys-apache.conf.drift $HOME/etc/stinfosys-apache.conf
```

#### Utvikling
```
cp $GIT/etc/stinfosys-apache.conf.test $HOME/etc/stinfosys-apache.conf
```

#### Eldre kode
#### For utvikling må de øverste variablene i filen $HOME/etc/stinfosys-apache.conf endres

##### Enten editere filen $HOME/etc/stinfosys-apache.conf og endre variablene ServerAdmin 
```
$EDITOR $HOME/etc/stinfosys-apache.conf
```
##### Eller følge oppsettet nedenfor  
Man kan editere disse variablene ServerAdmin og ServerAlias til noe annet, men en kan også beholde de:
```   
ServerAdmin=stinfosys-dev@met.no
```
  
Deretter utfør:
``` 
sed -i.bak "s/ServerAdmin=.*/ServerAdmin=$ServerAdmin/" $HOME/etc/stinfosys-apache.conf
```

#### Gjør som root bruker:
```
a2enmod ssl headers
a2dissite 000-default
cp -pv  /home/stinfosys/etc/stinfosys-apache.conf /etc/apache2/sites-available/
a2ensite stinfosys-apache.conf
a2enmod ldap
a2enmod authnz_ldap
# systemctl status apache2.service
a2dismod mpm_event
a2enmod mpm_prefork
a2enmod cgi
service apache2 restart
```

#### DNS
For drift så må aliaset stinfosys være på plass i DNS; \\
for utvikling så må aliaset stinfosys-test være på plass.

Dersom stinfosys-test midlertidig ikke skulle finnes i DNS så kan en gjøre et lokalt hack:\\ 
På ens egen arbeidsstasjon legg inn følgende i /etc/hosts:
```
  <ip-adresse-til-utviklingsserver>	stinfosys-test
```

### Ikke virtual host oppsett 
root bruker: 
```
  # cd /etc/apache2/conf.d
  # ln -s /home/stinfosys/etc/stinfosys-apache.conf
  # $EDITOR /etc/apache2/httpd.conf
```

Legg til følgende linje:
=======================8<---------------
```
Include conf.d
```
-------------------->8==================


* Sørg for at katalogen sites-enabled er tom.

### Test om Apache2 oppsettet virker
Deretter tester en at Apache2 oppsettet vårt virker og restarter

root bruker:
```
# /usr/sbin/apache2ctl configtest
# /usr/sbin/apache2ctl restart
```

Husk å restarte Apache2 hver gang en har gjort en endring i konfigurasjonen.

Dersom noe allikevel skulle gå galt så kan en få feilmelding i fra /var/log/apache2/stinfosys-dev-error.log:
```
tail -f /var/log/apache2/stinfosys-dev-error.log
```

### Forklaring  
Apache må settes opp til å lese fila stinfosys-apache.conf:
* Sørg for at apache-modulene mod_ldap.so og mod_authnz_ldap.so er aktivert. (Se i /etc/apache2/mods-enabled/)


# Oppsett av Tomcat
```
  # sudo apt-cache search tomcat9 
  # sudo apt-get install tomcat9 tomcat9-admin
```
  
rediger filen /etc/default/tomcat9 slik at TOMCAT_SECURITY settes til "no".

rediger /var/lib/tomcat9/conf/tomcat-users.xml for å legge til en administrator:

<user username="admin" password="admin" roles="admin,manager"/>

Kommando for at tomcat skal starte ved omstart av maskinen:
```
   # update-rc.d tomcat9 defaults 
```

Apache brukes som proxy for Tomcat (dette var det enkleste) for å skjule for bruker at det er to
forskjellige applikasjoner som leverer tjenester.

Jeg har gjort dette ved å opprette filen /etc/apache2/mods-enabled/tomcat-passthrough.conf og å
skrive følgende i den:

```
# start of proxy conf for tomcat
###
#
# load proxy modules
LoadModule proxy_module /usr/lib/apache2/modules/mod_proxy.so
LoadModule proxy_http_module /usr/lib/apache2/modules/mod_proxy_http.so

# proxy for tomcat homepage
ProxyPass /tomcat/ http://localhost:8180/
ProxyPassReverse /tomcat/ http://localhost:8180/
ProxyPass /tomcat http://localhost:8180/
ProxyPassReverse /tomcat http://localhost:8180/

# proxy for rettinn
ProxyPass /rettinn/ http://localhost:8180/rettinn/
ProxyPassReverse /rettinn/ http://localhost:8180/rettinn/
ProxyPass /rettinn http://localhost:8180/rettinn/
ProxyPassReverse /rettinn http://localhost:8180/rettinn/
#
###
# end of proxy conf for tomcat
```

De dobbelte oppføringene skyldes at det skilles mellom
http://<server>/<applikasjon>  og
http://<server>/<applikasjon>/

Deretter kjører du kommandoen "sudo /etc/init.d/apache2 reload" for å laste ny konfigurasjon.


# Filarkiv
Legg merke til at pathen til katalogen station_info må være i overenstemmelse med det som er definert i filen
/metno/stinfosys/etc/stinfosys.conf
```
ST_station_info=/metno/stinfosys/share/metadata/station_info
ST_url_station_info=http://stinfosys/station_info
```

# Logging til fil
GUI-ene baserer seg på logging til fil, web-brukeren trenger skriverettigheter til denne katalogen der logfilene skrives til:
```
$ mkdir -p /metno/stinfosys/var/log/history
$ chmod a+w /metno/stinfosys/var/log/history
``` 