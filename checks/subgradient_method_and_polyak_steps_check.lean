-- The subgradient method: for a convex function with subgradients no longer than G and a start within R of a minimiser, the best of the first K points of the subgradient method is within R G / sqrt K of the minimum, both with the fixed-horizon step and with Polyak's step, by way of the one-step distance inequality.
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.Convex.Function
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Order.Filter.Extr
import Mathlib.Data.Finset.Lattice.Fold

open scoped RealInnerProductSpace

/-! The card's notation.
* `E` is the space of choices, with inner product `⟪u, v⟫` (the card's `u · v`) and length `‖u‖`.
* `f` is the convex cost, minimised; `xstar` is a minimiser `x*`, so `f xstar` is `f(x*)`.
* `x k` is the point after `k` steps, `x 0` the start; `g k` is the subgradient used there.
* Mathlib has no subgradient, so `g k ∈ ∂f(x k)` is written out as the card defines it: the
  line with slope `g k` through `(x k, f (x k))` stays on or below the graph,
  `f (x k) + ⟪g k, y - x k⟫ ≤ f y` for every `y`.
* The best of the first `K` points, `min_{0 ≤ k < K} f(x_k)`, is
  `(Finset.range K).inf' _ (fun k => f (x k))`. -/

/-- Expanding the square of one subgradient step. -/
theorem subgradient_aux_step_expand
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (x g xstar : E) (α : ℝ) :
    ‖(x - α • g) - xstar‖ ^ 2
      = ‖x - xstar‖ ^ 2 - 2 * α * ⟪g, x - xstar⟫ + α ^ 2 * ‖g‖ ^ 2 := by
  rw [sub_right_comm, norm_sub_sq_real, real_inner_smul_right, norm_smul, real_inner_comm,
    mul_pow, Real.norm_eq_abs, sq_abs]
  ring

/-- One step with a nonnegative size, before bounding `‖g‖`. -/
theorem subgradient_aux_step_le
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (f : E → ℝ) (xstar x g : E) (α : ℝ) (hα : 0 ≤ α)
    (hsub : ∀ y, f x + ⟪g, y - x⟫ ≤ f y) :
    ‖(x - α • g) - xstar‖ ^ 2
      ≤ ‖x - xstar‖ ^ 2 - 2 * α * (f x - f xstar) + α ^ 2 * ‖g‖ ^ 2 := by
  rw [subgradient_aux_step_expand]
  have h1 := hsub xstar
  have h2 : ⟪g, xstar - x⟫ = -⟪g, x - xstar⟫ := by
    rw [← inner_neg_right, neg_sub]
  rw [h2] at h1
  nlinarith

/-- The minimum over the first `K` points is below each of them and at least `f xstar`. -/
theorem subgradient_aux_inf_bounds
    {E : Type*} (f : E → ℝ) (xstar : E) (hmin : IsMinOn f Set.univ xstar)
    (x : ℕ → E) (K : ℕ) (hK : 0 < K) :
    0 ≤ (Finset.range K).inf' ⟨0, Finset.mem_range.mpr hK⟩ (fun k => f (x k)) - f xstar ∧
    ∀ k < K, (Finset.range K).inf' ⟨0, Finset.mem_range.mpr hK⟩ (fun k => f (x k)) - f xstar
      ≤ f (x k) - f xstar := by
  refine ⟨?_, fun k hk => ?_⟩
  · have : f xstar ≤ (Finset.range K).inf' ⟨0, Finset.mem_range.mpr hK⟩ (fun k => f (x k)) :=
      Finset.le_inf' _ _ (fun k _ => isMinOn_iff.mp hmin (x k) (Set.mem_univ _))
    linarith
  · have := Finset.inf'_le (fun k => f (x k)) (Finset.mem_range.mpr hk)
    linarith

/-- Telescoping a one-step decrease. -/
theorem subgradient_aux_telescope (c d : ℕ → ℝ) (h : ∀ k, c k ≤ d k - d (k + 1)) (n : ℕ) :
    ∑ k ∈ Finset.range n, c k ≤ d 0 - d n := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_range_succ]
    linarith [h n]

#print axioms subgradient_aux_step_expand
#print axioms subgradient_aux_step_le
#print axioms subgradient_aux_inf_bounds
#print axioms subgradient_aux_telescope

