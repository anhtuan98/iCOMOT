/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package at.ac.tuwien.dsg.icomot.examples;

import at.ac.tuwien.dsg.comot.common.model.*;
import static at.ac.tuwien.dsg.comot.common.model.ArtifactTemplate.SingleScriptArtifact;
import static at.ac.tuwien.dsg.comot.common.model.BASHAction.BASHAction;
import static at.ac.tuwien.dsg.comot.common.model.CloudService.ServiceTemplate;
import static at.ac.tuwien.dsg.comot.common.model.CommonOperatingSystemSpecification.OpenstackMicro;
import static at.ac.tuwien.dsg.comot.common.model.CommonOperatingSystemSpecification.OpenstackSmall;
import at.ac.tuwien.dsg.comot.common.model.Constraint.Metric;
import static at.ac.tuwien.dsg.comot.common.model.EntityRelationship.ConnectToRelation;
import static at.ac.tuwien.dsg.comot.common.model.EntityRelationship.HostedOnRelation;
import static at.ac.tuwien.dsg.comot.common.model.OperatingSystemUnit.OperatingSystemUnit;
import static at.ac.tuwien.dsg.comot.common.model.ServiceTopology.ServiceTopology;
import static at.ac.tuwien.dsg.comot.common.model.SoftwareNode.SingleSoftwareUnit;
import static at.ac.tuwien.dsg.comot.common.model.Strategy.Strategy;
import at.ac.tuwien.dsg.comot.orchestrator.interraction.iCOMOTOrchestrator;
import java.util.HashMap;

/**
 *
 * @author Georgiana
 */
public class LifecycleManagement {

    private CloudService serviceTemplate;
    private ServiceUnit dataControllerUnit;
    private ServiceUnit dataNodeUnit;
    private ServiceUnit momUnit;
    private ServiceUnit eventProcessingUnit;
    private ServiceUnit loadbalancerUnit;
    private ServiceUnit mqttUnit;
    private ServiceUnit localProcessingUnit;
    private ServiceTopology dataEndTopology;
    private ServiceTopology eventProcessingTopology;
    private ServiceTopology localProcessingTopology;
    private iCOMOTOrchestrator iCOMOTorchestrator;
    private HashMap<String,ServiceUnit> serviceUnits= new HashMap<String,ServiceUnit>();
    private HashMap<String,ServiceTopology> serviceTopologies= new HashMap<String,ServiceTopology>();
    
    //specify service units in terms of software
    String salsaRepo = "http://128.130.172.215/iCOMOTTutorial/files/ElasticIoTPlatform/";
    
