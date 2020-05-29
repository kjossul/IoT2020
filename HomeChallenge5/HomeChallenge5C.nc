#include "printf.h" 
#include "Timer.h"
#include "HomeChallenge5.h"
 
/**
 * Implementation of Home Challenge #1 for IoT course 2019/2020 @ PoliMi.
 * The challenge consists in setting up 3 motes exchanging messages with each other,
 * each one sending at different frequencies (1, 3 and 5 Hz respectively) and incrementing
 * a local counter everytime a message is received.
 * Messages whose counter value is a multiple of 10 switch off all the leds, otherwise
 * they toggle a single LED based on the sender (led0 if sent from node 1 and so on).
 */

module HomeChallenge5C @safe() {
  uses {
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
    interface Random;
  }
}
implementation {

  message_t packet;

  bool locked;
  uint16_t period = 5000;
  char id[2];
  
  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      if (TOS_NODE_ID != 1) {
        call MilliTimer.startPeriodic(period);
      }
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
  }
  
  event void MilliTimer.fired() {
    if (locked) {
      return;
    }
    else {
      mymsg_t* rm = (mymsg_t*)call Packet.getPayload(&packet, sizeof(mymsg_t));
      if (rm == NULL) {
	return;
      }
      rm->value = call Random.rand16() % 101;
      strcpy(rm->topic, "foo/bar");
      // Appends mote id to the topic to make it unique
      sprintf(id, "%d", TOS_NODE_ID);
      strcat(rm->topic, id);
      if (call AMSend.send(1, &packet, sizeof(mymsg_t)) == SUCCESS) {
	printf("Packet sent with value %u and topic %s.\n", rm->value, rm->topic);	
	locked = TRUE;
      }
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
    if (len != sizeof(mymsg_t)) {return bufPtr;}
    else {
      mymsg_t* rm = (mymsg_t*)payload;
      
      printf("Received %u - %s\n", rm->value, rm->topic);
      return bufPtr;
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

}




