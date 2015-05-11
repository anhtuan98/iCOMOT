/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package at.ac.tuwien.dsg.icomot.examples;

import at.ac.tuwien.dsg.comot.common.model.ServiceUnit;
import at.ac.tuwien.dsg.comot.orchestrator.interraction.iCOMOTOrchestrator;
import at.ac.tuwien.dsg.comot.orchestrator.interraction.iCOMOTOrchestrator.SensorCapability;

/**
 * This example simulates sensors and gateways, which send data to the Cloud IOT
 * Platform deployed by the ElasticIoTPlatform.java example file
 *
 * @author http://dsg.tuwien.ac.at
 */
public class ChangeSensorMonFrequency {

    public static void main(String[] args) {

        ServiceUnit sensor = new ServiceUnit("Sensor").ofType("FM5300");

        iCOMOTOrchestrator orchestrator = new iCOMOTOrchestrator("localhost");

        orchestrator.enforceCapabilityOnClassOfUnits(sensor, SensorCapability.START);
        orchestrator.enforceCapabilityOnClassOfUnits(sensor, SensorCapability.UPDATE_MON_FREQ, "1");
            
    }
}
