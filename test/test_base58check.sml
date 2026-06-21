(* test_base58check.sml -- Base58Check: round-trips, a known Bitcoin address
   vector, and checksum-failure detection. *)

structure Base58CheckTests =
struct
  open Support

  (* Bitcoin genesis coinbase P2PKH address: version byte 0x00 followed by the
     20-byte hash160 0x62e9...8f18 encodes to this well-known address. *)
  val genesisHash160 = "62e907b15cbf27d5425399ebf6f0fb50ebb88f18"
  val genesisPayload = hex ("00" ^ genesisHash160)
  val genesisAddr    = "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa"

  val payloads =
    [ "",
      "00",
      "61",
      hex "00010203040506070809",
      (* version 0x05 (P2SH) + 20-byte hash *)
      hex ("05" ^ "0102030405060708090a0b0c0d0e0f1011121314"),
      genesisPayload ]

  fun run () =
    let
      val _ = Harness.section "base58check known address vector"
      val () = Harness.checkString "encodeCheck genesis payload -> genesis address"
                 (genesisAddr, B.encodeCheck genesisPayload)
      val () = checkOpt "decodeCheck genesis address -> payload"
                 (SOME genesisPayload, B.decodeCheck genesisAddr)

      val _ = Harness.section "base58check round-trips"
      val () =
        List.app
          (fn p =>
             checkOpt ("decodeCheck (encodeCheck x) = SOME x [" ^ toHex p ^ "]")
               (SOME p, B.decodeCheck (B.encodeCheck p)))
          payloads

      val _ = Harness.section "base58check checksum-failure detection"
      (* Corrupt one character of a valid Base58Check string -> NONE. *)
      val enc = B.encodeCheck genesisPayload
      val corrupt =
        let
          val cs = explode enc
          val (h, t) = (hd cs, tl cs)
          (* flip the second char to a different valid alphabet symbol *)
          val c0 = hd t
          val c1 = if c0 = #"A" then #"B" else #"A"
        in
          String.implode (h :: c1 :: tl t)
        end
      val () = Harness.check "corrupt address differs from original" (corrupt <> enc)
      val () = checkOpt "decodeCheck (corrupted) -> NONE" (NONE, B.decodeCheck corrupt)

      (* Too-short input (no room for a 4-byte checksum) -> NONE. *)
      val () = checkOpt "decodeCheck \"\" -> NONE" (NONE, B.decodeCheck "")
      val () = checkOpt "decodeCheck \"1\" -> NONE (1 byte)" (NONE, B.decodeCheck "1")

      (* Invalid base58 characters propagate to NONE. *)
      val () = checkOpt "decodeCheck invalid char -> NONE" (NONE, B.decodeCheck "0OIl")
    in
      ()
    end
end
