-- Yield from price: when every payment is positive and the quoted price is positive, exactly one yield above -100 percent reprices the stream to that quote, a price gap converts into a yield bound, and the quarry's out-in-out stream has two yields.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Topology.Algebra.Order.Field
import Mathlib.Algebra.BigOperators.Field

open Finset

theorem yfp_inv_pow_gap (t : ℕ) (u v B : ℝ) (hv : 0 < v) (hvu : v ≤ u) (huB : u ≤ B) :
    (t : ℝ) * (u - v) / B ^ (t + 1) ≤ 1 / v ^ t - 1 / u ^ t := by
  have hu : 0 < u := lt_of_lt_of_le hv hvu
  have hB : 0 < B := lt_of_lt_of_le hu huB
  induction t with
  | zero => simp
  | succ t ih =>
    have huv : 0 ≤ u - v := sub_nonneg.mpr hvu
    have hsplit : 1 / v ^ (t + 1) - 1 / u ^ (t + 1) =
        (1 / v) * (1 / v ^ t - 1 / u ^ t) + (u - v) / (u ^ (t + 1) * v) := by
      field_simp
      ring
    have h1 : (t : ℝ) * (u - v) / B ^ (t + 2) ≤ (1 / v) * (1 / v ^ t - 1 / u ^ t) := by
      have hnn : 0 ≤ (t : ℝ) * (u - v) / B ^ (t + 1) := by positivity
      calc (t : ℝ) * (u - v) / B ^ (t + 2) = (1 / B) * ((t : ℝ) * (u - v) / B ^ (t + 1)) := by
            field_simp; ring
        _ ≤ (1 / v) * ((t : ℝ) * (u - v) / B ^ (t + 1)) := by
            apply mul_le_mul_of_nonneg_right _ hnn
            exact one_div_le_one_div_of_le hv (le_trans hvu huB)
        _ ≤ (1 / v) * (1 / v ^ t - 1 / u ^ t) := by
            apply mul_le_mul_of_nonneg_left ih (by positivity)
    have h2 : (u - v) / B ^ (t + 2) ≤ (u - v) / (u ^ (t + 1) * v) := by
      apply div_le_div_of_nonneg_left huv (by positivity)
      calc u ^ (t + 1) * v ≤ B ^ (t + 1) * B := by
            apply mul_le_mul (pow_le_pow_left₀ hu.le huB _) (le_trans hvu huB) hv.le (by positivity)
        _ = B ^ (t + 2) := by ring
    rw [hsplit]
    have : ((t + 1 : ℕ) : ℝ) * (u - v) / B ^ (t + 1 + 1) =
        (t : ℝ) * (u - v) / B ^ (t + 2) + (u - v) / B ^ (t + 2) := by
      push_cast; ring
    rw [this]
    linarith

theorem yfp_slowest_fall_pos (N : ℕ) (hN : 1 ≤ N) (c : ℕ → ℝ)
    (hc : ∀ t ∈ Icc 1 N, 0 < c t) (B : ℝ) (hB : 0 < B) :
    0 < ∑ t ∈ Icc 1 N, (t : ℝ) * c t / B ^ (t + 1) := by
  apply Finset.sum_pos
  · intro t ht
    have ht1 : 1 ≤ t := (Finset.mem_Icc.mp ht).1
    have htpos : (0 : ℝ) < t := by exact_mod_cast ht1
    have := hc t ht
    positivity
  · exact ⟨1, Finset.mem_Icc.mpr ⟨le_refl 1, hN⟩⟩

theorem yfp_price_gap (N : ℕ) (c : ℕ → ℝ) (hc : ∀ t ∈ Icc 1 N, 0 < c t) (u v B : ℝ)
    (hv : 0 < v) (hvu : v ≤ u) (huB : u ≤ B) :
    (u - v) * ∑ t ∈ Icc 1 N, (t : ℝ) * c t / B ^ (t + 1) ≤
      ∑ t ∈ Icc 1 N, c t / v ^ t - ∑ t ∈ Icc 1 N, c t / u ^ t := by
  rw [Finset.mul_sum, ← Finset.sum_sub_distrib]
  apply Finset.sum_le_sum
  intro t ht
  have hk := yfp_inv_pow_gap t u v B hv hvu huB
  have hct := (hc t ht).le
  calc (u - v) * ((t : ℝ) * c t / B ^ (t + 1)) = c t * ((t : ℝ) * (u - v) / B ^ (t + 1)) := by
        ring
    _ ≤ c t * (1 / v ^ t - 1 / u ^ t) := mul_le_mul_of_nonneg_left hk hct
    _ = c t / v ^ t - c t / u ^ t := by ring