    public LifecycleManagement(){
        iCOMOTorchestrator = new iCOMOTOrchestrator("localhost");
    }
    /*
    *Describes service structure, with the artifacts and relation between them,
    *and the logical structure of the service.
    **/
    private void specifyServiceStructure() {
        //need to specify details of VM and operating system to deploy the software servide units on
        OperatingSystemUnit dataControllerVM = OperatingSystemUnit("DataControllerUnitVM")
                .providedBy(OpenstackSmall());
        OperatingSystemUnit dataNodeVM = OperatingSystemUnit("DataNodeUnitVM")
                .providedBy(OpenstackMicro());
        //finally, we define Vm types for event processing
        OperatingSystemUnit loadbalancerVM = OperatingSystemUnit("LoadBalancerUnitVM")
                .providedBy(OpenstackSmall());
        OperatingSystemUnit eventProcessingVM = OperatingSystemUnit("EventProcessingUnitVM")
                .providedBy(OpenstackSmall());
        OperatingSystemUnit localProcessingVM = OperatingSystemUnit("LocalProcessingUnitVM")
                .providedBy(OpenstackSmall());
        OperatingSystemUnit mqttQueueVM = OperatingSystemUnit("MqttQueueVM")
                .providedBy(OpenstackSmall());
        OperatingSystemUnit momVM = OperatingSystemUnit("MoMVM")
                .providedBy(OpenstackSmall());
        //start with Data End, and first with Data Controller
        dataControllerUnit = SingleSoftwareUnit("DataControllerUnit")
                //software artifacts needed for unit deployment   = script to deploy Cassandra
                .deployedBy(SingleScriptArtifact(salsaRepo + "deployCassandraSeed.sh"))
                //data controller exposed its IP 
                .exposes(Capability.Variable("DataController_IP_information"));
        serviceUnits.put("DataControllerUnit",dataControllerUnit);
        ElasticityCapability dataNodeUnitScaleIn = ElasticityCapability.ScaleIn();
        ElasticityCapability dataNodeUnitScaleOut = ElasticityCapability.ScaleOut();

        //specify data node
        dataNodeUnit = SingleSoftwareUnit("DataNodeUnit")
                .deployedBy(SingleScriptArtifact(salsaRepo + "deployCassandraNode.sh"))
                //data node MUST KNOW the IP of cassandra seed, to connect to it and join data cluster
                .requires(Requirement.Variable("DataController_IP_Data_Node_Req").withName("requiringDataNodeIP"))
                //.provides(dataNodeUnitScaleIn, dataNodeUnitScaleOut)
                //express elasticity strategy: Scale IN Data Node when cpu usage < 40%
                .controlledBy(Strategy("DN_ST1")
                        .when(Constraint.MetricConstraint("DN_ST1_CO1", new Metric("cpuUsage", "%")).lessThan("40"))
                        .enforce(dataNodeUnitScaleIn)
                )
                .controlledBy(Strategy("DN_ST2")
                        .when(Constraint.MetricConstraint("DN_ST2_CO1", new Metric("cpuUsage", "%")).greaterThan("80"))
                        .enforce(dataNodeUnitScaleOut)
                )
                .withLifecycleAction(LifecyclePhase.STOP, BASHAction("sudo service joinRing stop"));
        serviceUnits.put("DataNodeUnit",dataNodeUnit);

        //add the service units belonging to the event processing topology
        momUnit = SingleSoftwareUnit("MOMUnit")
                //load balancer must provide IP
                .exposes(Capability.Variable("MOM_IP_information"))
                .deployedBy(SingleScriptArtifact(salsaRepo + "deployQueue.sh"));
        serviceUnits.put("MOMUnit",momUnit);

        //add the service units belonging to the event processing topology
        eventProcessingUnit = SingleSoftwareUnit("EventProcessingUnit")
                .deployedBy(SingleScriptArtifact(salsaRepo + "deployEventProcessing.sh"))
                //event processing must register in Load Balancer, so it needs the IP
                .requires(Requirement.Variable("EventProcessingUnit_LoadBalancer_IP_Req"))
                //event processing also needs to querry the Data Controller to access data
                .requires(Requirement.Variable("EventProcessingUnit_DataController_IP_Req"))
                .requires(Requirement.Variable("EventProcessingUnit_MOM_IP_Req"))
                .provides(ElasticityCapability.ScaleIn(), ElasticityCapability.ScaleOut())
                //scale IN if throughput < 200 and responseTime < 200

                .withLifecycleAction(LifecyclePhase.STOP, BASHAction("sudo service event-processing stop"));
        serviceUnits.put("EventProcessingUnit",eventProcessingUnit);

        //add the service units belonging to the event processing topology
        loadbalancerUnit = SingleSoftwareUnit("LoadBalancerUnit")
                //load balancer must provide IP
                .exposes(Capability.Variable("LoadBalancer_IP_information"))
                .deployedBy(SingleScriptArtifact(salsaRepo + "deployLoadBalancer.sh"));
        serviceUnits.put("LoadBalancerUnit",loadbalancerUnit);

        mqttUnit = SingleSoftwareUnit("QueueUnit")
                //load balancer must provide IP
                .exposes(Capability.Variable("brokerIp_Capability"))
                .deployedBy(SingleScriptArtifact(salsaRepo + "/IoT/installApacheMQ.sh"));
        serviceUnits.put("QueueUnit",mqttUnit);

        localProcessingUnit = SingleSoftwareUnit("LocalProcessingUnit")
                //load balancer must provide IP
                .requires(Requirement.Variable("brokerIp_Requirement"))
                .requires(Requirement.Variable("loadBalancerIp_Requirement"))
                .provides(ElasticityCapability.ScaleIn(), ElasticityCapability.ScaleOut())
                .deployedBy(SingleScriptArtifact(salsaRepo + "/IoT/install-local-analysis-service.sh"));
        serviceUnits.put("LocalProcessingUnit",localProcessingUnit);

        //Describe a Data End service topology containing the previous 2 software service units
        dataEndTopology = ServiceTopology("DataEndTopology")
                .withServiceUnits(dataControllerUnit, dataNodeUnit //add also OS units to topology
                        , dataControllerVM, dataNodeVM
                );
        serviceTopologies.put("DataEndTopology",dataEndTopology);

        //define event processing unit topology
        eventProcessingTopology = ServiceTopology("EventProcessingTopology")
                .withServiceUnits(loadbalancerUnit, eventProcessingUnit, momUnit //add vm types to topology
                        , loadbalancerVM, eventProcessingVM, momVM
                );
        serviceTopologies.put("EventProcessingTopology",eventProcessingTopology);

        localProcessingTopology = ServiceTopology("Gateway")
                .withServiceUnits(mqttQueueVM, mqttUnit, localProcessingUnit, localProcessingVM
                );
        serviceTopologies.put("Gateway",localProcessingTopology);

        //describe the service template which will hold more topologies
        serviceTemplate = ServiceTemplate("ElasticIoTPlatform")
                .consistsOfTopologies(dataEndTopology)
                .consistsOfTopologies(eventProcessingTopology)
                .consistsOfTopologies(localProcessingTopology)
                //defining CONNECT_TO and HOSTED_ON relationships
                .andRelationships(
                        //Data Controller IP send to Data Node
                        ConnectToRelation("dataNodeToDataController")
                        .from(dataControllerUnit.getContext().get("DataController_IP_information"))
                        .to(dataNodeUnit.getContext().get("DataController_IP_Data_Node_Req")) //specify which software unit goes to which VM
                        ,
                        //event processing gets IP from load balancer
                        ConnectToRelation("eventProcessingToLoadBalancer")
                        .from(loadbalancerUnit.getContext().get("LoadBalancer_IP_information"))
                        .to(eventProcessingUnit.getContext().get("EventProcessingUnit_LoadBalancer_IP_Req")) //specify which software unit goes to which VM
                        ,
                        //event processing gets IP from data controller
                        ConnectToRelation("eventProcessingToDataController")
                        .from(dataControllerUnit.getContext().get("DataController_IP_information"))
                        .to(eventProcessingUnit.getContext().get("EventProcessingUnit_DataController_IP_Req")) //specify which software unit goes to which VM
                        ,
                        ConnectToRelation("eventProcessingToMOM")
                        .from(momUnit.getContext().get("MOM_IP_information"))
                        .to(eventProcessingUnit.getContext().get("EventProcessingUnit_MOM_IP_Req")) //specify which software unit goes to which VM
                        ,
                        ConnectToRelation("mqtt_broker")
                        .from(mqttUnit.getContext().get("brokerIp_Capability"))
                        .to(localProcessingUnit.getContext().get("brokerIp_Requirement")) //specify which software unit goes to which VM
                        ,
                        ConnectToRelation("load_balancer")
                        .from(loadbalancerUnit.getContext().get("LoadBalancer_IP_information"))
                        .to(localProcessingUnit.getContext().get("loadBalancerIp_Requirement")) //specify which software unit goes to which VM
                        ,
                        HostedOnRelation("dataControllerToVM")
                        .from(dataControllerUnit)
                        .to(dataControllerVM),
                        HostedOnRelation("dataNodeToVM")
                        .from(dataNodeUnit)
                        .to(dataNodeVM) //add hosted on relatinos
                        , HostedOnRelation("loadbalancerToVM")
                        .from(loadbalancerUnit)
                        .to(loadbalancerVM),
                        HostedOnRelation("eventProcessingToVM")
                        .from(eventProcessingUnit)
                        .to(eventProcessingVM),
                        HostedOnRelation("momToVM")
                        .from(momUnit)
                        .to(momVM),
                        HostedOnRelation("localProcessingToVM")
                        .from(localProcessingUnit)
                        .to(localProcessingVM),
                        HostedOnRelation("mqttToVM")
                        .from(mqttUnit)
                        .to(mqttQueueVM)
                )
                .withDefaultMetrics();

    }
    
    
    
