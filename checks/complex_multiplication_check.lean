-- Complex multiplication: for y^2 = x^3 - x the map (x, y) ↦ (-x, iy) is a symmetry of the group with [i][i] = [-1], and the number of points mod an odd prime p is p + 1 when p leaves 3 on division by 4 and p + 1 - 2a when p = a^2 + b^2 with b even and a + b leaving 1 on division by 4.
import Mathlib.AlgebraicGeometry.EllipticCurve.Affine.Point
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Fintype.Prod
import Mathlib.Algebra.Order.Group.Unbundled.Int
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.NumberTheory.LegendreSymbol.QuadraticChar.Basic
import Mathlib.NumberTheory.LegendreSymbol.Basic

/-- The curve y^2 = x^3 - x as a Weierstrass curve over a commutative ring `F`. -/
abbrev cmCurve (F : Type*) [CommRing F] : WeierstrassCurve F :=
  { a₁ := 0, a₂ := 0, a₃ := 0, a₄ := -1, a₆ := 0 }

/-- The points of y^2 = x^3 - x mod `p`, the point at infinity O included: one for O plus the
number of pairs `(x, y)` of remainders mod `p` with `y^2 = x^3 - x`. -/
def cmCount (p : ℕ) [NeZero p] : ℕ :=
  ((Finset.univ : Finset (ZMod p × ZMod p)).filter (fun q => q.2 ^ 2 = q.1 ^ 3 - q.1)).card + 1

section CmCharSums

open Finset

variable {F : Type*} [Field F] [Fintype F] [DecidableEq F]

lemma cm_card_sqrts (hF : ringChar F ≠ 2) (a : F) :
    ∑ y : F, (if y ^ 2 = a then (1 : ℤ) else 0) = quadraticChar F a + 1 := by
  rw [sum_boole]
  have := quadraticChar_card_sqrts hF a
  rw [Set.toFinset_ofPred] at this
  exact this
lemma cm_chi_cube (a : F) : quadraticChar F (a ^ 3) = quadraticChar F a := by
  rw [map_pow]
  rcases eq_or_ne a 0 with rfl | ha
  · simp
  · rcases quadraticChar_dichotomy ha with h | h <;> rw [h] <;> norm_num

lemma cm_chi_sq_self (a : F) : quadraticChar F a * quadraticChar F a = if a = 0 then 0 else 1 := by
  split_ifs with ha
  · simp [ha]
  · rw [← sq, quadraticChar_sq_one ha]

lemma cm_sum_nonzero : ∑ x : F, (if x = 0 then (0 : ℤ) else 1) = Fintype.card F - 1 := by
  have : ∀ x : F, (if x = 0 then (0 : ℤ) else 1) = 1 - if x = 0 then 1 else 0 := by
    intro x; split_ifs <;> simp
  simp only [this, sum_sub_distrib, sum_ite_eq', mem_univ, ite_true, sum_const, card_univ,
    nsmul_eq_mul, mul_one]

/-- `φ(c) = ∑ χ(x^3 + c x)`. -/
def cmPhi (F : Type*) [Field F] [Fintype F] [DecidableEq F] (c : F) : ℤ :=
  ∑ x : F, quadraticChar F (x ^ 3 + c * x)

lemma cmPhi_scale (c t : F) (ht : t ≠ 0) :
    cmPhi F (c * t ^ 2) = quadraticChar F t * cmPhi F c := by
  unfold cmPhi
  rw [← (mulLeft_bijective₀ t ht).sum_comp, mul_sum]
  refine sum_congr rfl fun x _ => ?_
  rw [show (t * x) ^ 3 + c * t ^ 2 * (t * x) = t ^ 3 * (x ^ 3 + c * x) by ring, map_mul,
    cm_chi_cube]

lemma cmPhi_zero (hF : ringChar F ≠ 2) : cmPhi F 0 = 0 := by
  unfold cmPhi
  simp only [zero_mul, add_zero, cm_chi_cube]
  exact quadraticChar_sum_zero hF

