# Teaching-HEIGVD-RES-2018-Labo-HTTPInfra



## Step 1: Static HTTP server with apache httpd

**<u>To test the implementation :</u>** 

1. Clone the repo (pull fb-apache-static branch)
2. run /docker-images/start.sh
3. <docker ip>: 9090/     in the browser

Template used : https://startbootstrap.com/themes/grayscale/

**<u>Script for the test:</u>** 

```bash
echo "########### Kill all containers... ###########"
docker kill $(docker ps -qa)
echo " "

echo "########### Remove all container... ###########"
docker rm $(docker ps -qa)
echo " "

echo "########### Build apache_static ########### "
docker build -t res/apache_static ./apache-php-image/
echo " "

echo "########### Run apache_static container ###########"
docker run -d -p 9090:80 --name apache_static res/apache_static
```



<u>**Dockerfile for the static server :**</u>

```dockerfile
FROM php:7.3-apache
COPY content/ /var/www/html
```



## Step 2: Dynamic HTTP server with express.js

**<u>To test the implementation :</u>** 

1. Clone the repo (pull fb-express-dynamic branch)
2. run /docker-images/start.sh
3. <docker ip>: 9090/     in the browser for the static page
4. <docker ip>: 9091/     in the browser for the dynamic page

**<u>Script for the test:</u>** 

```bash
echo "########### Kill all containers... ###########"
docker kill $(docker ps -qa)
echo " "

echo "########### Remove all container... ###########"
docker rm $(docker ps -qa)
echo " "

echo "########### Build apache_static ########### "
docker build -t res/apache_static ./apache-php-image/
echo " "

echo "########### Build express_dynamic ########### "
docker build -t res/express_students ./express-image/
echo " "

echo "########### Run apache_static container ###########"
docker run -d -p 9090:80 --name apache_static res/apache_static
echo " "

echo "########### Run express_students ###########"
docker run -d -p 9091:3000 --name express_dynamic res/express_students
```



<u>**Dockerfile for dynamic server:**</u>

```dockerfile
FROM node:10.16

COPY src /opt/app

CMD ["node", "/opt/app/index.js"]
```



<u>**Generation of random students**</u>

```js
var Chance = require('chance');
var chance = new Chance(); 

var express = require('express');
var app = express(); 

app.get('/test', function(req, res){
	res.send("Hello RES - test is working");
});

app.get('/', function(req, res){
	res.send(generateStudents());
});

app.listen(3000, function(){
	console.log('Accepting HTTP requests on port 3000.');
});

function generateStudents(){
	var numberOfStudents = chance.integer({
		min : 0,
		max : 10
	});
	
	console.log(numberOfStudents);
	
	var Students = [];
	
	for(var i = 0; i < numberOfStudents; ++i){
        var gender = chance.gender();
		Students.push({
            
            firstName   : chance.first({ gender: gender }),
            lastName    : chance.last(),
            gender 		: gender,
			birthday	: chance.birthday({year : chance.year({min : 1980,max : 2000})} )
		});
	}
	console.log(Students);
	return Students;
}
```



## Step 3: Reverse proxy with apache (static configuration)

**<u>To test the implementation :</u>** 

1. Clone the repo (pull fb-apache-static branch)
2. run /docker-images/start.sh
3. Do a DNS resolution to access the docker's entrance with demo.res.ch or use <docker ip address> instead.
4. docker.demo.ch:8080/     in the browser to get the static page
5. docker.demo.ch:8080/api/students/    in the browser to get the dynamic page



The static configuration is bad because docker give dynamically  ip address. So, every time we lunch the dockers containers, we need to configure the proxy. In our case, since docker more or less always give the addresses in the same way, we use this fact running the different containers in a specific order to make our script work correctly.
So in this step, we need to clean all the existing containers to get the ip address we want for our configuration. 
Obviously we need it to be change later on.

In this part, we need to configure a .conf file that we saw it was located in /etc/apache2/conf/sites-available. "000-default.conf" was already here and we want to create our own configuration called "001-reverse-proxy.conf".

Any of the static and dynamic server can be reached directly because the only "frontline" we have in this implementation is the reverse proxy (mapped on 8080) and this container is the link to both servers.
The proxy is the only way to get an access to them.

**<u>Script for the test:</u>** 

```bash
echo "########### Kill all containers... ###########"
docker kill $(docker ps -qa)
echo " "

echo "########### Remove all container... ###########"
docker rm $(docker ps -qa)
echo " "

echo "########### Build apache_static ########### "
docker build -t res/apache_static ./apache-php-image/
echo " "

echo "########### Build apache_rp ###########"
docker build -t res/apache_rp ./apache-reverse-proxy/
echo " "

echo "########### Build express_dynamic ########### "
docker build -t res/express_students ./express-image/
echo " "

echo "########### Run apache_static container ###########"
docker run -d res/apache_static
echo " "

echo "########### Run express_students ###########"
docker run -d res/express_students
echo " "

echo "########### Run apache_rp ###########"
docker run -d -p 8080:80 --name apache_rp res/apache_rp
```



