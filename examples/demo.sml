(* sml-base58 demo: encode/decode a sample payload with both plain Base58 and
   Base58Check, then show that a corrupted Base58Check string is rejected. *)

fun toHex s =
  String.concat
    (List.map
       (fn c =>
          let val n = ord c
              fun d n = String.sub ("0123456789abcdef", n)
          in String.implode [d (n div 16), d (n mod 16)] end)
       (explode s))

fun hexDigit c =
  if c >= #"0" andalso c <= #"9" then ord c - ord #"0"
  else if c >= #"a" andalso c <= #"f" then ord c - ord #"a" + 10
  else ord c - ord #"A" + 10

fun hex s =
  let
    fun loop [] = []
      | loop (a :: b :: r) = chr (hexDigit a * 16 + hexDigit b) :: loop r
      | loop _ = raise Fail "odd hex"
  in
    String.implode (loop (explode s))
  end

fun line s = print (s ^ "\n")

(* A Bitcoin P2PKH payload: version byte 0x00 + 20-byte hash160. *)
val payload = hex ("00" ^ "62e907b15cbf27d5425399ebf6f0fb50ebb88f18")

val () = line "sml-base58 demo"
val () = line "================"

val plain = Base58.encode payload
val () = line ("payload (hex)      : " ^ toHex payload)
val () = line ("Base58 encode      : " ^ plain)
val () =
  line ("Base58 decode ok   : " ^
        (case Base58.decode plain of
           SOME p => Bool.toString (p = payload)
         | NONE => "false"))

val addr = Base58.encodeCheck payload
val () = line ("Base58Check encode : " ^ addr)
val () =
  line ("Base58Check decode : " ^
        (case Base58.decodeCheck addr of
           SOME p => "SOME " ^ toHex p
         | NONE => "NONE"))

(* Corrupt one character and confirm the checksum rejects it. *)
val corrupt =
  let val cs = explode addr
  in String.implode (hd cs :: (if hd (tl cs) = #"A" then #"B" else #"A") :: tl (tl cs)) end
val () = line ("corrupted address  : " ^ corrupt)
val () =
  line ("corrupted decode   : " ^
        (case Base58.decodeCheck corrupt of
           SOME p => "SOME " ^ toHex p
         | NONE => "NONE (rejected)"))
