 #ifndef BLINKTORADIO_H
 #define BLINKTORADIO_H
 
enum 
{
	AM_BLINKTORADIO = 6,
	AM_BLINKTORADIOMSG = 6,   
	TIMER_PERIOD_MILLI = 5005,
  TIMER_PERIOD_MILLI1= 1333,
  TIMER_PERIOD_MILLI2= 2749,
  TIMER_PERIOD_MILLI3= 3313,
  TIMER_PERIOD_MILLI4= 4129,
};
 

typedef nx_struct TimeSync 
{
  
  nx_uint32_t T2;
  nx_uint32_t T3;
  nx_float phase_delay;
  nx_float prop_delay;
  nx_uint16_t nodeid_t;
  nx_uint8_t stage;
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



#endif
