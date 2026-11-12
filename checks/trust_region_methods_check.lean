-- Trust regions: the straight-downhill step inside a circle of radius Δ always earns a promised fall of at least ½‖g‖ min(Δ, ‖g‖/‖B‖), so when f is twice continuously differentiable, the model matches f's value and slope, and every step earns a fixed fraction of that, cutting the radius to a quarter after each refusal ends in a kept step with ratio above 3/4 after finitely many cuts; the banana valley's exact model error and the card's exact numbers are checked too.
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.InnerProductSpace.Adjoint
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Ring
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Tactic

open scoped Gradient RealInnerProductSpace

/-! The choices live in `EuclideanSpace ℝ (Fin n)`: n numbers. At the current point the slope is
a vector `g` and the curvature is a symmetric linear map `B` (`IsSelfAdjoint B`); `‖B‖` is its
operator norm, the most `B` stretches any vector. The model is
`m(d) = f(x) + ⟪g, d⟫ + ½ ⟪d, B d⟫`, so the fall it promises for a step `d` is
`m(0) − m(d) = −(⟪g, d⟫ + ½ ⟪d, B d⟫)`. -/

/-- The fall the quadratic model promises for the step `d`: `m(0) − m(d)`. -/
noncomputable def promisedFall {n : ℕ} (g : EuclideanSpace ℝ (Fin n))
    (B : EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n))
    (d : EuclideanSpace ℝ (Fin n)) : ℝ :=
  -(⟪g, d⟫ + 1 / 2 * ⟪d, B d⟫)

/-- The straight-downhill guarantee `½ ‖g‖ min(Δ, ‖g‖/‖B‖)`. When `B = 0` the card's
`‖g‖/‖B‖` is infinite and the minimum is `Δ`, so the bound is `½ ‖g‖ Δ`. -/
noncomputable def cauchyBound {n : ℕ} (g : EuclideanSpace ℝ (Fin n))
    (B : EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n)) (Δ : ℝ) : ℝ :=
  if ‖B‖ = 0 then 1 / 2 * ‖g‖ * Δ else 1 / 2 * ‖g‖ * min Δ (‖g‖ / ‖B‖)

/-- Helper: the curvature term is at most `‖B‖ ‖d‖²` in size. -/
theorem trm_abs_inner_le {n : ℕ}
    (B : EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n))
    (d : EuclideanSpace ℝ (Fin n)) : |⟪d, B d⟫| ≤ ‖B‖ * ‖d‖ ^ 2 := by
  calc |⟪d, B d⟫| ≤ ‖d‖ * ‖B d‖ := abs_real_inner_le_norm _ _
    _ ≤ ‖d‖ * (‖B‖ * ‖d‖) := by gcongr; exact B.le_opNorm d
    _ = ‖B‖ * ‖d‖ ^ 2 := by ring

#print axioms trm_abs_inner_le

