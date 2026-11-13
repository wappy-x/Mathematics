-- Beta-binomial: a Beta(a, b) prior on a chance, updated with s successes in n independent trials, becomes Beta(a + s, b + n - s), its average (a + s)/(a + b + n) is the next trial's chance of success, and the chance of k successes in m more trials is C(m, k) times rising products.
import Mathlib.Probability.Distributions.Beta
import Mathlib.RingTheory.Polynomial.Pochhammer
import Mathlib.Tactic.NormNum

open MeasureTheory


/-- Helper: the beta density integrates to 1. -/
theorem bb_integral_betaPDFReal {α β : ℝ} (hα : 0 < α) (hβ : 0 < β) :
    ∫ x, ProbabilityTheory.betaPDFReal α β x = 1 := by
  have h1 := ProbabilityTheory.lintegral_betaPDF_eq_one hα hβ
  have hnn : ∀ x, 0 ≤ ProbabilityTheory.betaPDFReal α β x := by
    intro x
    by_cases hx : 0 < x ∧ x < 1
    · exact (ProbabilityTheory.betaPDFReal_pos hx.1 hx.2 hα hβ).le
    · simp [ProbabilityTheory.betaPDFReal, hx]
  rw [integral_eq_lintegral_of_nonneg_ae (Filter.Eventually.of_forall hnn)
    (ProbabilityTheory.measurable_betaPDFReal α β).aestronglyMeasurable]
  change (∫⁻ x, ProbabilityTheory.betaPDF α β x).toReal = 1
  rw [h1]; simp

/-- Helper: multiplying the Beta(a, b) density by u^s (1-u)^j gives a multiple of the
Beta(a + s, b + j) density. -/
theorem bb_mul_betaPDFReal {a b : ℝ} (ha : 0 < a) (hb : 0 < b) (s j : ℕ) (u : ℝ) :
    u ^ s * (1 - u) ^ j * ProbabilityTheory.betaPDFReal a b u =
      ProbabilityTheory.beta (a + s) (b + j) / ProbabilityTheory.beta a b *
        ProbabilityTheory.betaPDFReal (a + s) (b + j) u := by
  unfold ProbabilityTheory.betaPDFReal
  by_cases hu : 0 < u ∧ u < 1
  · simp only [hu, and_self, ↓reduceIte]
    have h1 : (0:ℝ) < u := hu.1
    have h2 : (0:ℝ) < 1 - u := by linarith [hu.2]
    have e1 : u ^ (a + s - 1) = u ^ s * u ^ (a - 1) := by
      rw [← Real.rpow_natCast, ← Real.rpow_add h1]; ring_nf
    have e2 : (1 - u) ^ (b + j - 1) = (1 - u) ^ j * (1 - u) ^ (b - 1) := by
      rw [← Real.rpow_natCast, ← Real.rpow_add h2]; ring_nf
    rw [e1, e2]
    have B1 := ProbabilityTheory.beta_pos ha hb
    have B2 := ProbabilityTheory.beta_pos (α := a + s) (β := b + j) (by positivity) (by positivity)
    field_simp
  · simp [hu]

/-- Helper: Gamma(x + k) = x(x+1)...(x+k-1) Gamma(x) for x > 0. -/
theorem bb_Gamma_add_nat {x : ℝ} (hx : 0 < x) (k : ℕ) :
    Real.Gamma (x + k) = (ascPochhammer ℝ k).eval x * Real.Gamma x := by
  induction k with
  | zero => simp
  | succ k ih =>
    rw [ascPochhammer_succ_eval, Nat.cast_succ, ← add_assoc,
      Real.Gamma_add_one (by positivity), ih]
    ring

