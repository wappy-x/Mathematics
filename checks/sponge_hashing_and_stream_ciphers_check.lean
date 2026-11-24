-- SHA-3 and ChaCha20: every ChaCha20 quarter round and every run of ChaCha20 rounds can be undone, and a Poly1305 forgery works for at most 8⌈L/16⌉ secret points r.
import Mathlib.Algebra.Polynomial.Roots
import Mathlib.Algebra.Field.ZMod
import Mathlib.Data.Int.ModEq
import Mathlib.Data.Finset.Card
import Mathlib.Tactic.NormNum
import Mathlib.Data.FinEnum
import Mathlib.Data.Int.Interval

open Finset

/-- One ChaCha20 quarter round on four 32-bit words (w, x, y, z), as RFC 8439 2.1 writes it:
add, xor, rotate left by 16, 12, 8 and 7. `+` on `BitVec 32` is addition modulo 2^32. -/
def quarterRound (v : BitVec 32 × BitVec 32 × BitVec 32 × BitVec 32) :
    BitVec 32 × BitVec 32 × BitVec 32 × BitVec 32 :=
  let (w, x, y, z) := v
  let w := w + x
  let z := (z ^^^ w).rotateLeft 16
  let y := y + z
  let x := (x ^^^ y).rotateLeft 12
  let w := w + x
  let z := (z ^^^ w).rotateLeft 8
  let y := y + z
  let x := (x ^^^ y).rotateLeft 7
  (w, x, y, z)

/-- The ChaCha20 state: sixteen 32-bit words, 512 bits. -/
abbrev ChaChaState := Fin 16 → BitVec 32

/-- Run the quarter round on the words at positions a, b, c, d of the state. -/
def qrAt (a b c d : Fin 16) (s : ChaChaState) : ChaChaState :=
  let (w, x, y, z) := quarterRound (s a, s b, s c, s d)
  Function.update (Function.update (Function.update (Function.update s a w) b x) c y) d z

/-- A column round: the quarter round on the four columns of the 4 × 4 grid. -/
def columnRound (s : ChaChaState) : ChaChaState :=
  qrAt 3 7 11 15 (qrAt 2 6 10 14 (qrAt 1 5 9 13 (qrAt 0 4 8 12 s)))

/-- A diagonal round: the quarter round on the four diagonals of the 4 × 4 grid. -/
def diagonalRound (s : ChaChaState) : ChaChaState :=
  qrAt 3 4 9 14 (qrAt 2 7 8 13 (qrAt 1 6 11 12 (qrAt 0 5 10 15 s)))

/-- The first n ChaCha20 rounds, alternating column and diagonal rounds, starting with a column
round (ChaCha20 runs 20). -/
def chachaRounds : ℕ → ChaChaState → ChaChaState
  | 0 => id
  | n + 1 => fun s => (if n % 2 = 0 then columnRound else diagonalRound) (chachaRounds n s)


/-- Rotating a 32-bit word left by r < 32 places loses no bits. -/
theorem rotl32_inj (r : ℕ) (hr : r < 32) {x y : BitVec 32}
    (h : x.rotateLeft r = y.rotateLeft r) : x = y := by
  ext j hj
  by_cases hjr : j < 32 - r
  · have := congrArg (fun v : BitVec 32 => v.getLsbD (j + r)) h
    simpa [BitVec.getLsbD_rotateLeft, Nat.mod_eq_of_lt hr, show ¬ (j + r < r) by omega,
      show j + r < 32 by omega, show j + r - r = j by omega, BitVec.getLsbD_eq_getElem hj] using this
  · have := congrArg (fun v : BitVec 32 => v.getLsbD (j - (32 - r))) h
    simpa [BitVec.getLsbD_rotateLeft, Nat.mod_eq_of_lt hr, show j - (32 - r) < r by omega,
      show 32 - r + (j - (32 - r)) = j by omega, BitVec.getLsbD_eq_getElem hj] using this

