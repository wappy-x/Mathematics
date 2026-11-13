-- Beyond one factor: in G2++ with two shocks that fade at different speeds, any two different maturities have correlation strictly between -1 and 1, by an exact determinant identity, while a one-factor Hull-White model gives every pair of maturities correlation exactly 1.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Convex.SpecificFunctions.Pow
import Mathlib.Analysis.Convex.Slope

namespace TwoFactorShortRate

open Real

/-! Setting. The card works with the instantaneous covariance of bond log prices, not with the
paths themselves: over a short step the `u`-year bond's log price moves by
`-σ B_a(u) dW¹ - η B_b(u) dW²`, with `dW¹ dW² = ρ dt`. Multiplying two such moves and keeping the
`dt` terms gives the card's `C(u, v)`, and the correlation is `C(u,v)/√(C(u,u) C(v,v))`.
Dividing by `u` and `v` to pass from bonds to yields changes no correlation. -/

/-- The loading `B_c(u) = (1 - e^(-c u))/c`: how far a `u`-year bond's log price falls per unit
rise in a factor that fades at speed `c`. -/
noncomputable def loading (c u : ℝ) : ℝ := (1 - exp (-c * u)) / c

/-- G2++: the rate `C(u, v)` at which the `u`-year and `v`-year bonds' log prices co-vary,
`σ² B_a(u)B_a(v) + η² B_b(u)B_b(v) + ρ σ η [B_a(u)B_b(v) + B_b(u)B_a(v)]`. -/
noncomputable def g2Cov (a b σ η ρ u v : ℝ) : ℝ :=
  σ ^ 2 * loading a u * loading a v + η ^ 2 * loading b u * loading b v
    + ρ * σ * η * (loading a u * loading b v + loading b u * loading a v)

/-- G2++: the instantaneous correlation `C(u,v)/√(C(u,u) C(v,v))` of the `u`-year and `v`-year
bonds (and so of their yields). -/
noncomputable def g2Corr (a b σ η ρ u v : ℝ) : ℝ :=
  g2Cov a b σ η ρ u v / sqrt (g2Cov a b σ η ρ u u * g2Cov a b σ η ρ v v)

/-- Hull-White, one factor: the covariance `σ² B(u) B(v)` of the `u`-year and `v`-year bonds'
log prices, with `B = B_a` the loading at reversion speed `a`. -/
noncomputable def hwCov (a σ u v : ℝ) : ℝ := σ ^ 2 * loading a u * loading a v

/-- Hull-White: the instantaneous correlation `C(u,v)/√(C(u,u) C(v,v))`. -/
noncomputable def hwCorr (a σ u v : ℝ) : ℝ :=
  hwCov a σ u v / sqrt (hwCov a σ u u * hwCov a σ v v)

/-- Helper: for `0 < a < b` and `0 < u < v`, the cross products of `1 - e^(-c t)` are strictly
ordered (strict concavity of `x ↦ x^(a/b)`). -/
lemma cross_lt {a b u v : ℝ} (ha : 0 < a) (hab : a < b) (hu : 0 < u) (huv : u < v) :
    (1 - exp (-a * u)) * (1 - exp (-b * v)) < (1 - exp (-a * v)) * (1 - exp (-b * u)) := by
  have hb : 0 < b := ha.trans hab
  have hv : 0 < v := hu.trans huv
  have hr0 : 0 < a / b := div_pos ha hb
  have hr1 : a / b < 1 := (div_lt_one hb).2 hab
  have hconc := Real.strictConcaveOn_rpow hr0 hr1
  set x := exp (-b * v) with hxdef
  set y := exp (-b * u) with hydef
  have hx0 : 0 < x := exp_pos _
  have hy0 : 0 < y := exp_pos _
  have hxy : x < y := by
    rw [hxdef, hydef]; apply exp_lt_exp.2; nlinarith
  have hy1 : y < 1 := by
    rw [hydef]; apply Real.exp_lt_one_iff.2
    nlinarith
  have hx1 : x < 1 := hxy.trans hy1
  have key := hconc.secant_strict_mono (a := 1) (x := x) (y := y)
    (by simp) (Set.mem_Ici.2 hx0.le) (Set.mem_Ici.2 hy0.le) hx1.ne hy1.ne hxy
  have ex : x ^ (a / b) = exp (-a * v) := by
    rw [hxdef, ← Real.exp_mul]; congr 1; field_simp
  have ey : y ^ (a / b) = exp (-a * u) := by
    rw [hydef, ← Real.exp_mul]; congr 1; field_simp
  simp only [Real.one_rpow] at key
  rw [ex, ey] at key
  have h1 : 0 < 1 - x := by linarith
  have h2 : 0 < 1 - y := by linarith
  have key' : (1 - exp (-a * u)) / (1 - y) < (1 - exp (-a * v)) / (1 - x) := by
    have e1 : (exp (-a * u) - 1) / (y - 1) = (1 - exp (-a * u)) / (1 - y) := by
      rw [← neg_div_neg_eq]; ring_nf
    have e2 : (exp (-a * v) - 1) / (x - 1) = (1 - exp (-a * v)) / (1 - x) := by
      rw [← neg_div_neg_eq]; ring_nf
    rw [← e1, ← e2]; exact key
  rw [div_lt_div_iff₀ h2 h1] at key'
  linarith

#print axioms cross_lt