/-- The `RG/√K` guarantee with the fixed-horizon step: let `f` be convex, `x*` a minimiser,
the start within `R` of `x*`, and every subgradient used no longer than `G`. Run `K ≥ 1`
steps `x_{k+1} = x_k - α g_k` of the one size `α = R / (G √K)`. Then the best of the first
`K` points is above the minimum by at most `R G / √K`. -/
theorem subgradient_method_best_gap_le_RG_div_sqrt_K
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (f : E → ℝ) (hf : ConvexOn ℝ Set.univ f) (xstar : E) (hmin : IsMinOn f Set.univ xstar)
    (x g : ℕ → E) (R G : ℝ) (K : ℕ) (hK : 0 < K)
    (hR : ‖x 0 - xstar‖ ≤ R)
    (hsub : ∀ k y, f (x k) + ⟪g k, y - x k⟫ ≤ f y)
    (hG : ∀ k, ‖g k‖ ≤ G)
    (hstep : ∀ k, x (k + 1) = x k - (R / (G * Real.sqrt K)) • g k) :
    (Finset.range K).inf' ⟨0, Finset.mem_range.mpr hK⟩ (fun k => f (x k)) - f xstar
      ≤ R * G / Real.sqrt K := by
  obtain ⟨hm0, hm⟩ := subgradient_aux_inf_bounds f xstar hmin x K hK
  set m := (Finset.range K).inf' ⟨0, Finset.mem_range.mpr hK⟩ (fun k => f (x k)) - f xstar
    with hmdef
  have hR0 : 0 ≤ R := le_trans (norm_nonneg _) hR
  have hG0 : 0 ≤ G := le_trans (norm_nonneg _) (hG 0)
  have hs : 0 < Real.sqrt K := Real.sqrt_pos.mpr (by exact_mod_cast hK)
  have hsK : Real.sqrt K ^ 2 = K := Real.sq_sqrt (by positivity)
  have hrhs : 0 ≤ R * G / Real.sqrt K := div_nonneg (mul_nonneg hR0 hG0) hs.le
  have hm00 := hm 0 hK
  rcases hR0.eq_or_lt with hR0' | hRpos
  · have hx0 : x 0 = xstar := by
      rw [← sub_eq_zero, ← norm_eq_zero]
      linarith [norm_nonneg (x 0 - xstar)]
    rw [hx0, sub_self] at hm00
    linarith
  rcases hG0.eq_or_lt with hG0' | hGpos
  · have hg0 : g 0 = 0 := by
      rw [← norm_eq_zero]
      linarith [norm_nonneg (g 0), hG 0]
    have h := hsub 0 xstar
    rw [hg0, inner_zero_left] at h
    linarith
  set α := R / (G * Real.sqrt K) with hαdef
  have hα : 0 < α := by positivity
  have hαGs : α * (G * Real.sqrt K) = R := by
    rw [hαdef]; field_simp
  have hstepk : ∀ k, 2 * α * (f (x k) - f xstar) - α ^ 2 * G ^ 2
      ≤ ‖x k - xstar‖ ^ 2 - ‖x (k + 1) - xstar‖ ^ 2 := by
    intro k
    have h := subgradient_aux_step_le f xstar (x k) (g k) α hα.le (hsub k)
    rw [← hstep k] at h
    have : ‖g k‖ ^ 2 ≤ G ^ 2 := pow_le_pow_left₀ (norm_nonneg _) (hG k) 2
    nlinarith
  have htel := subgradient_aux_telescope _ _ hstepk K
  have hlow : ∑ _k ∈ Finset.range K, (2 * α * m - α ^ 2 * G ^ 2)
      ≤ ∑ k ∈ Finset.range K, (2 * α * (f (x k) - f xstar) - α ^ 2 * G ^ 2) := by
    apply Finset.sum_le_sum
    intro k hk
    have := hm k (Finset.mem_range.mp hk)
    nlinarith
  rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul] at hlow
  have hd0 : ‖x 0 - xstar‖ ^ 2 ≤ R ^ 2 := pow_le_pow_left₀ (norm_nonneg _) hR 2
  have hdK : 0 ≤ ‖x K - xstar‖ ^ 2 := by positivity
  rw [← hsK] at hlow
  -- s² (2 α m - α² G²) ≤ R², and α G s = R
  have key : R * (Real.sqrt K * m) ≤ R * (R * G) := by
    have h1 : Real.sqrt K ^ 2 * (2 * α * m - α ^ 2 * G ^ 2) ≤ R ^ 2 := by linarith
    have h2 : Real.sqrt K ^ 2 * α ^ 2 * G ^ 2 = R ^ 2 := by rw [← hαGs]; ring
    have h3 : Real.sqrt K ^ 2 * α * m ≤ R ^ 2 := by nlinarith
    have h4 : (α * (G * Real.sqrt K)) * (Real.sqrt K * m) ≤ R ^ 2 * G := by
      nlinarith
    rw [hαGs] at h4
    nlinarith
  have key2 : Real.sqrt K * m ≤ R * G := le_of_mul_le_mul_left key hRpos
  rw [le_div_iff₀ hs]
  linarith

