======================================================
Apache Axis2 1.1.1 build (January 9 2007)
Binary Release

http://ws.apache.org/axis2
------------------------------------------------------

This is the Standard Binary Release of Axis2.

The lib directory contains;

1. axis2-adb-1.1.1.jar
2. axis2-adb-codegen-1.1.1.jar
3. axis2-codegen-1.1.1.jar
4. axis2-java2wsdl-1.1.1.jar
5. axis2-jibx-1.1.1.jar
6. axis2-jaxbri-1.1.1.jar
7. axis2-kernel-1.1.1.jar
8. axis2-spring-1.1.1.jar
9. axis2-tools-1.1.1.jar
10. axis2-xmlbeans-1.1.1.jar
11. axis2-saaj-1.1.1.jar
12. axis2-soapmonitor-1.1.1.jar

and all 3rd party distributable dependencies of the above jars.

The repository/modules directory contains the deployable addressing module.

The webapp folder contains an ant build script to generate the axis2.war out of this distribution.
(This requires Ant 1.6.5)

The samples directory contains all the Axis2 samples which demonstrates some of the key features of
Axis2. It also contains a few samples relevant to documents found in Axis2's Docs Distribution.

The bin directory contains a set of usefull scripts for the users.

The conf directory contains the axis2.xml file which allows to configure Axis2.

(Please note that this release does not include the other WS-* implementation modules, like
WS-Security, that are being developed within Axis2. Those can be downloaded from
http://ws.apache.org/axis2/modules/)
