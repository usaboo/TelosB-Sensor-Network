 #include <Timer.h>
 #include "Sender.h"
 
 configuration SenderAppC 
 {
 
 }
 
 implementation 
 {
   components MainC;
   components LedsC;
   components SenderC as App;
   components new TimerMilliC() as Timer0;
   components new DemoSensorC() as Sensor;
   components ActiveMessageC;
   components new AMSenderC(AM_BLINKTORADIO);
   components new AMReceiverC(AM_BLINKTORADIO);
   components LocalTimeMilliC;	
   components CC2420PacketC;
   components SerialPrintfC;
   
	
   App.Boot -> MainC;
   App.Leds -> LedsC;
   App.Timer0 -> Timer0;
   App.Packet -> AMSenderC;
   App.AMPacket -> AMSenderC;
   App.AMSend -> AMSenderC;
   App.AMControl -> ActiveMessageC;
   App.Receive -> AMReceiverC;
   App.LocalTime->LocalTimeMilliC;
   App.CC2420Packet -> CC2420PacketC;
   App.Read -> Sensor;
}