/-- One step, one inequality: if `f` is convex, `x*` a minimiser, `g` a subgradient of `f`
at `x` no longer than `G`, and the step size `α` is positive, then the step
`x⁺ = x - α g` satisfies
`‖x⁺ - x*‖² ≤ ‖x - x*‖² - 2 α (f(x) - f(x*)) + α² G²`. -/
theorem subgradient_step_sq_dist_le
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (f : E → ℝ) (hf : ConvexOn ℝ Set.univ f) (xstar : E) (hmin : IsMinOn f Set.univ xstar)
    (x g : E) (α G : ℝ) (hα : 0 < α)
    (hsub : ∀ y, f x + ⟪g, y - x⟫ ≤ f y)
    (hG : ‖g‖ ≤ G) :
    ‖(x - α • g) - xstar‖ ^ 2 ≤ ‖x - xstar‖ ^ 2 - 2 * α * (f x - f xstar) + α ^ 2 * G ^ 2 := by
  have h := subgradient_aux_step_le f xstar x g α hα.le hsub
  have : ‖g‖ ^ 2 ≤ G ^ 2 := pow_le_pow_left₀ (norm_nonneg _) hG 2
  nlinarith

/-- Polyak's step reaches the same guarantee with no budget fixed in advance: let `f` be
convex, `x*` a minimiser with `f(x*)` known exactly, the start within `R` of `x*`, and every
subgradient used no longer than `G`. Take steps `x_{k+1} = x_k - α_k g_k` with
`α_k = (f(x_k) - f(x*)) / ‖g_k‖²`. Then for every `K ≥ 1` the best of the first `K` points
is above the minimum by at most `R G / √K`. -/
theorem polyak_step_best_gap_le_RG_div_sqrt_K
    {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (f : E → ℝ) (hf : ConvexOn ℝ Set.univ f) (xstar : E) (hmin : IsMinOn f Set.univ xstar)
    (x g : ℕ → E) (R G : ℝ)
    (hR : ‖x 0 - xstar‖ ≤ R)
    (hsub : ∀ k y, f (x k) + ⟪g k, y - x k⟫ ≤ f y)
    (hG : ∀ k, ‖g k‖ ≤ G)
    (hstep : ∀ k, x (k + 1) = x k - ((f (x k) - f xstar) / ‖g k‖ ^ 2) • g k)
    (K : ℕ) (hK : 0 < K) :
    (Finset.range K).inf' ⟨0, Finset.mem_range.mpr hK⟩ (fun k => f (x k)) - f xstar
      ≤ R * G / Real.sqrt K := by
  obtain ⟨hm0, hm⟩ := subgradient_aux_inf_bounds f xstar hmin x K hK
  set m := (Finset.range K).inf' ⟨0, Finset.mem_range.mpr hK⟩ (fun k => f (x k)) - f xstar
    with hmdef
  have hR0 : 0 ≤ R := le_trans (norm_nonneg _) hR
  have hG0 : 0 ≤ G := le_trans (norm_nonneg _) (hG 0)
  have hs : 0 < Real.sqrt K := Real.sqrt_pos.mpr (by exact_mod_cast hK)
  have hsK : Real.sqrt K ^ 2 = K := Real.sq_sqrt (by positivity)
  have hgap : ∀ k, 0 ≤ f (x k) - f xstar := fun k => by
    linarith [isMinOn_iff.mp hmin (x k) (Set.mem_univ _)]
  have hstepk : ∀ k, (f (x k) - f xstar) ^ 2
      ≤ G ^ 2 * ‖x k - xstar‖ ^ 2 - G ^ 2 * ‖x (k + 1) - xstar‖ ^ 2 := by
    intro k
    by_cases hg : g k = 0
    · have h := hsub k xstar
      rw [hg, inner_zero_left] at h
      have hk1 : x (k + 1) = x k := by rw [hstep k, hg, smul_zero, sub_zero]
      rw [hk1]
      have := hgap k
      have : f (x k) - f xstar = 0 := by linarith
      rw [this]; simp
    · have hn : 0 < ‖g k‖ := norm_pos_iff.mpr hg
      set n := ‖g k‖ with hndef
      set a := f (x k) - f xstar with hadef
      have ha := hgap k
      have h := subgradient_aux_step_le f xstar (x k) (g k) (a / n ^ 2) (by positivity) (hsub k)
      rw [← hstep k, ← hndef] at h
      have heq : 2 * (a / n ^ 2) * a - (a / n ^ 2) ^ 2 * n ^ 2 = a ^ 2 / n ^ 2 := by
        field_simp; ring
      have ht : a ^ 2 / n ^ 2 ≤ ‖x k - xstar‖ ^ 2 - ‖x (k + 1) - xstar‖ ^ 2 := by
        linarith
      have hnG : n ^ 2 ≤ G ^ 2 := pow_le_pow_left₀ hn.le (hG k) 2
      have ht0 : 0 ≤ a ^ 2 / n ^ 2 := by positivity
      have ha2 : a ^ 2 = a ^ 2 / n ^ 2 * n ^ 2 := by field_simp
      nlinarith
  have htel := subgradient_aux_telescope _ (fun k => G ^ 2 * ‖x k - xstar‖ ^ 2) hstepk K
  have hlow : ∑ _k ∈ Finset.range K, m ^ 2
      ≤ ∑ k ∈ Finset.range K, (f (x k) - f xstar) ^ 2 := by
    apply Finset.sum_le_sum
    intro k hk
    exact pow_le_pow_left₀ hm0 (hm k (Finset.mem_range.mp hk)) 2
  rw [Finset.sum_const, Finset.card_range, nsmul_eq_mul, ← hsK] at hlow
  have hd0 : ‖x 0 - xstar‖ ^ 2 ≤ R ^ 2 := pow_le_pow_left₀ (norm_nonneg _) hR 2
  have hdK : 0 ≤ G ^ 2 * ‖x K - xstar‖ ^ 2 := by positivity
  have hsq : (Real.sqrt K * m) ^ 2 ≤ (R * G) ^ 2 := by
    have : G ^ 2 * ‖x 0 - xstar‖ ^ 2 ≤ G ^ 2 * R ^ 2 :=
      mul_le_mul_of_nonneg_left hd0 (by positivity)
    nlinarith
  have key2 : Real.sqrt K * m ≤ R * G :=
    (pow_le_pow_iff_left₀ (by positivity) (mul_nonneg hR0 hG0) two_ne_zero).mp hsq
  rw [le_div_iff₀ hs]
  linarith

/-! The card's worked numbers, exactly. The depot's total distance to shops at km 1, 2, 6 is
`f(x) = |x - 1| + |x - 2| + |x - 6|`, started at km 10. -/

-- The start: f(10) = 9 + 8 + 4 = 21 km; the best spot: f(2) = 5 km.
example : |(10 : ℚ) - 1| + |10 - 2| + |10 - 6| = 21 := by norm_num
example : |(2 : ℚ) - 1| + |2 - 2| + |2 - 6| = 5 := by norm_num
-- R = |10 - 2| = 8 and G = 3, so RG = 24; a 1 km gap needs √K ≥ 24, K = 24² = 576 steps,
-- and the fixed-horizon step is 8 / (3 × 24) = 1/9 (the card's 0.1111).
example : |(10 : ℚ) - 2| = 8 ∧ (8 : ℚ) * 3 = 24 ∧ (24 : ℕ) ^ 2 = 576 ∧ (8 : ℚ) / (3 * 24) = 1 / 9 := by
  norm_num
-- Budgets of 16, 36 and 144 steps (√K = 4, 6, 12) guarantee 24/4, 24/6, 24/12 = 6, 4, 2 km.
example : (4 : ℕ) ^ 2 = 16 ∧ (6 : ℕ) ^ 2 = 36 ∧ (12 : ℕ) ^ 2 = 144 ∧
    (24 : ℚ) / 4 = 6 ∧ (24 : ℚ) / 6 = 4 ∧ (24 : ℚ) / 12 = 2 := by norm_num
-- First fixed step: 10 - (1/9) × 3 = 29/3 (km 9.6667).
example : (10 : ℚ) - 1 / 9 * 3 = 29 / 3 := by norm_num
-- One-step bound at step 0: 64 - 2 (1/9)(16) + (1/9)² 9 = 545/9 (60.5556), against the true
-- squared distance (29/3 - 2)² = 529/9 (58.7778).
example : (64 : ℚ) - 2 * (1 / 9) * 16 + (1 / 9) ^ 2 * 9 = 545 / 9 ∧
    ((29 : ℚ) / 3 - 2) ^ 2 = 529 / 9 ∧ (529 : ℚ) / 9 ≤ 545 / 9 := by norm_num
-- Reaching km 2: 12 moves of 3 × 1/9 to km 6, one more of 3 × 1/9, then 33 of 1/9: step 46.
example : (10 : ℚ) - 12 * (3 * (1 / 9)) = 6 ∧ (6 : ℚ) - 3 * (1 / 9) - 33 * (1 / 9) = 2 ∧
    12 + 1 + 33 = 46 := by norm_num
-- Polyak's first step: (21 - 5)/3² = 16/9 (1.7778), to 10 - (16/9) × 3 = 14/3 (km 4.6667),
-- where the total is 23/3 (7.6667).
example : ((21 : ℚ) - 5) / 3 ^ 2 = 16 / 9 ∧ (10 : ℚ) - 16 / 9 * 3 = 14 / 3 ∧
    |(14 : ℚ) / 3 - 1| + |14 / 3 - 2| + |14 / 3 - 6| = 23 / 3 := by norm_num
-- Polyak's second step: (23/3 - 5)/1² = 8/3 (2.6667), to 14/3 - 8/3 = 2, total 5: exact.
example : ((23 : ℚ) / 3 - 5) / 1 ^ 2 = 8 / 3 ∧ (14 : ℚ) / 3 - 8 / 3 * 1 = 2 ∧
    |(2 : ℚ) - 1| + |2 - 2| + |2 - 6| = 5 := by norm_num
-- Polyak's promise after one step: |14/3 - 2|² = 64/9 (7.1111), at most 64 - 16²/9 = 320/9
-- (35.5556).
example : ((14 : ℚ) / 3 - 2) ^ 2 = 64 / 9 ∧ (64 : ℚ) - 16 ^ 2 / 9 = 320 / 9 ∧
    (64 : ℚ) / 9 ≤ 320 / 9 := by norm_num
-- The many-variable floor at K = 576: RG / (2 (1 + √K)) = 24 / (2 × 25) = 12/25 (0.4800 km).
example : (24 : ℚ) / (2 * (1 + 24)) = 12 / 25 := by norm_num
-- What breaks, fixed step 0.7 for ever: the point bounces 23/10 → 16/10 → 23/10 (slopes +1, -1),
-- and the best total there is 53/10, a gap of 3/10.
example : (23 : ℚ) / 10 - 7 / 10 * 1 = 16 / 10 ∧ (16 : ℚ) / 10 - 7 / 10 * (-1) = 23 / 10 ∧
    |(23 : ℚ) / 10 - 1| + |23 / 10 - 2| + |23 / 10 - 6| = 53 / 10 ∧
    |(16 : ℚ) / 10 - 1| + |16 / 10 - 2| + |16 / 10 - 6| = 54 / 10 := by norm_num
-- What breaks, Polyak with f(x*) guessed as 6: at km 3 the total is 6, so the step is 0 and the
-- method stalls with gap 1.
example : |(3 : ℚ) - 1| + |3 - 2| + |3 - 6| = 6 ∧ ((6 : ℚ) - 6) / 1 ^ 2 = 0 := by norm_num
-- What breaks, Polyak with f(x*) guessed as 0: from km 3 (total 6, slope 1) to km -3
-- (total 18, slope -3) and back to km 3, for ever.
example : (3 : ℚ) - (6 - 0) / 1 ^ 2 * 1 = -3 ∧
    |(-3 : ℚ) - 1| + |-3 - 2| + |-3 - 6| = 18 ∧
    (-3 : ℚ) - (18 - 0) / (-3) ^ 2 * (-3) = 3 := by norm_num

#print axioms subgradient_method_best_gap_le_RG_div_sqrt_K
#print axioms subgradient_step_sq_dist_le
#print axioms polyak_step_best_gap_le_RG_div_sqrt_K
