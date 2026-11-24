-- Geometric programs: a posynomial with positive coefficients becomes a convex function after a log change of variables, the best crate holds 500 litres, and state prices cap Kelly growth.
import Mathlib.Analysis.MeanInequalities
import Mathlib.Analysis.Convex.SpecificFunctions.Basic

open Real

/-- A posynomial is a sum of monomials `k j * x 1 ^ α j 1 * ... * x n ^ α j n` with every
coefficient `k j` positive and any real powers. Substitute `x i = exp (u i)` and take the log:
the result, a log-sum-exp of affine functions of `u`, is convex on all of `ℝⁿ`. So a geometric
program becomes a convex problem in the log variables. -/
theorem log_posynomial_exp_convex {n : ℕ} {ι : Type*} [Fintype ι]
    (k : ι → ℝ) (α : ι → Fin n → ℝ) (hk : ∀ j, 0 < k j) :
    ConvexOn ℝ Set.univ
      (fun u : Fin n → ℝ => Real.log (∑ j, k j * ∏ i, Real.exp (u i) ^ α j i)) := by
  set g : ι → (Fin n → ℝ) → ℝ := fun j u => Real.log (k j) + ∑ i, u i * α j i with hgdef
  have hfun : (fun u : Fin n → ℝ => Real.log (∑ j, k j * ∏ i, Real.exp (u i) ^ α j i))
      = fun u => Real.log (∑ j, Real.exp (g j u)) := by
    funext u
    congr 1
    refine Finset.sum_congr rfl fun j _ => ?_
    simp only [hgdef, Real.exp_add, Real.exp_log (hk j), Real.exp_sum, ← Real.exp_mul]
  rw [hfun]
  rcases isEmpty_or_nonempty ι with hι | hι
  · simp only [Finset.univ_eq_empty, Finset.sum_empty, Real.log_zero]
    exact convexOn_const 0 convex_univ
  refine ⟨convex_univ, ?_⟩
  intro x _ y _ a b ha hb hab
  have hg : ∀ j, g j (a • x + b • y) = a * g j x + b * g j y := by
    intro j
    have hs : ∑ i, (a • x + b • y) i * α j i
        = a * ∑ i, x i * α j i + b * ∑ i, y i * α j i := by
      rw [Finset.mul_sum, Finset.mul_sum, ← Finset.sum_add_distrib]
      refine Finset.sum_congr rfl fun i _ => ?_
      simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
      ring
    simp only [hgdef]
    rw [hs]
    linear_combination (-(Real.log (k j))) * hab
  set P : ι → ℝ := fun j => Real.exp (g j x) with hP
  set Q : ι → ℝ := fun j => Real.exp (g j y) with hQ
  have hPpos : ∀ j, 0 < P j := fun j => Real.exp_pos _
  have hQpos : ∀ j, 0 < Q j := fun j => Real.exp_pos _
  set A := ∑ j, P j with hA
  set B := ∑ j, Q j with hB
  have hApos : 0 < A := Finset.sum_pos (fun j _ => hPpos j) Finset.univ_nonempty
  have hBpos : 0 < B := Finset.sum_pos (fun j _ => hQpos j) Finset.univ_nonempty
  have hterm : ∀ j, Real.exp (g j (a • x + b • y)) = P j ^ a * Q j ^ b := by
    intro j
    rw [hg j, Real.exp_add, mul_comm a, mul_comm b, Real.exp_mul, Real.exp_mul]
  have key : ∀ j, P j ^ a * Q j ^ b ≤ A ^ a * B ^ b * (a * (P j / A) + b * (Q j / B)) := by
    intro j
    have h := Real.geom_mean_le_arith_mean2_weighted ha hb
      (div_nonneg (hPpos j).le hApos.le) (div_nonneg (hQpos j).le hBpos.le) hab
    rw [Real.div_rpow (hPpos j).le hApos.le, Real.div_rpow (hQpos j).le hBpos.le] at h
    have hAa : 0 < A ^ a := Real.rpow_pos_of_pos hApos a
    have hBb : 0 < B ^ b := Real.rpow_pos_of_pos hBpos b
    calc P j ^ a * Q j ^ b = A ^ a * B ^ b * (P j ^ a / A ^ a * (Q j ^ b / B ^ b)) := by
          field_simp
      _ ≤ _ := mul_le_mul_of_nonneg_left h (by positivity)
  have hsum : ∑ j, Real.exp (g j (a • x + b • y)) ≤ A ^ a * B ^ b := by
    calc ∑ j, Real.exp (g j (a • x + b • y)) = ∑ j, P j ^ a * Q j ^ b :=
          Finset.sum_congr rfl fun j _ => hterm j
      _ ≤ ∑ j, A ^ a * B ^ b * (a * (P j / A) + b * (Q j / B)) :=
          Finset.sum_le_sum fun j _ => key j
      _ = A ^ a * B ^ b * (a * (A / A) + b * (B / B)) := by
          rw [← Finset.mul_sum, Finset.sum_add_distrib, ← Finset.mul_sum, ← Finset.mul_sum,
            ← Finset.sum_div, ← Finset.sum_div]
      _ = A ^ a * B ^ b := by
          rw [div_self hApos.ne', div_self hBpos.ne', mul_one, mul_one, hab, mul_one]
  have hlpos : 0 < ∑ j, Real.exp (g j (a • x + b • y)) :=
    Finset.sum_pos (fun j _ => Real.exp_pos _) Finset.univ_nonempty
  calc Real.log (∑ j, Real.exp (g j (a • x + b • y))) ≤ Real.log (A ^ a * B ^ b) :=
        Real.log_le_log hlpos hsum
    _ = a • Real.log A + b • Real.log B := by
        rw [Real.log_mul (Real.rpow_pos_of_pos hApos a).ne' (Real.rpow_pos_of_pos hBpos b).ne',
          Real.log_rpow hApos, Real.log_rpow hBpos, smul_eq_mul, smul_eq_mul]

