package at.ac.tuwien.dsg.icomot.templates;

import static at.ac.tuwien.dsg.comot.common.model.ArtifactTemplate.SingleScriptArtifact;
import static at.ac.tuwien.dsg.comot.common.model.ArtifactTemplate.MiscArtifact;
import static at.ac.tuwien.dsg.comot.common.model.BASHAction.BASHAction;
import static at.ac.tuwien.dsg.comot.common.model.CloudService.ServiceTemplate;
import static at.ac.tuwien.dsg.comot.common.model.CommonOperatingSystemSpecification.DockerDefault;
import static at.ac.tuwien.dsg.comot.common.model.DockerUnit.DockerUnit;
import static at.ac.tuwien.dsg.comot.common.model.EntityRelationship.ConnectToRelation;
import static at.ac.tuwien.dsg.comot.common.model.EntityRelationship.HostedOnRelation;
import static at.ac.tuwien.dsg.comot.common.model.ServiceTopology.ServiceTopology;
import static at.ac.tuwien.dsg.comot.common.model.SoftwareNode.SingleSoftwareUnit;
import static at.ac.tuwien.dsg.comot.common.model.Strategy.Strategy;
import at.ac.tuwien.dsg.comot.common.model.Capability;
import at.ac.tuwien.dsg.comot.common.model.CloudService;
import static at.ac.tuwien.dsg.comot.common.model.CommonOperatingSystemSpecification.FlexiantMicro;
import static at.ac.tuwien.dsg.comot.common.model.CommonOperatingSystemSpecification.FlexiantSmall;
import static at.ac.tuwien.dsg.comot.common.model.CommonOperatingSystemSpecification.LocalDocker;
import static at.ac.tuwien.dsg.comot.common.model.CommonOperatingSystemSpecification.OpenstackMedium;
import static at.ac.tuwien.dsg.comot.common.model.CommonOperatingSystemSpecification.OpenstackMicro;
import static at.ac.tuwien.dsg.comot.common.model.CommonOperatingSystemSpecification.OpenstackSmall;
import static at.ac.tuwien.dsg.comot.common.model.CommonOperatingSystemSpecification.OpenstackTiny;
import at.ac.tuwien.dsg.comot.common.model.Constraint;
import at.ac.tuwien.dsg.comot.common.model.Constraint.Metric;
import at.ac.tuwien.dsg.comot.common.model.DockerUnit;
import at.ac.tuwien.dsg.comot.common.model.ElasticityCapability;
import at.ac.tuwien.dsg.comot.common.model.OperatingSystemUnit;
import static at.ac.tuwien.dsg.comot.common.model.OperatingSystemUnit.OperatingSystemUnit;
import at.ac.tuwien.dsg.comot.common.model.LifecyclePhase;
import at.ac.tuwien.dsg.comot.common.model.Requirement;
import at.ac.tuwien.dsg.comot.common.model.ServiceTopology;
import at.ac.tuwien.dsg.comot.common.model.ServiceUnit;
import at.ac.tuwien.dsg.comot.orchestrator.interraction.COMOTOrchestrator;

/**
 *
 * In this template, the scaling policy is not a direct if value > Threshold action, else another action.
 * Instead, for each elasticity capability exposed by the unit,its expected effect is defined, based on which rSYBL smart controller 
 * automatically decides on scaling actions
 * 
 * 
 * This template describes an elastic service with two software units from
 * different services which must communicate, and thus the IP of one called unit
 * must be send to the calling unit. Moreover, the calling unit uses the
 * received IP to register itself in the called unit, and then the called unit
 * acts as load balancer
 *
 * In this example we keep only the information required for scaling . For other
 * configuration options follow other examples
 *
 * @author http://dsg.tuwien.ac.at
 */
public class DeployElasticServiceWithScalingPolicyIncludingEffects {

