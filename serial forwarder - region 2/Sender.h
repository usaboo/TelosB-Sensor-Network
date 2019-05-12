 #ifndef BLINKTORADIO_H
 #define BLINKTORADIO_H
 
 enum {
	AM_BLINKTORADIO = 6,
	AM_BLINKTORADIOMSG = 6,   
	TIMER_PERIOD_MILLI = 5005,
  TIMER_PERIOD_MILLI1= 1333,
  TIMER_PERIOD_MILLI2= 2749,
  TIMER_PERIOD_MILLI3= 3313,
  TIMER_PERIOD_MILLI4= 4129,
  TIME_SYNC = 00,
  DATA_AGGR = 01
 };
 

typedef nx_struct serial_pkt {
	nx_uint16_t nodeid;
	nx_uint16_t ackn;
}  serial_pkt;

typedef nx_struct query {
	nx_uint16_t nodeid;
	nx_uint16_t flag;
}  query;

typedef nx_struct response {
	nx_uint16_t nodeid;
  	nx_uint16_t counter;
  	nx_float time_stamp;
	nx_uint16_t flag;
}  response;

typedef nx_struct energy {
	nx_uint16_t serial_id_1;
  	nx_uint16_t value_1;
	nx_uint16_t serial_id_2;
  	nx_uint16_t value_2;
	nx_uint16_t serial_id_3;
  	nx_uint16_t value_3;
	nx_uint16_t serial_id_4;
  	nx_uint16_t value_4;		
}  energy;


typedef nx_struct TimeSync 
{
  
  nx_uint32_t T2;
  nx_uint32_t T3;
  nx_float phase_delay;
  nx_float prop_delay;
  //NODE ID OF THAT WHICH HAS SENT MESSAGE
  nx_uint16_t nodeid_t;
  //VERY IMPORTANT
  nx_uint8_t stage;
  //IF IT IS 0 IT MEANS NOTE DOWN T2,T3 AND SEND DOWN
  //IF IT IS 1 IT MEANS YOU HAVE RECEIVED PROP AND PHASE DELAYS
  //IF IT IS 2 IT MEANS YOU HAVE RECEIVED T2,T3 AND MUST NOTE DOWN T4 AND CALCULATE PROP AND PHASE DELAYS

} TimeSync;


typedef nx_struct BlinkToRadioMsg {

  nx_uint16_t nodeid_3;
  nx_uint16_t counter_3;
  nx_float time_stamp_3;
  nx_uint16_t nodeid_2;
  nx_uint16_t counter_2;
  nx_float time_stamp_2;
  nx_uint16_t nodeid_1;
  nx_uint16_t counter_1;
  nx_float time_stamp_1;
  nx_uint16_t serial_id;
} BlinkToRadioMsg;

 #endif