/-- Helper: B(x + k, y + j) / B(x, y) as rising products. -/
theorem bb_beta_ratio {x y : ℝ} (hx : 0 < x) (hy : 0 < y) (k j : ℕ) :
    ProbabilityTheory.beta (x + k) (y + j) / ProbabilityTheory.beta x y =
      (ascPochhammer ℝ k).eval x * (ascPochhammer ℝ j).eval y /
        (ascPochhammer ℝ (k + j)).eval (x + y) := by
  unfold ProbabilityTheory.beta
  have hxy : 0 < x + y := by linarith
  have e : x + k + (y + j) = (x + y) + ((k + j : ℕ) : ℝ) := by push_cast; ring
  rw [e, bb_Gamma_add_nat hx, bb_Gamma_add_nat hy, bb_Gamma_add_nat hxy]
  have g1 := Real.Gamma_pos_of_pos hx
  have g2 := Real.Gamma_pos_of_pos hy
  have g3 := Real.Gamma_pos_of_pos hxy
  have p3 : 0 < (ascPochhammer ℝ (k + j)).eval (x + y) := ascPochhammer_pos _ _ hxy
  field_simp

/-- The conjugate update. Take a beta prior Beta(a, b) on the chance θ, with a > 0 and b > 0,
and a record of n independent trials with s successes, whose likelihood is θ^s (1 - θ)^(n - s).
Bayes' rule (prior times likelihood, divided by the evidence, its integral) gives exactly the
Beta(a + s, b + n - s) density at every θ. The evidence itself is B(a + s, b + n - s) / B(a, b). -/
theorem beta_binomial_conjugate_update (a b : ℝ) (ha : 0 < a) (hb : 0 < b)
    (n s : ℕ) (hs : s ≤ n) :
    (∫ u, u ^ s * (1 - u) ^ (n - s) * ProbabilityTheory.betaPDFReal a b u) =
        ProbabilityTheory.beta (a + s) (b + (n - s : ℕ)) / ProbabilityTheory.beta a b ∧
      ∀ θ : ℝ,
        θ ^ s * (1 - θ) ^ (n - s) * ProbabilityTheory.betaPDFReal a b θ /
            (∫ u, u ^ s * (1 - u) ^ (n - s) * ProbabilityTheory.betaPDFReal a b u) =
          ProbabilityTheory.betaPDFReal (a + s) (b + (n - s : ℕ)) θ := by
  have hpt : ∀ u : ℝ, u ^ s * (1 - u) ^ (n - s) * ProbabilityTheory.betaPDFReal a b u =
      ProbabilityTheory.beta (a + s) (b + (n - s : ℕ)) / ProbabilityTheory.beta a b *
        ProbabilityTheory.betaPDFReal (a + s) (b + (n - s : ℕ)) u :=
    fun u => bb_mul_betaPDFReal ha hb s (n - s) u
  have hI : (∫ u, u ^ s * (1 - u) ^ (n - s) * ProbabilityTheory.betaPDFReal a b u) =
      ProbabilityTheory.beta (a + s) (b + (n - s : ℕ)) / ProbabilityTheory.beta a b := by
    simp_rw [hpt]
    rw [integral_const_mul, bb_integral_betaPDFReal (by positivity) (by positivity), mul_one]
  refine ⟨hI, fun θ => ?_⟩
  rw [hI, hpt θ]
  have B1 := ProbabilityTheory.beta_pos ha hb
  have B2 := ProbabilityTheory.beta_pos (α := a + s) (β := b + (n - s : ℕ))
    (by positivity) (by positivity)
  field_simp

