-- Stochastic control: Merton's value function solves the HJB equation, with the best fraction in shares at the unique top of a concave hill, while dropping the noise term leaves a ramp with no top.
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Tactic

/-- Certainty-equivalent growth per year of keeping the fixed fraction `p` (the card's `π`) in shares:
bank rate, plus the shares' extra return, minus half of risk aversion times variance times `p²`. -/
noncomputable def ceGrowth (r μ σ γ p : ℝ) : ℝ :=
  r + p * (μ - r) - 1 / 2 * γ * σ ^ 2 * p ^ 2

/-- Merton's best fraction in shares, `(μ - r) / (γ σ²)`. -/
noncomputable def mertonFraction (r μ σ γ : ℝ) : ℝ :=
  (μ - r) / (γ * σ ^ 2)

/-- Merton's best certainty-equivalent growth, `r + (μ - r)² / (2 γ σ²)`. -/
noncomputable def mertonGrowth (r μ σ γ : ℝ) : ℝ :=
  r + (μ - r) ^ 2 / (2 * γ * σ ^ 2)

/-- Merton's value function `V(t, x) = U(x) · exp((1 - γ) g* (T - t))`
with power utility `U(x) = x^(1-γ) / (1-γ)`. -/
noncomputable def mertonV (r μ σ γ T t x : ℝ) : ℝ :=
  x ^ (1 - γ) / (1 - γ) * Real.exp ((1 - γ) * mertonGrowth r μ σ γ * (T - t))

/-- The HJB expression `V_t + b V_x + ½ s² V_xx` for the fortune, with drift
`b = x (r + π (μ - r))` and noise size `s = x π σ`, at time `t`, fortune `x`, fraction `p` (the card's `π`).
The derivatives are Mathlib's `deriv`, taken of Merton's `V`. -/
noncomputable def hjbExpr (r μ σ γ T t x p : ℝ) : ℝ :=
  deriv (fun s => mertonV r μ σ γ T s x) t
    + x * (r + p * (μ - r)) * deriv (fun y => mertonV r μ σ γ T t y) x
    + 1 / 2 * (x * p * σ) ^ 2 * deriv (deriv (fun y => mertonV r μ σ γ T t y)) x

/-- The same expression done with the ordinary chain rule: the noise term `½ s² V_xx` dropped. -/
noncomputable def noiselessExpr (r μ σ γ T t x p : ℝ) : ℝ :=
  deriv (fun s => mertonV r μ σ γ T s x) t
    + x * (r + p * (μ - r)) * deriv (fun y => mertonV r μ σ γ T t y) x

lemma powScaled_hasDerivAt (a c x : ℝ) (ha : a ≠ 0) (hx : 0 < x) :
    HasDerivAt (fun y : ℝ => y ^ a / a * c) (x ^ (a - 1) * c) x := by
  have h := ((Real.hasDerivAt_rpow_const (p := a) (Or.inl hx.ne')).div_const a).mul_const c
  convert h using 1
  field_simp

lemma powScaled_deriv2 (a c x : ℝ) (ha : a ≠ 0) (hx : 0 < x) :
    deriv (deriv (fun y : ℝ => y ^ a / a * c)) x = (a - 1) * x ^ (a - 2) * c := by
  have heq : deriv (fun y : ℝ => y ^ a / a * c) =ᶠ[nhds x] fun y => y ^ (a - 1) * c := by
    filter_upwards [lt_mem_nhds hx] with y hy
    exact (powScaled_hasDerivAt a c y ha hy).deriv
  rw [heq.deriv_eq]
  have h := (Real.hasDerivAt_rpow_const (p := a - 1) (Or.inl hx.ne')).mul_const c
  rw [h.deriv]
  ring_nf

lemma timeExp_hasDerivAt (k T t : ℝ) :
    HasDerivAt (fun s : ℝ => Real.exp (k * (T - s))) (Real.exp (k * (T - t)) * (-k)) t := by
  have h1 : HasDerivAt (fun s : ℝ => k * (T - s)) (-k) t := by
    have := ((hasDerivAt_id t).const_sub T).const_mul k
    convert this using 1 <;> first | rfl | ring
  exact h1.exp

lemma mertonV_deriv_t (r μ σ γ T t x : ℝ) (hγ1 : γ ≠ 1) :
    deriv (fun s => mertonV r μ σ γ T s x) t
      = -mertonGrowth r μ σ γ * x ^ (1 - γ) * Real.exp ((1 - γ) * mertonGrowth r μ σ γ * (T - t)) := by
  have ha : (1 - γ) ≠ 0 := sub_ne_zero.mpr (Ne.symm hγ1)
  have h := (timeExp_hasDerivAt ((1 - γ) * mertonGrowth r μ σ γ) T t).const_mul (x ^ (1 - γ) / (1 - γ))
  unfold mertonV
  rw [h.deriv]
  field_simp

lemma mertonV_deriv_x (r μ σ γ T t x : ℝ) (hγ1 : γ ≠ 1) (hx : 0 < x) :
    x * deriv (fun y => mertonV r μ σ γ T t y) x
      = x ^ (1 - γ) * Real.exp ((1 - γ) * mertonGrowth r μ σ γ * (T - t)) := by
  have ha : (1 - γ) ≠ 0 := sub_ne_zero.mpr (Ne.symm hγ1)
  unfold mertonV
  rw [(powScaled_hasDerivAt (1 - γ) _ x ha hx).deriv, Real.rpow_sub hx, Real.rpow_one]
  field_simp

lemma mertonV_deriv_xx (r μ σ γ T t x : ℝ) (hγ1 : γ ≠ 1) (hx : 0 < x) :
    x ^ 2 * deriv (deriv (fun y => mertonV r μ σ γ T t y)) x
      = -γ * x ^ (1 - γ) * Real.exp ((1 - γ) * mertonGrowth r μ σ γ * (T - t)) := by
  have ha : (1 - γ) ≠ 0 := sub_ne_zero.mpr (Ne.symm hγ1)
  unfold mertonV
  rw [powScaled_deriv2 (1 - γ) _ x ha hx, Real.rpow_sub hx, Real.rpow_two]
  field_simp
  ring

lemma hjbExpr_eq (r μ σ γ T t x p : ℝ) (hγ1 : γ ≠ 1) (hx : 0 < x) :
    hjbExpr r μ σ γ T t x p
      = x ^ (1 - γ) * Real.exp ((1 - γ) * mertonGrowth r μ σ γ * (T - t))
        * (ceGrowth r μ σ γ p - mertonGrowth r μ σ γ) := by
  have h1 := mertonV_deriv_t r μ σ γ T t x hγ1
  have h2 := mertonV_deriv_x r μ σ γ T t x hγ1 hx
  have h3 := mertonV_deriv_xx r μ σ γ T t x hγ1 hx
  unfold hjbExpr ceGrowth
  have e2 : x * (r + p * (μ - r)) * deriv (fun y => mertonV r μ σ γ T t y) x
      = (r + p * (μ - r)) * (x * deriv (fun y => mertonV r μ σ γ T t y) x) := by ring
  have e3 : 1 / 2 * (x * p * σ) ^ 2 * deriv (deriv (fun y => mertonV r μ σ γ T t y)) x
      = 1 / 2 * p ^ 2 * σ ^ 2 * (x ^ 2 * deriv (deriv (fun y => mertonV r μ σ γ T t y)) x) := by ring
  rw [e2, e3, h1, h2, h3]
  ring

lemma noiselessExpr_eq (r μ σ γ T t x p : ℝ) (hγ1 : γ ≠ 1) (hx : 0 < x) :
    noiselessExpr r μ σ γ T t x p
      = x ^ (1 - γ) * Real.exp ((1 - γ) * mertonGrowth r μ σ γ * (T - t))
        * (r + p * (μ - r) - mertonGrowth r μ σ γ) := by
  have h1 := mertonV_deriv_t r μ σ γ T t x hγ1
  have h2 := mertonV_deriv_x r μ σ γ T t x hγ1 hx
  unfold noiselessExpr
  have e2 : x * (r + p * (μ - r)) * deriv (fun y => mertonV r μ σ γ T t y) x
      = (r + p * (μ - r)) * (x * deriv (fun y => mertonV r μ σ γ T t y) x) := by ring
  rw [e2, h1, h2]
  ring

lemma ceGrowth_gap (r μ σ γ p : ℝ) (hσ : 0 < σ) (hγ : 0 < γ) :
    mertonGrowth r μ σ γ - ceGrowth r μ σ γ p
      = 1 / 2 * γ * σ ^ 2 * (p - mertonFraction r μ σ γ) ^ 2 := by
  unfold mertonGrowth ceGrowth mertonFraction
  have : γ * σ ^ 2 ≠ 0 := by positivity
  field_simp
  ring

lemma ce_growth_hill_aux (r μ σ γ : ℝ) (hσ : 0 < σ) (hγ : 0 < γ) :
    (∀ p : ℝ, ceGrowth r μ σ γ p ≤ mertonGrowth r μ σ γ) ∧
    (∀ p : ℝ, ceGrowth r μ σ γ p = mertonGrowth r μ σ γ ↔ p = mertonFraction r μ σ γ) := by
  have hc : 0 < 1 / 2 * γ * σ ^ 2 := by positivity
  refine ⟨fun p => ?_, fun p => ?_⟩
  · have := ceGrowth_gap r μ σ γ p hσ hγ
    nlinarith [sq_nonneg (p - mertonFraction r μ σ γ)]
  · have := ceGrowth_gap r μ σ γ p hσ hγ
    constructor
    · intro h
      have h0 : 1 / 2 * γ * σ ^ 2 * (p - mertonFraction r μ σ γ) ^ 2 = 0 := by linarith
      rcases mul_eq_zero.mp h0 with h0 | h0
      · linarith
      · exact sub_eq_zero.mp (pow_eq_zero_iff (n := 2) (by norm_num) |>.mp h0)
    · intro h
      subst h
      have h0 : (0:ℝ) ^ 2 = 0 := by norm_num
      rw [sub_self, h0, mul_zero] at this
      linarith

#print axioms powScaled_hasDerivAt
#print axioms powScaled_deriv2
#print axioms timeExp_hasDerivAt
#print axioms mertonV_deriv_t
#print axioms mertonV_deriv_x
#print axioms mertonV_deriv_xx
#print axioms hjbExpr_eq
#print axioms noiselessExpr_eq
#print axioms ceGrowth_gap
#print axioms ce_growth_hill_aux

/-- Merton's problem solved by HJB. For power utility with risk aversion `γ > 0`, `γ ≠ 1`, shares
with volatility `σ > 0`, and any positive fortune `x` at any time `t`, Merton's value function
satisfies the HJB equation: no fraction `π` makes `V_t + b V_x + ½ s² V_xx` positive, the
fraction `π* = (μ - r)/(γ σ²)` makes it exactly zero and is the only one that does, and at the
horizon `V(T, x) = U(x)`. -/
theorem merton_value_solves_hjb (r μ σ γ T t x : ℝ) (hσ : 0 < σ) (hγ : 0 < γ) (hγ1 : γ ≠ 1)
    (hx : 0 < x) :
    (∀ p : ℝ, hjbExpr r μ σ γ T t x p ≤ 0) ∧
    (∀ p : ℝ, hjbExpr r μ σ γ T t x p = 0 ↔ p = mertonFraction r μ σ γ) ∧
    mertonV r μ σ γ T T x = x ^ (1 - γ) / (1 - γ) := by
  have hpos : 0 < x ^ (1 - γ) * Real.exp ((1 - γ) * mertonGrowth r μ σ γ * (T - t)) := by
    have := Real.rpow_pos_of_pos hx (1 - γ)
    positivity
  obtain ⟨hle, hiff⟩ := ce_growth_hill_aux r μ σ γ hσ hγ
  refine ⟨fun p => ?_, fun p => ?_, ?_⟩
  · rw [hjbExpr_eq r μ σ γ T t x p hγ1 hx]
    exact mul_nonpos_of_nonneg_of_nonpos hpos.le (by linarith [hle p])
  · rw [hjbExpr_eq r μ σ γ T t x p hγ1 hx, ← hiff p, mul_eq_zero, sub_eq_zero]
    constructor
    · rintro (h | h)
      · exact absurd h hpos.ne'
      · exact h
    · exact Or.inr
  · unfold mertonV
    simp

/-- The hill: for `γ > 0` and `σ > 0`, the certainty-equivalent growth of a fixed fraction is
at most `g* = r + (μ - r)²/(2 γ σ²)`, and it reaches `g*` only at `π* = (μ - r)/(γ σ²)`. -/
theorem ce_growth_hill_top (r μ σ γ : ℝ) (hσ : 0 < σ) (hγ : 0 < γ) :
    (∀ p : ℝ, ceGrowth r μ σ γ p ≤ mertonGrowth r μ σ γ) ∧
    (∀ p : ℝ, ceGrowth r μ σ γ p = mertonGrowth r μ σ γ ↔ p = mertonFraction r μ σ γ) := by
  exact ce_growth_hill_aux r μ σ γ hσ hγ

/-- The usual mistake: with the ordinary chain rule (the noise term dropped) and shares that beat
the bank (`μ > r`), the HJB expression strictly increases with the fraction in shares, so more
shares always look better and no fraction is best. -/
theorem noiseless_hjb_has_no_best_fraction (r μ σ γ T t x : ℝ)
    (hγ1 : γ ≠ 1) (hx : 0 < x) (hμ : r < μ) :
    StrictMono (fun p => noiselessExpr r μ σ γ T t x p) ∧
    ¬ ∃ p₀ : ℝ, ∀ p : ℝ, noiselessExpr r μ σ γ T t x p ≤ noiselessExpr r μ σ γ T t x p₀ := by
  have hpos : 0 < x ^ (1 - γ) * Real.exp ((1 - γ) * mertonGrowth r μ σ γ * (T - t)) := by
    have := Real.rpow_pos_of_pos hx (1 - γ)
    positivity
  have hmono : StrictMono (fun p => noiselessExpr r μ σ γ T t x p) := by
    intro a b hab
    simp only [noiselessExpr_eq r μ σ γ T t x _ hγ1 hx]
    apply mul_lt_mul_of_pos_left _ hpos
    nlinarith
  refine ⟨hmono, ?_⟩
  rintro ⟨p₀, hp₀⟩
  have h1 := hmono (lt_add_one p₀)
  have h2 := hp₀ (p₀ + 1)
  simp only at h1
  linarith

-- The card's numbers, exactly, as fractions: r = 3/100, μ = 8/100, σ = 25/100, γ = 2.
-- Best fraction: 0.05 / 0.125 = 0.4.
example : ((8 : ℚ) / 100 - 3 / 100) / (2 * (25 / 100) ^ 2) = 2 / 5 := by norm_num
-- Dollars in shares today: 0.4 × 200,000 = 80,000.
example : (2 : ℚ) / 5 * 200000 = 80000 := by norm_num
-- Best CE growth: 0.03 + 0.05² / (2 × 2 × 0.0625) = 0.04.
example : (3 : ℚ) / 100 + (5 / 100) ^ 2 / (2 * 2 * (25 / 100) ^ 2) = 4 / 100 := by norm_num
-- The hill, g(π) = 0.03 + 0.05 π − 0.0625 π², at π = 0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2:
-- 3.00, 3.75, 4.00, 3.75, 3.00, 1.75, 0.00 percent a year.
example : (fun p : ℚ => 3 / 100 + p * (5 / 100) - 1 / 2 * 2 * (25 / 100) ^ 2 * p ^ 2) 0 = 300 / 10000 := by norm_num
example : (fun p : ℚ => 3 / 100 + p * (5 / 100) - 1 / 2 * 2 * (25 / 100) ^ 2 * p ^ 2) (1 / 5) = 375 / 10000 := by norm_num
example : (fun p : ℚ => 3 / 100 + p * (5 / 100) - 1 / 2 * 2 * (25 / 100) ^ 2 * p ^ 2) (2 / 5) = 400 / 10000 := by norm_num
example : (fun p : ℚ => 3 / 100 + p * (5 / 100) - 1 / 2 * 2 * (25 / 100) ^ 2 * p ^ 2) (3 / 5) = 375 / 10000 := by norm_num
example : (fun p : ℚ => 3 / 100 + p * (5 / 100) - 1 / 2 * 2 * (25 / 100) ^ 2 * p ^ 2) (4 / 5) = 300 / 10000 := by norm_num
example : (fun p : ℚ => 3 / 100 + p * (5 / 100) - 1 / 2 * 2 * (25 / 100) ^ 2 * p ^ 2) 1 = 175 / 10000 := by norm_num
example : (fun p : ℚ => 3 / 100 + p * (5 / 100) - 1 / 2 * 2 * (25 / 100) ^ 2 * p ^ 2) (6 / 5) = 0 := by norm_num
-- Mistakes: σ for σ² gives 0.05 / (2 × 0.25) = 0.1; risk aversion 1 gives 0.05 / 0.0625 = 0.8.
example : ((5 : ℚ) / 100) / (2 * (25 / 100)) = 1 / 10 := by norm_num
example : ((5 : ℚ) / 100) / (1 * (25 / 100) ^ 2) = 4 / 5 := by norm_num
-- HJB residual (g(π) − g*)/g*: ordinary chain rule at π = 0.4, 1, 10, 100 gives 0.25, 1, 12.25, 124.75;
-- with the Ito term at π = 1 and 10 it gives −0.5625 and −144.
example : (fun p : ℚ => (3 / 100 + p * (5 / 100) - 4 / 100) / (4 / 100)) (2 / 5) = 1 / 4 := by norm_num
example : (fun p : ℚ => (3 / 100 + p * (5 / 100) - 4 / 100) / (4 / 100)) 1 = 1 := by norm_num
example : (fun p : ℚ => (3 / 100 + p * (5 / 100) - 4 / 100) / (4 / 100)) 10 = 1225 / 100 := by norm_num
example : (fun p : ℚ => (3 / 100 + p * (5 / 100) - 4 / 100) / (4 / 100)) 100 = 12475 / 100 := by norm_num
example : (fun p : ℚ => (3 / 100 + p * (5 / 100) - (25 / 100) ^ 2 * p ^ 2 - 4 / 100) / (4 / 100)) 1
    = -5625 / 10000 := by norm_num
example : (fun p : ℚ => (3 / 100 + p * (5 / 100) - (25 / 100) ^ 2 * p ^ 2 - 4 / 100) / (4 / 100)) 10
    = -144 := by norm_num

#print axioms merton_value_solves_hjb
#print axioms ce_growth_hill_top
#print axioms noiseless_hjb_has_no_best_fraction
