#include <Timer.h>
#include "Sender.h"

module SenderC 

{
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
  	uses interface Packet;
  	uses interface AMPacket;
  	uses interface AMSend;
  	uses interface SplitControl as AMControl;
	uses interface Receive;
	uses interface LocalTime<TMilli>;
	uses interface CC2420Packet;
	uses interface Read<uint16_t>;
}
	

implementation 
{
	

	bool busy = FALSE;
  	message_t pkt ;
  	double prop_delay=0,phase_delay=0;
	uint32_t    t1,t2,t3,t4;
	uint16_t counter_3;
	
	

	event void Boot.booted() 
	{
		call AMControl.start();

	}


	event void AMControl.startDone(error_t err) 
	{
    		if (err == SUCCESS)
			{ 
      			//DATA AGGREGATION	
				call Timer0.startPeriodic(10000);
			}
    		else
     	 		call AMControl.start();
  	}

	//DATA AGGREGATION
	event void Timer0.fired() 
	{		
		//START COLLECTING DATA
    	call Read.read();
    	
	}


  //ONCE DATA COLLECTION IS DONE ONLY YOU CAN SEND.
  event void Read.readDone(error_t result, uint16_t data) 
  {
		if (result == SUCCESS)
		{

			//DATA AGGREGATION PACKET 			
			BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof (BlinkToRadioMsg)));
			btrpkt->nodeid_3 = 2123;
    		btrpkt->counter_3 =data;
    		counter_3=data;
			btrpkt->time_stamp_3= call LocalTime.get() + prop_delay - phase_delay;
			call CC2420Packet.setPower (&pkt, 31);	
			if(!busy)
			{
				if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS)
				{
      				
					call Leds.set(7);
					busy=TRUE;
				}
			}

     	}

  }
	 
	event void AMControl.stopDone(error_t err) {}

	event void AMSend.sendDone(message_t* msg, error_t error) 
	{
    		if (&pkt == msg) 
		{
      		call Leds.set(0);
			busy = FALSE;
    	}
 	}

  

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) 
	{
	
		
		/*IMPORTANT NOTE ABOUT TIMESYNC->stage
		
		IF IT IS 0 IT MEANS NOTE DOWN T2,T3 AND SEND DOWN
  		IF IT IS 1 IT MEANS YOU HAVE RECEIVED PROP AND PHASE DELAYS
  		IF IT IS 2 IT MEANS YOU HAVE RECEIVED T2,T3 AND MUST NOTE DOWN T4 AND CALCULATE PROP AND PHASE DELAYS*/



		//TIME SYNCHRONIZATION
		if(len==sizeof(TimeSync))
		{

			TimeSync* btrpkt = (TimeSync*)payload;
			TimeSync* newpkt = (TimeSync*)(call Packet.getPayload(&pkt, sizeof (TimeSync)));	
			newpkt->nodeid_t=2123;

			//FIRST OF ALL MAKE SURE THE GUY SENDING TIME SYNC PACKET IS IMMEDIATE NEIGHBOUR
			if(btrpkt->nodeid_t==2122)
			{

				
				//YOU HAVE RECEIVED PHASE AND PROP DELAYS FROM BELOW	 		
				if(btrpkt->stage==1)

				{
		    			call Leds.set(3);
		    			phase_delay=btrpkt->phase_delay;
		    			prop_delay=btrpkt->prop_delay;
				}
		
			
				//YOU ARE BEING ASKED TO NOTE DOWN T2,T3 AND SEND DOWN	
				if(btrpkt->stage==0)	
				{ 
					
					newpkt->T2 =call LocalTime.get();
					newpkt->stage=2;
					call CC2420Packet.setPower (&pkt, 31);
					if(!busy)
					{
						if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(TimeSync)) == SUCCESS)
						{  		
							newpkt->T3 = call LocalTime.get();
							busy=TRUE;
						}
					}
				}
			}
		}

		if(len==sizeof(query))
		{	
			query* btrpkt = (query*)payload;
				if(btrpkt->nodeid == 2123 && btrpkt->flag==0)
				{	
					response* newpkt = (response*)(call Packet.getPayload(&pkt, sizeof (response)));
					newpkt->nodeid=2123;
					newpkt->counter=counter_3;
					newpkt->time_stamp=call LocalTime.get() + prop_delay - phase_delay;
					newpkt->flag=5;

					if(!busy)
					{	
						call CC2420Packet.setPower (&pkt, 31);
                		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(response)) == SUCCESS)
						{
							busy=TRUE;
							//call Leds.set(1);
							call Leds.led0Toggle();
						}
					}
				}
		}
		
		
		return msg;	

	}

 		
}
	

	