/-- The crate: among all crates with positive height `h`, width `w` and depth `d` (in dm), wall
area `2 h (w + d)` at most 200 and floor area `w d` at most 100, the largest volume `h w d` is
500 litres, reached by the 10 × 10 × 5 crate. -/
theorem crate_max_volume_eq_500 :
    IsGreatest {V : ℝ | ∃ h w d : ℝ, 0 < h ∧ 0 < w ∧ 0 < d ∧
      2 * h * (w + d) ≤ 200 ∧ w * d ≤ 100 ∧ V = h * w * d} 500 := by
  refine ⟨⟨5, 10, 10, by norm_num, by norm_num, by norm_num, by norm_num, by norm_num,
    by norm_num⟩, ?_⟩
  rintro V ⟨h, w, d, hh, hw, hd, hwall, hfloor, rfl⟩
  have hs : h * (w + d) ≤ 100 := by linarith
  have hsq : 4 * (w * d) ≤ (w + d) ^ 2 := by nlinarith [sq_nonneg (w - d)]
  have hV : 0 ≤ h * w * d := by positivity
  have h1 : (h * w * d) ^ 2 * 4 ≤ (w * d) * (h * (w + d)) ^ 2 := by
    have : (h * w * d) ^ 2 * 4 = h ^ 2 * (w * d) * (4 * (w * d)) := by ring
    rw [this]
    have : (w * d) * (h * (w + d)) ^ 2 = h ^ 2 * (w * d) * (w + d) ^ 2 := by ring
    rw [this]
    exact mul_le_mul_of_nonneg_left hsq (by positivity)
  have h2 : (h * (w + d)) ^ 2 ≤ 100 ^ 2 := by
    have : 0 ≤ h * (w + d) := by positivity
    nlinarith
  have h3 : (w * d) * (h * (w + d)) ^ 2 ≤ 100 * 100 ^ 2 := by
    have : 0 ≤ w * d := by positivity
    have : 0 ≤ (h * (w + d)) ^ 2 := by positivity
    nlinarith
  nlinarith

