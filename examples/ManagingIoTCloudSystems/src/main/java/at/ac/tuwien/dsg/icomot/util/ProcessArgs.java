package at.ac.tuwien.dsg.icomot.util;

import java.util.HashMap;
import java.util.Map;

public class ProcessArgs {
	public enum Arg {
		ORCHESTRATOR_IP("iCOMOT_IP"), SALSA_PORT("SALSA_PORT"), SALSA_IP(
				"SALSA_IP"), rSYBL_IP("rSYBL_IP"), rSYBL_PORT("rSYBL_PORT"), GovOps_PORT(
				"GovOps_PORT"), GovOps_IP("GovOps_IP");

		private String arg;

		private Arg(String s) {
			arg = s;
		}

		public String toString() {
			return arg;
		}
		
		
	}

	public static Map<Arg, String> processArgs(String[] args) {
		Map<Arg, String> argsMap = new HashMap<>();
		if (args.length > 0) {
			for(String arg : args){
				if(arg.contains("=")){
					String argKey = arg.split("=")[0];
					String argVal = arg.split("=")[1];
					if(argKey.equals(Arg.ORCHESTRATOR_IP.toString())){
						argsMap.put(Arg.ORCHESTRATOR_IP, argVal);
					} else if(argKey.equals(Arg.SALSA_PORT.toString())){
						argsMap.put(Arg.SALSA_PORT, argVal);
					} else if(argKey.equals(Arg.SALSA_IP.toString())){
						argsMap.put(Arg.SALSA_IP, argVal);
					} else if(argKey.equals(Arg.rSYBL_PORT.toString())){
						argsMap.put(Arg.rSYBL_PORT, argVal);
					} else if(argKey.equals(Arg.rSYBL_IP.toString())){
						argsMap.put(Arg.rSYBL_IP, argVal);
					} else if(argKey.equals(Arg.GovOps_PORT.toString())){
						argsMap.put(Arg.GovOps_PORT, argVal);
					} else if(argKey.equals(Arg.GovOps_IP.toString())){
						argsMap.put(Arg.GovOps_IP, argVal);
					}
				}
			}
		}
		return argsMap;
	}

}
