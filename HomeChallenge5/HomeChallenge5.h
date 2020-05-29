#ifndef HOME_CHALLENGE_5_H
#define HOME_CHALLENGE_5_H

typedef nx_struct mymsg {
  nx_uint16_t value;
  nx_uint8_t topic[10];
} mymsg_t;

enum {
  AM_RADIO_MSG = 6,
};

#endif
