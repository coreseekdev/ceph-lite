roles:
- - mon.a
  - mds.a
  - osd.0
  - osd.1
- - mon.b
  - mon.c
  - osd.2
  - osd.3
- - client.0
tasks:
- install:
     branch: bobtail
- ceph:
- workunit:
     clients:
        client.0:
           - rados/load-gen-big.sh
- install.upgrade:
     all:
        branch: master
- ceph.restart: [mds.a, osd.0, osd.1, osd.2, osd.3, mon.a, mon.b, mon.c]
- workunit:
     clients:
        client.0:
           - rados/load-gen-big.sh
