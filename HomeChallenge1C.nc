#include "printf.h" 
#include "Timer.h"
#include "HomeChallenge1.h"
 
/**
 * Implementation of Home Challenge #1 for IoT course 2019/2020 @ PoliMi.
 * The challenge consists in setting up 3 motes exchanges messages with each other,
 * each one sending at different frequencies (1, 3 and 5 Hz respectively) and incrementing
 * a local counter everytime a message is received.
 * Messages whose counter value is a multiple of 10 switch off all the leds, otherwise
 * they toggle a single LED based on the sender (led0 if sent from node 1 and so on).
 */

module HomeChallenge1C @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl; // Interface to start the radio
    interface Packet;
  }
}
implementation {

  message_t packet;

  bool locked;
  uint16_t counter = 0;
  int period;
  
  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      if (TOS_NODE_ID == 1) {
        period = 1000;
      } else if (TOS_NODE_ID == 2) {
        period = 333;
      } else {
        period = 200;
      }
      call MilliTimer.startPeriodic(period);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  event void MilliTimer.fired() {
    printf("RadioCountToLedsC: timer fired, counter is %u.\n", counter);
    if (locked) {
      return;
    }
    else {
      radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));
      if (rcm == NULL) {
	return;
      }
	  // use TOS_NODE_ID if the sender ID needs to be included in the message
      rcm->counter = counter;
      rcm->senderId = TOS_NODE_ID;
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
	printf("RadioCountToLedsC: packet sent.\n");	
	locked = TRUE;
      }
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, 
				   void* payload, uint8_t len) {
    if (len != sizeof(radio_count_msg_t)) {return bufPtr;}
    else {
      radio_count_msg_t* rcm = (radio_count_msg_t*)payload;
      counter++;  // increase counter when message is received
      
      if (rcm->counter % 10 == 0) {
        printf("Received message with counter %u, LEDs off.\n", rcm->counter);
	    call Leds.led0Off();
	    call Leds.led1Off();
	    call Leds.led2Off();
      } else if (rcm->senderId == 1) {
	    call Leds.led0Toggle();
	    printf("Toggling LED %u.\n", rcm->senderId);
      } else if (rcm->senderId == 2) {
	    call Leds.led1Toggle();
	    printf("Toggling LED %u.\n", rcm->senderId);
      } else if (rcm->senderId == 3) {
	    call Leds.led2Toggle();
	    printf("Toggling LED %u.\n", rcm->senderId);
      }
      return bufPtr;
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

}




