/**
 *  Source file for implementation of module sendAckC in which
 *  the node 1 send a request to node 2 until it receives a response.
 *  The reply message contains a reading from the Fake Sensor.
 *
 *  @author Luca Pietro Borsani
 */

#include "sendAck.h"
#include "Timer.h"

module sendAckC @safe() {

  uses {
  /****** INTERFACES *****/
	interface Boot; 
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
    
    //New Interface required
    interface PacketAcknowledgements;
    
	//interface used to perform sensor reading (to get the value from a sensor)
	interface Read<uint16_t>;
  }

} implementation {

  uint16_t counter=0;
  uint16_t rec_id;
  message_t packet;

  void sendReq();
  void sendResp();
  
  
  //***************** Send request function ********************//

  void sendReq() {
   
   my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
  
   mess-> msg_type = REQ;
   mess-> counter = counter ++;
   
   dgb("radio_send","I am trying to send a Request to node 2 at time %s \n ", sim_time_string() );
   
   // we are calling the function for receiving ACK//
   
   call PacketAcknowledgements.requestAck (&packet);
   
   if ( call AMSend.send(2,&packet,sizeof(my_msg_t)) == SUCCESS){
   
   //Showing what is gonna happen//
   
   dbg_clear("radio_send","Packet Passed \n");
   dbg_clear("radio_pack"," \t Source is  \n", call AMPacket.source( &packet));
   dbg_clear("radio_pack"," \t Destination is \n", call AMPacket.destination ( &packet ));
   
   //we are specifying the msg structure//
   
   dbg_clear("radio_pack","\t\t AM TYPE \n", call AMPacket.type (&packet));
   
   dbg_clear("radio_pack","\t\t MSG TYPE %hhu \n", mess->msg_type);
   dbg_clear("radio_pack","\t\t MSG COUNTER FIELD %hhu \n", mess->counter);
   dbg_clear("radio_pack","\t\t MSG VALUE FIELD %hhu \n", mess->value);
   
   dbg_clear("radio_send"," \n trying to send  \n ");   
   }
   
   
   
 }        

  //****************** Task send response *****************//
  
  void sendResp() {
  	
	call Read.read();
  }

  //***************** Boot interface ********************//
  
  event void Boot.booted() {
	dbg("boot","The Application is now booted.\n");
	call SplitControl.start();
		
  }

  //***************** SplitControl interface ********************//
  event void AMControl.startDone(error_t err){
    
    if (err == SUCCESS) {
    
    dbg("radio","radio on!\n ");
    
    if (TOS_NODE_ID = 1) {
    // node 1 will make the the event starting...
    
    dbg("role","I am node 1 \n");
    call MilliTimer.startPeriodic ( 100 );
    
    }
    
    else{
    call SplitControl.start();
    }
    
    
    }
  }
  
  event void AMControl.stopDone(error_t err){
    /* Fill it ... */
  }


  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {
		call SendReq;
  }
  

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {

	if(&packet== buf && err == SUCCESS){
	// control the ACK // 
	if ( call PacketAcknowledgements.wasAcked(buf)) {
	dgb_clear("radio_ack","ACK received");
	// PER RICCARDO/RAFFAELE DOBBIAMO USARE I DBG PER MOSTRARE I FIELD DEL MESSAGGIO RICEVUTO //
	call MilliTimer.stop();

	}else {
	dgb_clear("radio_ack","ACK not received");
	call sendReq();
	
	}
	
	dgb_clear("radio_send","at time %s \n") , sim_time_string());

	}

  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	
   my_msg_t* mess=(my_msg_t*)payload;
   rec_id = mess->value;
  
   
   dgb("radio_rec","I am trying to receive a message from Node 1 at time %s \n ", sim_time_string() );
   
   //Showing what is gonna happen//
   
   dbg_clear("radio_pack"," \t Source is  \n", call AMPacket.source( buf ));
   dbg_clear("radio_pack"," \t Destination is  \n", call AMPacket.destination( buf ));
        
   //we are specifying the msg structure//
   
   dbg_clear("radio_pack","\t\t AM TYPE \n", call AMPacket.type (&packet));
   dbg_clear("radio_pack","\t\t MSG TYPE %hhu \n", mess->msg_type);
   dbg_clear("radio_pack","\t\t MSG COUNTER FIELD %hhu \n", mess->counter);
   dbg_clear("radio_pack","\t\t MSG VALUE FIELD %hhu \n", mess->value);
  
  
   dgb("radio_rec"," \n ");
  
   if (mess->msg_type == REQ ){
  		post sendResp();
   
   }
  
  	return buf;
  
    }
  }
  
  //************************* Read interface **********************//
  event void Read.readDone(error_t result, uint16_t data) {

   my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
  
   mess-> msg_type = RESP;
   mess-> value = value;
   mess->counter =data;
   
   dgb("radio_send","I am trying to send a Response to node 1 at time %s \n ", sim_time_string() );
   
   // we are calling the function for receiving ACK//
   
   call PacketAcknowledgements.requestAck (&packet);
   
   if ( call AMSend.send(1,&packet,sizeof(my_msg_t)) == SUCCESS){
   
   //Showing what is gonna happen//
   
   dbg_clear("radio_send","Packet Passed \n");
   dbg_clear("radio_pack"," \t Source is  \n", call AMPacket.source( &packet));
   dbg_clear("radio_pack"," \t Destination is \n", call AMPacket.destination ( &packet ));
   
   //we are specifying the msg structure//
   
   dbg_clear("radio_pack","\t\t AM TYPE \n", call AMPacket.type (&packet));
   
   dbg_clear("radio_pack","\t\t MSG TYPE %hhu \n", mess->msg_type);
   dbg_clear("radio_pack","\t\t MSG COUNTER FIELD %hhu \n", mess->counter);
   dbg_clear("radio_pack","\t\t MSG VALUE FIELD %hhu \n", mess->value);
   
   dbg_clear("radio_send"," \n trying to send  \n ");   
   }  
  
  }
  



