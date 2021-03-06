//
//                           SimuLTE
// Copyright (C) 2013 Antonio Virdis
//
// This file is part of a software released under the license included in file
// "license.pdf". This license can be also found at http://www.ltesimulator.com/
// The above file and the present reference are part of the software itself,
// and cannot be removed from it.
//

import inet.networklayer.autorouting.ipv4.IPv4NetworkConfigurator;
import inet.networklayer.ipv4.RoutingTableRecorder;
import inet.nodes.inet.Router;
import inet.nodes.inet.StandardHost;
import inet.util.ThruputMeteringChannel;
import inet.world.radio.ChannelControl;
import lte.corenetwork.binder.LteBinder;
import lte.corenetwork.nodes.Ue;
import lte.corenetwork.nodes.eNBpp;
import lte.epc.PgwStandard;
import lte.epc.SgwStandard;

network swarm_network
{
    parameters:
        int numUe = default(1);
        @display("i=block/network2;bgb=1194,600;bgi=background/campus");
    types:
        channel networkConnection extends ThruputMeteringChannel
        {
            @signal[channelBusy](type="int");
            @signal[messageSent](type=cMessage);
            @signal[messageDiscarded](type=cMessage);
            @statistic[busy](source=channelBusy; record=vector?; interpolationmode=sample-hold);
            @statistic[utilization](source="timeavg(channelBusy)"; record=last?);
            @statistic[packets](source="constant1(messageSent)"; record=count?; interpolationmode=none);
            @statistic[packetBytes](source="packetBytes(messageSent)"; record=sum?; unit=B; interpolationmode=none);
            @statistic[packetsDiscarded](source="constant1(messageDiscarded)"; record=count?; interpolationmode=none);
            @statistic[throughput](source="sumPerDuration(packetBits(messageSent))"; record=last?; unit=bps);
            delay = 0.1us;
            datarate = 10Mbps;
            thruputDisplayFormat = "u";
        }
    submodules:
        channelControl: ChannelControl {
            @display("p=50,25;is=s");
        }
        routingRecorder: RoutingTableRecorder {
            @display("p=434,25;is=s");
        }
        configurator: IPv4NetworkConfigurator {
            @display("p=183,25");
            config = xmldoc("lteCoreConfigFiles/lteIpAddresses.xml");
        }
        binder: LteBinder {
            @display("p=310,25;is=s");
        }
        eNodeB: eNBpp {
            @display("is=vl;p=518,346");
        }
        ue[numUe]: Ue {
            parameters:
                @signal[voIPJitter](type="double");
                @statistics[sample](title="voIP jitter"; source="voIPJitter"; record=all; interpolationmode=none);
                @display("i=misc/robot;is=n");
        }
        router1: Router {
            @display("p=671,281");
        }
        Controller: StandardHost {
            @display("p=1010,303;i=device/wifilaptop");
        }
        pgwStandard: PgwStandard {
            nodeType = "PGW";
            @display("p=914,444");
        }
        router: Router {
            @display("p=831,240");
        }
        router3: Router {
            @display("p=1117,271");
        }
        sgwStandard1: SgwStandard {
            @display("p=711,415");
        }
    connections:
        router1.pppg++ <--> networkConnection <--> eNodeB.ppp;
        Controller.ethg++ <--> networkConnection <--> router3.ethg++;

        pgwStandard.pppg++ <--> networkConnection <--> router.pppg++;
        pgwStandard.filterGate <--> networkConnection <--> router3.pppg++;

        router.pppg++ <--> networkConnection <--> sgwStandard1.pppg++;
        router1.pppg++ <--> networkConnection <--> sgwStandard1.pppg++;
}
