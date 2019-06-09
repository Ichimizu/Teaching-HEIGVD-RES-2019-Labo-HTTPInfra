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