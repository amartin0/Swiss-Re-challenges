## Challenge 3

### Addedd 

server/scripts/certificate.py -> get a custome certificate using secret and ID of a  Service Principal  
server/scripts/configure-apache-ssl.sh -> configure apache as Mozilla Intermediate Cipher Suite Configuration  
server/scripts/disk1.bash -> format a disk and migrate /var/www/html data  
server/scripts/get-secrets.py -> get secret and ID of a  Service Principal for the python script server/scripts/certificate.py  
server/scripts/update-apache-certs.sh -> update the certificate of the web server  

### Modified

Asign User-Assigned Managed Identity to the server and a independent disk.    
server/server.json   
server/server-params.json  

Configure the server and the apache with the new requisites.  
server/cloud-init.yaml  

## Challenge 2

### Added

server/cloud-init.yaml -> cloud-init to configure apache in the webserver.  

### Modified

Add NAT firewall rules  
network/firewall.json  
network/firewall-params.json  

Add cloud-init during the start of the server.  
server/server.json  
server/server-params.json  


## Challenge 1

### Added

network/bastion.json  
network/bastion-params.json  
network/firewall.json  
network/firewall-params.json  
network/udr.json  
network/udr-params.json  
network/vnet.json  
network/vnet-params.json  
server/server.json  
server/server-params.json  
rg/rg.json  
rg/rg-params.json  