/-- The quarter round is one-to-one: run each step backwards. -/
theorem quarterRound_injective : Function.Injective quarterRound := by
  -- add x into w
  have A : Function.Injective (fun v : BitVec 32 × BitVec 32 × BitVec 32 × BitVec 32 =>
      (v.1 + v.2.1, v.2.1, v.2.2.1, v.2.2.2)) := by
    rintro ⟨w, x, y, z⟩ ⟨w', x', y', z'⟩ h
    simp only [Prod.mk.injEq] at h ⊢
    obtain ⟨h1, rfl, rfl, rfl⟩ := h
    exact ⟨(BitVec.add_left_inj _).1 h1, rfl, rfl, rfl⟩
  -- z := (z xor w) rotated left k
  have B : ∀ k < 32, Function.Injective (fun v : BitVec 32 × BitVec 32 × BitVec 32 × BitVec 32 =>
      (v.1, v.2.1, v.2.2.1, (v.2.2.2 ^^^ v.1).rotateLeft k)) := by
    intro k hk
    rintro ⟨w, x, y, z⟩ ⟨w', x', y', z'⟩ h
    simp only [Prod.mk.injEq] at h ⊢
    obtain ⟨rfl, rfl, rfl, h4⟩ := h
    exact ⟨rfl, rfl, rfl, (BitVec.xor_left_inj _).1 (rotl32_inj k hk h4)⟩
  -- add z into y
  have C : Function.Injective (fun v : BitVec 32 × BitVec 32 × BitVec 32 × BitVec 32 =>
      (v.1, v.2.1, v.2.2.1 + v.2.2.2, v.2.2.2)) := by
    rintro ⟨w, x, y, z⟩ ⟨w', x', y', z'⟩ h
    simp only [Prod.mk.injEq] at h ⊢
    obtain ⟨rfl, rfl, h3, rfl⟩ := h
    exact ⟨rfl, rfl, (BitVec.add_left_inj _).1 h3, rfl⟩
  -- x := (x xor y) rotated left k
  have D : ∀ k < 32, Function.Injective (fun v : BitVec 32 × BitVec 32 × BitVec 32 × BitVec 32 =>
      (v.1, (v.2.1 ^^^ v.2.2.1).rotateLeft k, v.2.2.1, v.2.2.2)) := by
    intro k hk
    rintro ⟨w, x, y, z⟩ ⟨w', x', y', z'⟩ h
    simp only [Prod.mk.injEq] at h ⊢
    obtain ⟨rfl, h2, rfl, rfl⟩ := h
    exact ⟨rfl, (BitVec.xor_left_inj _).1 (rotl32_inj k hk h2), rfl, rfl⟩
  have e : quarterRound = (fun v : BitVec 32 × BitVec 32 × BitVec 32 × BitVec 32 =>
        (v.1, (v.2.1 ^^^ v.2.2.1).rotateLeft 7, v.2.2.1, v.2.2.2)) ∘
      (fun v : BitVec 32 × BitVec 32 × BitVec 32 × BitVec 32 =>
        (v.1, v.2.1, v.2.2.1 + v.2.2.2, v.2.2.2)) ∘
      (fun v : BitVec 32 × BitVec 32 × BitVec 32 × BitVec 32 =>
        (v.1, v.2.1, v.2.2.1, (v.2.2.2 ^^^ v.1).rotateLeft 8)) ∘
      (fun v : BitVec 32 × BitVec 32 × BitVec 32 × BitVec 32 =>
        (v.1 + v.2.1, v.2.1, v.2.2.1, v.2.2.2)) ∘
      (fun v : BitVec 32 × BitVec 32 × BitVec 32 × BitVec 32 =>
        (v.1, (v.2.1 ^^^ v.2.2.1).rotateLeft 12, v.2.2.1, v.2.2.2)) ∘
      (fun v : BitVec 32 × BitVec 32 × BitVec 32 × BitVec 32 =>
        (v.1, v.2.1, v.2.2.1 + v.2.2.2, v.2.2.2)) ∘
      (fun v : BitVec 32 × BitVec 32 × BitVec 32 × BitVec 32 =>
        (v.1, v.2.1, v.2.2.1, (v.2.2.2 ^^^ v.1).rotateLeft 16)) ∘
      (fun v : BitVec 32 × BitVec 32 × BitVec 32 × BitVec 32 =>
        (v.1 + v.2.1, v.2.1, v.2.2.1, v.2.2.2)) := by
    funext ⟨w, x, y, z⟩
    rfl
  rw [e]
  exact (D 7 (by norm_num)).comp (C.comp ((B 8 (by norm_num)).comp (A.comp
    ((D 12 (by norm_num)).comp (C.comp ((B 16 (by norm_num)).comp A))))))

