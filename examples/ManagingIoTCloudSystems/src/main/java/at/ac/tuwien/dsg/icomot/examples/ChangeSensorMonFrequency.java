/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package at.ac.tuwien.dsg.icomot.examples;

import java.util.Map;

import at.ac.tuwien.dsg.comot.common.model.ServiceUnit;
import at.ac.tuwien.dsg.comot.orchestrator.interraction.iCOMOTOrchestrator;
import at.ac.tuwien.dsg.comot.orchestrator.interraction.iCOMOTOrchestrator.SensorCapability;
import at.ac.tuwien.dsg.icomot.util.ProcessArgs;
import at.ac.tuwien.dsg.icomot.util.ProcessArgs.Arg;

/**
 * This example simulates sensors and gateways, which send data to the Cloud IOT
 * Platform deployed by the ElasticIoTPlatform.java example file
 * 
 * @author http://dsg.tuwien.ac.at
 */
public class ChangeSensorMonFrequency {

	public static void main(String[] args) {

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

		ServiceUnit sensor = new ServiceUnit("Sensor").ofType("GPSSensors");

		orchestrator.enforceCapabilityOnClassOfUnits(sensor,
				SensorCapability.START);
		orchestrator.enforceCapabilityOnClassOfUnits(sensor,
				SensorCapability.UPDATE_MON_FREQ, "1");

	}
}
