package at.ac.tuwien.dsg.icomot.examples;

import java.util.Map;

import static at.ac.tuwien.dsg.comot.common.model.ArtifactTemplate.MiscArtifact;
import static at.ac.tuwien.dsg.comot.common.model.ArtifactTemplate.SingleScriptArtifact;
import static at.ac.tuwien.dsg.comot.common.model.BASHAction.BASHAction;
import at.ac.tuwien.dsg.comot.common.model.Capability;
import at.ac.tuwien.dsg.comot.common.model.Constraint;
import at.ac.tuwien.dsg.comot.common.model.Constraint.Metric;
import static at.ac.tuwien.dsg.comot.common.model.EntityRelationship.ConnectToRelation;
import static at.ac.tuwien.dsg.comot.common.model.EntityRelationship.HostedOnRelation;
import at.ac.tuwien.dsg.comot.common.model.OperatingSystemUnit;
import at.ac.tuwien.dsg.comot.common.model.Requirement;
import at.ac.tuwien.dsg.comot.common.model.CloudService;
import static at.ac.tuwien.dsg.comot.common.model.CloudService.ServiceTemplate;
import static at.ac.tuwien.dsg.comot.common.model.CommonOperatingSystemSpecification.DockerDefault;
import static at.ac.tuwien.dsg.comot.common.model.CommonOperatingSystemSpecification.LocalDocker;
import static at.ac.tuwien.dsg.comot.common.model.DockerUnit.DockerUnit;
import at.ac.tuwien.dsg.comot.common.model.DockerUnit;

import at.ac.tuwien.dsg.comot.common.model.ElasticityCapability;
import at.ac.tuwien.dsg.comot.common.model.LifecyclePhase;
import static at.ac.tuwien.dsg.comot.common.model.OperatingSystemUnit.OperatingSystemUnit;
import at.ac.tuwien.dsg.comot.common.model.ServiceTopology;
import static at.ac.tuwien.dsg.comot.common.model.ServiceTopology.ServiceTopology;
import at.ac.tuwien.dsg.comot.common.model.ServiceUnit;
import static at.ac.tuwien.dsg.comot.common.model.SoftwareNode.SingleSoftwareUnit;
import static at.ac.tuwien.dsg.comot.common.model.Strategy.Strategy;
import at.ac.tuwien.dsg.comot.orchestrator.interraction.iCOMOTOrchestrator;
import at.ac.tuwien.dsg.icomot.util.ProcessArgs;
import at.ac.tuwien.dsg.icomot.util.ProcessArgs.Arg;

/**
 * This example deploys an elastic IOT platform running in the cloud
 *
 * @author http://dsg.tuwien.ac.at
 */
public class ElasticIoTPlatformOnDocker {

