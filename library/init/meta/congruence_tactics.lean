/-
Copyright (c) 2016 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura
-/
prelude
import init.meta.tactic

/- Congruence closure state -/
meta constant cc_state              : Type
meta constant cc_state.mk           : cc_state
/- Create a congruence closure state object using the hypotheses in the current goal. -/
meta constant cc_state.mk_using_hs  : tactic cc_state
meta constant cc_state.next         : cc_state → expr → expr
meta constant cc_state.roots_core   : cc_state → bool → list expr
meta constant cc_state.root         : cc_state → expr → expr
meta constant cc_state.mt           : cc_state → expr → nat
meta constant cc_state.is_cg_root   : cc_state → expr → bool
meta constant cc_state.pp_eqc       : cc_state → expr → tactic format
meta constant cc_state.pp_core      : cc_state → bool → tactic format
meta constant cc_state.internalize  : cc_state → expr → bool → tactic cc_state
meta constant cc_state.add          : cc_state → expr → tactic cc_state
meta constant cc_state.is_eqv       : cc_state → expr → expr → tactic bool
meta constant cc_state.is_not_eqv   : cc_state → expr → expr → tactic bool
meta constant cc_state.eqv_proof    : cc_state → expr → expr → tactic expr
meta constant cc_state.inconsistent : cc_state → bool
/- If the given state is inconsistent, return a proof for false. Otherwise fail. -/
meta constant cc_state.false_proof  : cc_state → tactic expr
namespace cc_state

meta def roots (s : cc_state) : list expr :=
cc_state.roots_core s tt

meta def pp (s : cc_state) : tactic format :=
cc_state.pp_core s tt

meta def eqc_of_core (s : cc_state) : expr → expr → list expr → list expr
| e f r :=
  let n := s^.next e in
  if n = f then e::r else eqc_of_core n f (e::r)

meta def eqc_of (s : cc_state) (e : expr) : list expr :=
s^.eqc_of_core e e []

meta def in_singlenton_eqc (s : cc_state) (e : expr) : bool :=
to_bool (s^.next e = e)

meta def eqc_size (s : cc_state) (e : expr) : nat :=
(s^.eqc_of e)^.length

end cc_state

open tactic
meta def tactic.cc : tactic unit :=
do intros, s ← cc_state.mk_using_hs, t ← target, s ← s^.internalize t tt,
   if s^.inconsistent then do {
     pr ← s^.false_proof,
     mk_app `false.elim [t, pr] >>= exact}
   else do {
     tr ← return $ expr.const `true [],
     b ← s^.is_eqv t tr,
     if b then do {
       pr ← s^.eqv_proof t tr,
       mk_app `of_eq_true [pr] >>= exact}
     else fail "cc tactic failed"
   }