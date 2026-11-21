// header comment, prefs before any OPTION go to the base file
user_pref("base.bool", true);

/****************************************************************************
 * OPTION: FIRST CHOICE                                                     *
****************************************************************************/
  user_pref("first.indented", 1);
// user_pref("first.commented", false);
user_pref("first.string", "a b"); // trailing comment

/****************************************************************************
 * OPTION: Second (v2)                                                      *
****************************************************************************/
user_pref( "second.spaced" ,  -5 );
user_pref("second.dup", 1);
user_pref("second.dup", 2);