/-- State prices cap Kelly growth: take scenario probabilities `p s` (at least 0, adding to 1),
positive wealth multipliers `R s i` for asset `i` in scenario `s`, and positive prices `y s` with
`∑ s, y s * R s i ≤ 1` for every asset. Then every long-only mix `x` (shares at least 0, adding
to 1) has growth `∑ s, p s * log W s`, where `W s = ∑ i, R s i * x i`, at most
`∑ s, p s * log (p s / y s)`. -/
theorem kelly_growth_le_state_price_bound {S A : Type*} [Fintype S] [Fintype A]
    (p y : S → ℝ) (R : S → A → ℝ) (x : A → ℝ)
    (hp : ∀ s, 0 ≤ p s) (hp1 : ∑ s, p s = 1) (hR : ∀ s i, 0 < R s i)
    (hy : ∀ s, 0 < y s) (hprice : ∀ i, ∑ s, y s * R s i ≤ 1)
    (hx : ∀ i, 0 ≤ x i) (hx1 : ∑ i, x i = 1) :
    ∑ s, p s * Real.log (∑ i, R s i * x i) ≤ ∑ s, p s * Real.log (p s / y s) := by
  obtain ⟨i0, hi0⟩ : ∃ i, 0 < x i := by
    by_contra hcon
    push Not at hcon
    have : ∑ i, x i ≤ 0 := Finset.sum_nonpos fun i _ => hcon i
    linarith
  have hW : ∀ s, 0 < ∑ i, R s i * x i := fun s =>
    Finset.sum_pos' (fun i _ => mul_nonneg (hR s i).le (hx i))
      ⟨i0, Finset.mem_univ _, mul_pos (hR s i0) hi0⟩
  have hterm : ∀ s, p s * Real.log (∑ i, R s i * x i) - p s * Real.log (p s / y s)
      ≤ y s * (∑ i, R s i * x i) - p s := by
    intro s
    rcases (hp s).lt_or_eq with hps | hps
    · have hlog : Real.log (∑ i, R s i * x i) - Real.log (p s / y s)
          = Real.log (y s * (∑ i, R s i * x i) / p s) := by
        rw [Real.log_div (mul_pos (hy s) (hW s)).ne' hps.ne', Real.log_mul (hy s).ne' (hW s).ne',
          Real.log_div hps.ne' (hy s).ne']
        ring
      have hle := Real.log_le_sub_one_of_pos (div_pos (mul_pos (hy s) (hW s)) hps)
      have : p s * (Real.log (∑ i, R s i * x i) - Real.log (p s / y s))
          ≤ p s * (y s * (∑ i, R s i * x i) / p s - 1) := by
        rw [hlog]; exact mul_le_mul_of_nonneg_left hle hps.le
      have hpe : p s * (y s * (∑ i, R s i * x i) / p s - 1) = y s * (∑ i, R s i * x i) - p s := by
        field_simp
      linarith
    · rw [← hps]
      simp only [zero_mul, sub_zero]
      exact (mul_pos (hy s) (hW s)).le
  have hswap : ∑ s, y s * (∑ i, R s i * x i) = ∑ i, x i * ∑ s, y s * R s i := by
    simp only [Finset.mul_sum]
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun s _ => ?_
    ring
  have hle1 : ∑ i, x i * ∑ s, y s * R s i ≤ 1 := by
    calc ∑ i, x i * ∑ s, y s * R s i ≤ ∑ i, x i * 1 :=
          Finset.sum_le_sum fun i _ => mul_le_mul_of_nonneg_left (hprice i) (hx i)
      _ = 1 := by simp [hx1]
  have htot := Finset.sum_le_sum fun s (_ : s ∈ Finset.univ) => hterm s
  rw [Finset.sum_sub_distrib, Finset.sum_sub_distrib, hswap, hp1] at htot
  linarith

-- The best crate 10 × 10 × 5 uses all 200 dm² of wall and all 100 dm² of floor, and holds 500 L.
example : (2 : ℚ) * 5 * (10 + 10) = 200 ∧ (10 : ℚ) * 10 = 100 ∧ (5 : ℚ) * 10 * 10 = 500 := by
  norm_num

-- Crates A (2 × 2 × 25) and B (10 × 10 × 5) both use 200 dm² of wall; their plain mix
-- 6 × 6 × 15 needs 360 dm², more than the plywood allows.
example : (2 : ℚ) * 25 * (2 + 2) = 200 ∧ (2 : ℚ) * 5 * (10 + 10) = 200 ∧
    (2 : ℚ) * 15 * (6 + 6) = 360 ∧ (200 : ℚ) < 360 := by
  norm_num

-- Multipliers in logs: λ₁ = 1 and λ₂ = 1/2 with softmax weights 1/2, 1/2 make all three
-- stationarity rows zero.
example : (-1 : ℚ) + 1 * 1 + (1 / 2) * 0 = 0 ∧ (-1 : ℚ) + 1 * (1 / 2) + (1 / 2) * 1 = 0 := by
  norm_num

-- Drop the floor limit: a square floor of side 20 or 40 with height 50 / side uses all the wall
-- and holds 1,000 or 2,000 litres.
example : (2 : ℚ) * (50 / 20) * (20 + 20) = 200 ∧ (50 / 20 : ℚ) * 20 * 20 = 1000 ∧
    (2 : ℚ) * (50 / 40) * (40 + 40) = 200 ∧ (50 / 40 : ℚ) * 40 * 40 = 2000 := by
  norm_num

#print axioms log_posynomial_exp_convex
#print axioms crate_max_volume_eq_500
#print axioms kelly_growth_le_state_price_bound
