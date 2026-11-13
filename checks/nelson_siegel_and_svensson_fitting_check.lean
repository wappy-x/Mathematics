-- Fitting a curve with four or six parameters: the Svensson zero rate is the average of its forward rate, its dials read as level, start and hump, and a best least-squares fit to bond prices exists when the dials stay in a closed box.
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Topology.Order.Compact
import Mathlib.Order.Interval.Finset.Nat

open Real Filter Topology

/-- Slope loading `L(x) = (1 - e^{-x}) / x`. -/
noncomputable def loadL (x : ℝ) : ℝ := (1 - Real.exp (-x)) / x

/-- Hump loading `H(x) = L(x) - e^{-x}`. -/
noncomputable def loadH (x : ℝ) : ℝ := loadL x - Real.exp (-x)

/-- Svensson forward rate
`f(t) = β₀ + β₁ e^{-t/τ₁} + β₂ (t/τ₁) e^{-t/τ₁} + β₃ (t/τ₂) e^{-t/τ₂}`.
Nelson-Siegel is the case `β₃ = 0`. -/
noncomputable def svFwd (β₀ β₁ β₂ β₃ τ₁ τ₂ t : ℝ) : ℝ :=
  β₀ + β₁ * Real.exp (-t / τ₁) + β₂ * (t / τ₁) * Real.exp (-t / τ₁)
    + β₃ * (t / τ₂) * Real.exp (-t / τ₂)

/-- Svensson zero rate
`R(t) = β₀ + β₁ L(t/τ₁) + β₂ H(t/τ₁) + β₃ H(t/τ₂)`. -/
noncomputable def svZero (β₀ β₁ β₂ β₃ τ₁ τ₂ t : ℝ) : ℝ :=
  β₀ + β₁ * loadL (t / τ₁) + β₂ * loadH (t / τ₁) + β₃ * loadH (t / τ₂)

/-- Model price of a bond paying coupon `c` at years `1, …, n` and 100 at year `n`,
discounted with the zero-rate curve `R`:
`∑_{k=1}^{n} c e^{-k R(k)} + 100 e^{-n R(n)}`. -/
noncomputable def bondPrice (R : ℝ → ℝ) (n : ℕ) (c : ℝ) : ℝ :=
  (∑ k ∈ Finset.Icc 1 n, c * Real.exp (-(k : ℝ) * R k)) + 100 * Real.exp (-(n : ℝ) * R n)

/-- The six dials as one point `p` of `ℝ⁶`: `p 0 … p 3` are `β₀ … β₃`,
`p 4` is `τ₁` and `p 5` is `τ₂`. -/
noncomputable def svZeroOf (p : Fin 6 → ℝ) (t : ℝ) : ℝ :=
  svZero (p 0) (p 1) (p 2) (p 3) (p 4) (p 5) t

/-- Least-squares score `S = ∑ᵢ (P̂ᵢ - Pᵢ)²` of the dials `p` against bonds with
maturities `mat i`, coupons `cpn i` and market prices `mkt i`. -/
noncomputable def fitScore {m : ℕ} (mat : Fin m → ℕ) (cpn mkt : Fin m → ℝ)
    (p : Fin 6 → ℝ) : ℝ :=
  ∑ i, (bondPrice (svZeroOf p) (mat i) (cpn i) - mkt i) ^ 2

lemma hasDerivAt_exp_neg_div (τ s : ℝ) :
    HasDerivAt (fun x : ℝ => Real.exp (-x / τ)) (Real.exp (-s / τ) * (-1 / τ)) s := by
  have h := ((hasDerivAt_id s).neg.div_const τ).exp
  simpa using h