    /*
    *Specify SYBL requirements for different parts of the service
    **/
    private void specifyServiceRequirements(){
        eventProcessingUnit.controlledBy(Strategy("EP_ST1")
                .when(Constraint.MetricConstraint("EP_ST1_CO1", new Metric("responseTime", "ms")).lessThan("100"))
                .and(Constraint.MetricConstraint("EP_ST1_CO2", new Metric("avgThroughput", "operations/s")).lessThan("200"))
                .enforce(ElasticityCapability.ScaleIn())
        )
                .controlledBy(Strategy("EP_ST2")
                        .when(Constraint.MetricConstraint("EP_ST2_CO1", new Metric("responseTime", "ms")).greaterThan("100"))
                        .and(Constraint.MetricConstraint("EP_ST2_CO2", new Metric("avgThroughput", "operations/s")).greaterThan("200"))
                        .enforce(ElasticityCapability.ScaleOut())
                ).constrainedBy(Constraint.MetricConstraint("EP_CO3", new Metric("cost", "$")).lessThan("400"));


        localProcessingUnit.
                controlledBy(Strategy("LPT_ST1").when(Constraint.MetricConstraint("LPT_ST1_CO1", new Metric("avgBufferSize", "#")).lessThan("50"))
                        .enforce(ElasticityCapability.ScaleIn()));
        localProcessingUnit.
                controlledBy(Strategy("LPT_ST2").when(Constraint.MetricConstraint("LPT_ST2_CO1", new Metric("avgBufferSize", "#")).greaterThan("50"))
                        .enforce(ElasticityCapability.ScaleOut()));
        //specify constraints on the data topology
        //thus, the CPU usage of all Service Unit instances of the data end Topology must be below 80%
        dataEndTopology.controlledBy(Strategy("EP_ST3")
                .when(Constraint.MetricConstraint("DET_CO1", new Metric("cpuUsage", "%")).lessThan("80"))
                .enforce(ElasticityCapability.ScaleOut())
        );
    }
    
    
    /*
    * Initialize structural description and set service requirements.
    */
    public void initializeServiceDescription() {
        specifyServiceStructure();
        specifyServiceRequirements();
    }
    
