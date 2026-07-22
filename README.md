# sml-base58

[![CI](https://github.com/sjqtentacles/sml-base58/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-base58/actions/workflows/ci.yml)

Base58 and Base58Check in pure Standard ML — the Bitcoin alphabet, with a
double-SHA256 checksum supplied by the vendored
[`sml-codec`](https://github.com/sjqtentacles/sml-codec). No FFI, no external
dependencies, and **deterministic**, byte-identically under both
[MLton](http://mlton.org/) and [Poly/ML](https://www.polyml.org/).

## Status

- 61 assertions, green on MLton and Poly/ML.
- Basis-library only (`IntInf` for the big-number conversion); deterministic
  across compilers.
- Vendors `sml-codec` (Layout B), so the repo builds standalone.
- Validated against the canonical Bitcoin Core Base58 vectors and the genesis
  P2PKH address `1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa`.

## Install

With [`smlpkg`](https://github.com/diku-dk/smlpkg):

```
smlpkg add github.com/sjqtentacles/sml-base58
smlpkg sync
```

Include the MLB from your own (it pulls in the vendored `sml-codec`):

```
local
  $(SML_LIB)/basis/basis.mlb
  lib/github.com/sjqtentacles/sml-base58/... (via smlpkg)
in
  ...
end
```

This brings `structure Base58` (and the vendored codec structures) into scope.

## Quick start

```sml
(* values are raw byte strings: one byte per char, 0-255 *)
val s   = Base58.encode "\000abc"          (* leading 0x00 -> leading '1' *)
val d   = Base58.decode s                  (* SOME "\000abc"; NONE on bad chars *)

(* Base58Check: append first 4 bytes of double-SHA256 as checksum *)
val addr = Base58.encodeCheck payload      (* e.g. a version byte + hash160 *)
val ok   = Base58.decodeCheck addr         (* SOME payload, or NONE if corrupt *)
```

## What's inside

| Function | Behavior |
| --- | --- |
| `encode : string -> string` | raw bytes -> Base58; leading `0x00` bytes become leading `'1'`s; `""` -> `""` |
| `decode : string -> string option` | Base58 -> raw bytes; `NONE` on any character outside the alphabet |
| `encodeCheck : string -> string` | append 4-byte double-SHA256 checksum, then Base58-encode |
| `decodeCheck : string -> string option` | decode, verify + strip checksum; `NONE` on bad/short checksum or invalid chars |

### Conventions

- Alphabet is the Bitcoin set
  `123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz` (no `0`, `O`,
  `I`, `l`).
- Each leading `0x00` byte maps to a leading `'1'`; the remaining bytes are
  treated as one big-endian integer and rebased to 58.
- Base58Check uses `Sha256.digest` (double hash, first 4 bytes); `decodeCheck`
  returns `NONE` rather than raising on any failure.
- Round-trips hold: `decodeCheck (encodeCheck x) = SOME x` for any `x`.

## Build & test

```
make test        # MLton
make test-poly   # Poly/ML
make all-tests   # both
make example     # build + run examples/demo.sml
make clean
```

## License

MIT — see [LICENSE](LICENSE).