lemma hasDerivAt_hump_prim (τ s : ℝ) (hτ : τ ≠ 0) :
    HasDerivAt (fun x : ℝ => -(x + τ) * Real.exp (-x / τ))
      ((s / τ) * Real.exp (-s / τ)) s := by
  have ha : HasDerivAt (fun x : ℝ => -(x + τ)) (-1) s := ((hasDerivAt_id' s).add_const τ).neg
  have h : HasDerivAt (fun x : ℝ => -(x + τ) * Real.exp (-x / τ))
      (-1 * Real.exp (-s / τ) + -(s + τ) * (Real.exp (-s / τ) * (-1 / τ))) s :=
    ha.mul (hasDerivAt_exp_neg_div τ s)
  convert h using 1
  field_simp
  ring

lemma integral_svFwd (β₀ β₁ β₂ β₃ τ₁ τ₂ t : ℝ) (hτ₁ : τ₁ ≠ 0) (hτ₂ : τ₂ ≠ 0) :
    ∫ s in (0 : ℝ)..t, svFwd β₀ β₁ β₂ β₃ τ₁ τ₂ s
      = β₀ * t + β₁ * τ₁ * (1 - Real.exp (-t / τ₁))
        + β₂ * (τ₁ - (t + τ₁) * Real.exp (-t / τ₁))
        + β₃ * (τ₂ - (t + τ₂) * Real.exp (-t / τ₂)) := by
  let F : ℝ → ℝ := fun x => β₀ * x + β₁ * (-τ₁ * Real.exp (-x / τ₁))
      + β₂ * (-(x + τ₁) * Real.exp (-x / τ₁)) + β₃ * (-(x + τ₂) * Real.exp (-x / τ₂))
  have hF : ∀ s, HasDerivAt F (svFwd β₀ β₁ β₂ β₃ τ₁ τ₂ s) s := by
    intro s
    have h1 := ((hasDerivAt_exp_neg_div τ₁ s).const_mul (-τ₁)).const_mul β₁
    have h0 := (hasDerivAt_id' s).const_mul β₀
    have h2 := (hasDerivAt_hump_prim τ₁ s hτ₁).const_mul β₂
    have h3 := (hasDerivAt_hump_prim τ₂ s hτ₂).const_mul β₃
    have h := ((h0.add h1).add h2).add h3
    convert h using 1
    simp only [svFwd]
    field_simp
  have hc : Continuous (svFwd β₀ β₁ β₂ β₃ τ₁ τ₂) := by
    unfold svFwd; fun_prop
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun s _ => hF s)
    (hc.intervalIntegrable _ _)]
  simp only [F]
  simp
  ring

lemma loadL_tendsto_atTop : Tendsto loadL atTop (𝓝 0) := by
  have h : Tendsto (fun x : ℝ => 1 - Real.exp (-x)) atTop (𝓝 (1 - 0)) :=
    tendsto_const_nhds.sub Real.tendsto_exp_neg_atTop_nhds_zero
  exact h.div_atTop tendsto_id

lemma loadH_tendsto_atTop : Tendsto loadH atTop (𝓝 0) := by
  have h := loadL_tendsto_atTop.sub Real.tendsto_exp_neg_atTop_nhds_zero
  rw [sub_zero] at h
  exact h

lemma loadL_tendsto_zero_right : Tendsto loadL (𝓝[>] 0) (𝓝 1) := by
  have hd : HasDerivAt (fun x : ℝ => 1 - Real.exp (-x)) 1 0 := by
    have h := ((hasDerivAt_id' (0 : ℝ)).neg.exp).const_sub 1
    simpa using h
  have h := hd.tendsto_slope_zero_right
  refine h.congr' ?_
  filter_upwards with t
  simp [loadL, div_eq_inv_mul]

lemma loadH_tendsto_zero_right : Tendsto loadH (𝓝[>] 0) (𝓝 0) := by
  have he : Tendsto (fun x : ℝ => Real.exp (-x)) (𝓝[>] 0) (𝓝 1) := by
    have : Tendsto (fun x : ℝ => Real.exp (-x)) (𝓝 0) (𝓝 (Real.exp (-0))) :=
      (Real.continuous_exp.comp continuous_neg).tendsto 0
    simpa using this.mono_left nhdsWithin_le_nhds
  have h := loadL_tendsto_zero_right.sub he
  rw [sub_self] at h
  exact h

lemma loadH_pos (x : ℝ) (hx : 0 < x) : 0 < loadH x := by
  have h := Real.add_one_lt_exp (neg_ne_zero.mpr hx.ne')
  unfold loadH loadL
  rw [lt_sub_iff_add_lt, zero_add, lt_div_iff₀ hx]
  have h2 : Real.exp (-x) * Real.exp x = 1 := by rw [← Real.exp_add]; simp
  have h3 := Real.add_one_lt_exp hx.ne'
  have h4 := Real.exp_pos (-x)
  nlinarith

lemma loadL_continuousOn_div (t : ℝ) (j : Fin 6) (S : Set (Fin 6 → ℝ))
    (hS : ∀ p ∈ S, 0 < p j) : ContinuousOn (fun p : Fin 6 → ℝ => loadL (t / p j)) S := by
  by_cases ht : t = 0
  · subst ht
    simp only [zero_div]
    exact continuousOn_const
  · unfold loadL
    have hc : ContinuousOn (fun p : Fin 6 → ℝ => t / p j) S :=
      continuousOn_const.div (continuous_apply j).continuousOn
        (fun p hp => (hS p hp).ne')
    refine ContinuousOn.div ?_ hc ?_
    · exact continuousOn_const.sub (Real.continuous_exp.comp_continuousOn hc.neg)
    · intro p hp
      exact div_ne_zero ht (hS p hp).ne'

lemma loadH_continuousOn_div (t : ℝ) (j : Fin 6) (S : Set (Fin 6 → ℝ))
    (hS : ∀ p ∈ S, 0 < p j) : ContinuousOn (fun p : Fin 6 → ℝ => loadH (t / p j)) S := by
  unfold loadH
  refine (loadL_continuousOn_div t j S hS).sub ?_
  exact Real.continuous_exp.comp_continuousOn
    (continuousOn_const.div (continuous_apply j).continuousOn
      (fun p hp => (hS p hp).ne')).neg

lemma svZeroOf_continuousOn (t : ℝ) (S : Set (Fin 6 → ℝ))
    (h4 : ∀ p ∈ S, 0 < p 4) (h5 : ∀ p ∈ S, 0 < p 5) :
    ContinuousOn (fun p => svZeroOf p t) S := by
  unfold svZeroOf svZero
  have c : ∀ j : Fin 6, ContinuousOn (fun p : Fin 6 → ℝ => p j) S :=
    fun j => (continuous_apply j).continuousOn
  exact (((c 0).add ((c 1).mul (loadL_continuousOn_div t 4 S h4))).add
    ((c 2).mul (loadH_continuousOn_div t 4 S h4))).add
    ((c 3).mul (loadH_continuousOn_div t 5 S h5))

/-- Averaging the forward rate gives the zero rate: for positive time scales and any
maturity `t > 0`, `(1/t) ∫₀ᵗ f(s) ds = β₀ + β₁ L(t/τ₁) + β₂ H(t/τ₁) + β₃ H(t/τ₂)`.
So `L` and `H` are the averages of the fading and hump shapes, and the discount
factor `e^{-∫₀ᵗ f}` equals `e^{-t R(t)}`. -/
theorem zero_rate_is_average_of_forward (β₀ β₁ β₂ β₃ τ₁ τ₂ t : ℝ)
    (hτ₁ : 0 < τ₁) (hτ₂ : 0 < τ₂) (ht : 0 < t) :
    (1 / t) * ∫ s in (0 : ℝ)..t, svFwd β₀ β₁ β₂ β₃ τ₁ τ₂ s
        = svZero β₀ β₁ β₂ β₃ τ₁ τ₂ t ∧
      Real.exp (-∫ s in (0 : ℝ)..t, svFwd β₀ β₁ β₂ β₃ τ₁ τ₂ s)
        = Real.exp (-t * svZero β₀ β₁ β₂ β₃ τ₁ τ₂ t) := by
  have h1 : (1 / t) * ∫ s in (0 : ℝ)..t, svFwd β₀ β₁ β₂ β₃ τ₁ τ₂ s
        = svZero β₀ β₁ β₂ β₃ τ₁ τ₂ t := by
    rw [integral_svFwd _ _ _ _ _ _ _ hτ₁.ne' hτ₂.ne']
    simp only [svZero, loadH, loadL, neg_div]
    field_simp
    ring
  refine ⟨h1, ?_⟩
  congr 1
  rw [← h1]
  field_simp

/-- Reading the dials: far out the zero rate settles at the level `β₀`; near today it
starts at `β₀ + β₁` (so the long end minus the short end is `-β₁`); and the hump
loading `H` is positive at every positive `x`. -/
theorem reading_the_dials (β₀ β₁ β₂ β₃ τ₁ τ₂ : ℝ) (hτ₁ : 0 < τ₁) (hτ₂ : 0 < τ₂) :
    Tendsto (svZero β₀ β₁ β₂ β₃ τ₁ τ₂) atTop (𝓝 β₀) ∧
      Tendsto (svZero β₀ β₁ β₂ β₃ τ₁ τ₂) (𝓝[>] 0) (𝓝 (β₀ + β₁)) ∧
      ∀ x : ℝ, 0 < x → 0 < loadH x := by
  have top : ∀ τ : ℝ, 0 < τ → Tendsto (fun t : ℝ => t / τ) atTop atTop :=
    fun τ hτ => tendsto_id.atTop_div_const hτ
  have right : ∀ τ : ℝ, 0 < τ → Tendsto (fun t : ℝ => t / τ) (𝓝[>] 0) (𝓝[>] 0) := by
    intro τ hτ
    apply tendsto_nhdsWithin_of_tendsto_nhds_of_eventually_within
    · have : Tendsto (fun t : ℝ => t / τ) (𝓝 0) (𝓝 (0 / τ)) :=
        (continuous_id.div_const τ).tendsto 0
      simpa using this.mono_left nhdsWithin_le_nhds
    · filter_upwards [self_mem_nhdsWithin] with t ht
      exact div_pos ht hτ
  refine ⟨?_, ?_, loadH_pos⟩
  · have h := ((tendsto_const_nhds (x := β₀)).add
      ((loadL_tendsto_atTop.comp (top τ₁ hτ₁)).const_mul β₁)).add
      ((loadH_tendsto_atTop.comp (top τ₁ hτ₁)).const_mul β₂) |>.add
      ((loadH_tendsto_atTop.comp (top τ₂ hτ₂)).const_mul β₃)
    simp only [mul_zero, mul_one, add_zero, Function.comp_def] at h
    exact h
  · have h := ((tendsto_const_nhds (x := β₀)).add
      ((loadL_tendsto_zero_right.comp (right τ₁ hτ₁)).const_mul β₁)).add
      ((loadH_tendsto_zero_right.comp (right τ₁ hτ₁)).const_mul β₂) |>.add
      ((loadH_tendsto_zero_right.comp (right τ₂ hτ₂)).const_mul β₃)
    simp only [mul_zero, mul_one, add_zero, Function.comp_def] at h
    exact h

/-- A best fit exists: if every dial is kept in a closed range `[lo j, hi j]`, with the
two time scales above a positive floor, then for any bonds and market prices some
setting of the dials in that range has the smallest least-squares score.
(Taking `lo 3 = hi 3 = 0` gives the Nelson-Siegel case.) -/
theorem best_fit_exists {m : ℕ} (mat : Fin m → ℕ) (cpn mkt : Fin m → ℝ)
    (lo hi : Fin 6 → ℝ) (hle : lo ≤ hi) (hτ₁ : 0 < lo 4) (hτ₂ : 0 < lo 5) :
    ∃ p ∈ Set.Icc lo hi, ∀ q ∈ Set.Icc lo hi,
      fitScore mat cpn mkt p ≤ fitScore mat cpn mkt q := by
  have h4 : ∀ p ∈ Set.Icc lo hi, 0 < p 4 := fun p hp => lt_of_lt_of_le hτ₁ (hp.1 4)
  have h5 : ∀ p ∈ Set.Icc lo hi, 0 < p 5 := fun p hp => lt_of_lt_of_le hτ₂ (hp.1 5)
  have hcont : ContinuousOn (fitScore mat cpn mkt) (Set.Icc lo hi) := by
    unfold fitScore bondPrice
    refine continuousOn_finsetSum _ (fun i _ => ?_)
    refine ((ContinuousOn.add ?_ ?_).sub continuousOn_const).pow 2
    · refine continuousOn_finsetSum _ (fun k _ => ?_)
      exact continuousOn_const.mul (Real.continuous_exp.comp_continuousOn
        (continuousOn_const.mul (svZeroOf_continuousOn _ _ h4 h5)))
    · exact continuousOn_const.mul (Real.continuous_exp.comp_continuousOn
        (continuousOn_const.mul (svZeroOf_continuousOn _ _ h4 h5)))
  obtain ⟨p, hp, hmin⟩ :=
    isCompact_Icc.exists_isMinOn (Set.nonempty_Icc.mpr hle) hcont
  exact ⟨p, hp, fun q hq => hmin hq⟩

/-- The twelve bonds (maturities 1, 2, 3, 4, 5, 7, 10, 12, 15, 20, 25, 30, paying once
a year) pay on thirty different dates. -/
example :
    (({1, 2, 3, 4, 5, 7, 10, 12, 15, 20, 25, 30} : Finset ℕ).biUnion
      (fun n => Finset.Icc 1 n)).card = 30 := by
  decide +kernel

#print axioms zero_rate_is_average_of_forward
#print axioms reading_the_dials
#print axioms best_fit_exists
#print axioms hasDerivAt_exp_neg_div
#print axioms hasDerivAt_hump_prim
#print axioms integral_svFwd
#print axioms loadL_tendsto_atTop
#print axioms loadH_tendsto_atTop
#print axioms loadL_tendsto_zero_right
#print axioms loadH_tendsto_zero_right
#print axioms loadH_pos
#print axioms loadL_continuousOn_div
#print axioms loadH_continuousOn_div
#print axioms svZeroOf_continuousOn
