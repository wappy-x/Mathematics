-- Interior point methods: an exact minimiser of the log-barrier objective of a convex problem is within m/t of the best plan, and the card's pump problem has best plan (50, 50, 50) drawing 250 kW.
import Mathlib.Analysis.Convex.Function
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.LinearAlgebra.AffineSpace.AffineMap
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.Archimedean.Real.Basic

open Finset

/-- The barrier method's gap bound. Take a convex problem: a convex cost `f₀`, `m` convex limits
`f i x ≤ 0`, and affine rules `h x = 0`. Fix a weight `t > 0`. Suppose `xs` is strictly inside
(every slack `-f i xs` is positive, `h xs = 0`) and minimises the barrier objective
`t f₀(x) - ∑ log(-f i x)` over every strictly inside plan that obeys the rules (the centring is
done exactly). Then `xs` is within `m / t` of the best: `f₀ xs - f₀ x ≤ m / t` for every allowed
plan `x`. -/
theorem central_path_gap_le_m_div_t
    {E F : Type*} [AddCommGroup E] [Module ℝ E] [AddCommGroup F] [Module ℝ F]
    {m : ℕ} (f₀ : E → ℝ) (f : Fin m → E → ℝ) (h : E →ᵃ[ℝ] F) {t : ℝ} (ht : 0 < t)
    (hf₀ : ConvexOn ℝ Set.univ f₀) (hf : ∀ i, ConvexOn ℝ Set.univ (f i))
    (xs : E) (hxs_rule : h xs = 0) (hxs_inside : ∀ i, f i xs < 0)
    (hxs_min : ∀ y : E, h y = 0 → (∀ i, f i y < 0) →
      t * f₀ xs - ∑ i, Real.log (-f i xs) ≤ t * f₀ y - ∑ i, Real.log (-f i y)) :
    ∀ x : E, h x = 0 → (∀ i, f i x ≤ 0) → f₀ xs - f₀ x ≤ (m : ℝ) / t := by
  intro x hx hxle
  set D := f₀ xs - f₀ x with hD
  -- key bound: for every s ∈ (0,1), t * D * (1 - s) ≤ m
  have key : ∀ s : ℝ, 0 < s → s < 1 → t * D * (1 - s) ≤ m := by
    intro s hs0 hs1
    have h1s : 0 < 1 - s := by linarith
    set y : E := (1 - s) • xs + s • x with hy
    have hyl : y = AffineMap.lineMap xs x s := by
      rw [AffineMap.lineMap_apply_module]
    have hhy : h y = 0 := by
      rw [hyl, AffineMap.apply_lineMap, hxs_rule, hx, AffineMap.lineMap_same_apply]
    have hfy : ∀ i, f i y ≤ (1 - s) * f i xs + s * f i x := by
      intro i
      have := (hf i).2 (Set.mem_univ xs) (Set.mem_univ x) h1s.le hs0.le (by ring)
      simpa [smul_eq_mul] using this
    have hfy' : ∀ i, (1 - s) * (-f i xs) ≤ -f i y := by
      intro i
      have := hfy i
      have := hxle i
      nlinarith
    have hinside : ∀ i, f i y < 0 := by
      intro i
      have := hfy' i
      have := mul_pos h1s (neg_pos.mpr (hxs_inside i))
      linarith
    have hf0y : f₀ y ≤ (1 - s) * f₀ xs + s * f₀ x := by
      have := hf₀.2 (Set.mem_univ xs) (Set.mem_univ x) h1s.le hs0.le (by ring)
      simpa [smul_eq_mul] using this
    have hlog : ∀ i, Real.log (1 - s) + Real.log (-f i xs) ≤ Real.log (-f i y) := by
      intro i
      have hp : 0 < -f i xs := neg_pos.mpr (hxs_inside i)
      rw [← Real.log_mul h1s.ne' hp.ne']
      exact Real.log_le_log (mul_pos h1s hp) (hfy' i)
    have hsum : ∑ i, (Real.log (1 - s) + Real.log (-f i xs)) ≤ ∑ i, Real.log (-f i y) :=
      Finset.sum_le_sum (fun i _ => hlog i)
    rw [Finset.sum_add_distrib] at hsum
    simp only [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul] at hsum
    have hmin := hxs_min y hhy hinside
    -- t s D ≤ - m log(1-s)
    have hA : t * s * D ≤ -(m : ℝ) * Real.log (1 - s) := by
      have := mul_le_mul_of_nonneg_left hf0y ht.le
      rw [hD]; nlinarith
    -- -log(1-s) ≤ s/(1-s)
    have hL : -Real.log (1 - s) ≤ s / (1 - s) := by
      have := Real.log_le_sub_one_of_pos (inv_pos.mpr h1s)
      rw [Real.log_inv] at this
      have e : (1 - s)⁻¹ - 1 = s / (1 - s) := by field_simp; ring
      linarith
    have hm : (0 : ℝ) ≤ m := Nat.cast_nonneg m
    have hB : t * s * D ≤ (m : ℝ) * (s / (1 - s)) := by
      have := mul_le_mul_of_nonneg_left hL hm
      linarith
    have hC : t * s * D * (1 - s) ≤ (m : ℝ) * s := by
      have := mul_le_mul_of_nonneg_right hB h1s.le
      rw [mul_assoc (m : ℝ), div_mul_cancel₀ _ h1s.ne'] at this
      exact this
    have : s * (t * D * (1 - s)) ≤ s * m := by nlinarith
    exact le_of_mul_le_mul_left this hs0
  rw [le_div_iff₀ ht]
  by_contra hcon
  push Not at hcon
  have hm : (0 : ℝ) ≤ m := Nat.cast_nonneg m
  have hpos : 0 < t * D := by nlinarith
  set s := (t * D - m) / (2 * (t * D)) with hs
  have hs0 : 0 < s := div_pos (by nlinarith) (by linarith)
  have hs1 : s < 1 := by
    rw [hs, div_lt_one (by linarith)]; linarith
  have := key s hs0 hs1
  have e : t * D * (1 - s) = (t * D + m) / 2 := by
    have hD0 : D ≠ 0 := by rintro hz; rw [hz, mul_zero] at hpos; exact lt_irrefl _ hpos
    have ht0 : t ≠ 0 := ht.ne'
    rw [hs]; field_simp; ring
  rw [e] at this
  linarith

/-- The card's pump problem. Minimise the power `0.02 x₁² + 0.03 x₂² + 0.05 x₃²` kW over flows
with `x₁ + x₂ + x₃ = 150` L/s, head `0.1 x₁ + 0.2 x₂ + 0.4 x₃` between 35 m and 45 m, and every
flow at least 0. The plan (50, 50, 50) is allowed, draws 250 kW and puts the hill tank exactly on
its 35 m floor, and no allowed plan draws less than 250 kW. -/
theorem pump_best_plan_is_fifty_each :
    (let x₁ : ℝ := 50; let x₂ : ℝ := 50; let x₃ : ℝ := 50
      x₁ + x₂ + x₃ = 150 ∧ 0 ≤ x₁ ∧ 0 ≤ x₂ ∧ 0 ≤ x₃ ∧
      (1/10) * x₁ + (2/10) * x₂ + (4/10) * x₃ = 35 ∧
      (2/100) * x₁ ^ 2 + (3/100) * x₂ ^ 2 + (5/100) * x₃ ^ 2 = 250) ∧
    ∀ x₁ x₂ x₃ : ℝ, x₁ + x₂ + x₃ = 150 → 0 ≤ x₁ → 0 ≤ x₂ → 0 ≤ x₃ →
      35 ≤ (1/10) * x₁ + (2/10) * x₂ + (4/10) * x₃ →
      (1/10) * x₁ + (2/10) * x₂ + (4/10) * x₃ ≤ 45 →
      250 ≤ (2/100) * x₁ ^ 2 + (3/100) * x₂ ^ 2 + (5/100) * x₃ ^ 2 := by
  refine ⟨by norm_num, ?_⟩
  intro x₁ x₂ x₃ hsum _ _ _ hlo _
  nlinarith [sq_nonneg (x₁ - 50), sq_nonneg (x₂ - 50), sq_nonneg (x₃ - 50)]

-- The start (40, 50, 60) L/s: head 38 m, power 287 kW, slacks 3, 7, 40, 50, 60.
example : (1/10 : ℚ) * 40 + (2/10) * 50 + (4/10) * 60 = 38 := by norm_num
example : (2/100 : ℚ) * 40 ^ 2 + (3/100) * 50 ^ 2 + (5/100) * 60 ^ 2 = 287 := by norm_num
example : (38 : ℚ) - 35 = 3 ∧ (45 : ℚ) - 38 = 7 := by norm_num

-- 250 kW at £0.20 per kWh is £50 an hour.
example : (250 : ℚ) * (20/100) = 50 := by norm_num

-- The gap m / t with m = 5: 5 kW at t = 1; at t = 10^4 it is still above ε = 10^-4 kW,
-- and at t = 10^5 (the sixth stop) it is below, so six rounds are needed and enough.
example : (5 : ℚ) / 1 = 5 := by norm_num
example : (1 : ℚ) / 10000 < 5 / 10 ^ 4 ∧ (5 : ℚ) / 10 ^ 5 ≤ 1 / 10000 := by norm_num

-- Starting outside at (70, 50, 30) L/s: head 29 m, so the floor's slack is -6.
example : (1/10 : ℚ) * 70 + (2/10) * 50 + (4/10) * 30 = 29 ∧ (29 : ℚ) - 35 = -6 := by norm_num

-- The round count: 1 + ⌈log(m / (t₀ ε)) / log 10⌉ = 6 for m = 5, t₀ = 1, ε = 10⁻⁴.
example : (1 : ℤ) + ⌈Real.log (5 / (1 * (1 / 10000 : ℝ))) / Real.log 10⌉ = 6 := by
  have h10 : 0 < Real.log 10 := Real.log_pos (by norm_num)
  have e : (5 / (1 * (1 / 10000 : ℝ))) = 50000 := by norm_num
  rw [e]
  have hc : ⌈Real.log 50000 / Real.log 10⌉ = 5 := by
    rw [Int.ceil_eq_iff]
    constructor
    · rw [lt_div_iff₀ h10]
      have : Real.log ((10 : ℝ) ^ 4) < Real.log 50000 :=
        Real.log_lt_log (by norm_num) (by norm_num)
      rw [Real.log_pow] at this
      push_cast at this ⊢
      linarith
    · rw [div_le_iff₀ h10]
      have : Real.log 50000 ≤ Real.log ((10 : ℝ) ^ 5) :=
        Real.log_le_log (by norm_num) (by norm_num)
      rw [Real.log_pow] at this
      push_cast at this ⊢
      linarith
  rw [hc]; norm_num

#print axioms central_path_gap_le_m_div_t
#print axioms pump_best_plan_is_fifty_each
