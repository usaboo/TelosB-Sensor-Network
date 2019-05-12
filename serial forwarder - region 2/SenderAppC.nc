 #include <Timer.h>
 #include "Sender.h"
 
 configuration SenderAppC {
 }
 implementation {
   components MainC;
   components LedsC;
   components SenderC as App;
   components new TimerMilliC() as Timer0;         //transmission ke liye
   components new TimerMilliC() as Timer1;
   components new TimerMilliC() as Timer2;
   components new TimerMilliC() as Timer3;
   components new TimerMilliC() as Timer4;
   components new TimerMilliC() as Timer5;
   components new TimerMilliC() as Timer6;
   components ActiveMessageC;
   components new AMSenderC(AM_BLINKTORADIO);
   components new AMReceiverC(AM_BLINKTORADIO);
   components SerialPrintfC;
   components LocalTimeMilliC;	
    components CC2420PacketC;
     components new Msp430InternalVoltageC();
   
   App.BatteryRead   -> Msp430InternalVoltageC.Read;
 
	
   App.Boot -> MainC;
   App.Leds -> LedsC;
   App.Timer0 -> Timer0;
   App.Timer1 -> Timer1;
   App.Timer2 -> Timer2;
   App.Timer3 -> Timer3;
   App.Timer4 -> Timer4;
   App.Timer5 -> Timer5;
   App.Timer6 -> Timer6;
   
   App.Packet -> AMSenderC;
   App.AMPacket -> AMSenderC;
   App.AMSend -> AMSenderC;
   App.AMControl -> ActiveMessageC;
   
   App.CC2420Packet -> CC2420PacketC;
   App.LocalTime->LocalTimeMilliC;
   App.Receive -> AMReceiverC;
 }

