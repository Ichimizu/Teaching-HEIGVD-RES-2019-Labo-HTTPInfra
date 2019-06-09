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