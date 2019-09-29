# Notes on web app security (general)


## Entropy

Entropy rule of thumb: if your entropy allows N values, you're likely to run into a collision when you have sqrt(N) values.

Put in more practical terms:

  - If your entropy allows 1 million values, you're likely to get two colliding values after generating only 1 _thousand_ values.
  - If your entropy allows 1 million values, a brute-force attacker has a good chance of guessing a valid value (assuming they have a quick way to check for valid values) by trying (on average) just a thousand random values.

This is a special case of the birthday problem whose formal calculation is complex for large values.
