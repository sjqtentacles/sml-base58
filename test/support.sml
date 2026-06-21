(* support.sml -- shared helpers for the base58 test suites.

   `hex` turns a hex string into the raw byte string it denotes, so the test
   vectors below can be written in the same hex form used by the Base58 /
   Base58Check reference test data. *)

structure Support =
struct
  structure B = Base58

  fun hexDigit c =
    if c >= #"0" andalso c <= #"9" then ord c - ord #"0"
    else if c >= #"a" andalso c <= #"f" then ord c - ord #"a" + 10
    else if c >= #"A" andalso c <= #"F" then ord c - ord #"A" + 10
    else raise Fail ("bad hex digit: " ^ str c)

  (* hex string (even length) -> raw bytes *)
  fun hex s =
    let
      val cs = explode s
      fun loop [] = []
        | loop (a :: b :: rest) =
            chr (hexDigit a * 16 + hexDigit b) :: loop rest
        | loop [_] = raise Fail "odd-length hex"
    in
      String.implode (loop cs)
    end

  (* raw bytes -> lowercase hex, handy for failure messages *)
  fun toHex s =
    String.concat
      (List.map
         (fn c =>
            let val n = ord c
                fun d n = String.sub ("0123456789abcdef", n)
            in String.implode [d (n div 16), d (n mod 16)] end)
         (explode s))

  fun checkOpt name (expected, actual) =
    Harness.checkString name
      (case expected of NONE => "NONE" | SOME s => "SOME " ^ toHex s,
       case actual   of NONE => "NONE" | SOME s => "SOME " ^ toHex s)
end