/-- Helper: for small radii the ratio is above `3/4`. -/
theorem trm_small_radius {n : ℕ} {f : EuclideanSpace ℝ (Fin n) → ℝ}
    {x : EuclideanSpace ℝ (Fin n)} (hf : ContDiffAt ℝ 2 f x) (hg : ∇ f x ≠ 0)
    (B : EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n))
    {c : ℝ} (hc : 0 < c) (step : ℝ → EuclideanSpace ℝ (Fin n))
    (hlen : ∀ Δ, 0 < Δ → ‖step Δ‖ ≤ Δ)
    (hfall : ∀ Δ, 0 < Δ → c * cauchyBound (∇ f x) B Δ ≤ promisedFall (∇ f x) B (step Δ)) :
    ∃ η > 0, ∀ Δ, 0 < Δ → Δ < η →
      3 / 4 < (f x - f (x + step Δ)) / promisedFall (∇ f x) B (step Δ) := by
  set g := ∇ f x with hgdef
  have hG : 0 < ‖g‖ := norm_pos_iff.mpr hg
  set G := ‖g‖
  set L := ‖B‖
  have hL : 0 ≤ L := norm_nonneg _
  have hdiff : DifferentiableAt ℝ f x := hf.differentiableAt (by norm_num)
  have hfd : HasFDerivAt f (InnerProductSpace.toDual ℝ _ g) x := hdiff.hasGradientAt.hasFDerivAt
  have hlo := hasFDerivAt_iff_isLittleO_nhds_zero.mp hfd
  have hε : 0 < c * G / 32 := by positivity
  have hev := hlo.def hε
  obtain ⟨δ, hδ, hball⟩ := Metric.eventually_nhds_iff.mp hev
  refine ⟨min δ (min (G / (L + 1)) (c * G / (16 * (L + 1)))), by positivity, ?_⟩
  intro Δ hΔ hΔη
  have h1 : Δ < δ := lt_of_lt_of_le hΔη (min_le_left _ _)
  have h2 : Δ < G / (L + 1) := lt_of_lt_of_le hΔη ((min_le_right _ _).trans (min_le_left _ _))
  have h3 : Δ < c * G / (16 * (L + 1)) :=
    lt_of_lt_of_le hΔη ((min_le_right _ _).trans (min_le_right _ _))
  have hL1 : 0 < L + 1 := by linarith
  have h2' : Δ * L ≤ G := by
    rw [lt_div_iff₀ hL1] at h2; nlinarith
  have h3' : 16 * (Δ * L) ≤ c * G := by
    rw [lt_div_iff₀ (by positivity)] at h3; nlinarith
  set d := step Δ
  have hd : ‖d‖ ≤ Δ := hlen Δ hΔ
  -- the promised fall is at least c G Δ / 2
  have hcb : cauchyBound g B Δ = 1 / 2 * G * Δ := by
    unfold cauchyBound
    split_ifs with h0
    · rfl
    · have hLpos : 0 < L := lt_of_le_of_ne hL (Ne.symm h0)
      rw [min_eq_left]
      rw [le_div_iff₀ hLpos]; exact h2'
  have hP : c * (1 / 2 * G * Δ) ≤ promisedFall g B d := by
    rw [← hcb]; exact hfall Δ hΔ
  have hPpos : 0 < promisedFall g B d := lt_of_lt_of_le (by positivity) hP
  -- error bound
  have hE : ‖f (x + d) - f x - (InnerProductSpace.toDual ℝ _ g) d‖ ≤ c * G / 32 * ‖d‖ := by
    apply hball
    rw [dist_zero_right]; exact lt_of_le_of_lt hd h1
  rw [InnerProductSpace.toDual_apply_apply, Real.norm_eq_abs] at hE
  have hQ := trm_abs_inner_le B d
  have hd2 : ‖d‖ ^ 2 ≤ Δ ^ 2 := by gcongr
  rw [lt_div_iff₀ hPpos]
  unfold promisedFall at hP ⊢
  have hn0 : 0 ≤ ‖d‖ := norm_nonneg _
  have hEa := (abs_le.mp hE).2
  have hQa := (abs_le.mp hQ).1
  have : L * ‖d‖ ^ 2 ≤ L * Δ ^ 2 := by gcongr
  have : c * G / 32 * ‖d‖ ≤ c * G / 32 * Δ := by gcongr
  nlinarith

#print axioms trm_small_radius

/-- **Shrinking ends.** Let `f` have continuous second derivatives near the point `x`, with a
slope `∇f(x)` that is not zero, and let the model match `f`'s value and slope at `x`, with any
symmetric curvature map `B`. Let the step for radius `Δ` (`step Δ`) stay inside the circle and
earn at least a fixed fraction `c > 0` of the straight-downhill guarantee. Start from any radius
`Δ₀ > 0` and cut it to a quarter after each refusal. Then after finitely many cuts the ratio of
delivered fall to promised fall, `ρ = (f(x) − f(x + d)) / (m(0) − m(d))`, is above `3/4` (and
stays above it for every further cut), so the step is kept. -/
theorem trust_region_shrinking_ends {n : ℕ} {f : EuclideanSpace ℝ (Fin n) → ℝ}
    {x : EuclideanSpace ℝ (Fin n)} (hf : ContDiffAt ℝ 2 f x) (hg : ∇ f x ≠ 0)
    (B : EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n)) (hB : IsSelfAdjoint B)
    {c : ℝ} (hc : 0 < c) (step : ℝ → EuclideanSpace ℝ (Fin n))
    (hlen : ∀ Δ, 0 < Δ → ‖step Δ‖ ≤ Δ)
    (hfall : ∀ Δ, 0 < Δ → c * cauchyBound (∇ f x) B Δ ≤ promisedFall (∇ f x) B (step Δ))
    {Δ₀ : ℝ} (hΔ₀ : 0 < Δ₀) :
    ∃ N : ℕ, ∀ k ≥ N,
      3 / 4 < (f x - f (x + step (Δ₀ / 4 ^ k))) / promisedFall (∇ f x) B (step (Δ₀ / 4 ^ k)) := by
  obtain ⟨η, hη, hsmall⟩ := trm_small_radius hf hg B hc step hlen hfall
  have ht : Filter.Tendsto (fun k : ℕ => Δ₀ / 4 ^ k) Filter.atTop (nhds 0) :=
    tendsto_const_nhds.div_atTop (tendsto_pow_atTop_atTop_of_one_lt (by norm_num))
  obtain ⟨N, hN⟩ := Filter.eventually_atTop.mp (ht.eventually (gt_mem_nhds hη))
  exact ⟨N, fun k hk => hsmall _ (by positivity) (hN k hk)⟩