    /*
    * Start control
    */
    public void startElaticityControl() {
        iCOMOTorchestrator.deployAndControl(serviceTemplate);
    }
    
    /*
    * Pause control and then perform manual service check. 
    */
    public void pauseControlForManualServiceCheck() {
        iCOMOTorchestrator.pauseControl(serviceTemplate);
    }
    
    /*
    * Resume control after manual check was performed.
    */
    public void resumeControlAfterManualServiceCheck() {
        iCOMOTorchestrator.resumeControl(serviceTemplate);
    }
    
    /*
    * Change elasticity control parameters, and governance of IoT infrastructure.
    */
    public void changeElasticityControlAndGovernanceFocus() {
        //modify requirement EP_CO3 on cost, to approve bigger cost for current situation
        eventProcessingUnit.constrainedBy(Constraint.MetricConstraint("EP_CO3", new Metric("cost", "$")).lessThan("900"));
        iCOMOTorchestrator.updateServiceReqsOrStruct(serviceTemplate);
        
        //start new sensors of type FM5300 and specify the monitoring frequency at 1 second 
        ServiceUnit sensor = new ServiceUnit("Sensor").ofType("FM5300");
        iCOMOTorchestrator.enforceCapabilityOnClassOfUnits(sensor, iCOMOTOrchestrator.SensorCapability.START);
        iCOMOTorchestrator.enforceCapabilityOnClassOfUnits(sensor, iCOMOTOrchestrator.SensorCapability.UPDATE_MON_FREQ, "1");
    }
}
