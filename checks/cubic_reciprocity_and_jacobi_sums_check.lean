-- Cubic reciprocity: for a prime p that leaves 1 on division by 3, 2 is a cube mod p exactly when p = x^2 + 27y^2, the cubic Gauss sum cubed is p times the Jacobi sum, and that Jacobi sum is a + bω of norm p with a ≡ 2, b ≡ 0 mod 3 and b even exactly when χ(2) = 1.
import Mathlib.NumberTheory.JacobiSum.Basic
import Mathlib.Analysis.SpecialFunctions.Complex.CircleAddChar
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum
import Mathlib.GroupTheory.Perm.Cycle.Type
import Mathlib.RingTheory.RootsOfUnity.Complex

lemma card_filter_modEq_fixed {α : Type*} [Fintype α] [DecidableEq α] (P : α → Prop)
    [DecidablePred P] (σ : α → α) (hP : ∀ x, P x → P (σ x)) (q n : ℕ) [Fact q.Prime]
    (hσ : ∀ x, P x → σ^[q ^ n] x = x) :
    (Finset.univ.filter P).card ≡
      (Finset.univ.filter (fun x => P x ∧ σ x = x)).card [MOD q] := by
  let f : Function.End {x // P x} := fun y => ⟨σ y.1, hP _ y.2⟩
  have hpow : ∀ k (y : {x // P x}), ((f ^ k) y).1 = σ^[k] y.1 := by
    intro k
    induction k with
    | zero => intro y; rfl
    | succ k ih =>
      intro y
      rw [pow_succ, Function.iterate_succ_apply]
      exact ih (f y)
  have hf : f ^ q ^ n = 1 := by
    apply funext
    intro y
    apply Subtype.ext
    rw [hpow]
    exact hσ _ y.2
  have key := Equiv.Perm.card_fixedPoints_modEq (f := f) (p := q) (n := n) hf
  rw [Fintype.card_subtype] at key
  refine key.trans ?_
  rw [← Fintype.card_subtype]
  have e : Function.fixedPoints f ≃ {x // P x ∧ σ x = x} :=
    { toFun := fun y => ⟨y.1.1, y.1.2, congrArg Subtype.val y.2⟩
      invFun := fun x => ⟨⟨x.1, x.2.1⟩, Subtype.ext x.2.2⟩
      left_inv := fun _ => rfl
      right_inv := fun _ => rfl }
  rw [Fintype.card_congr e]

#print axioms card_filter_modEq_fixed

lemma sq_form_unique {p : ℕ} (hp : p.Prime) {x y u v : ℤ} (h1 : (p : ℤ) = x ^ 2 + 3 * y ^ 2)
    (h2 : (p : ℤ) = u ^ 2 + 3 * v ^ 2) : y ^ 2 = v ^ 2 := by
  have hpz : Prime (p : ℤ) := Nat.prime_iff_prime_int.mp hp
  have hp0 : (0 : ℤ) < p := by exact_mod_cast hp.pos
  have key : (x * v - y * u) * (x * v + y * u) = p * (v ^ 2 - y ^ 2) := by
    linear_combination (-v ^ 2) * h1 + y ^ 2 * h2
  have fin : ∀ t : ℤ, t = 0 → (x * v - y * u) * (x * v + y * u) = 0 → y ^ 2 = v ^ 2 := by
    intro _ _ h
    rw [key] at h
    rcases mul_eq_zero.1 h with h | h
    · exact absurd h hp0.ne'
    · linear_combination -h
  rcases hpz.dvd_or_dvd ⟨_, key⟩ with ⟨k, hk⟩ | ⟨k, hk⟩
  · have hsq : (p : ℤ) ^ 2 = (x * u + 3 * y * v) ^ 2 + 3 * (p * k) ^ 2 := by
      rw [← hk]; linear_combination (p : ℤ) * h2 + (u ^ 2 + 3 * v ^ 2) * h1
    by_cases hk0 : k = 0
    · exact fin 0 rfl (by rw [hk, hk0]; ring)
    · have : 0 < k ^ 2 := by positivity
      nlinarith [mul_nonneg (sub_nonneg.2 (show (1 : ℤ) ≤ k ^ 2 by linarith))
        (sq_nonneg (p : ℤ)), sq_nonneg (x * u + 3 * y * v)]
  · have hsq : (p : ℤ) ^ 2 = (x * u - 3 * y * v) ^ 2 + 3 * (p * k) ^ 2 := by
      rw [← hk]; linear_combination (p : ℤ) * h2 + (u ^ 2 + 3 * v ^ 2) * h1
    by_cases hk0 : k = 0
    · exact fin 0 rfl (by rw [hk, hk0]; ring)
    · have : 0 < k ^ 2 := by positivity
      nlinarith [mul_nonneg (sub_nonneg.2 (show (1 : ℤ) ≤ k ^ 2 by linarith))
        (sq_nonneg (p : ℤ)), sq_nonneg (x * u - 3 * y * v)]

#print axioms sq_form_unique

lemma two_ne_zero_zmod {p : ℕ} [Fact p.Prime] (hp : p % 3 = 1) : (2 : ZMod p) ≠ 0 := by
  have hpp : p.Prime := Fact.out
  have hp2 : p ≠ 2 := by omega
  intro h
  have : ((2 : ℕ) : ZMod p) = 0 := by exact_mod_cast h
  rw [ZMod.natCast_eq_zero_iff] at this
  exact hp2 ((Nat.prime_dvd_prime_iff_eq hpp Nat.prime_two).1 this)

#print axioms two_ne_zero_zmod

lemma cube_iff_mulChar_eq_one {p : ℕ} [Fact p.Prime] (χ : MulChar (ZMod p) ℂ)
    (hχ : orderOf χ = 3) (a : ZMod p) (ha : a ≠ 0) :
    (∃ x : ZMod p, x ^ 3 = a) ↔ χ a = 1 := by
  have hχ3 : χ ^ 3 = 1 := hχ ▸ pow_orderOf_eq_one χ
  constructor
  · rintro ⟨x, rfl⟩
    have hx : x ≠ 0 := by rintro rfl; simp at ha
    rw [map_pow, ← MulChar.pow_apply' χ (by norm_num), hχ3]
    exact MulChar.one_apply (isUnit_iff_ne_zero.2 hx)
  · intro h
    obtain ⟨g, hg⟩ := IsCyclic.exists_monoid_generator (α := (ZMod p)ˣ)
    have hχg3 : χ g ^ 3 = 1 := by
      rw [← MulChar.pow_apply' χ (by norm_num), hχ3]
      exact MulChar.one_apply_coe g
    have hχ1 : χ ≠ 1 := by
      intro h1; rw [h1, orderOf_one] at hχ; norm_num at hχ
    have hχg1 : χ g ≠ 1 := by
      intro h1
      apply hχ1
      ext u
      obtain ⟨k, rfl⟩ := (Submonoid.mem_powers_iff _ _).1 (hg u)
      rw [Units.val_pow_eq_pow_val, map_pow, h1, one_pow, ← Units.val_pow_eq_pow_val,
        MulChar.one_apply_coe]
    have : Fact (Nat.Prime 3) := ⟨Nat.prime_three⟩
    have hord : orderOf (χ g) = 3 := orderOf_eq_prime hχg3 hχg1
    obtain ⟨k, hk⟩ := (Submonoid.mem_powers_iff _ _).1 (hg (Units.mk0 a ha))
    have hk1 : χ g ^ k = 1 := by
      rw [← map_pow, ← Units.val_pow_eq_pow_val, hk, Units.val_mk0, h]
    obtain ⟨m, rfl⟩ := hord ▸ orderOf_dvd_of_pow_eq_one hk1
    refine ⟨((g ^ m : (ZMod p)ˣ) : ZMod p), ?_⟩
    rw [← Units.val_pow_eq_pow_val, ← pow_mul, mul_comm, hk, Units.val_mk0]

#print axioms cube_iff_mulChar_eq_one

/-- Helper: the content of `jacobiSum_eq_primary_of_norm_p`, proved here so the rule for 2
below can use it. -/
lemma jacobiSum_primary_aux {p : ℕ} [Fact p.Prime] (hp : p % 3 = 1)
    (χ : MulChar (ZMod p) ℂ) (hχ : orderOf χ = 3) (ω : ℂ) (hω : IsPrimitiveRoot ω 3) :
    ∃ a b : ℤ, jacobiSum χ χ = a + b * ω ∧ a ^ 2 - a * b + b ^ 2 = p ∧
      a % 3 = 2 ∧ b % 3 = 0 ∧ (χ 2 = 1 ↔ Even b) := by
  classical
  have hpp : p.Prime := Fact.out
  have h2 : (2 : ZMod p) ≠ 0 := two_ne_zero_zmod hp
  have hω3 : ω ^ 3 = 1 := hω.pow_eq_one
  have hω1 : ω ≠ 1 := hω.ne_one (by norm_num)
  have hωsum : ω ^ 2 + ω + 1 = 0 := by
    have : (ω - 1) * (ω ^ 2 + ω + 1) = 0 := by linear_combination hω3
    rcases mul_eq_zero.1 this with h | h
    · exact absurd (sub_eq_zero.1 h) hω1
    · exact h
  have hω0 : ω ≠ 0 := by rintro rfl; norm_num at hω3
  have hω21 : ω ^ 2 ≠ 1 := fun h => by
    have := (hω.pow_eq_one_iff_dvd 2).1 h; norm_num at this
  have hω2ω : ω ^ 2 ≠ ω := fun h => hω1 (by
    have : ω * (ω - 1) = 0 := by linear_combination h
    rcases mul_eq_zero.1 this with h' | h'
    · exact absurd h' hω0
    · exact sub_eq_zero.1 h')
  have hω20 : ω ^ 2 ≠ 0 := pow_ne_zero _ hω0
  have hωinv : ω⁻¹ = ω ^ 2 := inv_eq_of_mul_eq_one_right (by linear_combination hω3)
  have hω2inv : (ω ^ 2)⁻¹ = ω := inv_eq_of_mul_eq_one_right (by linear_combination hω3)
  have hχ3 : χ ^ 3 = 1 := hχ ▸ pow_orderOf_eq_one χ
  have hcube : ∀ x : ZMod p, x ≠ 0 → χ x ^ 3 = 1 := by
    intro x hx
    rw [← MulChar.pow_apply' χ (by norm_num), hχ3]
    exact MulChar.one_apply (isUnit_iff_ne_zero.2 hx)
  have htri : ∀ z : ℂ, z ^ 3 = 1 → z = 1 ∨ z = ω ∨ z = ω ^ 2 := by
    intro z hz
    obtain ⟨i, hi, rfl⟩ := hω.eq_pow_of_pow_eq_one hz
    interval_cases i <;> simp
  have hneg : χ (-1) = 1 := by
    have h1 : χ (-1) ^ 2 = 1 := by rw [← map_pow]; simp
    have h3 := hcube (-1) (neg_ne_zero.2 one_ne_zero)
    linear_combination (-χ (-1)) * h1 + h3
  have hinvc : ∀ v : ℂ, v ^ 3 = 1 → v⁻¹ = v ^ 2 := fun v hv =>
    inv_eq_of_mul_eq_one_right (by linear_combination hv)
  set f : ZMod p → ℂ := fun x => χ x * χ (1 - x) with hf
  have hf0 : ∀ x, f x = 0 ↔ (x = 0 ∨ x = 1) := by
    intro x
    constructor
    · intro h
      by_contra hx
      simp only [not_or] at hx
      have h1 : (1 : ZMod p) - x ≠ 0 := sub_ne_zero.2 (Ne.symm hx.2)
      have : f x ^ 3 = 1 := by
        simp only [hf]; rw [mul_pow, hcube x hx.1, hcube _ h1, one_mul]
      rw [h] at this; norm_num at this
    · rintro (rfl | rfl) <;> simp [hf, χ.map_zero]
  have hfval : ∀ x, f x ≠ 0 → f x = 1 ∨ f x = ω ∨ f x = ω ^ 2 := by
    intro x hx
    rw [Ne, hf0, not_or] at hx
    have h1 : (1 : ZMod p) - x ≠ 0 := sub_ne_zero.2 (Ne.symm hx.2)
    apply htri
    simp only [hf]; rw [mul_pow, hcube x hx.1, hcube _ h1, one_mul]
  -- the three counts
  set N1 := (Finset.univ.filter fun x => f x = 1).card with hN1
  set Nω := (Finset.univ.filter fun x => f x = ω).card with hNω
  set N2 := (Finset.univ.filter fun x => f x = ω ^ 2).card with hN2
  have hpt : ∀ x, f x = ((if f x = 1 then 1 else 0) + (if f x = ω then 1 else 0) * ω +
      (if f x = ω ^ 2 then 1 else 0) * ω ^ 2 : ℂ) := by
    intro x
    by_cases h0 : f x = 0
    · rw [h0]; simp [hω0.symm, hω20.symm]
    rcases hfval x h0 with h | h | h <;> rw [h] <;>
      simp [hω1, hω1.symm, hω21, hω21.symm, hω2ω, hω2ω.symm]
  have hptinv : ∀ x, (f x)⁻¹ = ((if f x = 1 then 1 else 0) + (if f x = ω then 1 else 0) * ω ^ 2 +
      (if f x = ω ^ 2 then 1 else 0) * ω : ℂ) := by
    intro x
    by_cases h0 : f x = 0
    · rw [h0]; simp [hω0.symm, hω20.symm]
    rcases hfval x h0 with h | h | h <;> rw [h] <;>
      simp [hω1, hω1.symm, hω21, hω21.symm, hω2ω, hω2ω.symm, hωinv, hω2inv]
  have hJ : jacobiSum χ χ = N1 + Nω * ω + N2 * ω ^ 2 := by
    rw [show jacobiSum χ χ = ∑ x, f x from rfl, Finset.sum_congr rfl (fun x _ => hpt x),
      Finset.sum_add_distrib, Finset.sum_add_distrib, ← Finset.sum_mul, ← Finset.sum_mul]
    simp only [Finset.sum_boole]
    rfl
  have hJ' : jacobiSum χ⁻¹ χ⁻¹ = N1 + Nω * ω ^ 2 + N2 * ω := by
    have : jacobiSum χ⁻¹ χ⁻¹ = ∑ x, (f x)⁻¹ := by
      simp only [jacobiSum, MulChar.inv_apply_eq_inv', hf, mul_inv]
    rw [this, Finset.sum_congr rfl (fun x _ => hptinv x),
      Finset.sum_add_distrib, Finset.sum_add_distrib, ← Finset.sum_mul, ← Finset.sum_mul]
    simp only [Finset.sum_boole]
    rfl
  have hχ1 : χ ≠ 1 := by
    intro h; rw [h, orderOf_one] at hχ; norm_num at hχ
  have hχχ : χ * χ ≠ 1 := by
    rw [← sq]; exact pow_ne_one_of_lt_orderOf (by norm_num) (by omega)
  have hchar : ringChar ℂ ≠ ringChar (ZMod p) := by
    rw [ringChar.eq_zero, ZMod.ringChar_zmod_n]; exact hpp.ne_zero.symm
  have hnorm := jacobiSum_mul_jacobiSum_inv hchar hχ1 hχ1 hχχ
  rw [hJ, hJ', ZMod.card] at hnorm
  -- total count
  have hsum : N1 + Nω + N2 = p - 2 := by
    have hpt3 : ∀ x, ((if f x = 1 then 1 else 0) + (if f x = ω then 1 else 0) +
        (if f x = ω ^ 2 then 1 else 0) : ℕ) = if x ≠ 0 ∧ x ≠ 1 then 1 else 0 := by
      intro x
      by_cases h0 : f x = 0
      · have := (hf0 x).1 h0
        rw [h0]
        have : ¬ (x ≠ 0 ∧ x ≠ 1) := by tauto
        simp [hω0.symm, hω20.symm, this]
      have : x ≠ 0 ∧ x ≠ 1 := by
        rw [hf0, not_or] at h0; exact h0
      rcases hfval x h0 with h | h | h <;> rw [h] <;>
        simp [hω1, hω1.symm, hω21, hω21.symm, hω2ω, hω2ω.symm, this]
    have := Finset.sum_congr rfl (fun x (_ : x ∈ Finset.univ) => hpt3 x)
    rw [Finset.sum_add_distrib, Finset.sum_add_distrib] at this
    simp only [Finset.sum_boole, Nat.cast_id] at this
    rw [this]
    have : (Finset.univ.filter fun x : ZMod p => x ≠ 0 ∧ x ≠ 1) = Finset.univ \ {0, 1} := by
      ext x; simp
    rw [this, Finset.card_univ_sdiff, ZMod.card, Finset.card_pair zero_ne_one]
  have hχinv : ∀ y : ZMod p, χ y⁻¹ = (χ y)⁻¹ := fun y => by
    rw [← MulChar.inv_apply', MulChar.inv_apply_eq_inv']
  have hfσ : ∀ x, x ≠ 0 → x ≠ 1 → f ((1 - x)⁻¹) = f x := by
    intro x hx0 hx1
    have h1x : (1 : ZMod p) - x ≠ 0 := sub_ne_zero.2 (Ne.symm hx1)
    have e : 1 - (1 - x)⁻¹ = (-1) * x * (1 - x)⁻¹ := by field_simp; ring
    have hv := hcube _ h1x
    simp only [hf]
    rw [e, map_mul, map_mul, hneg, hχinv, hinvc _ hv]
    linear_combination (χ x * χ (1 - x)) * hv
  have hσ3 : ∀ x : ZMod p, x ≠ 0 → x ≠ 1 → (1 - (1 - (1 - x)⁻¹)⁻¹)⁻¹ = x := by
    intro x hx0 hx1
    have h1x : (1 : ZMod p) - x ≠ 0 := sub_ne_zero.2 (Ne.symm hx1)
    have e : 1 - (1 - x)⁻¹ = (-x) * (1 - x)⁻¹ := by field_simp; ring
    have e2 : 1 - (1 - (1 - x)⁻¹)⁻¹ = x⁻¹ := by
      rw [e, mul_inv, inv_inv]; field_simp; ring
    rw [e2, inv_inv]
  have hmod3 : ∀ c : ℂ, c ≠ 0 → c ≠ 1 → (Finset.univ.filter fun x => f x = c).card % 3 = 0 := by
    intro c hc0 hc1
    have hc01 : ∀ x, f x = c → x ≠ 0 ∧ x ≠ 1 := by
      intro x hx
      have : f x ≠ 0 := hx ▸ hc0
      rw [Ne, hf0, not_or] at this
      exact this
    have key := card_filter_modEq_fixed (fun x => f x = c) (fun x => (1 - x)⁻¹)
      (fun x hx => by
        obtain ⟨h0, h1⟩ := hc01 x hx
        show f ((1 - x)⁻¹) = c
        rw [hfσ x h0 h1]; exact hx) 3 1
      (fun x hx => by
        obtain ⟨h0, h1⟩ := hc01 x hx
        show (fun x : ZMod p => (1 - x)⁻¹)^[3] x = x
        simp only [Function.iterate_succ_apply', Function.iterate_zero_apply]
        exact hσ3 x h0 h1)
    have hempty : (Finset.univ.filter fun x => f x = c ∧ (1 - x)⁻¹ = x) = ∅ := by
      rw [Finset.filter_eq_empty_iff]
      rintro x - ⟨hx, hfix⟩
      obtain ⟨h0, h1⟩ := hc01 x hx
      have h1x : (1 : ZMod p) - x ≠ 0 := sub_ne_zero.2 (Ne.symm h1)
      have hprod : x * (1 - x) = 1 := by
        have := inv_mul_cancel₀ h1x
        rw [hfix] at this
        exact this
      apply hc1
      rw [← hx]
      simp only [hf]
      rw [← map_mul, hprod, map_one]
    rw [hempty, Finset.card_empty] at key
    exact key
  have hhalf : f 2⁻¹ = χ 2 := by
    have e : (1 : ZMod p) - 2⁻¹ = 2⁻¹ := by field_simp; ring
    have hu := hcube 2 h2
    simp only [hf]
    rw [e, hχinv, hinvc _ hu]
    linear_combination χ 2 * hu
  have hfixeq : ∀ x : ZMod p, 1 - x = x ↔ x = 2⁻¹ := by
    intro x
    constructor
    · intro h
      field_simp
      linear_combination -h
    · rintro rfl
      field_simp
      ring
  have hmod2 : ∀ c : ℂ, (Finset.univ.filter fun x => f x = c).card % 2 =
      if χ 2 = c then 1 else 0 := by
    intro c
    have key := card_filter_modEq_fixed (fun x => f x = c) (fun x => 1 - x)
      (fun x hx => by
        show f (1 - x) = c
        rw [← hx]; simp only [hf]; rw [sub_sub_cancel, mul_comm]) 2 1
      (fun x _ => by
        show (fun x : ZMod p => 1 - x)^[2] x = x
        simp only [Function.iterate_succ_apply', Function.iterate_zero_apply, sub_sub_cancel])
    have hfixc : (Finset.univ.filter fun x => f x = c ∧ 1 - x = x).card =
        if χ 2 = c then 1 else 0 := by
      by_cases hc : χ 2 = c
      · simp only [hc, ↓reduceIte]
        rw [Finset.card_eq_one]
        refine ⟨2⁻¹, ?_⟩
        ext x
        simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_singleton]
        constructor
        · rintro ⟨-, h⟩; exact (hfixeq x).1 h
        · rintro rfl; exact ⟨hhalf.trans hc, (hfixeq _).2 rfl⟩
      · simp only [hc, ↓reduceIte]
        have : (Finset.univ.filter fun x => f x = c ∧ 1 - x = x) = ∅ := by
          rw [Finset.filter_eq_empty_iff]
          rintro x - ⟨hx, hfix⟩
          rw [(hfixeq x).1 hfix, hhalf] at hx
          exact hc hx
        rw [this, Finset.card_empty]
    rw [show _ % 2 = _ % 2 from key, hfixc]
    split_ifs <;> rfl
  have h3ω : Nω % 3 = 0 := hmod3 ω hω0 hω1
  have h32 : N2 % 3 = 0 := hmod3 (ω ^ 2) hω20 hω21
  have h2ω : Nω % 2 = if χ 2 = ω then 1 else 0 := hmod2 ω
  have h22 : N2 % 2 = if χ 2 = ω ^ 2 then 1 else 0 := hmod2 (ω ^ 2)
  have hp2le := hpp.two_le
  refine ⟨(N1 : ℤ) - N2, (Nω : ℤ) - N2, ?_, ?_, ?_, ?_, ?_⟩
  · rw [hJ]; push_cast; linear_combination (N2 : ℂ) * hωsum
  · have hC : ((((N1 : ℤ) - N2) ^ 2 - ((N1 : ℤ) - N2) * ((Nω : ℤ) - N2) +
        ((Nω : ℤ) - N2) ^ 2 : ℤ) : ℂ) = ((p : ℤ) : ℂ) := by
      push_cast
      linear_combination hnorm - ((Nω : ℂ) ^ 2 + (N2 : ℂ) ^ 2 + (Nω : ℂ) * N2 * ω) * hω3 -
        ((N1 : ℂ) * Nω + (N1 : ℂ) * N2 + (Nω : ℂ) * N2) * hωsum
    exact_mod_cast hC
  · omega
  · omega
  · rcases htri _ (hcube 2 h2) with h | h | h <;> rw [h] at h2ω h22 <;> rw [h, Int.even_iff] <;>
      simp [hω1, hω1.symm, hω21, hω21.symm, hω2ω, hω2ω.symm] at h2ω h22 ⊢ <;> omega

#print axioms jacobiSum_primary_aux

/-- The rule for 2 (Euler's conjecture, proved by Gauss): for a prime p that leaves remainder 1
on division by 3, 2 is a cube mod p exactly when p = x^2 + 27y^2 for whole numbers x and y. -/
theorem two_is_cube_mod_prime_iff_eq_sq_add_twentyseven_sq {p : ℕ} [Fact p.Prime]
    (hp : p % 3 = 1) :
    (∃ x : ZMod p, x ^ 3 = 2) ↔ ∃ x y : ℤ, (p : ℤ) = x ^ 2 + 27 * y ^ 2 := by
  have hpp : p.Prime := Fact.out
  have hω := Complex.isPrimitiveRoot_exp 3 (by norm_num)
  obtain ⟨χ, hχ⟩ := MulChar.exists_mulChar_orderOf (ZMod p) (n := 3)
    (by rw [ZMod.card]; omega) hω
  obtain ⟨a, b, -, hn, ha, hb, hiff⟩ := jacobiSum_primary_aux hp χ hχ _ hω
  rw [cube_iff_mulChar_eq_one χ hχ 2 (two_ne_zero_zmod hp), hiff]
  constructor
  · rintro ⟨c, rfl⟩
    have : c % 3 = 0 := by omega
    obtain ⟨d, rfl⟩ : (3 : ℤ) ∣ c := Int.dvd_of_emod_eq_zero this
    exact ⟨a - 3 * d, d, by rw [← hn]; ring⟩
  · rintro ⟨x, y, hxy⟩
    by_contra hbe
    rw [Int.not_even_iff_odd] at hbe
    have h3 : ∀ c u : ℤ, (p : ℤ) = u ^ 2 + 3 * c ^ 2 → (3 : ℤ) ∣ c := by
      intro c u h
      have := sq_form_unique hpp (x := x) (y := 3 * y) (u := u) (v := c)
        (by rw [hxy]; ring) h
      have hd : (3 : ℤ) ∣ c ^ 2 := ⟨3 * y ^ 2, by rw [← this]; ring⟩
      exact Int.prime_three.dvd_of_dvd_pow hd
    rcases Int.even_or_odd a with ⟨c, hc⟩ | hao
    · have := h3 c (b - c) (by rw [← hn, hc]; ring)
      omega
    · have hab : (a - b) % 2 = 0 := by
        obtain ⟨k, hk⟩ := hao
        obtain ⟨j, hj⟩ := hbe
        omega
      obtain ⟨c, hc⟩ := Int.dvd_of_emod_eq_zero hab
      have ha' : a = b + c + c := by omega
      subst ha'
      have := h3 c (b + c) (by rw [← hn]; ring)
      omega

/-- Step 2: for a prime p that leaves remainder 1 on division by 3 and a cubic character χ mod p
(a multiplicative character of order 3, with χ(0) = 0), the Gauss sum
g(χ) = ∑ χ(t) ζ_p^t, with ζ_p = e^(2πi/p), satisfies g(χ)^3 = p · J(χ, χ). -/
theorem gaussSum_cube_eq_mul_jacobiSum {p : ℕ} [Fact p.Prime] (hp : p % 3 = 1)
    (χ : MulChar (ZMod p) ℂ) (hχ : orderOf χ = 3) :
    gaussSum χ ZMod.stdAddChar ^ 3 = (p : ℂ) * jacobiSum χ χ := by
  have h := gaussSum_pow_eq_prod_jacobiSum (χ := χ) (ψ := ZMod.stdAddChar) (by omega)
    (ZMod.isPrimitive_stdAddChar p)
  have hχ3 : χ ^ 3 = 1 := hχ ▸ pow_orderOf_eq_one χ
  have h1 : χ (-1) ^ 2 = 1 := by rw [← map_pow]; simp
  have h3 : χ (-1) ^ 3 = 1 := by
    rw [← MulChar.pow_apply' χ (by norm_num), hχ3]
    exact MulChar.one_apply (isUnit_one.neg)
  have hneg : χ (-1) = 1 := by linear_combination (-χ (-1)) * h1 + h3
  rw [hχ] at h
  rw [h, hneg, ZMod.card]
  simp

/-- Steps 3 to 5: for a prime p that leaves remainder 1 on division by 3, a cubic character χ
mod p and a complex cube root of 1 written ω (other than 1), the Jacobi sum J(χ, χ) is a + bω
with whole a and b, where a^2 - ab + b^2 = p, a leaves 2 and b leaves 0 on division by 3, and
χ(2) = 1 (2 is a cube mod p) exactly when b is even. -/
theorem jacobiSum_eq_primary_of_norm_p {p : ℕ} [Fact p.Prime] (hp : p % 3 = 1)
    (χ : MulChar (ZMod p) ℂ) (hχ : orderOf χ = 3) (ω : ℂ) (hω : IsPrimitiveRoot ω 3) :
    ∃ a b : ℤ, jacobiSum χ χ = a + b * ω ∧ a ^ 2 - a * b + b ^ 2 = p ∧
      a % 3 = 2 ∧ b % 3 = 0 ∧ (χ 2 = 1 ↔ Even b) := by
  exact jacobiSum_primary_aux hp χ hχ ω hω

-- 31 = 2^2 + 27 * 1^2, and 4^3 = 64 leaves 2 mod 31; the cube roots of 2 mod 31 are 4, 7, 20.
example : (31 : ℤ) = 2 ^ 2 + 27 * 1 ^ 2 := by norm_num
example : (4 : ZMod 31) ^ 3 = 2 := by decide
example : (7 : ZMod 31) ^ 3 = 2 ∧ (20 : ZMod 31) ^ 3 = 2 := by decide
-- 2 is no cube mod 7 or mod 13; the nonzero cubes mod 7 are only 1 and 6.
example : ¬ ∃ x : ZMod 7, x ^ 3 = 2 := by decide
example : ¬ ∃ x : ZMod 13, x ^ 3 = 2 := by decide
example : ∀ x : ZMod 7, x ≠ 0 → x ^ 3 = 1 ∨ x ^ 3 = 6 := by decide
-- 7 and 13 have no form x^2 + 27y^2 (any solution has x^2 ≤ 13 and y = 0), yet 7 = 2^2 + 3 · 1^2.
example : ¬ ∃ x y : Fin 8, (x : ℕ) ^ 2 + 27 * (y : ℕ) ^ 2 = 7 := by decide
example : ¬ ∃ x y : Fin 8, (x : ℕ) ^ 2 + 27 * (y : ℕ) ^ 2 = 13 := by decide
example : (7 : ℤ) = 2 ^ 2 + 3 * 1 ^ 2 := by norm_num
-- J = -1 - 3ω mod 7 has norm 7, and 4 · 7 = 28 = 1^2 + 27 · 1^2; for 31, J = 5 + 6ω has norm 31.
example : (-1 : ℤ) ^ 2 - (-1) * (-3) + (-3) ^ 2 = 7 := by norm_num
example : (4 * 7 : ℤ) = (2 * (-1) - (-3)) ^ 2 + 27 * ((-3) / 3) ^ 2 := by norm_num
example : (5 : ℤ) ^ 2 - 5 * 6 + 6 ^ 2 = 31 ∧ (124 : ℤ) = 4 ^ 2 + 27 * 2 ^ 2 := by norm_num
-- Mod 11 all 10 nonzero remainders are cubes, and 7^3 leaves 2.
example : (7 : ZMod 11) ^ 3 = 2 := by decide
example : ∀ y : ZMod 11, ∃ x : ZMod 11, x ^ 3 = y := by decide
-- Gauss's quartic rule: 73 = 3^2 + 64 · 1^2, and 18^4 leaves 2 mod 73; the quartic J = 3 + 8i has norm 73.
example : (73 : ℤ) = 3 ^ 2 + 64 * 1 ^ 2 ∧ (3 : ℤ) ^ 2 + 8 ^ 2 = 73 := by norm_num
example : (18 : ZMod 73) ^ 4 = 2 := by decide
-- 17 = 1 + 16, but 2 is no fourth power mod 17.
example : ¬ ∃ x : ZMod 17, x ^ 4 = 2 := by decide

#print axioms two_is_cube_mod_prime_iff_eq_sq_add_twentyseven_sq
#print axioms gaussSum_cube_eq_mul_jacobiSum
#print axioms jacobiSum_eq_primary_of_norm_p