/-- **The straight-downhill guarantee.** For any slope `g`, any symmetric curvature map `B` and
any radius `Δ > 0`, some step straight downhill, `d = −t g` with `t ≥ 0` and `‖d‖ ≤ Δ`, makes
the model promise a fall of at least `½ ‖g‖ min(Δ, ‖g‖/‖B‖)`. -/
theorem cauchy_step_guarantee {n : ℕ} (g : EuclideanSpace ℝ (Fin n))
    (B : EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n)) (hB : IsSelfAdjoint B)
    {Δ : ℝ} (hΔ : 0 < Δ) :
    ∃ t : ℝ, 0 ≤ t ∧ ‖t • g‖ ≤ Δ ∧ cauchyBound g B Δ ≤ promisedFall g B (-(t • g)) := by
  have hpf : ∀ t : ℝ, promisedFall g B (-(t • g)) = t * ‖g‖ ^ 2 - 1 / 2 * t ^ 2 * ⟪g, B g⟫ := by
    intro t
    unfold promisedFall
    simp only [map_neg, map_smul, inner_neg_left, inner_neg_right, real_inner_smul_left,
      real_inner_smul_right, real_inner_self_eq_norm_sq]
    ring
  have hq : ⟪g, B g⟫ ≤ ‖B‖ * ‖g‖ ^ 2 := le_trans (le_abs_self _) (trm_abs_inner_le B g)
  by_cases hg : g = 0
  · subst hg
    refine ⟨0, le_refl _, by simp; exact hΔ.le, ?_⟩
    unfold cauchyBound promisedFall
    simp
  have hG : 0 < ‖g‖ := norm_pos_iff.mpr hg
  set G := ‖g‖
  set L := ‖B‖
  have hL : 0 ≤ L := norm_nonneg _
  by_cases hL0 : L = 0
  · refine ⟨Δ / G, by positivity, ?_, ?_⟩
    · rw [norm_smul, Real.norm_eq_abs, abs_of_pos (by positivity), div_mul_cancel₀ _ hG.ne']
    · rw [hpf]
      unfold cauchyBound
      rw [ite_cond_eq_true _ _ (eq_true hL0)]
      rw [hL0, zero_mul] at hq
      have : 0 ≤ (Δ / G) ^ 2 := sq_nonneg _
      have e : Δ / G * G ^ 2 = Δ * G := by field_simp
      nlinarith
  · have hLpos : 0 < L := lt_of_le_of_ne hL (Ne.symm hL0)
    set m := min Δ (G / L)
    have hm : 0 < m := lt_min hΔ (by positivity)
    have hmL : m * L ≤ G := by
      have := min_le_right Δ (G / L)
      rwa [le_div_iff₀ hLpos] at this
    refine ⟨m / G, by positivity, ?_, ?_⟩
    · rw [norm_smul, Real.norm_eq_abs, abs_of_pos (by positivity), div_mul_cancel₀ _ hG.ne']
      exact min_le_left _ _
    · rw [hpf]
      unfold cauchyBound
      rw [ite_cond_eq_false _ _ (eq_false hL0)]
      have e1 : m / G * G ^ 2 = m * G := by field_simp
      have e2 : (m / G) ^ 2 * (L * G ^ 2) = m ^ 2 * L := by field_simp
      have h4 : (m / G) ^ 2 * ⟪g, B g⟫ ≤ (m / G) ^ 2 * (L * G ^ 2) :=
        mul_le_mul_of_nonneg_left hq (sq_nonneg _)
      rw [e1]
      nlinarith

/-! Rosenbrock's banana `f(x, y) = (1 − x)² + 100 (y − x²)²`, its slope
`(−2(1 − x) − 400 x (y − x²), 200 (y − x²))` and its Hessian `[[a, b], [b, c]]` with
`a = 2 − 400 (y − x²) + 800 x²`, `b = −400 x`, `c = 200`. -/

/-- Rosenbrock's banana. -/
def rosen {K : Type*} [CommRing K] (x y : K) : K := (1 - x) ^ 2 + 100 * (y - x ^ 2) ^ 2

/-- First part of the slope. -/
def rosenGx {K : Type*} [CommRing K] (x y : K) : K := -2 * (1 - x) - 400 * x * (y - x ^ 2)

/-- Second part of the slope. -/
def rosenGy {K : Type*} [CommRing K] (x y : K) : K := 200 * (y - x ^ 2)

/-- Hessian entry `a`. -/
def rosenHa {K : Type*} [CommRing K] (x y : K) : K := 2 - 400 * (y - x ^ 2) + 800 * x ^ 2

/-- Hessian entry `b`. -/
def rosenHb {K : Type*} [CommRing K] (x _y : K) : K := -400 * x

/-- **Where the banana model fails, exactly.** For every point `(x, y)` and every step
`d = (u, v)`, the true value minus the quadratic model built from the value, slope and Hessian
at `(x, y)` is exactly `100 u⁴ − 200 u² (v − 2 x u)`. -/
theorem rosenbrock_model_error (x y u v : ℝ) :
    rosen (x + u) (y + v) -
        (rosen x y + rosenGx x y * u + rosenGy x y * v +
          1 / 2 * (rosenHa x y * u ^ 2 + 2 * rosenHb x y * u * v + 200 * v ^ 2)) =
      100 * u ^ 4 - 200 * u ^ 2 * (v - 2 * x * u) := by
  unfold rosen rosenGx rosenGy rosenHa rosenHb
  ring

-- The start (−1.2, 1): f = 24.2, slope (−215.6, −88), Hessian a, b, c = 1330, 480, 200.
example : rosen (-6 / 5 : ℚ) 1 = 121 / 5 ∧ rosenGx (-6 / 5 : ℚ) 1 = -1078 / 5 ∧
    rosenGy (-6 / 5 : ℚ) 1 = -88 ∧ rosenHa (-6 / 5 : ℚ) 1 = 1330 ∧ rosenHb (-6 / 5 : ℚ) 1 = 480 := by
  norm_num [rosen, rosenGx, rosenGy, rosenHa, rosenHb]

-- Step 0 is the Newton point: solving [[1330, 480], [480, 200]] d = (1078/5, 88) gives
-- d = (11/445, 847/2225), so x1 = (−523/445, 3072/2225) = (−1.175281…, 1.380674…).
example : (1330 : ℚ) * (11 / 445) + 480 * (847 / 2225) = 1078 / 5 ∧
    (480 : ℚ) * (11 / 445) + 200 * (847 / 2225) = 88 ∧
    (-6 / 5 : ℚ) + 11 / 445 = -523 / 445 ∧ (1 : ℚ) + 847 / 2225 = 3072 / 2225 := by norm_num

-- At x1: f = 4.731884… (between 4.731884 and 4.731885), slope (−4.637816…, −0.122207…),
-- Hessian a = 1107.2726…, b = 470.1124…, c = 200.
example : 4731884 / 1000000 < rosen (-523 / 445 : ℚ) (3072 / 2225) ∧
    rosen (-523 / 445 : ℚ) (3072 / 2225) < 4731885 / 1000000 ∧
    rosenGx (-523 / 445 : ℚ) (3072 / 2225) = -16347584 / 3524845 ∧
    rosenGy (-523 / 445 : ℚ) (3072 / 2225) = -968 / 7921 ∧
    rosenHa (-523 / 445 : ℚ) (3072 / 2225) = 8770706 / 7921 ∧
    rosenHb (-523 / 445 : ℚ) (3072 / 2225) = 41840 / 89 := by
  norm_num [rosen, rosenGx, rosenGy, rosenHa, rosenHb]

-- Pure Newton from x1: the step (86152/44445, −8019158719/1760244225) has length 4.950945…
-- (its square lies between 4.95² and 4.96²) and lands where f = 1411.845… (between 1411 and 1412).
example : (4.95 : ℚ) ^ 2 < (86152 / 44445 : ℚ) ^ 2 + (-8019158719 / 1760244225 : ℚ) ^ 2 ∧
    (86152 / 44445 : ℚ) ^ 2 + (-8019158719 / 1760244225 : ℚ) ^ 2 < (4.96 : ℚ) ^ 2 ∧
    (-523 / 445 : ℚ) + 86152 / 44445 = 3018581 / 3955605 ∧
    (3072 / 2225 : ℚ) + -8019158719 / 1760244225 = -5588835007 / 1760244225 ∧
    1411 < rosen (3018581 / 3955605 : ℚ) (-5588835007 / 1760244225) ∧
    rosen (3018581 / 3955605 : ℚ) (-5588835007 / 1760244225) < 1412 := by
  norm_num [rosen]

-- The certificate at (1, 1): f = 0, slope 0, Hessian a = 802 and determinant
-- 802 · 200 − (−400)² = 400 > 0; and f, a sum of squares, is never below 0.
example : rosen (1 : ℚ) 1 = 0 ∧ rosenGx (1 : ℚ) 1 = 0 ∧ rosenGy (1 : ℚ) 1 = 0 ∧
    rosenHa (1 : ℚ) 1 = 802 ∧ rosenHa (1 : ℚ) 1 * 200 - rosenHb (1 : ℚ) 1 ^ 2 = 400 := by
  norm_num [rosen, rosenGx, rosenGy, rosenHa, rosenHb]
example (x y : ℝ) : rosen 1 1 ≤ rosen x y := by
  norm_num [rosen]; positivity

#print axioms trust_region_shrinking_ends
#print axioms cauchy_step_guarantee
#print axioms rosenbrock_model_error
