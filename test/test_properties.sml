(* test_properties.sml -- sml-check property suite for Base58/Base58Check.

   decode-of-encode is the central law for this codec: for any byte
   string, decoding what we just encoded must return the original bytes.
   The fixed vectors in test_base58.sml / test_base58check.sml only cover
   a handful of hand-picked payloads (Bitcoin's canonical test vectors);
   these properties fuzz across random lengths and byte content. *)

structure Base58PropTests =
struct
  open Support

  (* Random byte strings of length 0..64, covering every byte value. *)
  val genByteStr : string Check.gen =
    Check.map (String.implode o List.map Char.chr)
      (Check.resize 64 (Check.listOf (Check.choose (0, 255))))

  fun showByteStr (s : string) : string =
    "\"" ^ toHex s ^ "\" (len=" ^ Int.toString (String.size s) ^ ")"

  fun run () =
    let
      val () = Harness.section "Properties (sml-check)"

      val () =
        Harness.check "prop: base58 encode/decode round-trips"
          (case Check.quickCheck
                  (Check.forAll genByteStr showByteStr
                     (fn s => B.decode (B.encode s) = SOME s)) of
               Check.Passed _ => true
             | Check.Failed _ => false)

      val () =
        Harness.check "prop: base58Check encode/decodeCheck round-trips"
          (case Check.quickCheck
                  (Check.forAll genByteStr showByteStr
                     (fn s => B.decodeCheck (B.encodeCheck s) = SOME s)) of
               Check.Passed _ => true
             | Check.Failed _ => false)

      val () =
        Harness.check "prop: base58 encode is deterministic"
          (case Check.quickCheck
                  (Check.forAll genByteStr showByteStr
                     (fn s => B.encode s = B.encode s)) of
               Check.Passed _ => true
             | Check.Failed _ => false)

      (* Format invariant: encode output only ever uses the Bitcoin
         58-symbol alphabet. *)
      val bitcoinAlphabet =
        "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
      val () =
        Harness.check "prop: base58 output stays within the Bitcoin alphabet"
          (case Check.quickCheck
                  (Check.forAll genByteStr showByteStr
                     (fn s =>
                        List.all (fn c => Char.contains bitcoinAlphabet c)
                          (String.explode (B.encode s)))) of
               Check.Passed _ => true
             | Check.Failed _ => false)

      (* Each leading 0x00 byte maps to exactly one leading '1' character
         (and vice versa), per the documented convention. *)
      fun countLeading p s =
        let
          val n = String.size s
          fun go i = if i < n andalso p (String.sub (s, i)) then go (i + 1) else i
        in go 0 end

      val () =
        Harness.check "prop: leading zero bytes map to leading '1' chars"
          (case Check.quickCheck
                  (Check.forAll genByteStr showByteStr
                     (fn s =>
                        countLeading (fn c => c = #"\000") s
                          = countLeading (fn c => c = #"1") (B.encode s))) of
               Check.Passed _ => true
             | Check.Failed _ => false)
    in
      ()
    end
end