#print axioms yfp_inv_pow_gap
#print axioms yfp_slowest_fall_pos
#print axioms yfp_price_gap

/-! The price machine: payments `c t` fall due in years `t = 1, …, N`, and at a yield `y`
the price is `P(y) = ∑_{t=1}^{N} c t / (1 + y)^t`. Rates are taken above `-1`, so that
the growth factor `1 + y` is positive. The yield for a quoted price `p` is a `y` with `P(y) = p`. -/

/-- Existence and uniqueness of the yield: if the stream has at least one payment, every
payment is positive and the quoted price `p` is positive, then exactly one rate `y` above
`-1` makes the discounted payments add up to `p`. -/
theorem yield_exists_unique_of_positive_payments (N : ℕ) (hN : 1 ≤ N) (c : ℕ → ℝ)
    (hc : ∀ t ∈ Icc 1 N, 0 < c t) (p : ℝ) (hp : 0 < p) :
    ∃! y : ℝ, -1 < y ∧ ∑ t ∈ Icc 1 N, c t / (1 + y) ^ t = p := by
  have hc1 : 0 < c 1 := hc 1 (Finset.mem_Icc.mpr ⟨le_refl 1, hN⟩)
  set f : ℝ → ℝ := fun y => ∑ t ∈ Icc 1 N, c t / (1 + y) ^ t with hf
  set S : ℝ := ∑ t ∈ Icc 1 N, c t with hS
  have hSpos : 0 < S := Finset.sum_pos (fun t ht => hc t ht)
    ⟨1, Finset.mem_Icc.mpr ⟨le_refl 1, hN⟩⟩
  set a : ℝ := c 1 / p - 1 with ha
  set b : ℝ := max 1 (S / p) - 1 with hb
  have ha1 : -1 < a := by
    have : 0 < c 1 / p := div_pos hc1 hp
    rw [ha]; linarith
  have hb1 : 1 ≤ 1 + b := by rw [hb]; simp
  have hb1' : -1 < b := by linarith
  have hfa : p ≤ f a := by
    have h1 : c 1 / (1 + a) ^ 1 ≤ f a := by
      apply Finset.single_le_sum (f := fun t => c t / (1 + a) ^ t)
      · intro t ht
        have := hc t ht
        have : 0 < 1 + a := by linarith
        positivity
      · exact Finset.mem_Icc.mpr ⟨le_refl 1, hN⟩
    have h2 : c 1 / (1 + a) ^ 1 = p := by
      rw [pow_one, ha, show 1 + (c 1 / p - 1) = c 1 / p by ring]
      field_simp
    linarith
  have hfb : f b ≤ p := by
    have h1 : f b ≤ ∑ t ∈ Icc 1 N, c t / (1 + b) := by
      apply Finset.sum_le_sum
      intro t ht
      have ht1 : 1 ≤ t := (Finset.mem_Icc.mp ht).1
      apply div_le_div_of_nonneg_left (hc t ht).le (by linarith)
      exact le_self_pow₀ hb1 (by omega)
    have h2 : ∑ t ∈ Icc 1 N, c t / (1 + b) = S / (1 + b) := by
      rw [hS, Finset.sum_div]
    have h3 : S / (1 + b) ≤ p := by
      rw [div_le_iff₀ (by linarith)]
      have : S / p ≤ 1 + b := by rw [hb]; simp
      rw [div_le_iff₀ hp] at this
      linarith
    linarith
  have hsub : ∀ x ∈ Set.uIcc a b, -1 < x := by
    intro x hx
    rcases Set.mem_uIcc.mp hx with h | h <;> linarith [h.1]
  have hcont : ContinuousOn f (Set.uIcc a b) := by
    rw [hf]
    apply continuousOn_finsetSum
    intro t _
    apply ContinuousOn.div continuousOn_const
    · exact (continuousOn_const.add continuousOn_id).pow t
    · intro x hx
      have := hsub x hx
      apply pow_ne_zero
      linarith
  have hmem : p ∈ Set.uIcc (f a) (f b) := Set.mem_uIcc.mpr (Or.inr ⟨hfb, hfa⟩)
  obtain ⟨y, hy, hfy⟩ := intermediate_value_uIcc hcont hmem
  have hy1 := hsub y hy
  refine ⟨y, ⟨hy1, hfy⟩, ?_⟩
  rintro y' ⟨hy1', hfy'⟩
  have strict : ∀ y₁ y₂ : ℝ, -1 < y₁ → y₁ < y₂ → f y₂ < f y₁ := by
    intro y₁ y₂ h1 h12
    have hg := yfp_price_gap N c hc (1 + y₂) (1 + y₁) (1 + y₂) (by linarith) (by linarith)
      (le_refl _)
    have hm := yfp_slowest_fall_pos N hN c hc (1 + y₂) (by linarith)
    have hpos : 0 < ((1 + y₂) - (1 + y₁)) * ∑ t ∈ Icc 1 N, (t : ℝ) * c t / (1 + y₂) ^ (t + 1) :=
      mul_pos (by linarith) hm
    have : f y₁ - f y₂ > 0 := by
      simp only [hf]
      linarith
    linarith
  rcases lt_trichotomy y' y with h | h | h
  · have := strict y' y hy1' h
    simp only [hf] at this hfy
    linarith
  · exact h
  · have := strict y y' hy1 h
    simp only [hf] at this hfy
    linarith