**<u>001-reverse-proxy.conf :</u>** 

```bash
<VirtualHost *:80>
	ServerName demo.res.ch

	ProxyPass "/api/students/" "http://172.17.0.3:3000/"
	ProxyPassReverse "/api/students/" "http://172.17.0.3:3000/"

	ProxyPass "/" "http://172.17.0.2:80/"
    ProxyPassReverse "/" "http://172.17.0.2:80/"
</VirtualHost>
```

We can see here how we mapped both contents.

<u>**Dockerfile for the reverse proxy :**</u>

```dockerfile
FROM php:7.3-apache

COPY conf/ /etc/apache2

RUN a2enmod proxy proxy_http
RUN a2ensite 000-* 001-*
```

We use the same image used for the static server created in part 1, but we need to copy the configuration at the right location.

We also did a DNS resolution to access the docker entrance with demo.res.ch. It was a bit tricky to do it on windows but with some internet researches, we found how to get the job done.



## Step 4: AJAX requests with JQuery

**<u>To test the implementation :</u>**

1. Clone the repo (pull fb-ajax-jquery2 branch)

2. run /docker-images/start.sh

3. Do a DNS resolution to access the docker's entrance with demo.res.ch or use <docker ip address> instead.

4. docker.demo.ch:8080/     in the browser to get the static page and see how the names change regulary

    

The goal of this step is to link our static and dynamic content. We will use AJAX requests with JQuery to do so. It will dynamically refresh the static content with the  payload received from the dynamic server at a fixed rate. 

We will use an AJAX request made with the JQuery library to retrieve content from the backend API and change the header text.

The script for testing this part didn't change since the previous step.

<u>**Add link to the script in the index.html of static server :**</u>

```html
  <script src="js/students.js"></script>
```

We added this at the end of the file to link it.

**<u>students.js</u>**

```js
$(function(){
        console.log("loading students");
        function loadStudents() {
                $.getJSON("/api/students/", function(students){
                        console.log(students);
                        var message = "Nobody is here";
                        if(students.length > 0) {
                                message = students[0].firstName + " " + students[0].lastName;
                        }
                        $(".text-white-50").text(message);
                });
        };

        loadStudents();
        setInterval(loadStudents, 2000);
});
```

This file will call the random generation of students and will display the first one generated on the static page. It will be refreshed every 2 seconds and we'll get a new student to display.



## Step 5: Dynamic reverse proxy configuration

**<u>To test the implementation :</u>**

1. Clone the repo (pull fb-dynamic-configuration branch)
2. run /docker-images/start.sh
3. Do a DNS resolution to access the docker's entrance with demo.res.ch or use <docker ip address> instead.
4. docker.demo.ch:8080/     in the browser to get the static page and see how the names change regulary
5. docker.demo.ch:8080/api/students    in the browser to get the dynamic page



In this step, we will get rid of the the reverse proxy static configuration. The goal is to have a way to launch the containers in the order we want and having a working reverse proxy without needing to rebuild the image.

<u>**Script for the test:**</u>

```bash
echo "### Kill all containers..."
docker kill $(docker ps -qa)
echo " "

echo "### Remove all container..."
docker rm $(docker ps -qa)
echo " "

echo "### Build apache_static"
docker build -t res/apache_static ./apache-php-image/
echo " "

echo "### Build express_dynamic"
docker build -t res/express_students ./express-image/
echo " "

echo "### Build apache_rp"
docker build -t res/apache_rp ./apache-reverse-proxy/
echo " "

echo "### Run apache_static container"
docker run -d --name apache_static res/apache_static
echo " "

echo "### Run express_dynamic"
docker run -d --name express_students res/express_students
echo " "

echo "### Run apache_rp"
docker run -d -p 8080:80 -e STATIC_APP=172.17.0.2:80 -e DYNAMIC_APP=172.17.0.3:3000 --name apache_rp res/apache_rp
echo " "

echo "### check ip apache_static container (should be 172.17.0.2)"
docker inspect apache_static | grep -i ipaddress
echo " "

echo "### check ip express_dynamic conatiner (should be 172.17.0.3)"
docker inspect express_students | grep -i ipaddress
```



**<u>apache2-foreground</u>**

```bash
# Add setup for RES lab
echo "Setup for the RES lab..."
echo "Static app URL: $STATIC_APP"
echo "Dynamic app URL : $DYNAMIC_APP"

php /var/apache2/templates/config-template.php > /etc/apache2/sites-available/001-reverse-proxy.conf
```

We learn on the webcast that we can use event variable inside the container with the -e option.
So we modified the foreground file like this.

Then we create a new configuration file to use a dynamic proxy that will get the ip and port for it.

**<u>config-template.php</u>**

```php
<?php 
	$dynamic_app = getenv('DYNAMIC_APP');
	$static_app = getenv('STATIC_APP');
?>
<VirtualHost *:80>
	ServerName demo.res.ch

	ProxyPass '/api/students/' 'http://<?php print "$dynamic_app"?>/'
	ProxyPassReverse '/api/students/' 'http://<?php print "$dynamic_app"?>/'

	ProxyPass '/' 'http://<?php print "$static_app"?>/'
    ProxyPassReverse '/' 'http://<?php print "$static_app"?>/'
</VirtualHost>
```



