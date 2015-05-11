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
 * This template describes two software units from same service which must communicate,
 * and thus the IP of one called unit must be send to the calling unit.
 * 
 * Moreover, one of the service units should be automatically scaled in/out when a certain threshold
 * is encountered on a certain metric.
 *
 * @author http://dsg.tuwien.ac.at
 */
public class DeployServiceWithCommunicatingUnits {

    public static void main(String[] args) {

        //specify repository holding service software artifacts
        String softwareRepository = "http://URL/";

        //soecify the type of virtual container (VM/Docker Container) whcih will be hosting the software
        OperatingSystemUnit virtualContainer_1 = OperatingSystemUnit("VirtualContainer_1")
                //please choose one of the below default providers, or another from at.ac.tuwien.dsg.comot.common.mode.CommonOperatingSystemSpecification
                .providedBy(OpenstackSmall()
                        //specify if needed common software packages to be installed in the virtual container                        
                        .addSoftwarePackage("package name")
                ) //              ....
                ;

        //virtual container for second software unit
        OperatingSystemUnit virtualContainer_2 = OperatingSystemUnit("VirtualContainer_2") // configuration of provider and software packages here              ....
                ;

        //define the software service to which another unit will connect to
        ServiceUnit softwareUnit_1 = SingleSoftwareUnit("SoftwareUnit_1")
                //specify which script to be used to install the software. This script should take care of all installation taks
                //such as untar-ing archives
                .deployedBy(SingleScriptArtifact(softwareRepository + "installFirstUnit.sh"))
                //if required to manage unit's lifecycle, custom actions can be invoked
                .withLifecycleAction(LifecyclePhase.STOP, BASHAction("service serviceName stop"))
                //the IP of the software unit will be injected in the /etc/environment of any unit
                //which wants to connect to this one
                //under the form SoftwareUnit_1_Address
                .exposes(Capability.Variable("SoftwareUnit_1_Address"));

        //define the software service connecting tot he previous one which another unit will connect to
        ServiceUnit softwareUnit_2 = SingleSoftwareUnit("SoftwareUnit_2")
                //specify which script to be used to install the software. This script should take care of all installation taks
                //such as untar-ing archives
                .deployedBy(SingleScriptArtifact(softwareRepository + "installSecondUnit.sh"))
                //if required to manage unit's lifecycle, custom actions can be invoked
                .withLifecycleAction(LifecyclePhase.STOP, BASHAction("service serviceName stop"))
                //requires the IP of the software unit will be injected in the /etc/environment of any unit
                //which wants to connect to this one
                .requires(Requirement.Requirement("SoftwareUnit_1_Address"));

        //group units in a logical grouping concept called topology
        //topologies are used to logically group units. At minimum a service has one topology with one unit
        ServiceTopology softwareTopology = ServiceTopology("ServiceTopologyID")
                .withServiceUnits(virtualContainer_1, softwareUnit_1,
                        virtualContainer_2, softwareUnit_2
                );

        //link all units and topologies together and define the service, including relationships between units
        CloudService serviceTemplate = ServiceTemplate("Service")
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