/-- The stopping rule: with positive payments, take a bracket `[a, b]` of rates above `-1`
holding both a guess `y` and the true yield `y⋆` (where the price equals the quote `p`).
Then the yield still missing is at most the price still missing divided by
`m = ∑ t * c t / (1 + b)^(t+1)`, the slowest the price falls anywhere in the bracket. -/
theorem yield_error_le_price_residual_div_slowest_fall (N : ℕ) (hN : 1 ≤ N) (c : ℕ → ℝ)
    (hc : ∀ t ∈ Icc 1 N, 0 < c t) (a b y ystar p : ℝ) (ha : -1 < a)
    (hy : y ∈ Set.Icc a b) (hystar : ystar ∈ Set.Icc a b)
    (hroot : ∑ t ∈ Icc 1 N, c t / (1 + ystar) ^ t = p) :
    |y - ystar| ≤
      |∑ t ∈ Icc 1 N, c t / (1 + y) ^ t - p| /
        ∑ t ∈ Icc 1 N, (t : ℝ) * c t / (1 + b) ^ (t + 1) := by
  have hy1 : -1 < y := lt_of_lt_of_le ha hy.1
  have hys1 : -1 < ystar := lt_of_lt_of_le ha hystar.1
  have hB : 0 < 1 + b := by linarith [hy.2]
  have hm := yfp_slowest_fall_pos N hN c hc (1 + b) hB
  rw [le_div_iff₀ hm]
  rcases le_total y ystar with h | h
  · have hg := yfp_price_gap N c hc (1 + ystar) (1 + y) (1 + b) (by linarith) (by linarith)
      (by linarith [hystar.2])
    rw [hroot] at hg
    have e : (1 + ystar) - (1 + y) = |y - ystar| := by
      rw [abs_of_nonpos (by linarith)]; ring
    rw [e] at hg
    exact le_trans hg (le_abs_self _)
  · have hg := yfp_price_gap N c hc (1 + y) (1 + ystar) (1 + b) (by linarith) (by linarith)
      (by linarith [hy.2])
    rw [hroot] at hg
    have e : (1 + y) - (1 + ystar) = |y - ystar| := by
      rw [abs_of_nonneg (by linarith)]; ring
    rw [e] at hg
    refine le_trans hg ?_
    rw [abs_sub_comm]
    exact le_abs_self _

