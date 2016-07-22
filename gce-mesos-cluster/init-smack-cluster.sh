
echo bring up mesos-dns...
curl -i -H 'Content-Type: application/json' \
  -d@./def-tasks/marathon-mesos-dns.json mesos-master-1:8080/v2/apps

sleep 5

echo "set slave DNS..."
./utils.sh -c set-slave-dns -n mesos-slave-1,mesos-slave-2,mesos-slave-3

sleep 3

echo "bring up Cassandra on each slave"

curl -i -H 'Content-Type: application/json' \
  -d@./def-tasks/marathon-cassandra.json mesos-master-1:8080/v2/apps

echo "bring Spark-Dispatcher"

curl -i -H 'Content-Type: application/json' \
  -d@./def-tasks/marathon-spark-dispatcher.json mesos-master-1:8080/v2/apps