/-- The next trial's chance of success is the posterior average. With the prior Beta(a, b),
a > 0 and b > 0, and s successes in n trials, the average of θ under the posterior
Beta(a + s, b + n - s), which is the chance that trial n + 1 succeeds, equals (a + s)/(a + b + n). -/
theorem beta_binomial_next_trial_chance (a b : ℝ) (ha : 0 < a) (hb : 0 < b)
    (n s : ℕ) (hs : s ≤ n) :
    ∫ θ, θ * ProbabilityTheory.betaPDFReal (a + s) (b + (n - s : ℕ)) θ = (a + s) / (a + b + n) := by
  have hα : 0 < a + s := by positivity
  have hβ : 0 < b + (n - s : ℕ) := by positivity
  have hpt : ∀ θ : ℝ, θ * ProbabilityTheory.betaPDFReal (a + s) (b + (n - s : ℕ)) θ =
      ProbabilityTheory.beta (a + s + ((1 : ℕ) : ℝ)) (b + (n - s : ℕ) + ((0 : ℕ) : ℝ)) /
        ProbabilityTheory.beta (a + s) (b + (n - s : ℕ)) *
        ProbabilityTheory.betaPDFReal (a + s + ((1 : ℕ) : ℝ)) (b + (n - s : ℕ) + ((0 : ℕ) : ℝ)) θ := by
    intro θ
    rw [← bb_mul_betaPDFReal hα hβ 1 0 θ]
    simp
  simp_rw [hpt]
  rw [integral_const_mul, bb_integral_betaPDFReal (by positivity) (by positivity), mul_one,
    bb_beta_ratio hα hβ 1 0]
  have hns : ((n - s : ℕ) : ℝ) = (n : ℝ) - s := by push_cast [Nat.cast_sub hs]; ring
  rw [hns]
  have : 0 < a + b + n := by positivity
  simp [ascPochhammer_one]
  ring_nf