<u>**Dockerfile**</u>

```dockerfile
FROM php:7.3-apache

RUN apt-get update && \
	apt-get install -y vim

COPY apache2-foreground /usr/local/bin
COPY templates /var/apache2/templates
COPY conf/ /etc/apache2

RUN a2enmod proxy proxy_http
RUN a2ensite 000-* 001-*
```

Here we have the modified Dockerfile to copy these files and make it work properly.



## Additional steps to get extra points on top of the "base" grade

### Load balancing: multiple server nodes (0.5pt)

**<u>To test the implementation :</u>**

1. Clone the repo (pull fb-load-balancing branch)

2. run /docker-images/start.sh

3. Do a DNS resolution to access the docker's entrance with demo.res.ch or use <docker ip address> instead.

4. docker.demo.ch:8080/     in the browser to get the static page and see how the names change regulary

5. docker.demo.ch:8080/api/students    in the browser to get the dynamic page

6. delete 1 of both containers that is used in the cluster

7. do 4 and 5 again

8. delete the 2nd used container

9. do 4 and 5 and see it's not working anymore

    

For this part : <https://httpd.apache.org/docs/2.4/fr/mod/mod_proxy_balancer.html>

<u>**Dockerfile of the reverse proxy :**</u>

```dockerfile
RUN a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests status
```

- **<u>proxy_balancer</u>**: use the load balancer
- **<u>lbmethod_byrequests</u>**: balances the charge. 
- **<u>status</u>**: admin interface

To use the balance system, we need 2 servers of both (static and dynamic) so we modify the script

<u>**Script for testing : **</u>

```bash
echo "########### Kill all containers... ###########"
docker kill $(docker ps -qa)
echo " "

echo "########### Remove all container... ###########"
docker rm $(docker ps -qa)
echo " "

echo "########### Build apache_static ########### "
docker build -t res/apache_static ./apache-php-image/
echo " "

echo "########### Build express_dynamic ########### "
docker build -t res/express_students ./express-image/
echo " "

echo "########### Build apache_rp ###########"
docker build -t res/apache_rp ./apache-reverse-proxy/
echo " "

echo "########### Run apache_static container ###########"
docker run -d res/apache_php #useless
docker run -d res/apache_php #useless
docker run -d --name apache_static1 res/apache_php
docker run -d --name apache_static2 res/apache_php
echo " "

echo "########### Run express_students ###########"
docker run -d res/express_students #useless
docker run -d res/express_students #useless
docker run -d --name express_dynamic1 res/express_students
docker run -d --name express_dynamic2 res/express_students

echo " "

echo "########### Run apache_rp ###########"
static_app1=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' apache_static1`
static_app2=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' apache_static2`
dynamic_app1=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' express_dynamic1`
dynamic_app2=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' express_dynamic2`
echo " "

echo "## IP of injected: static $static_app1, $static_app2 and dynamic $dynamic_app1, $dynamic_app2\n" 
docker run -d -p 8080:80 -e STATIC_APP1=$static_app1:80 -e STATIC_APP2=$static_app2:80 -e DYNAMIC_APP1=$dynamic_app1:3000 -e DYNAMIC_APP2=$dynamic_app2:3000 --name apache_rp res/apache_rp
```

We run 2 useless containers and 2 working containers to test the implementation.

<u>**Config-template.php :**</u>

```php
<?php
  $dynamic_app1 = getenv('DYNAMIC_APP1');
  $dynamic_app2 = getenv('DYNAMIC_APP2');
  $static_app1 = getenv('STATIC_APP1');
  $static_app2 = getenv('STATIC_APP2');
?>

<VirtualHost *:80>
  ServerName demo.res.ch

  <Proxy "balancer://dynamic_app">
    BalancerMember 'http://<?php print "$dynamic_app1"?>'
    BalancerMember 'http://<?php print "$dynamic_app2"?>'
  </Proxy>
  <Proxy "balancer://static_app">
    BalancerMember 'http://<?php print "$static_app1"?>/'
    BalancerMember 'http://<?php print "$static_app2"?>/'
  </Proxy>

  ProxyPass '/api/students/' 'balancer://dynamic_app/'
  ProxyPassReverse '/api/students/' 'balancer://dynamic_app/'

  ProxyPass '/' 'balancer://static_app/'
  ProxyPassReverse '/' 'balancer://static_app/'

</VirtualHost>
```

We use <Proxy> to create a cluster of servers. We have 2 clusters of 2 servers. Then we change the proxy pass to go in the clusters instead of the containers and it works.

### Load balancing: round-robin vs sticky sessions (0.5 pt)

### Dynamic cluster management (0.5 pt)

### Management UI (0.5 pt)

I simply added a script to install a docker UI management really well done already : 

<u>**UI-management-install.sh : **</u>

```bash
docker volume create portainer_data
docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer
```

This creates a container. To access it and be able to manage containers, go to <docker ip adress>:9000
