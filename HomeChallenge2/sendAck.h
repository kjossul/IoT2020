/**
 *  @author Luca Pietro Borsani
 */

#ifndef SENDACK_H
#define SENDACK_H

//payload of the msg
typedef nx_struct req_msg {
  nx_uint16_t msgType;
  nx_uint16_t counter;
} req_msg_t;

typedef nx_struct resp_msg {
  nx_uint16_t msgType;
  nx_uint16_t counter;
  nx_uint16_t sensorValue;
} resp_msg_t;

#define REQ 1
#define RESP 2 

enum{
AM_RADIO_COUNT_MSG = 6,
};

#endif