/-- The beta-binomial predictive law. With α = a + s and β = b + n - s the posterior's two numbers
(a > 0, b > 0, s successes in n trials), the chance of k successes in m more trials, the binomial
chance C(m, k) θ^k (1 - θ)^(m - k) averaged over the posterior, is
C(m, k) · α(α+1)⋯(α+k-1) · β(β+1)⋯(β+m-k-1) / ((α+β)(α+β+1)⋯(α+β+m-1)). -/
theorem beta_binomial_predictive_law (a b : ℝ) (ha : 0 < a) (hb : 0 < b)
    (n s : ℕ) (hs : s ≤ n) (m k : ℕ) (hk : k ≤ m) :
    ∫ θ, (m.choose k : ℝ) * θ ^ k * (1 - θ) ^ (m - k) *
        ProbabilityTheory.betaPDFReal (a + s) (b + (n - s : ℕ)) θ =
      (m.choose k : ℝ) * (ascPochhammer ℝ k).eval (a + s) *
          (ascPochhammer ℝ (m - k)).eval (b + (n - s : ℕ)) /
        (ascPochhammer ℝ m).eval ((a + s) + (b + (n - s : ℕ))) := by
  have hα : 0 < a + s := by positivity
  have hβ : 0 < b + (n - s : ℕ) := by positivity
  have hpt : ∀ θ : ℝ, (m.choose k : ℝ) * θ ^ k * (1 - θ) ^ (m - k) *
        ProbabilityTheory.betaPDFReal (a + s) (b + (n - s : ℕ)) θ =
      (m.choose k : ℝ) * (ProbabilityTheory.beta (a + s + k) (b + (n - s : ℕ) + (m - k : ℕ)) /
        ProbabilityTheory.beta (a + s) (b + (n - s : ℕ)) *
        ProbabilityTheory.betaPDFReal (a + s + k) (b + (n - s : ℕ) + (m - k : ℕ)) θ) := by
    intro θ
    rw [← bb_mul_betaPDFReal hα hβ k (m - k) θ]
    ring
  simp_rw [hpt]
  rw [integral_const_mul, integral_const_mul,
    bb_integral_betaPDFReal (by positivity) (by positivity), mul_one,
    bb_beta_ratio hα hβ k (m - k), Nat.add_sub_cancel' hk]
  ring

/-! The card's worked numbers, as exact whole numbers and fractions. -/

-- Prior Beta(2, 2), 7 heads in 10 flips: posterior numbers 2 + 7 = 9 and 2 + 3 = 5.
example : 2 + 7 = 9 ∧ 2 + (10 - 7) = 5 := by decide

-- Posterior average 9/14, also the compromise 4/14 × 1/2 + 10/14 × 7/10.
example : (2 + 7 : ℚ) / (2 + 2 + 10) = 9 / 14 := by norm_num
example : (4 / 14 : ℚ) * (1 / 2) + (10 / 14) * (7 / 10) = 9 / 14 := by norm_num

-- Posterior variance 9 × 5 / (14^2 × 15) = 45/2940; mode (9 - 1)/(9 + 5 - 2) = 8/12.
example : (9 * 5 : ℚ) / (14 ^ 2 * 15) = 45 / 2940 := by norm_num
example : (9 - 1 : ℚ) / (9 + 5 - 2) = 8 / 12 := by norm_num

-- Constants: 1/B(2, 2) = 3!/(1! 1!) = 6 and 1/B(9, 5) = 13!/(8! 4!) = 6435; C(10, 7) = 120.
example : Nat.factorial 3 / (Nat.factorial 1 * Nat.factorial 1) = 6 := by decide
example : Nat.factorial 13 / (Nat.factorial 8 * Nat.factorial 4) = 6435 := by decide
example : Nat.choose 10 7 = 120 := by decide

-- Evidence for 7 heads in 10: 120 × 6/6435 = 720/6435 = 16/143.
example : (120 * 6 : ℚ) / 6435 = 16 / 143 := by norm_num

-- Chance the coin favours heads: fewer than 9 of 13 below 1/2, 7099 of 8192.
example : (Finset.range 9).sum (fun j => Nat.choose 13 j) = 7099 ∧ 2 ^ 13 = 8192 := by decide

-- Two more flips: 0, 1, 2 heads have chances 5·6/210, 2·9·5/210, 9·10/210 = 1/7, 3/7, 3/7.
example : (5 * 6 : ℚ) / (14 * 15) = 1 / 7 ∧ (2 * 9 * 5 : ℚ) / (14 * 15) = 3 / 7 ∧
    (9 * 10 : ℚ) / (14 * 15) = 3 / 7 := by norm_num

-- Next ten flips: variance 10 · 9 · 5 · 24 / (14^2 · 15) = 180/49.
example : (10 * 9 * 5 * 24 : ℚ) / (14 ^ 2 * 15) = 180 / 49 := by norm_num

-- The urn: all 1,024 paths of ten draws weigh 14 × 15 × ... × 23 = 4151586700800 in total.
example : (Finset.range 10).prod (fun j => 14 + j) = 4151586700800 := by decide

-- Ten heads in ten more flips: 9 × 10 × ... × 18 / (14 × 15 × ... × 23) = 117/3059.
example : ((Finset.range 10).prod (fun j => (9 + j : ℚ))) /
    ((Finset.range 10).prod (fun j => (14 + j : ℚ))) = 117 / 3059 := by
  norm_num [Finset.prod_range_succ]

-- Flip by flip (H T H H H T H H T H) the posterior's first number, 2 plus the heads so far, walks
-- 3, 3, 4, 5, 6, 6, 7, 8, 8, 9 over totals 5 to 14: averages 3/5, 3/6, 4/7, ..., 9/14.
example : (List.range 10).map (fun i => 2 + ([true, false, true, true, true, false, true, true,
    false, true].take (i + 1)).count true) = [3, 3, 4, 5, 6, 6, 7, 8, 8, 9] := by decide

-- Laplace's rule with a flat prior Beta(1, 1): (7 + 1)/(10 + 2) = 8/12.
example : (7 + 1 : ℚ) / (10 + 2) = 8 / 12 := by norm_num

-- Mistake: heads added to the second number gives Beta(5, 9), average 5/14.
example : (2 + 3 : ℚ) / 14 = 5 / 14 := by norm_num

-- Mistake: the 10 flips counted twice gives Beta(16, 8); it lies above 1/2 with chance
-- 7997952/8388608 (fewer than 16 of 23 below 1/2).
example : 2 + 2 * 7 = 16 ∧ 2 + 2 * 3 = 8 ∧
    (Finset.range 16).sum (fun j => Nat.choose 23 j) = 7997952 ∧ 2 ^ 23 = 8388608 := by decide

#print axioms bb_integral_betaPDFReal
#print axioms bb_mul_betaPDFReal
#print axioms bb_Gamma_add_nat
#print axioms bb_beta_ratio
#print axioms beta_binomial_conjugate_update
#print axioms beta_binomial_next_trial_chance
#print axioms beta_binomial_predictive_law