    public static void main(String[] args) {

        ElasticityCapability scaleIn = ElasticityCapability.ScaleIn();
        //primitive operations are required if different enforcing controllers are used with rSYBL, and we want to enforce a particular set of oeprations
        //for example, to deregister a unit from a load balancer before removing it, in the case this is not done automatically by the unit
        //but in general the primitive operations can be ignored
        ElasticityCapability scaleOut = ElasticityCapability.ScaleOut().withPrimitiveOperations("primitive operation1", "primitive operation 2");

        ServiceUnit softwareUnit_1 = SingleSoftwareUnit("SoftwareUnit_1")
                .exposes(Capability.Variable("SoftwareUnit_1_Address"));

        //define the elastic unit
        ServiceUnit softwareUnit_2 = SingleSoftwareUnit("SoftwareUnit_2")
                //list of provided elasticity capabilities
                .provides(scaleIn, scaleOut)
                //direct scaling policy stating when metric > threshold scale OUT, when < scale IN
                //the responseTime metric must be exposed by the unit and collected by MELA and the underlying monitoring mechanism
                .controlledBy(Strategy("EP_ST1")
                        .when(Constraint.MetricConstraint("EP_ST1_CO1", new Metric("responseTime", "ms")).lessThan("10"))
                        .enforce(scaleIn))
                .controlledBy(Strategy("EP_ST2")
                        .when(Constraint.MetricConstraint("EP_ST1_CO2", new Metric("responseTime", "ms")).greaterThan("50"))
                        .enforce(scaleOut))
                .withLifecycleAction(LifecyclePhase.START, BASHAction("register to SoftwareUnit_1"))
                .withLifecycleAction(LifecyclePhase.STOP, BASHAction("deregister from SoftwareUnit_1"))
                //requires the IP of the software unit will be injected in the /etc/environment of any unit
                //which wants to connect to this one
                .requires(Requirement.Requirement("SoftwareUnit_1_Address"));

        
        //rest of the template is normal, without any special information
        OperatingSystemUnit virtualContainer_1 = OperatingSystemUnit("VirtualContainer_1");

        //virtual container for second software unit
        OperatingSystemUnit virtualContainer_2 = OperatingSystemUnit("VirtualContainer_2") // configuration of provider and software packages here              ....
                ;

        //group units in a logical grouping concept called topology
        //topologies are used to logically group units. At minimum a service has one topology with one unit
        ServiceTopology softwareTopology = ServiceTopology("ServiceTopologyID")
                .withServiceUnits(virtualContainer_1, softwareUnit_1,
                        virtualContainer_2, softwareUnit_2
                );

        //link all units and topologies together and define the service, including relationships between units
        CloudService serviceTemplate = ServiceTemplate("Service_2")
                .consistsOfTopologies(softwareTopology)
                //defining CONNECT_TO and HOSTED_ON relationships
                .andRelationships(
                        //which software unit is hosted on which virtual container
                        HostedOnRelation("software1ToVirtualContainer1")
                        .from(softwareUnit_1)
                        .to(virtualContainer_1),
                        HostedOnRelation("software2ToVirtualContainer2")
                        .from(softwareUnit_2)
                        .to(virtualContainer_2),
                        //and relation that specifies the IP of the First Unit must be injected
                        //in the second unit
                        //IP is also injected in the unit with relationship name + "_IP such as: software1Address_IP
                        ConnectToRelation("software1Address")
                        .from(softwareUnit_1.getContext().get("SoftwareUnit_1_Address"))
                        .to(softwareUnit_2.getContext().get("SoftwareUnit_1_Address"))
                )
                //as we can have horizontally scalable software unit(one service unit can have more instances)
                //metrics must be aggregated between unit instances
                .withDefaultMetrics();

        //instantiate COMOT orchestrator to deploy, monitor and control the service
        COMOTOrchestrator orchestrator = new COMOTOrchestrator("COMOT IP");

        //alternatively, if comot tools are deployed in a distributed manner, each on different IPs and or PORTS,
        //the orchestrator can be configured with options for each too:  .withSalsaIP(), .withSalsaPORT(), etc
        //service deployment options
        //only deploy the service
        orchestrator.deploy(serviceTemplate);

        //deploy and also monitor the service using MELA
        orchestrator.deployAndMonitor(serviceTemplate);

        //monitor previousely deployed service
        orchestrator.monitorExisting(serviceTemplate);

        //deploy, monitor and control the service's elasticity
        //for this it is required for us to define constraints and strategies
        //for this please check template X
        orchestrator.deployAndControl(serviceTemplate);

    }
}
