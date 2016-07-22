```
gcloud compute instances list

sudo ./set-hostname.sh 

gcloud compute ssh mesos-slave-1



tail /var/log/startupscript.log 

curl -X DELETE http://mesos-master-3:5050/framworks/spark-dispatcher.1e709b1b-f7b7-11e5-b900-42010af00004

curl -X DELETE http://mesos-master-3:5050/framworks/

curl -X POST http://mesos-master-1:5050/master/teardown -d 'frameworkId=driver-20160401031028-0001'

```

mesos
http://mesos-master-1:5050/#/

marathon
http://mesos-master-1:8080

spark-ui (on driver)
http://mesos-slave-3:4040/