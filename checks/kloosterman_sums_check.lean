-- Kloosterman sums: for every odd prime p the fourth powers of the Kloosterman sums K(a, 1; p) add up over a = 1 to p − 1 to exactly 2p³ − 3p² − 3p − 1, so every sum with p dividing neither weight has size below 2^(1/4) p^(3/4).
import Mathlib.Analysis.SpecialFunctions.Complex.CircleAddChar
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Data.ZMod.Basic

open Finset

/-- The Kloosterman sum `K(a, b; p)`: the sum over every nonzero `x` mod `p` of
`ζ_p ^ (a x + b x⁻¹)`, where `x⁻¹` is the inverse of `x` mod `p` and
`ZMod.stdAddChar t = exp (2πi t / p)`. -/
noncomputable def kloosterman (p : ℕ) [NeZero p] (a b : ZMod p) : ℂ :=
  ∑ x ∈ univ.filter (fun x : ZMod p => x ≠ 0), ZMod.stdAddChar (a * x + b * x⁻¹)

-- Helper lemmas for the three theorems below.

lemma kl_full (p : ℕ) [Fact p.Prime] (a b : ZMod p) :
    ∑ x : ZMod p, ZMod.stdAddChar (a * x + b * x⁻¹) = 1 + kloosterman p a b := by
  unfold kloosterman
  rw [Finset.filter_ne', Finset.sum_erase_eq_sub (mem_univ _)]
  simp

lemma kl_char_sum (p : ℕ) [Fact p.Prime] (t : ZMod p) :
    ∑ a : ZMod p, ZMod.stdAddChar (a * t) = if t = 0 then (p : ℂ) else 0 := by
  rw [AddChar.sum_mulShift t (ZMod.isPrimitive_stdAddChar p)]
  simp [ZMod.card]

lemma kl_zero_zero (p : ℕ) [Fact p.Prime] : kloosterman p 0 0 = (p : ℂ) - 1 := by
  have h := kl_full p 0 0
  simp [ZMod.card] at h
  linear_combination -h

lemma kl_b_zero (p : ℕ) [Fact p.Prime] (a : ZMod p) (ha : a ≠ 0) : kloosterman p a 0 = -1 := by
  have h := kl_full p a 0
  simp only [zero_mul, add_zero] at h
  simp_rw [mul_comm a] at h
  rw [kl_char_sum] at h
  simp only [ha, ite_false] at h
  linear_combination -h

lemma kl_a_zero (p : ℕ) [Fact p.Prime] (b : ZMod p) (hb : b ≠ 0) : kloosterman p 0 b = -1 := by
  have h := kl_full p 0 b
  simp only [zero_mul, zero_add] at h
  rw [← Equiv.sum_comp (Equiv.inv (ZMod p))] at h
  simp only [Equiv.inv_apply, inv_inv] at h
  simp_rw [mul_comm b] at h
  rw [kl_char_sum] at h
  simp only [hb, ite_false] at h
  linear_combination -h

lemma kl_mul (p : ℕ) [Fact p.Prime] (a b : ZMod p) (hb : b ≠ 0) :
    kloosterman p a b = kloosterman p (a * b) 1 := by
  have h1 := kl_full p a b
  have h2 := kl_full p (a * b) 1
  have h3 : ∑ y : ZMod p, ZMod.stdAddChar (a * (b * y) + b * (b * y)⁻¹)
      = ∑ x : ZMod p, ZMod.stdAddChar (a * x + b * x⁻¹) :=
    Equiv.sum_comp (Equiv.mulLeft₀ b hb) (fun x => ZMod.stdAddChar (a * x + b * x⁻¹))
  have e : ∀ y : ZMod p, a * (b * y) + b * (b * y)⁻¹ = a * b * y + 1 * y⁻¹ := by
    intro y
    rw [mul_inv, mul_inv_cancel_left₀ hb]; ring
  rw [← h3] at h1
  simp only [e] at h1
  linear_combination h2 - h1

lemma kl_conj (p : ℕ) [Fact p.Prime] (a b : ZMod p) :
    (starRingEnd ℂ) (kloosterman p a b) = kloosterman p a b := by
  have h1 := kl_full p a b
  have h2 : ∑ x : ZMod p, ZMod.stdAddChar (a * x + b * x⁻¹)
      = (starRingEnd ℂ) (∑ x : ZMod p, ZMod.stdAddChar (a * x + b * x⁻¹)) := by
    rw [map_sum]
    simp_rw [← AddChar.map_neg_eq_conj]
    rw [← Equiv.sum_comp (Equiv.neg (ZMod p))]
    refine Finset.sum_congr rfl fun x _ => ?_
    congr 1
    simp only [Equiv.neg_apply, inv_neg]
    ring
  rw [h1, map_add, map_one] at h2
  linear_combination -h2

lemma kl_norm_le (p : ℕ) [Fact p.Prime] (a b : ZMod p) :
    ‖kloosterman p a b‖ ≤ ((univ.filter (fun x : ZMod p => x ≠ 0)).card : ℝ) := by
  unfold kloosterman
  refine (norm_sum_le _ _).trans ?_
  simp [AddChar.norm_apply]

lemma kl_card (p : ℕ) [Fact p.Prime] :
    (univ.filter (fun x : ZMod p => x ≠ 0)).card + 1 = p := by
  rw [Finset.filter_ne', Finset.card_erase_add_one (mem_univ _), card_univ, ZMod.card]

lemma kl_split (p : ℕ) [Fact p.Prime] (g : ZMod p → ℂ) :
    ∑ a, g a = g 0 + ∑ a ∈ univ.filter (fun x : ZMod p => x ≠ 0), g a := by
  rw [Finset.filter_ne', Finset.add_sum_erase _ _ (mem_univ 0)]

lemma kl_pow_four (p : ℕ) [Fact p.Prime] (a b : ZMod p) :
    kloosterman p a b ^ 4 = ∑ x ∈ univ.filter (fun x : ZMod p => x ≠ 0) ×ˢ
      univ.filter (fun x : ZMod p => x ≠ 0) ×ˢ univ.filter (fun x : ZMod p => x ≠ 0) ×ˢ
      univ.filter (fun x : ZMod p => x ≠ 0),
      ZMod.stdAddChar (a * (x.1 + x.2.1 + x.2.2.1 + x.2.2.2)
        + b * (x.1⁻¹ + x.2.1⁻¹ + x.2.2.1⁻¹ + x.2.2.2⁻¹)) := by
  rw [show kloosterman p a b ^ 4 = kloosterman p a b * (kloosterman p a b *
    (kloosterman p a b * kloosterman p a b)) by ring]
  simp only [kloosterman, Finset.sum_mul, Finset.mul_sum, Finset.sum_product]
  refine sum_congr rfl fun x1 _ => sum_congr rfl fun x2 _ => sum_congr rfl fun x3 _ =>
    sum_congr rfl fun x4 _ => ?_
  rw [← AddChar.map_add_eq_mul, ← AddChar.map_add_eq_mul, ← AddChar.map_add_eq_mul]
  congr 1
  ring
lemma kl_two_ne_zero (p : ℕ) [hp' : Fact p.Prime] (hp : p ≠ 2) : (2 : ZMod p) ≠ 0 := by
  intro h
  have h2 : ((2 : ℕ) : ZMod p) = 0 := by exact_mod_cast h
  rw [ZMod.natCast_eq_zero_iff] at h2
  have := Nat.le_of_dvd two_pos h2
  have := hp'.out.two_le
  omega

lemma kl_inner4 (p : ℕ) [Fact p.Prime] (x1 x2 x3 : ZMod p) :
    ∑ x4 : ZMod p, (if x1 ≠ 0 ∧ x2 ≠ 0 ∧ x3 ≠ 0 ∧ x4 ≠ 0 ∧ x1 + x2 = x3 + x4 ∧
      x1⁻¹ + x2⁻¹ = x3⁻¹ + x4⁻¹ then 1 else 0 : ℕ)
    = if x1 ≠ 0 ∧ x2 ≠ 0 ∧ x3 ≠ 0 ∧ x1 + x2 - x3 ≠ 0 ∧
      x1⁻¹ + x2⁻¹ = x3⁻¹ + (x1 + x2 - x3)⁻¹ then 1 else 0 := by
  rw [Finset.sum_eq_single (x1 + x2 - x3)]
  · exact if_congr ⟨fun ⟨a, b, c, d, _, f⟩ => ⟨a, b, c, d, f⟩,
      fun ⟨a, b, c, d, f⟩ => ⟨a, b, c, d, by ring, f⟩⟩ rfl rfl
  · intro x4 _ hne
    rw [ite_eq_right_iff]
    rintro ⟨-, -, -, -, h, -⟩
    exact absurd (by linear_combination -h) hne
  · intro h; exact absurd (mem_univ _) h

lemma kl_mid (p : ℕ) [Fact p.Prime] (x1 x2 : ZMod p) :
    ∑ x3 : ZMod p, (if x1 ≠ 0 ∧ x2 ≠ 0 ∧ x3 ≠ 0 ∧ x1 + x2 - x3 ≠ 0 ∧
      x1⁻¹ + x2⁻¹ = x3⁻¹ + (x1 + x2 - x3)⁻¹ then 1 else 0 : ℕ)
    = if x1 ≠ 0 ∧ x2 ≠ 0 then
        (if x1 + x2 = 0 then p - 1 else if x1 = x2 then 1 else 2) else 0 := by
  by_cases h12 : x1 ≠ 0 ∧ x2 ≠ 0
  swap
  · rw [ite_eq_right_of_eq_false _ _ (eq_false h12)]
    exact Finset.sum_eq_zero fun x3 _ => by
      rw [ite_eq_right_iff]; exact fun h => absurd ⟨h.1, h.2.1⟩ h12
  rw [ite_eq_left_of_eq_true _ _ (eq_true h12)]
  obtain ⟨h1, h2⟩ := h12
  rw [← Finset.card_filter]
  by_cases hs : x1 + x2 = 0
  · rw [ite_eq_left_of_eq_true _ _ (eq_true hs)]
    have hx2 : x2 = -x1 := by linear_combination hs
    subst hx2
    have : (univ.filter fun x3 : ZMod p => x1 ≠ 0 ∧ -x1 ≠ 0 ∧ x3 ≠ 0 ∧ x1 + -x1 - x3 ≠ 0 ∧
        x1⁻¹ + (-x1)⁻¹ = x3⁻¹ + (x1 + -x1 - x3)⁻¹) = univ.filter (fun x3 : ZMod p => x3 ≠ 0) := by
      ext x3
      simp [h1, inv_neg]
    rw [this, Finset.filter_ne', Finset.card_erase_of_mem (mem_univ _), card_univ, ZMod.card]
  · rw [ite_eq_right_of_eq_false _ _ (eq_false hs)]
    have : (univ.filter fun x3 : ZMod p => x1 ≠ 0 ∧ x2 ≠ 0 ∧ x3 ≠ 0 ∧ x1 + x2 - x3 ≠ 0 ∧
        x1⁻¹ + x2⁻¹ = x3⁻¹ + (x1 + x2 - x3)⁻¹) = {x1, x2} := by
      ext x3
      simp only [mem_filter, mem_univ, true_and, mem_insert, mem_singleton]
      constructor
      · rintro ⟨-, -, h3, h4, h5⟩
        rw [inv_add_inv h1 h2, inv_add_inv h3 h4,
          div_eq_div_iff (mul_ne_zero h1 h2) (mul_ne_zero h3 h4)] at h5
        have key : (x3 - x1) * (x3 - x2) * (x1 + x2) = 0 := by linear_combination (-1) * h5
        rcases mul_eq_zero.1 key with h | h
        · rcases mul_eq_zero.1 h with h | h
          · left; linear_combination h
          · right; linear_combination h
        · exact absurd h hs
      · rintro (rfl | rfl)
        · simp [h1, h2]
        · simp [h1, h2, add_comm]
    rw [this]
    by_cases he : x1 = x2
    · rw [ite_eq_left_of_eq_true _ _ (eq_true he), he]; simp
    · rw [ite_eq_right_of_eq_false _ _ (eq_false he), Finset.card_pair he]

lemma kl_outer (p : ℕ) [hp' : Fact p.Prime] (hp : p ≠ 2) (x1 : ZMod p) :
    ∑ x2 : ZMod p, (if x1 ≠ 0 ∧ x2 ≠ 0 then
        (if x1 + x2 = 0 then p - 1 else if x1 = x2 then 1 else 2) else 0 : ℕ)
    = if x1 ≠ 0 then 3 * (p - 2) else 0 := by
  by_cases h1 : x1 = 0
  · simp [h1]
  rw [ite_eq_left_of_eq_true _ _ (eq_true h1)]
  have hp3 : 3 ≤ p := by have := hp'.out.two_le; omega
  have h2 := kl_two_ne_zero p hp
  have hne : x1 ≠ -x1 := by
    intro h
    have : (2 : ZMod p) * x1 = 0 := by linear_combination h
    exact (mul_ne_zero h2 h1) this
  have key : ∀ x2 : ZMod p, (if x1 ≠ 0 ∧ x2 ≠ 0 then
        (if x1 + x2 = 0 then p - 1 else if x1 = x2 then 1 else 2) else 0 : ℕ)
        + (if x2 = 0 then 2 else 0) + (if x2 = x1 then 1 else 0)
      = 2 + (if x2 = -x1 then p - 3 else 0) := by
    intro x2
    have hs : x1 + x2 = 0 ↔ x2 = -x1 :=
      ⟨fun h => by linear_combination h, fun h => by linear_combination h⟩
    simp only [hs]
    by_cases a : x2 = 0
    · subst a
      have : (0 : ZMod p) ≠ -x1 := fun h => h1 (by linear_combination h)
      simp [h1, this, Ne.symm h1]
    by_cases b : x2 = -x1
    · subst b
      simp [h1, a, Ne.symm hne]
      omega
    by_cases c : x2 = x1
    · subst c
      simp [a, b]
    · simp [a, b, c, h1, Ne.symm c]
  have hsum := Finset.sum_congr (s₁ := (univ : Finset (ZMod p))) rfl (fun x2 _ => key x2)
  simp only [Finset.sum_add_distrib, Finset.sum_ite_eq', mem_univ, ite_true, sum_const,
    card_univ, ZMod.card, smul_eq_mul] at hsum
  omega

lemma kl_quad_count (p : ℕ) [Fact p.Prime] (hp : p ≠ 2) :
    (univ.filter (fun x : ZMod p × ZMod p × ZMod p × ZMod p =>
      x.1 ≠ 0 ∧ x.2.1 ≠ 0 ∧ x.2.2.1 ≠ 0 ∧ x.2.2.2 ≠ 0 ∧
      x.1 + x.2.1 = x.2.2.1 + x.2.2.2 ∧
      x.1⁻¹ + x.2.1⁻¹ = x.2.2.1⁻¹ + x.2.2.2⁻¹)).card = 3 * (p - 1) * (p - 2) := by
  rw [Finset.card_filter]
  simp only [Fintype.sum_prod_type]
  simp only [kl_inner4, kl_mid, kl_outer p hp]
  rw [← Finset.sum_filter, sum_const, smul_eq_mul]
  have := kl_card p
  rw [show (univ.filter (fun x : ZMod p => x ≠ 0)).card = p - 1 by omega]
  ring

lemma kl_count_neg (p : ℕ) [Fact p.Prime] :
    ((univ.filter (fun x : ZMod p => x ≠ 0) ×ˢ univ.filter (fun x : ZMod p => x ≠ 0) ×ˢ
      univ.filter (fun x : ZMod p => x ≠ 0) ×ˢ univ.filter (fun x : ZMod p => x ≠ 0)).filter
      (fun x : ZMod p × ZMod p × ZMod p × ZMod p =>
        x.1 + x.2.1 + x.2.2.1 + x.2.2.2 = 0 ∧ x.1⁻¹ + x.2.1⁻¹ + x.2.2.1⁻¹ + x.2.2.2⁻¹ = 0)).card
    = (univ.filter (fun x : ZMod p × ZMod p × ZMod p × ZMod p =>
      x.1 ≠ 0 ∧ x.2.1 ≠ 0 ∧ x.2.2.1 ≠ 0 ∧ x.2.2.2 ≠ 0 ∧
      x.1 + x.2.1 = x.2.2.1 + x.2.2.2 ∧
      x.1⁻¹ + x.2.1⁻¹ = x.2.2.1⁻¹ + x.2.2.2⁻¹)).card := by
  refine Finset.card_nbij' (fun x => (x.1, x.2.1, -x.2.2.1, -x.2.2.2))
    (fun x => (x.1, x.2.1, -x.2.2.1, -x.2.2.2)) ?_ ?_ ?_ ?_
  · rintro ⟨x1, x2, x3, x4⟩ hx
    simp only [coe_filter, mem_product, mem_filter, mem_univ, true_and, Set.mem_ofPred_eq] at hx ⊢
    obtain ⟨⟨h1, h2, h3, h4⟩, hs, ht⟩ := hx
    refine ⟨h1, h2, neg_ne_zero.2 h3, neg_ne_zero.2 h4, by linear_combination hs, ?_⟩
    rw [inv_neg, inv_neg]
    linear_combination ht
  · rintro ⟨x1, x2, x3, x4⟩ hx
    simp only [coe_filter, mem_product, mem_filter, mem_univ, true_and, Set.mem_ofPred_eq] at hx ⊢
    obtain ⟨h1, h2, h3, h4, hs, ht⟩ := hx
    refine ⟨⟨h1, h2, neg_ne_zero.2 h3, neg_ne_zero.2 h4⟩, by linear_combination hs, ?_⟩
    rw [inv_neg, inv_neg]
    linear_combination ht
  · rintro ⟨x1, x2, x3, x4⟩ _
    simp
  · rintro ⟨x1, x2, x3, x4⟩ _
    simp

lemma kl_double_sum (p : ℕ) [Fact p.Prime] :
    ∑ a : ZMod p, ∑ b : ZMod p, kloosterman p a b ^ 4
      = (p : ℂ) ^ 2 * ((univ.filter (fun x : ZMod p × ZMod p × ZMod p × ZMod p =>
      x.1 ≠ 0 ∧ x.2.1 ≠ 0 ∧ x.2.2.1 ≠ 0 ∧ x.2.2.2 ≠ 0 ∧
      x.1 + x.2.1 = x.2.2.1 + x.2.2.2 ∧
      x.1⁻¹ + x.2.1⁻¹ = x.2.2.1⁻¹ + x.2.2.2⁻¹)).card : ℂ) := by
  rw [← kl_count_neg, Finset.card_filter]
  simp only [kl_pow_four]
  rw [Finset.sum_congr rfl fun a _ => Finset.sum_comm, Finset.sum_comm]
  push_cast
  rw [Finset.mul_sum]
  refine Finset.sum_congr rfl fun x _ => ?_
  have e : ∀ a b : ZMod p, ZMod.stdAddChar (a * (x.1 + x.2.1 + x.2.2.1 + x.2.2.2)
        + b * (x.1⁻¹ + x.2.1⁻¹ + x.2.2.1⁻¹ + x.2.2.2⁻¹))
      = ZMod.stdAddChar (a * (x.1 + x.2.1 + x.2.2.1 + x.2.2.2))
        * ZMod.stdAddChar (b * (x.1⁻¹ + x.2.1⁻¹ + x.2.2.1⁻¹ + x.2.2.2⁻¹)) :=
    fun a b => AddChar.map_add_eq_mul _ _ _
  simp only [e, ← Finset.sum_mul_sum, kl_char_sum]
  split_ifs <;> simp_all [sq]

lemma kl_inner_shift (p : ℕ) [Fact p.Prime] (a : ZMod p) (ha : a ≠ 0) (f : ZMod p → ℂ) :
    ∑ b ∈ univ.filter (fun x : ZMod p => x ≠ 0), f (a * b)
      = ∑ c ∈ univ.filter (fun x : ZMod p => x ≠ 0), f c := by
  have h := Equiv.sum_comp (Equiv.mulLeft₀ a ha) f
  have h' : ∑ b : ZMod p, f (a * b) = ∑ c : ZMod p, f c := h
  rw [kl_split p (fun b => f (a * b)), kl_split p f, mul_zero] at h'
  linear_combination h'

/-- The exact fourth moment: for an odd prime `p`, the fourth powers of the Kloosterman sums
`K(a, 1; p)`, added over the nonzero weights `a = 1, …, p − 1`, come to exactly
`2p³ − 3p² − 3p − 1`. -/
theorem kloosterman_fourth_moment (p : ℕ) [Fact p.Prime] (hp : p ≠ 2) :
    ∑ a ∈ univ.filter (fun a : ZMod p => a ≠ 0), kloosterman p a 1 ^ 4
      = 2 * (p : ℂ) ^ 3 - 3 * (p : ℂ) ^ 2 - 3 * (p : ℂ) - 1 := by
  have hD := kl_double_sum p
  rw [kl_quad_count p hp] at hD
  have hp2 : 2 ≤ p := (Fact.out : p.Prime).two_le
  have hcard : ((univ.filter (fun x : ZMod p => x ≠ 0)).card : ℂ) = (p : ℂ) - 1 := by
    have h : (((univ.filter (fun x : ZMod p => x ≠ 0)).card : ℕ) : ℂ) + 1 = p := by
      exact_mod_cast kl_card p
    linear_combination h
  rw [kl_split p, kl_split p, kl_zero_zero] at hD
  have e1 : ∑ b ∈ univ.filter (fun x : ZMod p => x ≠ 0), kloosterman p 0 b ^ 4
      = (p : ℂ) - 1 := by
    rw [Finset.sum_congr rfl fun b hb => by
      rw [kl_a_zero p b (by simpa using hb)]]
    simp [hcard]
    norm_num
  have e2 : ∑ a ∈ univ.filter (fun x : ZMod p => x ≠ 0), ∑ b : ZMod p, kloosterman p a b ^ 4
      = ∑ a ∈ univ.filter (fun x : ZMod p => x ≠ 0), (1 + ∑ c ∈ univ.filter
          (fun x : ZMod p => x ≠ 0), kloosterman p c 1 ^ 4) := by
    refine Finset.sum_congr rfl fun a ha => ?_
    have ha' : a ≠ 0 := by simpa using ha
    rw [kl_split p, kl_b_zero p a ha']
    congr 1
    · norm_num
    · rw [Finset.sum_congr rfl fun b hb => by rw [kl_mul p a b (by simpa using hb)]]
      exact kl_inner_shift p a ha' (fun c => kloosterman p c 1 ^ 4)
  rw [e1, e2, Finset.sum_const, nsmul_eq_mul, hcard] at hD
  have hp1 : (p : ℂ) - 1 ≠ 0 := by
    rw [sub_ne_zero]; exact_mod_cast (by omega : p ≠ 1)
  apply mul_left_cancel₀ hp1
  push_cast [Nat.cast_sub (by omega : 1 ≤ p), Nat.cast_sub hp2] at hD
  linear_combination hD

/-- Kloosterman's bound: for a prime `p` dividing neither weight `a` nor `b`, the Kloosterman sum
`K(a, b; p)` has size below `2^(1/4) p^(3/4)`. -/
theorem kloosterman_bound (p : ℕ) [Fact p.Prime] (a b : ZMod p) (ha : a ≠ 0) (hb : b ≠ 0) :
    ‖kloosterman p a b‖ < (2 : ℝ) ^ (1 / 4 : ℝ) * (p : ℝ) ^ (3 / 4 : ℝ) := by
  have hp0 : (0 : ℝ) ≤ p := Nat.cast_nonneg p
  have hB : ((2 : ℝ) ^ (1 / 4 : ℝ) * (p : ℝ) ^ (3 / 4 : ℝ)) ^ 4 = 2 * (p : ℝ) ^ 3 := by
    rw [mul_pow, ← Real.rpow_mul_natCast (by norm_num), ← Real.rpow_mul_natCast hp0]
    norm_num
  have hBnn : 0 ≤ (2 : ℝ) ^ (1 / 4 : ℝ) * (p : ℝ) ^ (3 / 4 : ℝ) := by positivity
  refine lt_of_pow_lt_pow_left₀ 4 hBnn ?_
  rw [hB]
  have hp2 : 2 ≤ p := (Fact.out : p.Prime).two_le
  by_cases hp : p = 2
  · have h1 := kl_norm_le p a b
    have hc := kl_card p
    have hc1 : (univ.filter (fun x : ZMod p => x ≠ 0)).card = 1 := by omega
    rw [hc1, Nat.cast_one] at h1
    have : ‖kloosterman p a b‖ ^ 4 ≤ 1 := pow_le_one₀ (norm_nonneg _) h1
    have hp' : (p : ℝ) = 2 := by exact_mod_cast hp
    rw [hp']
    linarith
  · rw [kl_mul p a b hb]
    have hc : a * b ≠ 0 := mul_ne_zero ha hb
    have hreal : ∀ c : ZMod p, kloosterman p c 1 = ((kloosterman p c 1).re : ℂ) := fun c =>
      (Complex.conj_eq_iff_re.1 (kl_conj p c 1)).symm
    have hM := kloosterman_fourth_moment p hp
    have hR : ∑ c ∈ univ.filter (fun x : ZMod p => x ≠ 0), (kloosterman p c 1).re ^ 4
        = 2 * (p : ℝ) ^ 3 - 3 * (p : ℝ) ^ 2 - 3 * (p : ℝ) - 1 := by
      apply Complex.ofReal_injective
      push_cast
      rw [← hM]
      exact Finset.sum_congr rfl fun c _ => by rw [← hreal c]
    have hle : (kloosterman p (a * b) 1).re ^ 4
        ≤ ∑ c ∈ univ.filter (fun x : ZMod p => x ≠ 0), (kloosterman p c 1).re ^ 4 :=
      Finset.single_le_sum (f := fun c => (kloosterman p c 1).re ^ 4)
        (fun c _ => by positivity) (by simpa using hc)
    have hn : ‖kloosterman p (a * b) 1‖ ^ 4 = (kloosterman p (a * b) 1).re ^ 4 := by
      rw [hreal (a * b), Complex.norm_real, Real.norm_eq_abs, Complex.ofReal_re,
        Even.pow_abs (by decide)]
    have hp3 : (0 : ℝ) < p := by positivity
    rw [hn]
    nlinarith

/-- The count behind the fourth moment: for an odd prime `p`, the quadruples of nonzero remainders
mod `p` with `x₁ + x₂ = x₃ + x₄` and `x₁⁻¹ + x₂⁻¹ = x₃⁻¹ + x₄⁻¹` number exactly `3(p − 1)(p − 2)`. -/
theorem kloosterman_quadruple_count (p : ℕ) [Fact p.Prime] (hp : p ≠ 2) :
    (univ.filter (fun x : ZMod p × ZMod p × ZMod p × ZMod p =>
      x.1 ≠ 0 ∧ x.2.1 ≠ 0 ∧ x.2.2.1 ≠ 0 ∧ x.2.2.2 ≠ 0 ∧
      x.1 + x.2.1 = x.2.2.1 + x.2.2.2 ∧
      x.1⁻¹ + x.2.1⁻¹ = x.2.2.1⁻¹ + x.2.2.2⁻¹)).card = 3 * (p - 1) * (p - 2) := by
  exact kl_quad_count p hp

-- The card's worked values of the fourth moment: 517 at p = 7 and 3,847 at p = 13.
example : 2 * 7 ^ 3 - 3 * 7 ^ 2 - 3 * 7 - 1 = 517 := by norm_num
example : 2 * 13 ^ 3 - 3 * 13 ^ 2 - 3 * 13 - 1 = 3847 := by norm_num
-- The card's count at p = 13: 3 · 12 · 11 = 396 quadruples, and Step 4's arithmetic.
example : 3 * (13 - 1) * (13 - 2) = 396 := by norm_num
example : (13 ^ 2 * 396 - (13 - 1) ^ 4 - 2 * (13 - 1)) / (13 - 1) = 3847 := by norm_num
-- The direct count of quadruples at p = 7: 3 · 6 · 5 = 90.
example : (univ.filter (fun x : ZMod 7 × ZMod 7 × ZMod 7 × ZMod 7 =>
      x.1 ≠ 0 ∧ x.2.1 ≠ 0 ∧ x.2.2.1 ≠ 0 ∧ x.2.2.2 ≠ 0 ∧
      x.1 + x.2.1 = x.2.2.1 + x.2.2.2 ∧
      x.1⁻¹ + x.2.1⁻¹ = x.2.2.1⁻¹ + x.2.2.2⁻¹)).card = 90 := by decide +kernel

-- The direct count of quadruples at p = 13: 3 · 12 · 11 = 396.
example : (univ.filter (fun x : ZMod 13 × ZMod 13 × ZMod 13 × ZMod 13 =>
      x.1 ≠ 0 ∧ x.2.1 ≠ 0 ∧ x.2.2.1 ≠ 0 ∧ x.2.2.2 ≠ 0 ∧
      x.1 + x.2.1 = x.2.2.1 + x.2.2.2 ∧
      x.1⁻¹ + x.2.1⁻¹ = x.2.2.1⁻¹ + x.2.2.2⁻¹)).card = 396 := by decide +kernel

#print axioms kl_full
#print axioms kl_char_sum
#print axioms kl_zero_zero
#print axioms kl_b_zero
#print axioms kl_a_zero
#print axioms kl_mul
#print axioms kl_conj
#print axioms kl_norm_le
#print axioms kl_card
#print axioms kl_split
#print axioms kl_pow_four
#print axioms kl_two_ne_zero
#print axioms kl_inner4
#print axioms kl_mid
#print axioms kl_outer
#print axioms kl_quad_count
#print axioms kl_count_neg
#print axioms kl_double_sum
#print axioms kl_inner_shift
#print axioms kloosterman_fourth_moment
#print axioms kloosterman_bound
#print axioms kloosterman_quadruple_count