lemma cm_sum_shift (hF : ringChar F ≠ 2) (d : F) (hd : d ≠ 0) :
    ∑ u : F, quadraticChar F u * quadraticChar F (u + d) = -1 := by
  have key : ∀ u : F, quadraticChar F u * quadraticChar F (u + d) =
      quadraticChar F (1 + d * u⁻¹) - if u = 0 then 1 else 0 := by
    intro u
    rcases eq_or_ne u 0 with rfl | hu
    · simp
    · simp only [hu, ite_false, sub_zero]
      rw [← map_mul, show u * (u + d) = (1 + d * u⁻¹) * u ^ 2 by field_simp, map_mul,
        quadraticChar_sq_one' hu, mul_one]
  simp only [key, sum_sub_distrib, sum_ite_eq', mem_univ, ite_true]
  have h1 : ∑ u : F, quadraticChar F (1 + d * u⁻¹) = ∑ v : F, quadraticChar F (1 + d * v) :=
    (Equiv.inv F).bijective.sum_comp (fun v => quadraticChar F (1 + d * v))
  have h2 : ∑ v : F, quadraticChar F (1 + d * v) = ∑ w : F, quadraticChar F w :=
    ((Equiv.addLeft (1 : F)).bijective.comp (mulLeft_bijective₀ d hd)).sum_comp
      (fun w => quadraticChar F w)
  rw [h1, h2, quadraticChar_sum_zero hF]
  simp

lemma cm_sum_pair (hF : ringChar F ≠ 2) (α β : F) :
    ∑ c : F, quadraticChar F (α + c) * quadraticChar F (β + c) =
      if α = β then (Fintype.card F : ℤ) - 1 else -1 := by
  rw [← (Equiv.addLeft (-α)).bijective.sum_comp]; simp only [Equiv.coe_addLeft]
  split_ifs with h
  · subst h
    simp only [add_neg_cancel_left, cm_chi_sq_self]
    exact cm_sum_nonzero
  · have := cm_sum_shift hF (β - α) (sub_ne_zero.mpr (Ne.symm h))
    rw [← this]
    refine sum_congr rfl fun u _ => ?_
    congr 2 <;> ring

lemma cm_inner (hF : ringChar F ≠ 2) (hneg : quadraticChar F (-1) = 1) (x : F) :
    ∑ y : F, (if x ^ 2 = y ^ 2 then quadraticChar F x * quadraticChar F y else 0) =
      if x = 0 then 0 else 2 := by
  rcases eq_or_ne x 0 with rfl | hx
  · simp
  · have : ∀ y : F, (if x ^ 2 = y ^ 2 then quadraticChar F x * quadraticChar F y else 0) =
        if y ^ 2 = x ^ 2 then 1 else 0 := by
      intro y
      by_cases h : y ^ 2 = x ^ 2
      · rw [ite_eq_left h.symm, ite_eq_left h]
        rcases sq_eq_sq_iff_eq_or_eq_neg.mp h with rfl | rfl
        · rw [cm_chi_sq_self, ite_eq_right hx]
        · rw [show -x = -1 * x by ring, map_mul, hneg, one_mul, cm_chi_sq_self, ite_eq_right hx]
      · rw [ite_eq_right (fun h' => h h'.symm), ite_eq_right h]
    rw [sum_congr rfl fun y _ => this y, cm_card_sqrts hF, quadraticChar_sq_one' hx, ite_eq_right hx]
    norm_num

lemma cmPhi_sum_sq (hF : ringChar F ≠ 2) (hneg : quadraticChar F (-1) = 1) :
    ∑ c : F, cmPhi F c ^ 2 = 2 * Fintype.card F * (Fintype.card F - 1) := by
  have expand : ∀ c : F, cmPhi F c ^ 2 = ∑ x : F, ∑ y : F,
      quadraticChar F x * quadraticChar F y *
        (quadraticChar F (x ^ 2 + c) * quadraticChar F (y ^ 2 + c)) := by
    intro c
    rw [cmPhi, sq, sum_mul_sum]
    refine sum_congr rfl fun x _ => sum_congr rfl fun y _ => ?_
    rw [show x ^ 3 + c * x = x * (x ^ 2 + c) by ring, show y ^ 3 + c * y = y * (y ^ 2 + c) by ring,
      map_mul, map_mul]
    ring
  simp only [expand]
  rw [sum_comm]
  rw [sum_congr rfl fun x _ => sum_comm]
  simp only [← mul_sum, cm_sum_pair hF]
  have step : ∀ x y : F, quadraticChar F x * quadraticChar F y *
      (if x ^ 2 = y ^ 2 then (Fintype.card F : ℤ) - 1 else -1) =
      Fintype.card F * (if x ^ 2 = y ^ 2 then quadraticChar F x * quadraticChar F y else 0) -
        quadraticChar F x * quadraticChar F y := by
    intro x y; split_ifs <;> ring
  simp only [step, sum_sub_distrib, ← mul_sum, cm_inner hF hneg,
    quadraticChar_sum_zero hF, mul_zero, sub_zero]
  have : ∑ x : F, (if x = 0 then (0 : ℤ) else 2) = 2 * ∑ x : F, (if x = 0 then (0 : ℤ) else 1) := by
    rw [mul_sum]; refine sum_congr rfl fun x _ => ?_; split_ifs <;> norm_num
  rw [this, cm_sum_nonzero]
  ring

lemma cmPhi_sq_class (r : F) (hr : quadraticChar F r = -1) (c : F) (hc : c ≠ 0) :
    2 * cmPhi F c ^ 2 = (1 + quadraticChar F c) * cmPhi F 1 ^ 2 +
      (1 - quadraticChar F c) * cmPhi F r ^ 2 := by
  have sqχ : ∀ t : F, t ≠ 0 → quadraticChar F t ^ 2 = 1 := fun t ht => quadraticChar_sq_one ht
  rcases quadraticChar_dichotomy hc with h | h
  · obtain ⟨t, rfl⟩ := (quadraticChar_one_iff_isSquare hc).mp h
    have ht : t ≠ 0 := by rintro rfl; simp at hc
    have := cmPhi_scale (1 : F) t ht
    rw [one_mul, sq] at this
    rw [this, h, mul_pow, sqχ t ht]
    ring
  · have hr0 : r ≠ 0 := by rintro rfl; simp at hr
    have hcr : quadraticChar F (c / r) = 1 := by
      have e : quadraticChar F (c / r) * quadraticChar F r = quadraticChar F c := by
        rw [← map_mul, div_mul_cancel₀ c hr0]
      rw [h, hr] at e
      linarith
    have hcr0 : c / r ≠ 0 := div_ne_zero hc hr0
    obtain ⟨t, ht⟩ := (quadraticChar_one_iff_isSquare hcr0).mp hcr
    have ht0 : t ≠ 0 := by rintro rfl; rw [mul_zero] at ht; exact hcr0 ht
    have hc' : c = r * t ^ 2 := by rw [sq, ← ht, mul_div_cancel₀ c hr0]
    rw [hc', cmPhi_scale r t ht0, mul_pow, sqχ t ht0, ← hc', h]
    ring

lemma cmPhi_four_q (hF : ringChar F ≠ 2) (hneg : quadraticChar F (-1) = 1) (r : F)
    (hr : quadraticChar F r = -1) :
    cmPhi F 1 ^ 2 + cmPhi F r ^ 2 = 4 * Fintype.card F := by
  set A := cmPhi F 1 ^ 2
  set B := cmPhi F r ^ 2
  have pt : ∀ c : F, 2 * cmPhi F c ^ 2 = (1 + quadraticChar F c) * A +
      (1 - quadraticChar F c) * B - if c = 0 then A + B else 0 := by
    intro c
    rcases eq_or_ne c 0 with rfl | hc
    · simp [cmPhi_zero hF]
    · rw [ite_eq_right hc, sub_zero, cmPhi_sq_class r hr c hc]
  have hsum := cmPhi_sum_sq hF hneg
  have h2 : ∑ c : F, 2 * cmPhi F c ^ 2 = 2 * (2 * (Fintype.card F : ℤ) * (Fintype.card F - 1)) := by
    rw [← mul_sum, hsum]
  simp only [pt, sum_sub_distrib, sum_add_distrib, ← sum_mul, sum_ite_eq', mem_univ, ite_true,
    quadraticChar_sum_zero hF, sum_const, card_univ, nsmul_eq_mul, mul_one, add_zero,
    sub_zero] at h2
  have hq : (1 : ℤ) < Fintype.card F := by exact_mod_cast Fintype.one_lt_card
  have : ((Fintype.card F : ℤ) - 1) * (A + B) = ((Fintype.card F : ℤ) - 1) * (4 * Fintype.card F) := by
    linear_combination h2
  exact mul_left_cancel₀ (by linarith) this

lemma cm_zeros (hF : ringChar F ≠ 2) :
    (univ.filter (fun x : F => x ^ 3 - x = 0)).card = 3 := by
  have h2 : (2 : F) ≠ 0 := Ring.two_ne_zero hF
  have e : univ.filter (fun x : F => x ^ 3 - x = 0) = {0, 1, -1} := by
    ext x
    simp only [mem_filter, mem_univ, true_and, mem_insert, mem_singleton]
    constructor
    · intro h
      have : x * (x - 1) * (x + 1) = 0 := by linear_combination h
      rcases mul_eq_zero.mp this with h' | h'
      · rcases mul_eq_zero.mp h' with h'' | h''
        · left; exact h''
        · right; left; linear_combination h''
      · right; right; linear_combination h'
    · rintro (rfl | rfl | rfl) <;> ring
  rw [e, card_insert_of_notMem, card_pair]
  · intro h; apply h2; linear_combination h
  · simp only [mem_insert, mem_singleton, not_or]
    exact ⟨zero_ne_one, by intro h; exact one_ne_zero (neg_eq_zero.mp h.symm)⟩

lemma cm_S_eq (hF : ringChar F ≠ 2) :
    ∑ x : F, quadraticChar F (x ^ 3 - x) =
      (Fintype.card F - 3 : ℤ) -
        2 * (univ.filter (fun x : F => quadraticChar F (x ^ 3 - x) = -1)).card := by
  have pt : ∀ x : F, quadraticChar F (x ^ 3 - x) =
      (1 - if x ^ 3 - x = 0 then 1 else 0) -
        2 * (if quadraticChar F (x ^ 3 - x) = -1 then 1 else 0) := by
    intro x
    by_cases h0 : x ^ 3 - x = 0
    · rw [h0]; simp
    · rcases quadraticChar_dichotomy h0 with h | h <;> simp [h, h0]
  rw [sum_congr rfl fun x _ => pt x]
  simp only [sum_sub_distrib, ← mul_sum, sum_boole, sum_const, card_univ, nsmul_eq_mul,
    mul_one, cm_zeros hF]
  push_cast
  ring

lemma cm_inv_mem (hneg : quadraticChar F (-1) = 1) (x : F) (hx : x ≠ 0) :
    quadraticChar F (x⁻¹ ^ 3 - x⁻¹) = quadraticChar F (x ^ 3 - x) := by
  have hx' : x⁻¹ ≠ 0 := inv_ne_zero hx
  rw [show x⁻¹ ^ 3 - x⁻¹ = -1 * (x ^ 3 - x) * (x⁻¹ ^ 2) ^ 2 by field_simp; ring, map_mul, map_mul,
    hneg, quadraticChar_sq_one' (pow_ne_zero 2 hx'), one_mul, mul_one]

lemma cm_neg_mem (hneg : quadraticChar F (-1) = 1) (x : F) :
    quadraticChar F ((-x) ^ 3 - -x) = quadraticChar F (x ^ 3 - x) := by
  rw [show (-x) ^ 3 - -x = -1 * (x ^ 3 - x) by ring, map_mul, hneg, one_mul]

lemma cm_four_dvd (hF : ringChar F ≠ 2) (hneg : quadraticChar F (-1) = 1) :
    4 ∣ (univ.filter (fun x : F => quadraticChar F (x ^ 3 - x) = -1)).card := by
  set M := univ.filter (fun x : F => quadraticChar F (x ^ 3 - x) = -1) with hM
  have h2 : (2 : F) ≠ 0 := Ring.two_ne_zero hF
  have memM : ∀ x, x ∈ M ↔ quadraticChar F (x ^ 3 - x) = -1 := by
    intro x; simp [hM]
  have props : ∀ x ∈ M, x ≠ 0 ∧ x ^ 2 ≠ 1 ∧ x ^ 2 ≠ -1 := by
    intro x hx
    rw [memM] at hx
    have hg : x ^ 3 - x ≠ 0 := by intro h; rw [h] at hx; simp at hx
    refine ⟨?_, ?_, ?_⟩
    · rintro rfl; simp at hg
    · intro h; apply hg; linear_combination x * h
    · intro h
      have e : x ^ 3 - x = (1 - x) ^ 2 := by linear_combination x * h - h
      have hne : 1 - x ≠ 0 := by intro h1; apply hg; rw [e, h1]; ring
      rw [e, quadraticChar_sq_one' hne] at hx
      norm_num at hx
  set h : F → F := fun x => x ^ 2 + x⁻¹ ^ 2 with hh
  rw [card_eq_sum_card_image h M]
  rw [sum_const_nat (m := 4)]
  · exact dvd_mul_left 4 _
  intro b hb
  obtain ⟨x, hxM, rfl⟩ := mem_image.mp hb
  obtain ⟨hx0, hx1, hxi⟩ := props x hxM
  have hxM' := (memM x).mp hxM
  rw [card_eq_four]
  refine ⟨x, -x, x⁻¹, -x⁻¹, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · intro e; apply hx0; have : 2 * x = 0 := by linear_combination e
    exact (mul_eq_zero.mp this).resolve_left h2
  · intro e; apply hx1; field_simp at e; linear_combination e
  · intro e; apply hxi; field_simp at e; linear_combination e
  · intro e; apply hxi; field_simp at e; linear_combination -e
  · intro e; apply hx1; field_simp at e; linear_combination -e
  · intro e; apply hx0; have : 2 * x⁻¹ = 0 := by linear_combination e
    exact inv_eq_zero.mp ((mul_eq_zero.mp this).resolve_left h2)
  · ext a
    simp only [mem_filter, mem_insert, mem_singleton, memM, hh]
    constructor
    · rintro ⟨haM, hha⟩
      have ha0 : a ≠ 0 := by rintro rfl; simp at haM
      have key : (a - x) * (a + x) * (a * x - 1) * (a * x + 1) = 0 := by
        field_simp at hha
        linear_combination hha
      rcases mul_eq_zero.mp key with k | k
      · rcases mul_eq_zero.mp k with k | k
        · rcases mul_eq_zero.mp k with k | k
          · left; linear_combination k
          · right; left; linear_combination k
        · right; right; left; field_simp; linear_combination k
      · right; right; right; field_simp; linear_combination k
    · rintro (rfl | rfl | rfl | rfl)
      · exact ⟨hxM', rfl⟩
      · exact ⟨by rw [cm_neg_mem hneg]; exact hxM', by ring⟩
      · exact ⟨by rw [cm_inv_mem hneg x hx0]; exact hxM', by rw [inv_inv]; ring⟩
      · refine ⟨by rw [cm_neg_mem hneg, cm_inv_mem hneg x hx0]; exact hxM', ?_⟩
        rw [inv_neg, inv_inv]; ring

end CmCharSums

lemma cm_not_two_dvd_odd (x : ℤ) (h : 2 * x + 1 = 0) : False := by omega

lemma cm_int_endgame (p : ℕ) (hp : p.Prime) (a b S R : ℤ) (hab : (p : ℤ) = a ^ 2 + b ^ 2)
    (hb : Even b) (hsign : a + b ≡ 1 [ZMOD 4]) (hSR : S ^ 2 + R ^ 2 = 4 * p)
    (h8 : (8 : ℤ) ∣ S - p + 3) : S = -2 * a := by
  obtain ⟨m, hm⟩ := hb
  obtain ⟨k, hk⟩ := hsign.dvd
  obtain ⟨j, hj⟩ := h8
  obtain ⟨a', ha'⟩ : ∃ a', a' = -m - 2 * k := ⟨_, rfl⟩
  have ha : a = 2 * a' + 1 := by rw [ha']; linarith
  obtain ⟨t, ht⟩ : ∃ t, t = a' ^ 2 + a' + m ^ 2 - 1 + 2 * j := ⟨_, rfl⟩
  obtain ⟨A, hA⟩ : ∃ A, A = 2 * t + 1 := ⟨_, rfl⟩
  have hS : S = 2 * A := by
    rw [hA, ht]; rw [hab, ha, hm] at hj; linear_combination hj
  -- `R` is even
  obtain ⟨B, hB⟩ : Even R := by
    rcases Int.even_or_odd R with h | ⟨n, hn⟩
    · exact h
    · exfalso
      apply cm_not_two_dvd_odd (2 * n ^ 2 + 2 * n - 2 * p + 2 * A ^ 2)
      rw [hS, hn] at hSR; linear_combination hSR
  have hAB : (p : ℤ) = A ^ 2 + B ^ 2 := by
    rw [hS, hB] at hSR; linarith
  -- `B` is even
  obtain ⟨n, hn⟩ : Even B := by
    rcases Int.even_or_odd B with h | ⟨n, hn⟩
    · exact h
    · exfalso
      apply cm_not_two_dvd_odd
        (2 * n ^ 2 + 2 * n + 2 * t ^ 2 + 2 * t - 2 * a' ^ 2 - 2 * a' - 2 * m ^ 2)
      rw [hn, hA] at hAB; rw [hab, ha, hm] at hAB; linear_combination -hAB
  have hpZ : Prime (p : ℤ) := Nat.prime_iff_prime_int.mp hp
  have hp0 : (0 : ℤ) < p := by exact_mod_cast hp.pos
  have hprod : (a * B - b * A) * (a * B + b * A) = p * (a ^ 2 - A ^ 2) := by
    linear_combination A ^ 2 * hab - a ^ 2 * hAB
  have hid1 : (a * A + b * B) ^ 2 + (a * B - b * A) ^ 2 = (p : ℤ) ^ 2 := by
    linear_combination (-(A ^ 2 + B ^ 2)) * hab + (-(p : ℤ)) * hAB
  have hid2 : (a * A - b * B) ^ 2 + (a * B + b * A) ^ 2 = (p : ℤ) ^ 2 := by
    linear_combination (-(A ^ 2 + B ^ 2)) * hab + (-(p : ℤ)) * hAB
  have hodd1 : a * A + b * B ≠ 0 := by
    intro h; apply cm_not_two_dvd_odd (2 * a' * t + a' + t + 2 * m * n)
    rw [ha, hA, hm, hn] at h; linear_combination h
  have hodd2 : a * A - b * B ≠ 0 := by
    intro h; apply cm_not_two_dvd_odd (2 * a' * t + a' + t - 2 * m * n)
    rw [ha, hA, hm, hn] at h; linear_combination h
  -- the cross term divisible by `p` vanishes
  have small : ∀ X Y : ℤ, X ≠ 0 → X ^ 2 + Y ^ 2 = (p : ℤ) ^ 2 → (p : ℤ) ∣ Y → Y = 0 := by
    intro X Y hX hXY ⟨u, hu⟩
    rcases eq_or_ne u 0 with rfl | hu0
    · simpa using hu
    · exfalso
      have hu1 : 1 ≤ u ^ 2 := by
        have := sq_pos_of_ne_zero hu0; omega
      have hX2 : 0 < X ^ 2 := sq_pos_of_ne_zero hX
      rw [hu] at hXY
      nlinarith
  have hsq : a ^ 2 = A ^ 2 := by
    have hdvd : (p : ℤ) ∣ (a * B - b * A) * (a * B + b * A) := ⟨_, hprod⟩
    rcases hpZ.dvd_or_dvd hdvd with h | h
    · have := small _ _ hodd1 hid1 h
      rw [this, zero_mul] at hprod
      have := (mul_eq_zero.mp hprod.symm).resolve_left hp0.ne'
      linarith
    · have := small _ _ hodd2 hid2 h
      rw [this, mul_zero] at hprod
      have := (mul_eq_zero.mp hprod.symm).resolve_left hp0.ne'
      linarith
  rcases sq_eq_sq_iff_eq_or_eq_neg.mp hsq with h | h
  · exfalso
    apply cm_not_two_dvd_odd (-(m ^ 2 + 2 * m * k + 2 * k ^ 2 + j))
    rw [ha, hA, ht, ha'] at h
    linarith
  · rw [hS, h]; ring

/-- One plus the number of affine points is `p + 1 + ∑ χ(x^3 - x)`, `χ` the quadratic character. -/
lemma cm_count_eq (p : ℕ) [Fact p.Prime] (hp2 : p ≠ 2) :
    (cmCount p : ℤ) = p + 1 + ∑ x : ZMod p, quadraticChar (ZMod p) (x ^ 3 - x) := by
  have hF : ringChar (ZMod p) ≠ 2 := by rw [ZMod.ringChar_zmod_n]; exact hp2
  unfold cmCount
  push_cast
  rw [← Finset.sum_boole, Fintype.sum_prod_type]
  simp only [cm_card_sqrts hF, Finset.sum_add_distrib, Finset.sum_const, Finset.card_univ,
    ZMod.card, nsmul_eq_mul, mul_one]
  ring

open WeierstrassCurve WeierstrassCurve.Affine in
lemma cm_nonsingular {F : Type*} [Field F] (i : F) (hi : i ^ 2 = -1) {x y : F}
    (h : (cmCurve F).toAffine.Nonsingular x y) :
    (cmCurve F).toAffine.Nonsingular (-x) (i * y) := by
  rw [nonsingular_iff', equation_iff'] at h ⊢
  obtain ⟨h1, h2⟩ := h
  have hi0 : i ≠ 0 := by rintro rfl; simp at hi
  refine ⟨by linear_combination (-1 : F) * h1 + y ^ 2 * hi, ?_⟩
  rcases h2 with h2 | h2
  · left; convert h2 using 1; ring
  · right
    intro h; apply h2
    have : i * (2 * y + 0 * x + 0) = 0 := by linear_combination h
    exact (mul_eq_zero.mp this).resolve_left hi0

lemma cm_inv_i {F : Type*} [Field F] (i : F) (hi : i ^ 2 = -1) : i⁻¹ = -i :=
  inv_eq_of_mul_eq_one_right (by linear_combination -hi)

open WeierstrassCurve WeierstrassCurve.Affine in
lemma cm_slope {F : Type*} [Field F] [DecidableEq F] (i : F) (hi : i ^ 2 = -1) (x₁ x₂ y₁ y₂ : F) :
    (cmCurve F).toAffine.slope (-x₁) (-x₂) (i * y₁) (i * y₂) =
      -i * (cmCurve F).toAffine.slope x₁ x₂ y₁ y₂ := by
  have hi0 : i ≠ 0 := by rintro rfl; simp at hi
  simp only [slope, negY]
  have e1 : (-x₁ = -x₂) ↔ x₁ = x₂ := neg_inj
  have e2 : (i * y₁ = -(i * y₂) - 0 * -x₂ - 0) ↔ (y₁ = -y₂ - 0 * x₂ - 0) := by
    constructor
    · intro h; apply mul_left_cancel₀ hi0; linear_combination h
    · intro h; rw [h]; ring
  simp only [e1, e2]
  split_ifs with hx hy
  · simp
  · have : i * y₁ - (-(i * y₁) - 0 * -x₁ - 0) = (y₁ - (-y₁ - 0 * x₁ - 0)) * i := by ring
    rw [this, ← div_div, div_eq_mul_inv _ i, cm_inv_i i hi]
    ring
  · rw [show -x₁ - -x₂ = (x₁ - x₂) * (-1) by ring, show i * y₁ - i * y₂ = (y₁ - y₂) * i by ring,
      mul_div_mul_comm, div_neg, div_one]
    ring

open WeierstrassCurve WeierstrassCurve.Affine in
/-- The map `(x, y) ↦ (-x, i y)` on points, `O` going to `O`. -/
def cmMulI {F : Type*} [Field F] (i : F) (hi : i ^ 2 = -1) :
    (cmCurve F).toAffine.Point → (cmCurve F).toAffine.Point
  | .zero => .zero
  | .some _ _ h => .some _ _ (cm_nonsingular i hi h)

#print axioms cm_card_sqrts
#print axioms cm_chi_cube
#print axioms cm_chi_sq_self
#print axioms cm_sum_nonzero
#print axioms cmPhi_scale
#print axioms cmPhi_zero
#print axioms cm_sum_shift
#print axioms cm_sum_pair
#print axioms cm_inner
#print axioms cmPhi_sum_sq
#print axioms cmPhi_sq_class
#print axioms cmPhi_four_q
#print axioms cm_zeros
#print axioms cm_S_eq
#print axioms cm_inv_mem
#print axioms cm_neg_mem
#print axioms cm_four_dvd
#print axioms cm_not_two_dvd_odd
#print axioms cm_int_endgame
#print axioms cm_count_eq
#print axioms cm_nonsingular
#print axioms cm_inv_i
#print axioms cm_slope

/-- The point count read from two squares: for an odd prime `p` written as `p = a^2 + b^2`
with `b` even and the sign of `a` chosen so that `a + b` leaves 1 on division by 4, the curve
y^2 = x^3 - x has exactly `p + 1 - 2a` points mod `p`, so `a_p = 2a`. -/
theorem card_points_eq_of_two_squares (p : ℕ) [Fact p.Prime] (hp2 : p ≠ 2) (a b : ℤ)
    (hab : (p : ℤ) = a ^ 2 + b ^ 2) (hb : Even b) (hsign : a + b ≡ 1 [ZMOD 4]) :
    (cmCount p : ℤ) = p + 1 - 2 * a := by
  have hF : ringChar (ZMod p) ≠ 2 := by rw [ZMod.ringChar_zmod_n]; exact hp2
  have hcard : Fintype.card (ZMod p) = p := ZMod.card p
  -- `p` leaves 1 on division by 4, so -1 is a square mod `p`
  have hp4 : p % 4 ≠ 3 := by
    obtain ⟨m, hm⟩ := hb
    obtain ⟨k, hk⟩ := hsign.dvd
    have ha : a = 1 - 4 * k - (m + m) := by linarith
    obtain ⟨w, hw⟩ : ∃ w : ℤ, (p : ℤ) = 4 * w + 1 :=
      ⟨-m - 2 * k + 2 * m ^ 2 + 4 * m * k + 4 * k ^ 2, by rw [hab, ha, hm]; ring⟩
    omega
  obtain ⟨i, hi⟩ := ZMod.exists_sq_eq_neg_one_iff.mpr hp4
  have hi0 : i ≠ 0 := by
    rintro rfl
    rw [mul_zero] at hi
    exact one_ne_zero (neg_eq_zero.mp hi)
  have hneg : quadraticChar (ZMod p) (-1) = 1 :=
    (quadraticChar_one_iff_isSquare (neg_ne_zero.mpr one_ne_zero)).mpr ⟨i, hi⟩
  obtain ⟨r, hr⟩ := quadraticChar_exists_neg_one hF
  have hS : ∑ x : ZMod p, quadraticChar (ZMod p) (x ^ 3 - x) = cmPhi (ZMod p) (-1) := by
    unfold cmPhi
    refine Finset.sum_congr rfl fun x _ => ?_
    congr 1
    ring
  have hS2 : cmPhi (ZMod p) (-1) ^ 2 = cmPhi (ZMod p) 1 ^ 2 := by
    have := cmPhi_scale (1 : ZMod p) i hi0
    rw [one_mul, sq i, ← hi] at this
    rw [this, mul_pow, quadraticChar_sq_one hi0, one_mul]
  have h4 := cmPhi_four_q hF hneg r hr
  rw [hcard] at h4
  obtain ⟨M4, hM4⟩ := cm_four_dvd hF hneg
  have h8 : (8 : ℤ) ∣ cmPhi (ZMod p) (-1) - p + 3 := by
    refine ⟨-(M4 : ℤ), ?_⟩
    rw [← hS, cm_S_eq hF, hM4, hcard]
    push_cast
    ring
  have key := cm_int_endgame p Fact.out a b (cmPhi (ZMod p) (-1)) (cmPhi (ZMod p) r) hab hb hsign (by rw [hS2]; exact h4) h8
  rw [cm_count_eq p hp2, hS, key]
  ring

/-- The supersingular case: for a prime `p` that leaves 3 on division by 4, the curve
y^2 = x^3 - x has exactly `p + 1` points mod `p`, so `a_p = 0`. -/
theorem card_points_eq_of_three_mod_four (p : ℕ) [Fact p.Prime] (hp : p % 4 = 3) :
    cmCount p = p + 1 := by
  have hp2 : p ≠ 2 := by omega
  have hF : ringChar (ZMod p) ≠ 2 := by rw [ZMod.ringChar_zmod_n]; exact hp2
  have hneg : quadraticChar (ZMod p) (-1) = -1 :=
    quadraticChar_neg_one_iff_not_isSquare.mpr (by rw [ZMod.exists_sq_eq_neg_one_iff]; omega)
  have hsum : ∑ x : ZMod p, quadraticChar (ZMod p) (x ^ 3 - x) = 0 := by
    have e := (Equiv.neg (ZMod p)).bijective.sum_comp
      (fun x => quadraticChar (ZMod p) (x ^ 3 - x))
    have e2 : ∀ x : ZMod p, quadraticChar (ZMod p) ((Equiv.neg (ZMod p)) x ^ 3 -
        (Equiv.neg (ZMod p)) x) = -quadraticChar (ZMod p) (x ^ 3 - x) := by
      intro x
      rw [Equiv.neg_apply, show (-x) ^ 3 - -x = -1 * (x ^ 3 - x) by ring, map_mul, hneg]
      ring
    simp only [e2, Finset.sum_neg_distrib] at e
    linarith
  have h := cm_count_eq p hp2
  rw [hsum, add_zero] at h
  exact_mod_cast h

/-- Complex multiplication by `i`: over any field containing a square root `i` of -1, the map
`(x, y) ↦ (-x, i y)` sends the points of y^2 = x^3 - x to points, respects adding (it is an
additive map of the group of points, O going to O), and applying it twice negates every point. -/
theorem exists_mul_i_endomorphism (F : Type*) [Field F] [DecidableEq F] (i : F) (hi : i ^ 2 = -1) :
    ∃ φ : (cmCurve F).toAffine.Point →+ (cmCurve F).toAffine.Point,
      (∀ (x y : F) (h : (cmCurve F).toAffine.Nonsingular x y),
        ∃ h' : (cmCurve F).toAffine.Nonsingular (-x) (i * y),
          φ (WeierstrassCurve.Affine.Point.some x y h) =
            WeierstrassCurve.Affine.Point.some (-x) (i * y) h') ∧
      ∀ P, φ (φ P) = -P := by
  have hi0 : i ≠ 0 := by rintro rfl; simp at hi
  refine ⟨{ toFun := cmMulI i hi, map_zero' := rfl, map_add' := ?_ }, ?_, ?_⟩
  · rintro (_ | ⟨x₁, y₁, h₁⟩) (_ | ⟨x₂, y₂, h₂⟩)
    · rfl
    · rfl
    · rfl
    by_cases hxy : x₁ = x₂ ∧ y₁ = (cmCurve F).toAffine.negY x₂ y₂
    · have hxy' : -x₁ = -x₂ ∧ i * y₁ = (cmCurve F).toAffine.negY (-x₂) (i * y₂) := by
        refine ⟨by rw [hxy.1], ?_⟩
        rw [hxy.2]; simp only [WeierstrassCurve.Affine.negY]; ring
      show cmMulI i hi (WeierstrassCurve.Affine.Point.some _ _ h₁ + WeierstrassCurve.Affine.Point.some _ _ h₂) =
        WeierstrassCurve.Affine.Point.some _ _ (cm_nonsingular i hi h₁) + WeierstrassCurve.Affine.Point.some _ _ (cm_nonsingular i hi h₂)
      rw [WeierstrassCurve.Affine.Point.add_of_Y_eq hxy.1 hxy.2, WeierstrassCurve.Affine.Point.add_of_Y_eq hxy'.1 hxy'.2]
      rfl
    · have hxy' : ¬(-x₁ = -x₂ ∧ i * y₁ = (cmCurve F).toAffine.negY (-x₂) (i * y₂)) := by
        rintro ⟨h1, h2⟩
        apply hxy
        refine ⟨neg_inj.mp h1, ?_⟩
        apply mul_left_cancel₀ hi0
        rw [h2]; simp only [WeierstrassCurve.Affine.negY]; ring
      show cmMulI i hi (WeierstrassCurve.Affine.Point.some _ _ h₁ + WeierstrassCurve.Affine.Point.some _ _ h₂) =
        WeierstrassCurve.Affine.Point.some _ _ (cm_nonsingular i hi h₁) + WeierstrassCurve.Affine.Point.some _ _ (cm_nonsingular i hi h₂)
      rw [WeierstrassCurve.Affine.Point.add_some hxy, WeierstrassCurve.Affine.Point.add_some hxy']
      simp only [cmMulI, WeierstrassCurve.Affine.Point.some.injEq, cm_slope i hi]
      constructor
      · simp only [WeierstrassCurve.Affine.addX]; linear_combination (-(WeierstrassCurve.Affine.slope (cmCurve F).toAffine x₁ x₂ y₁ y₂) ^ 2) * hi
      · simp only [WeierstrassCurve.Affine.addY, WeierstrassCurve.Affine.negAddY, WeierstrassCurve.Affine.addX, WeierstrassCurve.Affine.negY]
        linear_combination (-i * WeierstrassCurve.Affine.slope (cmCurve F).toAffine x₁ x₂ y₁ y₂ ^ 3) * hi
  · intro x y h
    exact ⟨cm_nonsingular i hi h, rfl⟩
  · rintro (_ | ⟨x, y, h⟩)
    · rfl
    · show cmMulI i hi (cmMulI i hi (WeierstrassCurve.Affine.Point.some x y h)) = -WeierstrassCurve.Affine.Point.some x y h
      simp only [cmMulI, WeierstrassCurve.Affine.Point.neg_some, WeierstrassCurve.Affine.Point.some.injEq, WeierstrassCurve.Affine.negY]
      constructor
      · ring
      · linear_combination y * hi

-- The card's counts: a_7 = a_11 = 0 (8 and 12 points), a_13 = 6, a_17 = 2, a_29 = -10.
example : cmCount 7 = 8 := by decide
example : cmCount 11 = 12 := by decide
example : cmCount 13 = 8 := by decide
example : cmCount 17 = 16 := by decide
example : cmCount 29 = 40 := by decide

-- The two-squares data behind them: 13 = 3^2 + 2^2 with 3 + 2 = 1 mod 4, so 13 + 1 - 2 * 3 = 8;
-- 17 = 1^2 + 4^2, so 16 points; 29 = (-5)^2 + 2^2 with -5 + 2 = 1 mod 4, so 29 + 1 + 10 = 40.
example : (13 : ℤ) = 3 ^ 2 + 2 ^ 2 ∧ (3 + 2 : ℤ) ≡ 1 [ZMOD 4] ∧ 13 + 1 - 2 * 3 = (8 : ℤ) := by
  decide
example : (17 : ℤ) = 1 ^ 2 + 4 ^ 2 ∧ (1 + 4 : ℤ) ≡ 1 [ZMOD 4] ∧ 17 + 1 - 2 * 1 = (16 : ℤ) := by
  decide
example : (29 : ℤ) = (-5) ^ 2 + 2 ^ 2 ∧ (-5 + 2 : ℤ) ≡ 1 [ZMOD 4] ∧ 29 + 1 - 2 * (-5) = (40 : ℤ) := by
  decide

-- Mod 13, i = 5: 5 * 5 leaves -1, [i](5, 4) = (8, 7), and Q = (5, 9) = (i, 1 - i) is on the curve.
example : (5 : ZMod 13) ^ 2 = -1 := by decide
example : ((-5 : ZMod 13), (5 : ZMod 13) * 4) = (8, 7) := by decide
example : (9 : ZMod 13) = 1 - 5 ∧ (9 : ZMod 13) ^ 2 = 5 ^ 3 - 5 := by decide

-- The whole j-values, from j = 1728 * 4A^3 / (4A^3 + 27B^2) for y^2 = x^3 + Ax + B.
example : (1728 * 4 * (-1) ^ 3 : ℚ) / (4 * (-1) ^ 3 + 27 * 0 ^ 2) = 12 ^ 3 := by norm_num
example : (1728 * 4 * (-30) ^ 3 : ℚ) / (4 * (-30) ^ 3 + 27 * 56 ^ 2) = 20 ^ 3 := by norm_num
example : (1728 * 4 * (-11) ^ 3 : ℚ) / (4 * (-11) ^ 3 + 27 * 14 ^ 2) = 66 ^ 3 := by norm_num

#print axioms card_points_eq_of_two_squares
#print axioms card_points_eq_of_three_mod_four
#print axioms exists_mul_i_endomorphism