/-- Helper: the loadings are positive for positive speed and maturity. -/
lemma loading_pos {c u : ℝ} (hc : 0 < c) (hu : 0 < u) : 0 < loading c u := by
  unfold loading
  apply div_pos _ hc
  have : exp (-c * u) < 1 := Real.exp_lt_one_iff.2 (by nlinarith)
  linarith

#print axioms loading_pos

/-- Helper: distinct speeds give a nonzero loading determinant. -/
lemma loading_det_ne {a b u v : ℝ} (ha : 0 < a) (hb : 0 < b) (hab : a ≠ b) (hu : 0 < u)
    (huv : u < v) : loading a u * loading b v - loading a v * loading b u ≠ 0 := by
  have e : loading a u * loading b v - loading a v * loading b u
      = ((1 - exp (-a * u)) * (1 - exp (-b * v)) - (1 - exp (-a * v)) * (1 - exp (-b * u)))
        / (a * b) := by
    unfold loading; field_simp
  rw [e]
  apply div_ne_zero _ (mul_pos ha hb).ne'
  rcases lt_or_gt_of_ne hab with h | h
  · have := cross_lt ha h hu huv; linarith
  · have := cross_lt hb h hu huv; linarith

#print axioms loading_det_ne

/-- Helper: the covariance determinant identity (same as the theorem below, needed earlier). -/
lemma cov_det_aux (a b σ η ρ u v : ℝ) :
    g2Cov a b σ η ρ u u * g2Cov a b σ η ρ v v - g2Cov a b σ η ρ u v ^ 2
      = σ ^ 2 * η ^ 2 * (1 - ρ ^ 2)
          * (loading a u * loading b v - loading a v * loading b u) ^ 2 := by
  unfold g2Cov
  ring

#print axioms cov_det_aux

/-- **G2++ correlations are below one** (the card's main claim). Take reversion speeds `a, b > 0`
that differ, shock sizes `σ, η > 0`, a shock correlation `ρ` with `|ρ| < 1`, and two maturities
`0 < u < v`. Then the correlation of the `u`-year and `v`-year bonds (equally, yields) satisfies
`|corr(u, v)| < 1`: the two maturities do not move in perfect step, so the curve can twist. -/
theorem g2_correlation_lt_one {a b σ η ρ u v : ℝ} (ha : 0 < a) (hb : 0 < b) (hab : a ≠ b)
    (hσ : 0 < σ) (hη : 0 < η) (hρ : |ρ| < 1) (hu : 0 < u) (huv : u < v) :
    |g2Corr a b σ η ρ u v| < 1 := by
  have hdet := cov_det_aux a b σ η ρ u v
  have hD := loading_det_ne ha hb hab hu huv
  have hρ2 : 0 < 1 - ρ ^ 2 := by
    have : ρ ^ 2 < 1 := by
      rw [← sq_abs]; nlinarith [abs_nonneg ρ]
    linarith
  have hpos : 0 < σ ^ 2 * η ^ 2 * (1 - ρ ^ 2)
      * (loading a u * loading b v - loading a v * loading b u) ^ 2 := by
    have := pow_pos (abs_pos.2 hD) 2
    rw [sq_abs] at this
    positivity
  have hlt : g2Cov a b σ η ρ u v ^ 2 < g2Cov a b σ η ρ u u * g2Cov a b σ η ρ v v := by
    linarith
  have hPQ : 0 < g2Cov a b σ η ρ u u * g2Cov a b σ η ρ v v :=
    lt_of_le_of_lt (sq_nonneg _) hlt
  unfold g2Corr
  rw [abs_div, abs_of_pos (Real.sqrt_pos.2 hPQ), div_lt_one (Real.sqrt_pos.2 hPQ)]
  exact (Real.lt_sqrt (abs_nonneg _)).2 (by rw [sq_abs]; exact hlt)

/-- **The covariance determinant identity** (the card's detailed proof). For any shock sizes
`σ, η`, shock correlation `ρ`, speeds `a, b` and maturities `u, v`,
`C(u,u) C(v,v) - C(u,v)² = σ² η² (1 - ρ²) [B_a(u) B_b(v) - B_a(v) B_b(u)]²`. -/
theorem g2_covariance_determinant (a b σ η ρ u v : ℝ) :
    g2Cov a b σ η ρ u u * g2Cov a b σ η ρ v v - g2Cov a b σ η ρ u v ^ 2
      = σ ^ 2 * η ^ 2 * (1 - ρ ^ 2)
          * (loading a u * loading b v - loading a v * loading b u) ^ 2 := by
  unfold g2Cov
  ring

/-- **One factor forces correlation one** (the card's Step 1). In Hull-White with reversion speed
`a > 0` and shock size `σ > 0`, any two maturities `u, v > 0` have correlation exactly 1: every
bond moves by a fixed positive multiple of the same single shock. -/
theorem hull_white_correlation_eq_one {a σ u v : ℝ} (ha : 0 < a) (hσ : 0 < σ)
    (hu : 0 < u) (hv : 0 < v) :
    hwCorr a σ u v = 1 := by
  have hu' := loading_pos ha hu
  have hv' := loading_pos ha hv
  have hc : 0 < hwCov a σ u v := by unfold hwCov; positivity
  have e : hwCov a σ u u * hwCov a σ v v = hwCov a σ u v ^ 2 := by unfold hwCov; ring
  unfold hwCorr
  rw [e, Real.sqrt_sq hc.le, div_self hc.ne']

#print axioms g2_correlation_lt_one
#print axioms g2_covariance_determinant
#print axioms hull_white_correlation_eq_one

end TwoFactorShortRate