/-- The quarter round on four different positions of the state is one-to-one. -/
theorem qrAt_injective (a b c d : Fin 16) (hab : a ≠ b) (hac : a ≠ c) (had : a ≠ d)
    (hbc : b ≠ c) (hbd : b ≠ d) (hcd : c ≠ d) : Function.Injective (qrAt a b c d) := by
  intro s t h
  unfold qrAt at h
  rcases hq : quarterRound (s a, s b, s c, s d) with ⟨w, x, y, z⟩
  rcases hq' : quarterRound (t a, t b, t c, t d) with ⟨w', x', y', z'⟩
  rw [hq, hq'] at h
  dsimp only at h
  have hd := congrFun h d
  have hc := congrFun h c
  have hb := congrFun h b
  have ha := congrFun h a
  simp [hab, hac, had, hbc, hbd, hcd] at hd hc hb ha
  have he : (s a, s b, s c, s d) = (t a, t b, t c, t d) :=
    quarterRound_injective (by rw [hq, hq', hd, hc, hb, ha])
  simp only [Prod.mk.injEq] at he
  obtain ⟨e1, e2, e3, e4⟩ := he
  funext i
  by_cases ia : i = a
  · subst ia; exact e1
  by_cases ib : i = b
  · subst ib; exact e2
  by_cases ic : i = c
  · subst ic; exact e3
  by_cases id : i = d
  · subst id; exact e4
  have := congrFun h i
  simpa [Function.update_apply, ia, ib, ic, id] using this

/-- A column round is one-to-one. -/
theorem columnRound_injective : Function.Injective columnRound := by
  unfold columnRound
  exact (qrAt_injective 3 7 11 15 (by decide) (by decide) (by decide) (by decide) (by decide)
    (by decide)).comp ((qrAt_injective 2 6 10 14 (by decide) (by decide) (by decide) (by decide)
    (by decide) (by decide)).comp ((qrAt_injective 1 5 9 13 (by decide) (by decide) (by decide)
    (by decide) (by decide) (by decide)).comp (qrAt_injective 0 4 8 12 (by decide) (by decide)
    (by decide) (by decide) (by decide) (by decide))))

/-- A diagonal round is one-to-one. -/
theorem diagonalRound_injective : Function.Injective diagonalRound := by
  unfold diagonalRound
  exact (qrAt_injective 3 4 9 14 (by decide) (by decide) (by decide) (by decide) (by decide)
    (by decide)).comp ((qrAt_injective 2 7 8 13 (by decide) (by decide) (by decide) (by decide)
    (by decide) (by decide)).comp ((qrAt_injective 1 6 11 12 (by decide) (by decide) (by decide)
    (by decide) (by decide) (by decide)).comp (qrAt_injective 0 5 10 15 (by decide) (by decide)
    (by decide) (by decide) (by decide) (by decide))))

/-- Every ChaCha20 quarter round can be undone: subtract undoes add, rotate right undoes rotate
left, and xor undoes itself, so the quarter round is a one-to-one map of four 32-bit words onto
four 32-bit words. -/
theorem quarter_round_bijective : Function.Bijective quarterRound := by
  rw [← Finite.injective_iff_bijective]
  exact quarterRound_injective

/-- The ChaCha20 rounds lose no information: for every number of rounds n (ChaCha20 uses 20),
the alternating column and diagonal rounds are a one-to-one map of 512-bit states onto
512-bit states, so a whole round output, run backwards, gives back the input. -/
theorem chacha_rounds_bijective (n : ℕ) : Function.Bijective (chachaRounds n) := by
  rw [← Finite.injective_iff_bijective]
  induction n with
  | zero => exact Function.injective_id
  | succ n ih =>
    have e : chachaRounds (n + 1)
        = (if n % 2 = 0 then columnRound else diagonalRound) ∘ chachaRounds n := rfl
    rw [e]
    split_ifs
    · exact columnRound_injective.comp ih
    · exact diagonalRound_injective.comp ih

/-- The polynomial part of a Poly1305 tag, by Horner's rule as RFC 8439 computes it: start at 0,
and for each chunk B_i add it and multiply by r; then reduce modulo p. This is
H_r = (B_1 r^q + B_2 r^(q-1) + ... + B_q r) mod p. -/
def polyHash (p r : ℕ) (B : List ℕ) : ℕ :=
  B.foldl (fun acc b => (acc + b) * r) 0 % p


open Polynomial in
/-- The Horner polynomial of a chunk list (read from the last chunk) has constant term 0. -/
theorem horner_coeff_zero (p : ℕ) (m : List ℕ) :
    (m.foldr (fun (b : ℕ) (a : (ZMod p)[X]) => (a + C (b : ZMod p)) * X) 0).coeff 0 = 0 := by
  cases m <;> simp

open Polynomial in
/-- The Horner polynomial of a list of q chunks has degree at most q. -/
theorem horner_natDegree_le (p : ℕ) [Fact p.Prime] (m : List ℕ) :
    (m.foldr (fun (b : ℕ) (a : (ZMod p)[X]) => (a + C (b : ZMod p)) * X) 0).natDegree ≤ m.length := by
  induction m with
  | nil => simp
  | cons b m ih =>
    simp only [List.foldr_cons, List.length_cons]
    refine natDegree_mul_le.trans ?_
    rw [natDegree_add_C]
    have := natDegree_X_le (R := ZMod p)
    omega

open Polynomial in
/-- Different chunk lists, with every chunk in [1, p), give different Horner polynomials. -/
theorem horner_inj (p : ℕ) [hp : Fact p.Prime] : ∀ m m' : List ℕ,
    (∀ b ∈ m, 1 ≤ b ∧ b < p) → (∀ b ∈ m', 1 ≤ b ∧ b < p) →
    m.foldr (fun (b : ℕ) (a : (ZMod p)[X]) => (a + C (b : ZMod p)) * X) 0
      = m'.foldr (fun (b : ℕ) (a : (ZMod p)[X]) => (a + C (b : ZMod p)) * X) 0 → m = m' := by
  have nz : ∀ b : ℕ, 1 ≤ b → b < p → (b : ZMod p) ≠ 0 := by
    intro b h1 h2 h0
    rw [ZMod.natCast_eq_zero_iff] at h0
    have := Nat.le_of_dvd (by omega) h0
    omega
  intro m
  induction m with
  | nil =>
    intro m' _ hm' h
    cases m' with
    | nil => rfl
    | cons b' m' =>
      exfalso
      simp only [List.foldr_cons, List.foldr_nil] at h
      have h0 := (mul_eq_zero.mp h.symm).resolve_right X_ne_zero
      have := congrArg (fun P : (ZMod p)[X] => P.coeff 0) h0
      simp only [coeff_add, coeff_C_zero, horner_coeff_zero, zero_add, coeff_zero] at this
      exact nz b' (hm' b' (by simp)).1 (hm' b' (by simp)).2 this
  | cons b m ih =>
    intro m' hm hm' h
    cases m' with
    | nil =>
      exfalso
      simp only [List.foldr_cons, List.foldr_nil] at h
      have h0 := (mul_eq_zero.mp h).resolve_right X_ne_zero
      have := congrArg (fun P : (ZMod p)[X] => P.coeff 0) h0
      simp only [coeff_add, coeff_C_zero, horner_coeff_zero, zero_add, coeff_zero] at this
      exact nz b (hm b (by simp)).1 (hm b (by simp)).2 this
    | cons b' m' =>
      simp only [List.foldr_cons] at h
      have h1 := mul_right_cancel₀ X_ne_zero h
      have hc := congrArg (fun P : (ZMod p)[X] => P.coeff 0) h1
      simp only [coeff_add, coeff_C_zero, horner_coeff_zero, zero_add] at hc
      have hbb : b = b' := by
        rw [ZMod.natCast_eq_natCast_iff'] at hc
        rwa [Nat.mod_eq_of_lt (hm b (by simp)).2, Nat.mod_eq_of_lt (hm' b' (by simp)).2] at hc
      subst hbb
      have h2 := add_right_cancel h1
      rw [ih m' (fun x hx => hm x (by simp [hx])) (fun x hx => hm' x (by simp [hx])) h2]

open Polynomial in
/-- Evaluating the Horner polynomial runs Horner's rule. -/
theorem horner_eval (p : ℕ) (m : List ℕ) (x : ZMod p) :
    (m.foldr (fun (b : ℕ) (a : (ZMod p)[X]) => (a + C (b : ZMod p)) * X) 0).eval x
      = m.foldr (fun (b : ℕ) (a : ZMod p) => (a + (b : ZMod p)) * x) 0 := by
  induction m with
  | nil => simp
  | cons b m ih => simp only [List.foldr_cons, eval_mul, eval_add, eval_C, eval_X, ih]

/-- Horner's rule on natural numbers, read in ZMod p. -/
theorem foldl_cast (p r : ℕ) (l : List ℕ) (acc : ℕ) :
    ((l.foldl (fun acc b => (acc + b) * r) acc : ℕ) : ZMod p)
      = l.foldl (fun (a : ZMod p) (b : ℕ) => (a + (b : ZMod p)) * (r : ZMod p)) (acc : ZMod p) := by
  induction l generalizing acc with
  | nil => simp
  | cons b l ih =>
    simp only [List.foldl_cons]
    rw [ih]
    push_cast
    rfl

open Polynomial in
/-- The Poly1305 hash, read in ZMod p, is the Horner polynomial of the reversed list at r. -/
theorem polyHash_cast (p r : ℕ) (B : List ℕ) :
    ((polyHash p r B : ℕ) : ZMod p)
      = (B.reverse.foldr (fun (b : ℕ) (a : (ZMod p)[X]) => (a + C (b : ZMod p)) * X) 0).eval (r : ZMod p) := by
  unfold polyHash
  rw [ZMod.natCast_mod, foldl_cast, horner_eval, List.foldr_reverse]
  simp

/-- Poly1305's forgery bound. Work modulo a prime p with 2^129 < p ≤ 2^130 (Poly1305 uses
p = 2^130 - 5). A message is a list of chunks B_i, each a 16-byte piece with a byte 01 after it,
so 1 ≤ B_i < 2^129; two different messages give different chunk lists B ≠ B', each of at most
⌈L/16⌉ chunks. A forger who saw a tag for B and sends B' with the tag shifted by g wins exactly
when H_r(B') − H_r(B) ≡ g (mod 2^128). Among any set R of candidate secret points r < p (for
Poly1305, the 2^106 clamped values), at most 8⌈L/16⌉ let the forgery through. -/
theorem poly1305_forgery_bound (p : ℕ) (hp : p.Prime) (hp_lo : 2 ^ 129 < p) (hp_hi : p ≤ 2 ^ 130)
    (L : ℕ) (B B' : List ℕ) (hne : B ≠ B')
    (hB : ∀ b ∈ B, 1 ≤ b ∧ b < 2 ^ 129) (hB' : ∀ b ∈ B', 1 ≤ b ∧ b < 2 ^ 129)
    (hlen : B.length ≤ (L + 15) / 16) (hlen' : B'.length ≤ (L + 15) / 16)
    (g : ℤ) (R : Finset ℕ) (hR : ∀ r ∈ R, r < p) :
    (R.filter (fun r => ((polyHash p r B' : ℤ) - polyHash p r B) ≡ g [ZMOD 2 ^ 128])).card
      ≤ 8 * ((L + 15) / 16) := by
  have := Fact.mk hp
  have hp0 : 0 < p := hp.pos
  have hBp : ∀ b ∈ B.reverse, 1 ≤ b ∧ b < p := fun b hb => by
    rw [List.mem_reverse] at hb; have := hB b hb; omega
  have hB'p : ∀ b ∈ B'.reverse, 1 ≤ b ∧ b < p := fun b hb => by
    rw [List.mem_reverse] at hb; have := hB' b hb; omega
  have hD : ∀ r, -(2 ^ 130 : ℤ) < (polyHash p r B' : ℤ) - polyHash p r B ∧
      (polyHash p r B' : ℤ) - polyHash p r B < 2 ^ 130 := by
    intro r
    have h1 : polyHash p r B < p := Nat.mod_lt _ hp0
    have h2 : polyHash p r B' < p := Nat.mod_lt _ hp0
    have h3 : (p : ℤ) ≤ 2 ^ 130 := by exact_mod_cast hp_hi
    constructor <;> omega
  -- For one fixed value v of the difference, at most ⌈L/16⌉ points r work.
  have piece : ∀ v : ℤ,
      (R.filter (fun r => (polyHash p r B' : ℤ) - polyHash p r B = v)).card ≤ (L + 15) / 16 := by
    intro v
    set F : Polynomial (ZMod p) := B'.reverse.foldr (fun (b : ℕ) (a : Polynomial (ZMod p)) => (a + Polynomial.C (b : ZMod p)) * Polynomial.X) 0
      - B.reverse.foldr (fun (b : ℕ) (a : Polynomial (ZMod p)) => (a + Polynomial.C (b : ZMod p)) * Polynomial.X) 0
      - Polynomial.C (v : ZMod p) with hFdef
    have hF : F ≠ 0 := by
      intro h0
      rw [hFdef, sub_eq_zero] at h0
      have hv : (v : ZMod p) = 0 := by
        have := congrArg (fun P : Polynomial (ZMod p) => P.coeff 0) h0
        simp only [Polynomial.coeff_sub, horner_coeff_zero, sub_zero, Polynomial.coeff_C_zero] at this
        exact this.symm
      rw [hv, Polynomial.C_0, sub_eq_zero] at h0
      exact hne (List.reverse_injective (horner_inj p _ _ hB'p hBp h0)).symm
    have hdeg : F.natDegree ≤ (L + 15) / 16 := by
      rw [hFdef, Polynomial.natDegree_sub_C]
      refine (Polynomial.natDegree_sub_le _ _).trans ?_
      have a1 := horner_natDegree_le p B'.reverse
      have a2 := horner_natDegree_le p B.reverse
      rw [List.length_reverse] at a1 a2
      omega
    calc (R.filter (fun r => (polyHash p r B' : ℤ) - polyHash p r B = v)).card
        = ((R.filter (fun r => (polyHash p r B' : ℤ) - polyHash p r B = v)).image
            (fun r : ℕ => (r : ZMod p))).card := by
          rw [Finset.card_image_of_injOn]
          intro r1 hr1 r2 hr2 he
          simp only [Finset.coe_filter, Set.mem_ofPred_eq] at hr1 hr2
          have he' : (r1 : ZMod p) = r2 := he
          rw [ZMod.natCast_eq_natCast_iff', Nat.mod_eq_of_lt (hR r1 hr1.1),
            Nat.mod_eq_of_lt (hR r2 hr2.1)] at he'
          exact he'
      _ ≤ F.roots.toFinset.card := by
          apply Finset.card_le_card
          intro x hx
          rw [Finset.mem_image] at hx
          obtain ⟨r, hr, rfl⟩ := hx
          rw [Finset.mem_filter] at hr
          rw [Multiset.mem_toFinset, Polynomial.mem_roots hF, Polynomial.IsRoot.def, hFdef]
          simp only [Polynomial.eval_sub, Polynomial.eval_C]
          rw [← polyHash_cast, ← polyHash_cast]
          have := congrArg (fun z : ℤ => (z : ZMod p)) hr.2
          push_cast at this
          rw [this, sub_self]
      _ ≤ Multiset.card F.roots := Multiset.toFinset_card_le _
      _ ≤ F.natDegree := Polynomial.card_roots' F
      _ ≤ (L + 15) / 16 := hdeg
  -- The difference lies in (-2^130, 2^130), so it takes at most 8 values ≡ g (mod 2^128).
  have cover : R.filter (fun r => ((polyHash p r B' : ℤ) - polyHash p r B) ≡ g [ZMOD 2 ^ 128])
      ⊆ (Finset.Icc (-4 : ℤ) 3).biUnion (fun k => R.filter
          (fun r => (polyHash p r B' : ℤ) - polyHash p r B = 2 ^ 128 * k + g % 2 ^ 128)) := by
    intro r hr
    rw [Finset.mem_filter] at hr
    rw [Finset.mem_biUnion]
    have hb := hD r
    have hm : ((polyHash p r B' : ℤ) - polyHash p r B) % 2 ^ 128 = g % 2 ^ 128 := hr.2
    have hdm := Int.mul_ediv_add_emod ((polyHash p r B' : ℤ) - polyHash p r B) (2 ^ 128)
    refine ⟨((polyHash p r B' : ℤ) - polyHash p r B) / 2 ^ 128, ?_, ?_⟩
    · rw [Finset.mem_Icc]
      constructor <;> omega
    · rw [Finset.mem_filter]
      exact ⟨hr.1, by omega⟩
  calc _ ≤ _ := Finset.card_le_card cover
    _ ≤ ∑ k ∈ Finset.Icc (-4 : ℤ) 3, (R.filter
          (fun r => (polyHash p r B' : ℤ) - polyHash p r B = 2 ^ 128 * k + g % 2 ^ 128)).card :=
        Finset.card_biUnion_le
    _ ≤ ∑ _k ∈ Finset.Icc (-4 : ℤ) 3, (L + 15) / 16 := Finset.sum_le_sum (fun k _ => piece _)
    _ = 8 * ((L + 15) / 16) := by simp

/-! The card's worked numbers. -/

/-- RFC 8439 2.1.1: the quarter-round test vector. -/
example : quarterRound (0x11111111#32, 0x01020304#32, 0x9b8d6f43#32, 0x01234567#32)
    = (0xea2a92f4#32, 0xcb1cf8ce#32, 0x4581472e#32, 0x5881c4bb#32) := by decide

/-- The hand table, steps 1 to 4 and 7 (step 7's carry past 32 bits is dropped). -/
example : 0x11111111#32 + 0x01020304#32 = 0x12131415#32 := by decide
example : (0x01234567#32 ^^^ 0x12131415#32).rotateLeft 16 = 0x51721330#32 := by decide
example : 0x9b8d6f43#32 + 0x51721330#32 = 0xecff8273#32 := by decide
example : (0x01020304#32 ^^^ 0xecff8273#32).rotateLeft 12 = 0xd8177edf#32 := by decide
example : 0xecff8273#32 + 0x5881c4bb#32 = 0x4581472e#32 := by decide

/-- SHA3-256: R + C = 1600 with R = 1088 bits, so a block is 136 bytes. -/
example : 1088 + 512 = 1600 ∧ 1088 / 8 = 136 := by norm_num

/-- The order: L = 64 bytes, so ⌈64/16⌉ = 4 chunks and at most 32 bad points; 32/2^106 = 1/2^101. -/
example : 8 * ((64 + 15) / 16) = 32 := by norm_num
example : (32 : ℚ) / 2 ^ 106 = 1 / 2 ^ 101 := by norm_num

#print axioms rotl32_inj
#print axioms quarterRound_injective
#print axioms qrAt_injective
#print axioms columnRound_injective
#print axioms diagonalRound_injective
#print axioms horner_coeff_zero
#print axioms horner_natDegree_le
#print axioms horner_inj
#print axioms horner_eval
#print axioms foldl_cast
#print axioms polyHash_cast
#print axioms quarter_round_bijective
#print axioms chacha_rounds_bijective
#print axioms poly1305_forgery_bound
