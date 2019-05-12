#include <Timer.h>
#include "Sender.h"
//#include <printf.h>


module SenderC 
{
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
	uses interface Timer<TMilli> as Timer1;
	uses interface Timer<TMilli> as Timer2;
	uses interface Timer<TMilli> as Timer3;
	uses interface Timer<TMilli> as Timer4;
	uses interface Timer<TMilli> as Timer5;
	uses interface Timer<TMilli> as Timer6;
	uses interface Packet;
  	uses interface AMPacket;
  	uses interface AMSend;
  	uses interface CC2420Packet;
  	uses interface SplitControl as AMControl;
	uses interface LocalTime<TMilli>;
	uses interface Receive;
	 uses interface Read<uint16_t> as BatteryRead;
}
	
implementation 
{
	bool busy = FALSE;
  	message_t pkt ;

	//YOU WILL RECEIVE THESE FROM THE BASE STATION
	float    prop_delay=0,phase_delay=0;

	//YOU WILL NEED THESE TO CALCULATE THE PROP AND PHASE DELAYS FOR THE MOTE ABOVE
	uint32_t    T1,T2,T3,T4;
	uint16_t min_v1;
	uint16_t min_v2;
	uint16_t min_v3;
	uint16_t min_v4;
	
	event void Boot.booted() 
	{
		call AMControl.start();
	}

	event void AMControl.startDone(error_t err) 
	{
    	if (err == SUCCESS) 
			{
			// for time sync
      		call Timer0.startPeriodic(2000); 
			 //for data aggregation
			call Timer5.startPeriodic(10000);
			// for energy checking
			call Timer6.startPeriodic(700);

      		}
    	else
      		call AMControl.start();
  	} 
	
	
	//TIME SYNCHRONIZATION
	event void Timer0.fired() 
	{
	 	
		TimeSync* newpkt = (TimeSync*)(call Packet.getPayload(&pkt, sizeof(TimeSync)));
		newpkt->stage=0;
		newpkt->nodeid_t=2100;
		call CC2420Packet.setPower (&pkt, 31);	
		T1 = call LocalTime.get();
		if(!busy)
		{	
    		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(TimeSync)) == SUCCESS)
			{
				
				busy=TRUE;					
			}
		}
	}

	//TDMA FOR DATA AGGREGATION
	//Tree 1
	event void Timer1.fired()
	{
		if (!busy) 
		{
    		serial_pkt* sfpkt = (serial_pkt*)(call Packet.getPayload(&pkt, sizeof (serial_pkt)));
    		sfpkt-> nodeid=2100;
    		sfpkt->ackn= 0x1;
    		call CC2420Packet.setPower (&pkt, 31);	
    		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(serial_pkt)) == SUCCESS) 
    		{	
    			call Leds.set(1);
    			busy = TRUE;
    		}

		}
	}
   	
   	event void Timer2.fired()
   	{
 		if (!busy) 
		{
    		serial_pkt* sfpkt = (serial_pkt*)(call Packet.getPayload(&pkt, sizeof (serial_pkt)));
    		sfpkt-> nodeid=2100;
    		sfpkt->ackn= 0x2;

    		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(serial_pkt)) == SUCCESS) 
    		{
      			busy = TRUE;
    		}
		}
	}
	
	event void Timer3.fired()
	{
			
		if (!busy) 
		{
    		serial_pkt* sfpkt = (serial_pkt*)(call Packet.getPayload(&pkt, sizeof (serial_pkt)));
    		sfpkt-> nodeid=2100;
    		sfpkt->ackn= 0x3;
    			
			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(serial_pkt)) == SUCCESS) 
			{
      			busy = TRUE;
    		}

		}
	}
	
	event void Timer4.fired()
	{
		if (!busy) 
		{
    		serial_pkt* sfpkt = (serial_pkt*)(call Packet.getPayload(&pkt, sizeof (serial_pkt)));
    		sfpkt-> nodeid=2100;
    		sfpkt->ackn= 0x4;

    		if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(serial_pkt)) == SUCCESS) 
    		{
      			busy = TRUE;
      				
    		}
		}
	} 
 
 	//starting of TDMA
 	event void Timer5.fired()
 	{
		call Timer1.startOneShot(1501);
	 	//call Timer2.startOneShot(2001);
	 	//call Timer3.startOneShot(2501);
	 	//call Timer4.startOneShot(2998);
	} 

	// battery sensing
	event void Timer6.fired()
  		{
    		if(call BatteryRead.read() == SUCCESS)
    		{
    		
			energy* newpkt = (energy*)(call Packet.getPayload(&pkt, sizeof (energy)));
			newpkt->serial_id_1=1;
			newpkt->serial_id_2=2;
			newpkt->serial_id_3=3;
			newpkt->serial_id_4=4;
			newpkt->value_2=min_v2;
			//call Leds.led2Toggle();
    		call CC2420Packet.setPower (&pkt, 31);	
						if(!busy)
							{                        
								if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(energy)) == SUCCESS) 
									{	
											//call Leds.led1Toggle();
											//call Leds.set(7);
											busy = TRUE;
    								} 
  							}
  			}
   				
 		}

	event void BatteryRead.readDone(error_t result, uint16_t val)
	{
		if(result == SUCCESS)
		{
			min_v2=val;
			//call Leds.set(0);
		}

	}
		
	event void AMControl.stopDone(error_t err) {}


	event void AMSend.sendDone(message_t* msg, error_t error) 
	{
    	if (&pkt == msg) 
    	{
      		busy = FALSE;
    	}
  	}

 


	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len)  
	{
		
		
		//DATA AGGREGATION
		if(len==sizeof(BlinkToRadioMsg))
		{   
			BlinkToRadioMsg* btrpkt = (BlinkToRadioMsg*)payload;
			BlinkToRadioMsg* newpkt = (BlinkToRadioMsg*)(call Packet.getPayload(&pkt, sizeof (BlinkToRadioMsg)));
			
			if(btrpkt-> nodeid_1==2111 || btrpkt->nodeid_1==2121 || btrpkt->nodeid_1 ==2211 || newpkt->nodeid_1 == 2221)
			{
			
				
					newpkt->serial_id=btrpkt-> nodeid_1;		
					newpkt->nodeid_3= btrpkt->nodeid_3;
                	newpkt->counter_3 = btrpkt->counter_3;
                	newpkt->time_stamp_3 = btrpkt-> time_stamp_3;
					newpkt->nodeid_2 = btrpkt-> nodeid_2;
                	newpkt->counter_2 = btrpkt-> counter_2;
                	newpkt->time_stamp_2 = btrpkt-> time_stamp_2;
					newpkt->nodeid_1 = btrpkt-> nodeid_1;
                	newpkt->counter_1 = btrpkt-> counter_1;
                	newpkt->time_stamp_1= btrpkt-> time_stamp_1;
					call CC2420Packet.setPower (&pkt, 31);	
					if(!busy)
					{                        
						if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) 
						{
							//call Leds.set(7);
							busy = TRUE;
    					} 
  					}
  			}
  			if(btrpkt-> nodeid_1==1111 || btrpkt->nodeid_1==1121 || btrpkt->nodeid_1 ==1211 || newpkt->nodeid_1 == 1221)
  			{	
  				newpkt=btrpkt;
  				call CC2420Packet.setPower (&pkt, 31);	
					
						if(!busy)
							{                        
								if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(BlinkToRadioMsg)) == SUCCESS) 
									{		
											//call Leds.led1Toggle();
											busy = TRUE;
    								} 
  							}
  			}
  						
		}  

  		//TIME SYNCHRONIZATION
		if(len==sizeof(TimeSync))
		{

			
			TimeSync* btrpkt = (TimeSync*)payload;
			TimeSync* newpkt = (TimeSync*)(call Packet.getPayload(&pkt, sizeof (TimeSync)));
			bool above = FALSE;
			bool below = FALSE;
			//call Leds.set(7);
			if(btrpkt->nodeid_t==2111 || btrpkt->nodeid_t==2121 || btrpkt->nodeid_t==2211 || btrpkt->nodeid_t==2221)
				above =TRUE;
			if(btrpkt->nodeid_t==0000)
				below =TRUE;
			if(above || below)
			{
				
				
				newpkt->nodeid_t=2100;

				//YOU HAVE TO NOTE DOWN T2,T3 AND SEND DOWN
				if(btrpkt->stage==0 && below)	
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

				//YOU HAVE RECEIVED PROP AND PHASE DELAY FROM THE MOTE BELOW	
	 			if(btrpkt->stage==1 && below)
				{ 
					//call Leds.set(3);
		    		phase_delay=btrpkt->phase_delay;
		    		prop_delay=btrpkt->prop_delay;
				}
		
				//YOU HAVE RECEIVED T2,T3 AND MUST IN TURN SEND PROP AND PHASE DELAY TO MOTE ABOVE
				if(btrpkt->stage== 2 && above)	
				{ 
			    	T4=call LocalTime.get();
    				T2=btrpkt->T2;
        			T3=btrpkt->T3;
					newpkt->phase_delay = ((T4-T3-T2+T1))/2; 
					newpkt->prop_delay = ((T4-T3)+(T2-T1))/2;
					newpkt->stage=1;
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
		//Query Based Reactive Routing
		if(len==sizeof(query))
		{	
			query* btrpkt = (query*)payload;
			query* newpkt = (query*)(call Packet.getPayload(&pkt, sizeof (query)));
			newpkt->flag = btrpkt->flag-1;
			newpkt->nodeid=	btrpkt->nodeid;
			if((btrpkt->nodeid>=1100 && btrpkt->nodeid<2224) && btrpkt->flag!=0)
			{	
					if(!busy)
						{	call CC2420Packet.setPower (&pkt, 31);
                			if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(query)) == SUCCESS)
								{
									call Leds.led0Toggle();
									busy=TRUE;
								}
						}
			}
				
		}
		//Response of query
		if(len==sizeof(response))
		{	
			response* btrpkt = (response*)payload;
			if((btrpkt->nodeid>=1100 && btrpkt->nodeid<2224) && btrpkt->flag!=0)
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
									call Leds.led2Toggle();
									busy=TRUE;
									
								}
						}
			}
				
		}

		//energy routing
		if(len==sizeof(energy))
		{	
			energy* btrpkt = (energy*)payload;
			energy* newpkt = (energy*)(call Packet.getPayload(&pkt, sizeof (energy)));
			
			newpkt=btrpkt;
			newpkt-> value_2 =min_v2;
			min_v1=btrpkt->value_1;
			min_v3=btrpkt->value_3;
			min_v4=btrpkt->value_4;
						if(!busy)
						{	
							call CC2420Packet.setPower (&pkt, 31);
               				if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(energy)) == SUCCESS)
								{
									busy=TRUE;
									call Leds.led2Toggle();
								}
						}
				
		}
 
		return msg;
	}
	
}

