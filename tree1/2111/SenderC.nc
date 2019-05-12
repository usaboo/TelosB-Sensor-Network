#include <Timer.h>
#include "Sender.h"

#include <printf.h> 
#include <stdio.h>
#include <string.h>


module SenderC 

{
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
	uses interface Timer<TMilli> as Timer1;
  	uses interface Packet;
  	uses interface AMPacket;
  	uses interface AMSend;
  	uses interface SplitControl as AMControl;
	uses interface Receive;
	uses interface CC2420Packet;
	uses interface LocalTime<TMilli>;
	uses interface Read<uint16_t>;
}

	

implementation 
{
	
	bool busy = FALSE;
  	message_t pkt ;
	//YOU WILL RECEIVE FROM MOTE BELOW
	float prop_delay=0,phase_delay=0;
	
	//YOU WILL NEED THESE WHILE SYNCING WITH MOTE ABOVE
	uint32_t    T1,T2,T3,T4;

	//FOR DATA AGGREGATION AS YOU SHOULD NOT REINITIALIZE VARIABLES
	uint16_t nodeid_1;
	uint16_t counter_1;
  	float time_stamp_1; 
	//TO SEND IT TO SERIAL FORWARDER
	uint16_t nodeid_2;
	uint16_t counter_2;
  	float time_stamp_2; 
	uint16_t nodeid_3;
	uint16_t counter_3;
  	float time_stamp_3; 
	uint16_t serial_id;

	//DO NOT EDIT
	event void Boot.booted() 
	{
		call AMControl.start();
	}

	//DO NOT EDIT
	event void AMControl.startDone(error_t err) 
	{
    		if (err == SUCCESS)
			{ 
      			//DATA AGGREGATION
      			call Timer0.startPeriodic(10000);

				//TIME SYNCHRONIZATION
				call Timer1.startPeriodic(2000);
			}
    		else
      			call AMControl.start();
  	}


  	event void AMControl.stopDone(error_t err) {}

	 
	//FOR DATA AGGREGATION TO SEND TO MOTE BELOW
	event void Timer0.fired() 
	{
		//START COLLECTING DATA
		call Read.read();
    	
			
	}

	event void Read.readDone(error_t result, uint16_t data) 
    {
		if (result == SUCCESS)
		{
			nodeid_1 = 2111;
    		counter_1 = data;
			time_stamp_1= call LocalTime.get() + prop_delay - phase_delay;
			//call Leds.set(1);
		
     	}

  	}

	
	//TO INITIATE TIME SYNCHRONIZATION WITH MOTE ABOVE
	event void Timer1.fired() 
	{
		
		TimeSync* btrpkt = (TimeSync*)(call Packet.getPayload(&pkt, sizeof (TimeSync)));
    	
		//SINCE YOU WANT THE NODE ABOVE TO NOTE DOWN T2,T3 AND SEND BACK 
    	btrpkt->stage = 0;
    	
    	//SINCE THE NODE ABOVE WILL ONLY TIME SYNC WITH YOU WHEN IT'S SURE IT'S YOU
    	btrpkt -> nodeid_t = 2111;
		
		//NOTE DOWN T1 BEFORE SENDING
    	T1=call LocalTime.get();
    	call CC2420Packet.setPower (&pkt, 31);	

		if (!busy) 
		{
    		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(TimeSync)) == SUCCESS)
			{
				
				busy = TRUE;			
			}
		}
   
    }		
	

	event void AMSend.sendDone(message_t* msg, error_t error) 
	{
    	if (&pkt == msg) 
		{
			//call Leds.set(0);
			busy = FALSE;
    	}
  	}

  

  	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) 
	
	{		
		if(len==sizeof(TimeSync))
		{


			//IMPORTANT NOTE ABOUT TIMESYNC->stage
			//IF IT IS 0 IT MEANS NOTE DOWN T2,T3 AND SEND DOWN
  			//IF IT IS 1 IT MEANS YOU HAVE RECEIVED PROP AND PHASE DELAYS
  			//IF IT IS 2 IT MEANS YOU HAVE RECEIVED T2,T3 AND MUST NOTE DOWN T4 AND CALCULATE PROP AND PHASE DELAYS
				
			TimeSync* btrpkt = (TimeSync*)payload;
			TimeSync* newpkt = (TimeSync*)(call Packet.getPayload(&pkt, sizeof (TimeSync)));

			//FIRST OF ALL YOU WILL ONLY DO TIME SYNC WITH NEIGHBOURS
			if(btrpkt -> nodeid_t == 2112 || btrpkt -> nodeid_t == 2100)
			
			{
				//IMMEDIATELY SET YOUR NODE ID IN THE PACKET YOU WILL SEND AS OTHER NODES NEED TO KNOW WHO YOU ARE
				newpkt -> nodeid_t = 2111;
	 			
				//YOU HAVE TO NOTE DOWN T2,T3 AND SEND DOWN
				if(btrpkt->stage==0 && btrpkt->nodeid_t==2100)	
				{	 
			    		
					newpkt->T2 =call LocalTime.get();

					//THE MOTE BELOW SHOULD KNOW THAT YOU ARE SENDING T2,T3 DOWN
					newpkt->stage =2;
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
				

				//YOU HAVE RECEIVED PROP AND PHASE DELAYS FROM NODE BELOW
	 			if(btrpkt->stage == 1 && btrpkt->nodeid_t==2100)
				{

		    		//call Leds.set(3);
		    		phase_delay=btrpkt->phase_delay;
		    		prop_delay=btrpkt->prop_delay;
				}
		
				
				//YOU HAVE RECEIVED T2,T3 FROM NODE ABOVE AND MUST IN TURN SEND IT PROP AND PHASE DELAYS
				if(btrpkt->stage ==2 && btrpkt->nodeid_t==2112)	
				{	 
			    		
					T4=call LocalTime.get();
    				T2=btrpkt->T2;
        			T3=btrpkt->T3;
					newpkt->phase_delay = ((T4-T3-T2+T1))/2; 
					newpkt->prop_delay = ((T4-T3)+(T2-T1))/2;
					//call Leds.set(3);	
					//THE MOTE ABOVE SHOULD KNOW THAT YOU ARE SENDING PROP DELAYS
					newpkt->stage =1;
					call CC2420Packet.setPower (&pkt, 31);	
					if(!busy)
					{
						if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(TimeSync)) == SUCCESS)
						{      							
							busy=TRUE;
						}
					}
				}
			}
		}
		// response from above motes
		if(len==sizeof(response))
		{
			response* btrpkt = (response*)payload;
			if((btrpkt->nodeid == 2112 || btrpkt->nodeid == 2113) && btrpkt->flag !=0)
				{
					if(!busy)
					{	
						
						response* newpkt = (response*)(call Packet.getPayload(&pkt, sizeof (response)));
						newpkt->nodeid=btrpkt->nodeid;
						newpkt->counter=btrpkt->counter;
						newpkt->time_stamp=btrpkt->time_stamp;
						newpkt->flag=btrpkt->flag-1;
						call CC2420Packet.setPower (&pkt, 31);
                		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(response)) == SUCCESS)
						{
							busy=TRUE;
							//call Leds.set(7);
							call Leds.led2Toggle();
						}
					}
				}

		}
		//DATA AGGREGATION REQUEST FROM SERIAL FORWARDER
	
		if(len==sizeof(serial_pkt))
		{ 
			
				serial_pkt* xyz = (serial_pkt*)payload;
				  
				if(xyz->nodeid==2100)
				{
			
				// ACK RECEIVED FROM SERIAL FORWARDER
		   			if(xyz->ackn==0x1)
		   			{

					BlinkToRadioMsg* newpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof (BlinkToRadioMsg)));
					newpkt->nodeid_3=nodeid_3;
                	newpkt->counter_3 = counter_3;
                	newpkt->time_stamp_3=time_stamp_3;
					newpkt->nodeid_2=nodeid_2;
                	newpkt->counter_2 = counter_2;
                	newpkt->time_stamp_2=time_stamp_2;
					newpkt->nodeid_1=nodeid_1;
                	newpkt->counter_1 = counter_1;
                	newpkt->time_stamp_1=time_stamp_1;
                	call CC2420Packet.setPower (&pkt, 31);	
					if(!busy)
					{
                		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS)
						{
							call Leds.set(7);			  			
							//received=FALSE;
							busy=TRUE;
						}
					}
		   
					}
				

			}
		}
	
		//DATA AGGREGATION FROM LEVEL 2 MOTES
		if(len==sizeof(BlinkToRadioMsg))
		{  
				
			
			BlinkToRadioMsg* abc = (BlinkToRadioMsg*)payload;
			
        		
        	if(abc->nodeid_2==2112)   		
			{
				//call Leds.set(4);  
				
				nodeid_3=abc->nodeid_3;
                counter_3 = abc->counter_3;
                time_stamp_3=abc->time_stamp_3;
				
				nodeid_2=abc->nodeid_2;
                counter_2 = abc->counter_2;
                time_stamp_2=abc->time_stamp_2;    
				           	
			}

		}

		if(len==sizeof(query))
		{	
			query* btrpkt = (query*)payload;
				if((btrpkt->nodeid == 2112 || btrpkt->nodeid == 2113) && btrpkt->flag!=0)
				{
					if(!busy)
					{	
						query* newpkt = (query*)(call Packet.getPayload(&pkt, sizeof (query)));
						newpkt->flag = btrpkt->flag-1;
						newpkt->nodeid=	btrpkt->nodeid;
						call CC2420Packet.setPower (&pkt, 31);
                		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(query)) == SUCCESS)
						{
							busy=TRUE;
							//call Leds.set(newpkt->nodeid);
							//call Leds.led0Toggle();
						}
					}
				}
				
				if(btrpkt->nodeid == 2111 && btrpkt->flag!=0)
				{	
					response* newpkt = (response*)(call Packet.getPayload(&pkt, sizeof (response)));
					newpkt->nodeid=nodeid_1;
					newpkt->counter=counter_1;
					newpkt->time_stamp=call LocalTime.get() + prop_delay - phase_delay;
					newpkt->flag=3;

					if(!busy)
					{	
						call CC2420Packet.setPower (&pkt, 31);
                		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(response)) == SUCCESS)
						{
							busy=TRUE;
							//call Leds.led1Toggle();
							//call Leds.set(1);
						}
					}
				}
		} 
		
		return msg;	
	}
		
 		
}



