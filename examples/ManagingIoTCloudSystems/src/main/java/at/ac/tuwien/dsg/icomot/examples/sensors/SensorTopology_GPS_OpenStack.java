/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package at.ac.tuwien.dsg.icomot.examples.sensors;

import at.ac.tuwien.dsg.icomot.examples.govops_gateways_sensors.*;
import java.util.Map;

import at.ac.tuwien.dsg.comot.api.ToscaDescriptionBuilder;
import at.ac.tuwien.dsg.comot.api.ToscaDescriptionBuilderImpl;
import static at.ac.tuwien.dsg.comot.common.model.ArtifactTemplate.DockerFileArtifact;
import static at.ac.tuwien.dsg.comot.common.model.ArtifactTemplate.MiscArtifact;
import static at.ac.tuwien.dsg.comot.common.model.ArtifactTemplate.SingleScriptArtifact;
import at.ac.tuwien.dsg.comot.common.model.Capability;
import at.ac.tuwien.dsg.comot.common.model.CloudService;
import static at.ac.tuwien.dsg.comot.common.model.CloudService.ServiceTemplate;
import static at.ac.tuwien.dsg.comot.common.model.CommonOperatingSystemSpecification.DockerDefault;
import static at.ac.tuwien.dsg.comot.common.model.CommonOperatingSystemSpecification.OpenstackSmall;
import static at.ac.tuwien.dsg.comot.common.model.DockerUnit.DockerUnit;
import at.ac.tuwien.dsg.comot.common.model.DockerUnit;
import static at.ac.tuwien.dsg.comot.common.model.EntityRelationship.HostedOnRelation;
import static at.ac.tuwien.dsg.comot.common.model.EntityRelationship.ConnectToRelation;
import at.ac.tuwien.dsg.comot.common.model.OperatingSystemUnit;
import static at.ac.tuwien.dsg.comot.common.model.OperatingSystemUnit.OperatingSystemUnit;
import at.ac.tuwien.dsg.comot.common.model.Requirement;
import static at.ac.tuwien.dsg.comot.common.model.ServiceTopology.ServiceTopology;
import at.ac.tuwien.dsg.comot.common.model.BASHAction;
import at.ac.tuwien.dsg.comot.common.model.LifecyclePhase;
import at.ac.tuwien.dsg.comot.common.model.ServiceTopology;
import at.ac.tuwien.dsg.comot.common.model.ServiceUnit;
import at.ac.tuwien.dsg.comot.common.model.SoftwareNode;
import static at.ac.tuwien.dsg.comot.common.model.SoftwareNode.SingleSoftwareUnit;
import at.ac.tuwien.dsg.comot.orchestrator.interraction.iCOMOTOrchestrator;
import at.ac.tuwien.dsg.icomot.util.ProcessArgs;
import at.ac.tuwien.dsg.icomot.util.ProcessArgs.Arg;

/**
 * This example simulates sensors and gateways, which send data to the Cloud IOT
 * Platform deployed by the ElasticIoTPlatform.java example file
 *
 * @author http://dsg.tuwien.ac.at
 */
public class SensorTopology_GPS_OpenStack {

    public static void main(String[] args) {

        String sensorRepo  = "http://localhost/iCOMOTTutorial/files/IoTSensorData/gps";
        String gatewayRepo = "http://localhost/iCOMOTTutorial/files/IoTGateway";

        ServiceUnit MqttQueueVM = OperatingSystemUnit("MqttQueueVM")
                .providedBy(OpenstackSmall())
                .andReference("MQTTGateway/MqttQueueVM");

        ServiceUnit QueueUnit = SoftwareNode.SingleSoftwareUnit("QueueUnit")
                .exposes(Capability.Variable("brokerIp_Capability"))
                .andReference("MQTTGateway/QueueUnit");

        OperatingSystemUnit sensorVM = OperatingSystemUnit("sensorVM")
                .providedBy(OpenstackSmall()
                        .withBaseImage("7ac2cc53-2301-40d7-a030-910d72f552ff") // this image includes docker, faster spin up
                );

        ServiceUnit sensorUnit = SingleSoftwareUnit("sensorUnit")
                .requires(Requirement.Variable("brokerIp_Requirement"))
                .deployedBy(SingleScriptArtifact(sensorRepo + "runSensor_gps1279_location.sh"))
                .deployedBy(MiscArtifact(sensorRepo + "sensor.tar.gz"))
                .withLifecycleAction(LifecyclePhase.UNDEPLOY, new BASHAction("decommission"))
                .withMaxColocatedInstances(1);

        ServiceTopology gatewayTopology = ServiceTopology("IoTTopology")
                .withServiceUnits(sensorUnit, sensorVM)
                .withServiceUnits(MqttQueueVM, QueueUnit);

        CloudService serviceTemplate = ServiceTemplate("IoTSensors")
                .consistsOfTopologies(gatewayTopology)
                //defining CONNECT_TO and HOSTED_ON relationships
                .andRelationships(HostedOnRelation("SensorOnVM")
                        .from(sensorUnit)
                        .to(sensorVM))
                .andRelationships(HostedOnRelation("QueueUnitOnMqttQueueVM")
                        .from(QueueUnit)
                        .to(MqttQueueVM))
                // note: the ID of connectto relationship for Sensors must be started with "mqtt", the sensor code is hard-coded to read this pattern.
                .andRelationships(ConnectToRelation("mqtt_broker")
                        .from(QueueUnit.getContext().get("brokerIp_Capability"))
                        .to(sensorUnit.getContext().get("brokerIp_Requirement")));

        ToscaDescriptionBuilder toscaBuilder = new ToscaDescriptionBuilderImpl();
        String tosca = toscaBuilder.toXml(serviceTemplate);
        System.out.println(tosca);

        iCOMOTOrchestrator orchestrator = new iCOMOTOrchestrator("localhost");
        // added to make it easier to run as jar from cmd line
 		{
 			Map<Arg, String> argsMap = ProcessArgs.processArgs(args);
 			for (Arg key : argsMap.keySet()) {
 				switch (key) {
 				case ORCHESTRATOR_IP:
 					orchestrator.withIP(argsMap.get(key));
 					break;
 				case SALSA_IP:
 					orchestrator.withSalsaIP(argsMap.get(key));
 					break;
 				case SALSA_PORT:
 					orchestrator.withSalsaPort(Integer.parseInt(argsMap
 							.get(key)));
 					break;
 				case rSYBL_IP:
 					orchestrator.withRsyblIP(argsMap.get(key));
 					break;
 				case rSYBL_PORT:
 					orchestrator.withRsyblPort(Integer.parseInt(argsMap
 							.get(key)));
 					break;
 				case GovOps_IP:
 					orchestrator.withGovOpsIP(argsMap.get(key));
 					break;
 				case GovOps_PORT:
 					orchestrator.withGovOpsPort(Integer.parseInt(argsMap
 							.get(key)));
 					break;
 				}
 			}
 		}
 		
        orchestrator.deploy(serviceTemplate);
    }
}
