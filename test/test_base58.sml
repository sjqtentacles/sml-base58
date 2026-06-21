(* test_base58.sml -- plain Base58 (Bitcoin alphabet) encode/decode vectors.

   The (hex, base58) pairs are the canonical Bitcoin Core
   base58_encode_decode test vectors; they exercise empty input,
   leading-zero-byte -> leading-'1' handling, and a spread of payload sizes. *)

structure Base58Tests =
struct
  open Support

  (* (raw-bytes-as-hex, expected base58 string) *)
  val vectors =
    [ ("",                                           ""),
      ("61",                                         "2g"),
      ("626262",                                     "a3gV"),
      ("636363",                                     "aPEr"),
      ("73696d706c792061206c6f6e6720737472696e67",   "2cFupjhnEsSn59qHXstmK2ffpLv2"),
      ("00eb15231dfceb60925886b67d065299925915aeb172c06647",
                                                     "1NS17iag9jJgTHD1VXjvLCEnZuQ3rJDE9L"),
      ("516b6fcd0f",                                 "ABnLTmg"),
      ("bf4f89001e670274dd",                         "3SEo3LWLoPntC"),
      ("572e4794",                                   "3EFU7m"),
      ("ecac89cad93923c02321",                       "EJDM8drfXA6uyA"),
      ("10c8511e",                                   "Rt5zm"),
      ("00000000000000000000",                       "1111111111") ]

  fun run () =
    let
      val _ = Harness.section "base58 encode (known vectors)"
      val () =
        List.app
          (fn (h, enc) =>
             Harness.checkString ("encode " ^ (if h = "" then "<empty>" else h))
               (enc, B.encode (hex h)))
          vectors

      val _ = Harness.section "base58 decode (known vectors)"
      val () =
        List.app
          (fn (h, enc) =>
             checkOpt ("decode " ^ (if enc = "" then "<empty>" else enc))
               (SOME (hex h), B.decode enc))
          vectors

      val _ = Harness.section "base58 leading-zero handling"
      val () = Harness.checkString "encode empty -> empty" ("", B.encode "")
      val () = checkOpt "decode empty -> SOME empty" (SOME "", B.decode "")
      val () = Harness.checkString "encode 0x00 -> \"1\"" ("1", B.encode (hex "00"))
      val () = Harness.checkString "encode 0x0000 -> \"11\"" ("11", B.encode (hex "0000"))
      val () = checkOpt "decode \"1\" -> 0x00" (SOME (hex "00"), B.decode "1")
      val () = checkOpt "decode \"11\" -> 0x0000" (SOME (hex "0000"), B.decode "11")
      val () = checkOpt "decode 0x00+value keeps zero" (SOME (hex "0001"), B.decode "12")

      val _ = Harness.section "base58 decode rejects invalid characters"
      (* '0', 'O', 'I', 'l' are not in the Bitcoin alphabet *)
      val () = checkOpt "decode \"0\" -> NONE" (NONE, B.decode "0")
      val () = checkOpt "decode \"O\" -> NONE" (NONE, B.decode "O")
      val () = checkOpt "decode \"I\" -> NONE" (NONE, B.decode "I")
      val () = checkOpt "decode \"l\" -> NONE" (NONE, B.decode "l")
      val () = checkOpt "decode \"abc def\" -> NONE" (NONE, B.decode "abc def")

      val _ = Harness.section "base58 round-trips"
      val () =
        List.app
          (fn (h, _) =>
             let val raw = hex h in
               checkOpt ("round-trip " ^ (if h = "" then "<empty>" else h))
                 (SOME raw, B.decode (B.encode raw))
             end)
          vectors
    in
      ()
    end
end
