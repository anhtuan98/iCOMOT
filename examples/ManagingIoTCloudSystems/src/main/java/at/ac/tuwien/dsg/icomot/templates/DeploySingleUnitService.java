package at.ac.tuwien.dsg.icomot.templates;

import static at.ac.tuwien.dsg.comot.common.model.ArtifactTemplate.SingleScriptArtifact;
import static at.ac.tuwien.dsg.comot.common.model.ArtifactTemplate.MiscArtifact;
import static at.ac.tuwien.dsg.comot.common.model.BASHAction.BASHAction;
import static at.ac.tuwien.dsg.comot.common.model.CloudService.ServiceTemplate;
import static at.ac.tuwien.dsg.comot.common.model.EntityRelationship.HostedOnRelation;
import static at.ac.tuwien.dsg.comot.common.model.ServiceTopology.ServiceTopology;
import static at.ac.tuwien.dsg.comot.common.model.SoftwareNode.SingleSoftwareUnit;
import at.ac.tuwien.dsg.comot.common.model.CloudService;
import static at.ac.tuwien.dsg.comot.common.model.CommonOperatingSystemSpecification.LocalDocker;
import static at.ac.tuwien.dsg.comot.common.model.CommonOperatingSystemSpecification.OpenstackMicro;
import static at.ac.tuwien.dsg.comot.common.model.CommonOperatingSystemSpecification.OpenstackSmall;
import static at.ac.tuwien.dsg.comot.common.model.CommonOperatingSystemSpecification.OpenstackTiny;
import at.ac.tuwien.dsg.comot.common.model.OperatingSystemUnit;
import static at.ac.tuwien.dsg.comot.common.model.OperatingSystemUnit.OperatingSystemUnit;
import at.ac.tuwien.dsg.comot.common.model.LifecyclePhase;
import at.ac.tuwien.dsg.comot.common.model.ServiceTopology;
import at.ac.tuwien.dsg.comot.common.model.ServiceUnit;
import at.ac.tuwien.dsg.comot.orchestrator.interraction.COMOTOrchestrator;

/**
 *
 * This template shows the most basic configuration of a cloud service, which has a single software unit
 * 
 * @author http://dsg.tuwien.ac.at
 */
public class DeploySingleUnitService {

    public static void main(String[] args) {

        //specify repository holding service software artifacts
        String softwareRepository = "http://URL/";

        //soecify the type of virtual container (VM/Docker Container) whcih will be hosting the software
        OperatingSystemUnit virtualContainer = OperatingSystemUnit("VirtualContainerID")
                //please choose one of the below default providers, or another from at.ac.tuwien.dsg.comot.common.mode.CommonOperatingSystemSpecification
                .providedBy(LocalDocker())
                .providedBy(OpenstackTiny())
                .providedBy(OpenstackMicro())
                .providedBy(OpenstackSmall()
                        //specify if needed common software packages to be installed in the virtual container
                        .addSoftwarePackage("openjdk-7-jre")
                        .addSoftwarePackage("package name")
                        
                        //if custom OS images from the target cloud provider (e.g., OpenStack)should be used for the virtual containers
                        .withBaseImage("a82e054f-4f01-49f9-bc4c-77a98045739c")
                ) //              ....
                ;

        //define the software service unit deployed by a script
        ServiceUnit softwareUnit = SingleSoftwareUnit("SoftwareUnitID")
                //specify additional artifacts to be deployed in the virtual container
                .deployedBy(MiscArtifact(softwareRepository + "softwareArtifact.tar.gz"))
                //specify which script to be used to install the software. This script should take care of all installation taks
                //such as untar-ing archives
                .deployedBy(SingleScriptArtifact(softwareRepository + "installSoftwareUnit.sh"))
                //if required to manage unit's lifecycle, custom actions can be invoked
                .withLifecycleAction(LifecyclePhase.DEPLOY, BASHAction("touch file"))
                .withLifecycleAction(LifecyclePhase.START, BASHAction("service serviceName start"))
                .withLifecycleAction(LifecyclePhase.STOP, BASHAction("service serviceName stop"))
                .withLifecycleAction(LifecyclePhase.UNDEPLOY, BASHAction("touch file"));

        //group units in a logical grouping concept called topology
        //topologies are used to logically group units. At minimum a service has one topology with one unit
        ServiceTopology softwareTopology = ServiceTopology("ServiceTopologyID")
                .withServiceUnits(virtualContainer, softwareUnit
                );

        //link all units and topologies together and define the service, including relationships between units
        CloudService serviceTemplate = ServiceTemplate("Service")
                .consistsOfTopologies(softwareTopology)
                //defining CONNECT_TO and HOSTED_ON relationships
                .andRelationships(
                        //which software unit is hosted on which virtual container
                        HostedOnRelation("softwareToVirtualContainer")
                        .from(softwareUnit)
                        .to(virtualContainer)
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