    public static void main(String[] args) {
        //specify service units in terms of software

        String platformRepo = "http://localhost/iCOMOTTutorial/files/ElasticIoTCloudPlatform/";
        String miscRepo = "http://localhost/iCOMOTTutorial/files/Misc/";

        //define localhost docker 
        OperatingSystemUnit personalMachine = OperatingSystemUnit("PersonalMachine")
                .providedBy(LocalDocker()
                );

        //need to specify details of VM and operating system to deploy the software servide units on
        DockerUnit dataControllerVM = DockerUnit("DataControllerUnitVM")
                .providedBy(DockerDefault().addSoftwarePackage("software-properties-common python-software-properties ganglia-monitor gmetad")
                );

        DockerUnit dataNodeVM = DockerUnit("DataNodeUnitVM")
                .providedBy(DockerDefault().addSoftwarePackage("ganglia-monitor gmetad")
                );

        //finally, we define Vm types for event processing
        DockerUnit loadbalancerVM = DockerUnit("LoadBalancerUnitVM")
                .providedBy(DockerDefault().addSoftwarePackage("curl software-properties-common python-software-properties ganglia-monitor gmetad")
                );

        DockerUnit eventProcessingVM = DockerUnit("EventProcessingUnitVM")
                .providedBy(DockerDefault().addSoftwarePackage("ganglia-monitor gmetad")
                );

        DockerUnit localProcessingVM = DockerUnit("LocalProcessingUnitVM")
                .providedBy(DockerDefault().addSoftwarePackage("ganglia-monitor gmetad")
                );

        DockerUnit mqttQueueVM = DockerUnit("MqttQueueVM")
                .providedBy(DockerDefault()
                );

        DockerUnit momVM = DockerUnit("MoMVM")
                .providedBy(DockerDefault()
                );

        //start with Data End, and first with Data Controller
        ServiceUnit dataControllerUnit = SingleSoftwareUnit("DataControllerUnit")
                //software artifacts needed for unit deployment   = software artifact archive and script to deploy Cassandra
                .deployedBy(SingleScriptArtifact(platformRepo + "scripts/Docker/deployCassandraSeed.sh"))
                .deployedBy(MiscArtifact(platformRepo + "artifacts/ElasticCassandraSetup-1.0.tar.gz"))
                //data controller exposed its IP 
                .exposes(Capability.Variable("DataController_IP_information"));

        ElasticityCapability dataNodeUnitScaleIn = ElasticityCapability.ScaleIn();
        ElasticityCapability dataNodeUnitScaleOut = ElasticityCapability.ScaleOut();

        //specify data node
        ServiceUnit dataNodeUnit = SingleSoftwareUnit("DataNodeUnit")
                .deployedBy(SingleScriptArtifact(platformRepo + "scripts/Docker/deployCassandraNode.sh"))
                .deployedBy(MiscArtifact(platformRepo + "artifacts/ElasticCassandraSetup-1.0.tar.gz"))
                //data node MUST KNOW the IP of cassandra seed, to connect to it and join data cluster
                .requires(Requirement.Variable("DataController_IP_Data_Node_Req").withName("requiringDataNodeIP"))
                .provides(dataNodeUnitScaleIn, dataNodeUnitScaleOut)
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

        //add the service units belonging to the event processing topology
        ServiceUnit momUnit = SingleSoftwareUnit("MOMUnit")
                //load balancer must provide IP
                .exposes(Capability.Variable("MOM_IP_information"))
                .deployedBy(SingleScriptArtifact(platformRepo + "scripts/Docker/deployQueue.sh"))
                .deployedBy(MiscArtifact(platformRepo + "artifacts/DaaSQueue-1.0.tar.gz"));

        ElasticityCapability eventProcessingUnitScaleIn = ElasticityCapability.ScaleIn();
        ElasticityCapability eventProcessingUnitScaleOut = ElasticityCapability.ScaleOut();

        //add the service units belonging to the event processing topology
        ServiceUnit eventProcessingUnit = SingleSoftwareUnit("EventProcessingUnit")
                .deployedBy(SingleScriptArtifact(platformRepo + "scripts/Docker/deployEventProcessing.sh"))
                .deployedBy(MiscArtifact(platformRepo + "artifacts/DaaS-1.0.tar.gz"))
                //event processing must register in Load Balancer, so it needs the IP
                .requires(Requirement.Variable("EventProcessingUnit_LoadBalancer_IP_Req"))
                //event processing also needs to querry the Data Controller to access data
                .requires(Requirement.Variable("EventProcessingUnit_DataController_IP_Req"))
                .requires(Requirement.Variable("EventProcessingUnit_MOM_IP_Req"))
                .provides(eventProcessingUnitScaleIn, eventProcessingUnitScaleOut)
                //scale IN if throughput < 200 and responseTime < 200
                .controlledBy(Strategy("EP_ST1")
                        .when(Constraint.MetricConstraint("EP_ST1_CO1", new Metric("responseTime", "ms")).lessThan("100"))
                        .and(Constraint.MetricConstraint("EP_ST1_CO2", new Metric("avgThroughput", "operations/s")).lessThan("200"))
                        .enforce(eventProcessingUnitScaleIn)
                )
                .controlledBy(Strategy("EP_ST2")
                        .when(Constraint.MetricConstraint("EP_ST2_CO1", new Metric("responseTime", "ms")).greaterThan("100"))
                        .and(Constraint.MetricConstraint("EP_ST2_CO2", new Metric("avgThroughput", "operations/s")).greaterThan("200"))
                        .enforce(eventProcessingUnitScaleOut)
                )
                .withLifecycleAction(LifecyclePhase.STOP, BASHAction("sudo service event-processing stop"));

        //add the service units belonging to the event processing topology
        ServiceUnit loadbalancerUnit = SingleSoftwareUnit("LoadBalancerUnit")
                //load balancer must provide IP
                .exposes(Capability.Variable("LoadBalancer_IP_information"))
                .deployedBy(SingleScriptArtifact(platformRepo + "scripts/Docker/deployLoadBalancer.sh"))
                .deployedBy(MiscArtifact(platformRepo + "artifacts/HAProxySetup-1.0.tar.gz"));

        ServiceUnit mqttUnit = SingleSoftwareUnit("QueueUnit")
                //load balancer must provide IP
                .exposes(Capability.Variable("brokerIp_Capability"))
                .deployedBy(SingleScriptArtifact(platformRepo + "scripts/Docker/run_mqtt_broker.sh"));

        ElasticityCapability localProcessingUnitScaleIn = ElasticityCapability.ScaleIn();
        ElasticityCapability localProcessingUnitScaleOut = ElasticityCapability.ScaleOut();

        ServiceUnit localProcessingUnit = SingleSoftwareUnit("LocalProcessingUnit")
                //load balancer must provide IP
                .requires(Requirement.Variable("brokerIp_Requirement"))
                .requires(Requirement.Variable("loadBalancerIp_Requirement"))
                .provides(localProcessingUnitScaleIn, localProcessingUnitScaleOut)
                .deployedBy(SingleScriptArtifact(platformRepo + "scripts/Docker/deployLocalAnalysis.sh"))
                .deployedBy(MiscArtifact(miscRepo + "artifacts/jre-7-linux-x64.tar.gz"))
                .deployedBy(MiscArtifact(platformRepo + "artifacts/LocalDataAnalysis.tar.gz"));
        
        localProcessingUnit.
                controlledBy(Strategy("LPT_ST1").when(Constraint.MetricConstraint("LPT_ST1_CO1", new Metric("avgBufferSize", "#")).lessThan("50"))
                        .enforce(localProcessingUnitScaleIn));
        localProcessingUnit.
                controlledBy(Strategy("LPT_ST2").when(Constraint.MetricConstraint("LPT_ST2_CO1", new Metric("avgBufferSize", "#")).greaterThan("50"))
                        .enforce(localProcessingUnitScaleOut));
        
 
        ServiceTopology dataEndTopology = ServiceTopology("DataEndTopology")
                .withServiceUnits(personalMachine, mqttQueueVM, loadbalancerVM,momVM,  dataControllerVM,  dataNodeVM , localProcessingVM, eventProcessingVM,  mqttUnit,  loadbalancerUnit, 
                        momUnit, dataControllerUnit  , dataNodeUnit 
                        , eventProcessingUnit,  localProcessingUnit
                );
        
        

        //describe the service template which will hold more topologies
        CloudService serviceTemplate = ServiceTemplate("ElasticIoTPlatform")
                .consistsOfTopologies(dataEndTopology)
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
                        .to(mqttQueueVM),
                        HostedOnRelation("dataControllerToLaptop")
                        .from(dataControllerVM)
                        .to(personalMachine),
                        HostedOnRelation("dataNodeVMToLaptop")
                        .from(dataNodeVM)
                        .to(personalMachine),
                        HostedOnRelation("loadbalancerVMToLaptop")
                        .from(loadbalancerVM)
                        .to(personalMachine),
                        HostedOnRelation("eventProcessingVMToLaptop")
                        .from(eventProcessingVM)
                        .to(personalMachine),
                        HostedOnRelation("localProcessingVMToLaptop")
                        .from(localProcessingVM)
                        .to(personalMachine),
                        HostedOnRelation("mqttQueueVMToLaptop")
                        .from(mqttQueueVM)
                        .to(personalMachine),
                        HostedOnRelation("momVMToLaptop")
                        .from(momVM)
                        .to(personalMachine)
                )
                .withDefaultMetrics();

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

        orchestrator.deployAndControl(serviceTemplate);

        //only to deploy
        //orchestrator.deploy(serviceTemplate);
        //for updating anything
        //orchestrator.controlExisting(serviceTemplate);
    }
}