/-- Two sign changes can give two yields: the quarry pays 1000 today, receives 3000 in a
year and pays 2000 at the end of the second year. Among rates above `-1`, its value today
is zero at exactly two yields, 0 percent and 100 percent. -/
theorem quarry_has_exactly_two_yields :
    {y : ℝ | -1 < y ∧ -1000 + 3000 / (1 + y) - 2000 / (1 + y) ^ 2 = 0} = {0, 1} := by
  ext y
  simp only [Set.mem_ofPred_eq, Set.mem_insert_iff, Set.mem_singleton_iff]
  constructor
  · rintro ⟨hy, h⟩
    have hz : (1 + y) ≠ 0 := by
      have : 0 < 1 + y := by linarith
      exact this.ne'
    have key : (-1000 + 3000 / (1 + y) - 2000 / (1 + y) ^ 2) * (1 + y) ^ 2 =
        -1000 * (1 + y) ^ 2 + 3000 * (1 + y) - 2000 := by
      field_simp
    rw [h, zero_mul] at key
    have hprod : y * (y - 1) = 0 := by linear_combination (1 / 1000 : ℝ) * key
    rcases mul_eq_zero.mp hprod with h0 | h0
    · left; exact h0
    · right; linarith
  · rintro (rfl | rfl) <;> norm_num

/-! The card's exact worked numbers for the house bond: face 1000, a 60 coupon each year
for five years, so the payments are 60, 60, 60, 60, 1060. -/

-- At a rate of nothing at all the price is the cash added up: 1300.
example : ((60 : ℚ) + 60 + 60 + 60 + 1060) = 1300 := by norm_num
-- At 100 percent the price is 30 + 15 + 7.50 + 3.75 + 33.125 = 89.375 = 715/8.
example : (60 : ℚ) / 2 + 60 / 2 ^ 2 + 60 / 2 ^ 3 + 60 / 2 ^ 4 + 1060 / 2 ^ 5 = 715 / 8 := by
  norm_num
-- At a yield of exactly 1/20 the price is the whole-number fraction 4260921200 / 4084101.
example : (60 : ℚ) / (21 / 20) + 60 / (21 / 20) ^ 2 + 60 / (21 / 20) ^ 3 + 60 / (21 / 20) ^ 4 +
    1060 / (21 / 20) ^ 5 = 4260921200 / 4084101 := by norm_num
-- At the 6 percent coupon rate the bond prices at its face, 1000.
example : (60 : ℚ) / (106 / 100) + 60 / (106 / 100) ^ 2 + 60 / (106 / 100) ^ 3 +
    60 / (106 / 100) ^ 4 + 1060 / (106 / 100) ^ 5 = 1000 := by norm_num

/-! The quarry's whole-number algebra: with `z = 1 + y`, break-even at a cost `C` is
`C z^2 - 3000 z + 2000 = 0`, and the number under the root sign is `3000^2 - 4 * C * 2000`. -/

-- The quarry's value at a rate of nothing at all: -1000 + 3000 - 2000 = 0.
example : (-1000 : ℤ) + 3000 - 2000 = 0 := by norm_num
-- Bought for 1000: the number under the root sign is 1000000 = 1000^2, a perfect square.
example : (3000 : ℤ) ^ 2 - 4 * 1000 * 2000 = 1000 ^ 2 := by norm_num
-- The two growth factors (3000 ∓ 1000) / 2000 are 1 and 2, the yields 0 and 100 percent.
example : ((3000 : ℚ) - 1000) / (2 * 1000) = 1 ∧ ((3000 : ℚ) + 1000) / (2 * 1000) = 2 := by
  norm_num
-- Bought for 1125: the number under the root sign is 0, one yield, z = 3000 / 2250 = 4/3.
example : (3000 : ℤ) ^ 2 - 4 * 1125 * 2000 = 0 ∧ (3000 : ℚ) / (2 * 1125) = 4 / 3 := by norm_num
-- Bought for 1200: the number under the root sign is -600000, so no yield exists.
example : (3000 : ℤ) ^ 2 - 4 * 1200 * 2000 = -600000 := by norm_num

#print axioms yield_exists_unique_of_positive_payments
#print axioms yield_error_le_price_residual_div_slowest_fall
#print axioms quarry_has_exactly_two_yields
