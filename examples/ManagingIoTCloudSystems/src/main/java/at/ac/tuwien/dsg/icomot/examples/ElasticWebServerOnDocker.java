package at.ac.tuwien.dsg.icomot.examples;



import static at.ac.tuwien.dsg.comot.common.model.ArtifactTemplate.SingleScriptArtifact;
import static at.ac.tuwien.dsg.comot.common.model.BASHAction.BASHAction;
import static at.ac.tuwien.dsg.comot.common.model.CloudService.ServiceTemplate;
import static at.ac.tuwien.dsg.comot.common.model.CommonOperatingSystemSpecification.DockerDefault;
import static at.ac.tuwien.dsg.comot.common.model.CommonOperatingSystemSpecification.LocalDocker;
import static at.ac.tuwien.dsg.comot.common.model.DockerUnit.DockerUnit;
import static at.ac.tuwien.dsg.comot.common.model.EntityRelationship.ConnectToRelation;
import static at.ac.tuwien.dsg.comot.common.model.EntityRelationship.HostedOnRelation;
import static at.ac.tuwien.dsg.comot.common.model.OperatingSystemUnit.OperatingSystemUnit;
import static at.ac.tuwien.dsg.comot.common.model.ServiceTopology.ServiceTopology;
import static at.ac.tuwien.dsg.comot.common.model.SoftwareNode.SingleSoftwareUnit;
import static at.ac.tuwien.dsg.comot.common.model.Strategy.Strategy;

import java.util.Map;

import at.ac.tuwien.dsg.comot.common.model.Capability;
import at.ac.tuwien.dsg.comot.common.model.CloudService;
import at.ac.tuwien.dsg.comot.common.model.Constraint;
import at.ac.tuwien.dsg.comot.common.model.Constraint.Metric;
import at.ac.tuwien.dsg.comot.common.model.DockerUnit;
import at.ac.tuwien.dsg.comot.common.model.ElasticityCapability;
import at.ac.tuwien.dsg.comot.common.model.LifecyclePhase;
import at.ac.tuwien.dsg.comot.common.model.OperatingSystemUnit;
import at.ac.tuwien.dsg.comot.common.model.Requirement;
import at.ac.tuwien.dsg.comot.common.model.ServiceTopology;
import at.ac.tuwien.dsg.comot.common.model.ServiceUnit;
import at.ac.tuwien.dsg.comot.orchestrator.interraction.iCOMOTOrchestrator;
import at.ac.tuwien.dsg.icomot.util.ProcessArgs;
import at.ac.tuwien.dsg.icomot.util.ProcessArgs.Arg;

/**
 *
 *  @author http://dsg.tuwien.ac.at
 */
public class ElasticWebServerOnDocker {

    public static void main(String[] args) {

        //specify repository holding service software artifacts
        String salsaRepo = "http://localhost/repository/files/HelloElasticity/";

        //define localhost docker 
        OperatingSystemUnit privateVM = OperatingSystemUnit("PersonalLaptop")
                .providedBy(LocalDocker()
                );

        //then, we define Docker types for event processing
        DockerUnit loadbalancerDocker = DockerUnit("LoadBalancerUnitDocker")
                .providedBy(DockerDefault()
                );

        DockerUnit eventProcessingDocker = DockerUnit("EventProcessingUnitDocker")
                .providedBy(DockerDefault()
                );
        
        //define the Load Balancer as a software service unit deployed by a script, and exposing its IP 
        //as context information
        ServiceUnit loadbalancerUnit = SingleSoftwareUnit("LoadBalancerUnit")
                //this exposed variable will be passed to anyone requesting a connection to this unit
                .exposes(Capability.Variable("LoadBalancer_IP_information"))
                .deployedBy(SingleScriptArtifact(salsaRepo + "deployLoadBalancer.sh"));

        //elasticity capabilities as first class citizens
        ElasticityCapability scaleOutEventProcessing = ElasticityCapability.ScaleOut();
        ElasticityCapability scaleInEventProcessing = ElasticityCapability.ScaleIn();

        //define the elastic service unit, with elasticity capabilities, elasticity strategies, and 
        //even lifecycle action required to gracefully shut down instances of this unit
        ServiceUnit eventProcessingUnit = SingleSoftwareUnit("EventProcessingUnit")
                .deployedBy(SingleScriptArtifact(salsaRepo + "deployEventProcessing.sh"))
                //event processing must register in Load Balancer, so it needs the IP
                .requires(Requirement.Variable("EventProcessingUnit_LoadBalancer_IP_Req"))
                //enabled elasticity capabilities
                .provides(scaleOutEventProcessing, scaleInEventProcessing)
                
                .controlledBy(
                        Strategy("EP_ST1")
                        .when(Constraint.MetricConstraint("EP_ST1_CO1", new Metric("avgResponseTime", "ms")).lessThan("500"))
                        .and(Constraint.MetricConstraint("EP_ST1_CO2", new Metric("avgThroughput", "#")).lessThan("50"))
                        .enforce(scaleInEventProcessing),
                        Strategy("EP_ST2")
                        .when(Constraint.MetricConstraint("EP_ST1_CO1", new Metric("avgResponseTime", "ms")).greaterThan("1000"))
                        .and(Constraint.MetricConstraint("EP_ST1_CO2", new Metric("totalPendingRequests", "#")).greaterThan("10"))
                        .enforce(scaleOutEventProcessing)
                )
                //manage unit lifecycle
                .withLifecycleAction(LifecyclePhase.STOP, BASHAction("sudo service event-processing stop"));

       

        //group units in a logical grouping concept called topology
        ServiceTopology eventProcessingTopology = ServiceTopology("EventProcessingTopology")
                .withServiceUnits(loadbalancerUnit, eventProcessingUnit //add vm types to topology
                        , loadbalancerDocker, eventProcessingDocker, privateVM
                );

        //link all units and topologies together and define the service, including relationships between units
        CloudService serviceTemplate = ServiceTemplate("HelloElasticity")
                .consistsOfTopologies(eventProcessingTopology)
                //defining CONNECT_TO and HOSTED_ON relationships
                .andRelationships(
                        //all Event Processing instances will receive the IP of the Load Balancer
                        ConnectToRelation("eventProcessingToLoadBalancer")
                        .from(loadbalancerUnit.getContext().get("LoadBalancer_IP_information"))
                        .to(eventProcessingUnit.getContext().get("EventProcessingUnit_LoadBalancer_IP_Req")),
                        
                        //which software unit is hosted on which virtual container
                        HostedOnRelation("loadbalancerToDocker")
                        .from(loadbalancerUnit)
                        .to(loadbalancerDocker),
                        HostedOnRelation("loadbalancerDockerToLocal")
                        .from(loadbalancerDocker)
                        .to(privateVM),
                        HostedOnRelation("eventProcessingToDocker")
                        .from(eventProcessingUnit)
                        .to(eventProcessingDocker),
                        HostedOnRelation("eventProcessingDockerToVM")
                        .from(eventProcessingDocker)
                        .to(privateVM)
                )
                //as we have horizontally scalable distributed systems (one service unit can have more instances)
                //metrics must be aggregated between unit instances
                .withDefaultMetrics();

        //instantiate COMOT orchestrator to deploy, monitor and control the service
        iCOMOTOrchestrator orchestrator = new iCOMOTOrchestrator("localhost");
        orchestrator.withSalsaPort(8380);
        orchestrator.withRsyblPort(8280);
        
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
        
    }
}
