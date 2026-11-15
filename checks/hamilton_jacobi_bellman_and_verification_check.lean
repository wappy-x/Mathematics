-- The HJB equation: a function with continuous first derivatives that solves the HJB equation and is zero on arrival is a lower bound for the fuel of every allowed trip and equals the fuel of a trip driven at its best speed, and the card's two-piece guess solves the equation.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.Analysis.Convex.Function
import Mathlib.Analysis.Calculus.FDeriv.Prod
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Calculus.FDeriv.Mul
import Mathlib.MeasureTheory.Integral.DominatedConvergence

open Set Filter Topology MeasureTheory

/-- An allowed trip from the state with `τ` hours left and `x` km left, for the fuel burn rate `F`
(litres per hour as a function of speed). The car drives at speed `u t ≥ 0` at clock time `t`;
`X t` is the distance left, continuous, falling at rate `u t` as the clock moves forward
(a right derivative, so speeds may jump, as on a grid of schedules). The car has not arrived
before time `θ`, arrives at `θ`, and `θ` is within the deadline `τ`. The distance it drives,
`∫ t in 0..θ, u t`, and its fuel, `∫ t in 0..θ, F (u t)`, are finite. -/
def AllowedTrip (F : ℝ → ℝ) (τ x θ : ℝ) (u X : ℝ → ℝ) : Prop :=
  0 ≤ θ ∧ θ ≤ τ ∧ X 0 = x ∧ X θ = 0 ∧ (∀ t ∈ Ico 0 θ, 0 < X t) ∧
    ContinuousOn X (Icc 0 θ) ∧ (∀ t ∈ Ico 0 θ, HasDerivWithinAt X (-u t) (Ioi t) t) ∧
    (∀ t ∈ Ico 0 θ, 0 ≤ u t) ∧ IntervalIntegrable u volume 0 θ ∧
    IntervalIntegrable (fun t => F (u t)) volume 0 θ

/-- Chain rule along a trip: the right derivative of `s ↦ W (T - s, X s)`. -/
lemma hjb_path_deriv (W : ℝ × ℝ → ℝ) (hC1 : ContDiffOn ℝ 1 W {q | 0 < q.1 ∧ 0 < q.2})
    (T : ℝ) (X : ℝ → ℝ) (v t : ℝ) (hX : HasDerivWithinAt X (-v) (Ioi t) t)
    (h1 : 0 < T - t) (h2 : 0 < X t) :
    HasDerivWithinAt (fun s => W (T - s, X s))
      (-(fderiv ℝ W (T - t, X t) (1, 0)) - v * fderiv ℝ W (T - t, X t) (0, 1)) (Ioi t) t := by
  have hopen : IsOpen {q : ℝ × ℝ | 0 < q.1 ∧ 0 < q.2} :=
    (isOpen_lt continuous_const continuous_fst).inter (isOpen_lt continuous_const continuous_snd)
  have hdiff : DifferentiableAt ℝ W (T - t, X t) :=
    (hC1.differentiableOn one_ne_zero).differentiableAt (hopen.mem_nhds ⟨h1, h2⟩)
  have hγ : HasDerivWithinAt (fun s => (T - s, X s)) ((-1 : ℝ), -v) (Ioi t) t :=
    ((hasDerivAt_id' t).const_sub T).hasDerivWithinAt.prodMk hX
  have := hdiff.hasFDerivAt.comp_hasDerivWithinAt t hγ
  refine HasDerivWithinAt.congr_deriv this ?_
  have e : ((-1 : ℝ), -v) = (-1 : ℝ) • ((1 : ℝ), (0 : ℝ)) + (-v) • ((0 : ℝ), (1 : ℝ)) := by
    ext <;> simp
  rw [e, map_add, map_smul, map_smul, smul_eq_mul, smul_eq_mul]
  ring

/-- Part 1 with a strictly later deadline `T > θ`. -/
lemma hjb_lower (F : ℝ → ℝ) (W : ℝ × ℝ → ℝ)
    (hC1 : ContDiffOn ℝ 1 W {q | 0 < q.1 ∧ 0 < q.2})
    (hcont : ContinuousOn W {q | 0 < q.1 ∧ 0 ≤ q.2})
    (hzero : ∀ s, 0 ≤ s → W (s, 0) = 0)
    (hHJB : ∀ q : ℝ × ℝ, 0 < q.1 → 0 < q.2 →
      IsLeast ((fun u => F u - fderiv ℝ W q (0, 1) * u) '' Ici 0) (fderiv ℝ W q (1, 0)))
    (T θ x : ℝ) (u X : ℝ → ℝ) (hθT : θ < T) (hθ0 : 0 ≤ θ)
    (hX0 : X 0 = x) (hXθ : X θ = 0) (hpos : ∀ t ∈ Ico 0 θ, 0 < X t)
    (hXc : ContinuousOn X (Icc 0 θ))
    (hXd : ∀ t ∈ Ico 0 θ, HasDerivWithinAt X (-u t) (Ioi t) t)
    (hu : ∀ t ∈ Ico 0 θ, 0 ≤ u t)
    (hFi : IntervalIntegrable (fun t => F (u t)) volume 0 θ) :
    W (T, x) ≤ ∫ t in (0)..θ, F (u t) := by
  have hgc : ContinuousOn (fun s => W (T - s, X s)) (Icc 0 θ) := by
    refine hcont.comp ((continuousOn_const.sub continuousOn_id).prodMk hXc) ?_
    intro t ht
    refine ⟨by simp only; linarith [ht.2], ?_⟩
    rcases ht.2.lt_or_eq with h | h
    · exact (hpos t ⟨ht.1, h⟩).le
    · simp only; rw [h, hXθ]
  have key := intervalIntegral.integral_le_sub_of_hasDeriv_right_of_le (φ := fun t => -F (u t))
    hθ0 hgc
    (fun t ht => hjb_path_deriv W hC1 T X (u t) t (hXd t ⟨ht.1.le, ht.2⟩) (by linarith [ht.2])
      (hpos t ⟨ht.1.le, ht.2⟩))
    ((intervalIntegrable_iff_integrableOn_Icc_of_le hθ0).mp hFi.neg)
    (fun t ht => by
      have hq := (hHJB (T - t, X t) (by simp only; linarith [ht.2])
        (hpos t ⟨ht.1.le, ht.2⟩)).2 ⟨u t, hu t ⟨ht.1.le, ht.2⟩, rfl⟩
      simp only at hq
      linarith)
  simp only [intervalIntegral.integral_neg, sub_zero, hX0, hXθ] at key
  rw [hzero _ (by linarith)] at key
  linarith

/-- Directional derivatives of `W (τ, x) = τ F (x / τ)` for `F(u) = a + c u + b u³`. -/
lemma hjb_db_derivs (a c b τ x : ℝ) (hτ : 0 < τ) :
    fderiv ℝ (fun q : ℝ × ℝ => q.1 * (a + c * (q.2 / q.1) + b * (q.2 / q.1) ^ 3)) (τ, x) (1, 0)
      = a - 2 * b * (x / τ) ^ 3 ∧
    fderiv ℝ (fun q : ℝ × ℝ => q.1 * (a + c * (q.2 / q.1) + b * (q.2 / q.1) ^ 3)) (τ, x) (0, 1)
      = c + 3 * b * (x / τ) ^ 2 := by
  have hd : DifferentiableAt ℝ
      (fun q : ℝ × ℝ => q.1 * (a + c * (q.2 / q.1) + b * (q.2 / q.1) ^ 3)) (τ, x) := by
    have hτ0 := hτ.ne'
    have h1 : DifferentiableAt ℝ (fun q : ℝ × ℝ => q.2 / q.1) (τ, x) := by
      simp_rw [div_eq_mul_inv]
      exact differentiableAt_snd.fun_mul (differentiableAt_fst.fun_inv (by simpa using hτ0))
    fun_prop
  constructor
  · have hl : HasDerivAt (fun t : ℝ => ((t, x) : ℝ × ℝ)) ((1 : ℝ), (0 : ℝ)) τ :=
      (hasDerivAt_id' τ).prodMk (hasDerivAt_const τ x)
    have h1 := hd.hasFDerivAt.comp_hasDerivAt τ hl
    have h2 : HasDerivAt (fun t : ℝ => t * (a + c * (x / t) + b * (x / t) ^ 3))
        (a - 2 * b * (x / τ) ^ 3) τ := by
      have hq : HasDerivAt (fun t : ℝ => x / t) (-(x / τ ^ 2)) τ := by
        convert HasDerivAt.div (hasDerivAt_const τ x) (hasDerivAt_id' τ) hτ.ne' using 1
        field_simp
        ring
      have := (hasDerivAt_id' τ).mul
        (((hasDerivAt_const τ a).add (hq.const_mul c)).add ((hq.pow 3).const_mul b))
      convert this using 1
      have hτ0 := hτ.ne'
      simp only [Pi.add_apply, Pi.pow_apply]
      norm_num
      field_simp
      ring
    exact h1.unique h2
  · have hl : HasDerivAt (fun y : ℝ => ((τ, y) : ℝ × ℝ)) ((0 : ℝ), (1 : ℝ)) x :=
      (hasDerivAt_const x τ).prodMk (hasDerivAt_id' x)
    have h1 := hd.hasFDerivAt.comp_hasDerivAt x hl
    have h2 : HasDerivAt (fun y : ℝ => τ * (a + c * (y / τ) + b * (y / τ) ^ 3))
        (c + 3 * b * (x / τ) ^ 2) x := by
      have hq : HasDerivAt (fun y : ℝ => y / τ) (1 / τ) x := (hasDerivAt_id' x).div_const τ
      have := (((hasDerivAt_const x a).add (hq.const_mul c)).add
        ((hq.pow 3).const_mul b)).const_mul τ
      convert this using 1
      have hτ0 := hτ.ne'
      norm_num
      field_simp
    exact h1.unique h2

#print axioms hjb_path_deriv
#print axioms hjb_lower
#print axioms hjb_db_derivs

/-- The verification theorem. Let the fuel rate `F` curve upward in speed (strictly convex for
speeds `u ≥ 0`). Let `W (τ, x)` be a guessed least fuel, as a function of the time
left `τ` and the distance left `x`, with continuous first derivatives where `τ > 0` and `x > 0`,
continuous up to arrival (`x = 0`), and zero on arrival. Let it solve the HJB equation
`W_τ + H(W_x) = 0` with `H(p) = -min_{u ≥ 0} (F(u) - p u)`, written here as: the least value of
`F(u) - W_x u` over speeds `u ≥ 0` exists and equals `W_τ`. Then
1. every allowed trip burns at least `W (τ, x)`; and
2. a trip driven at a speed that achieves that minimum at every moment, along which `W` takes
   its arrival value `0` at the moment of arrival, burns exactly `W (τ, x)`.
So such a `W` is the true least fuel, and that trip is a best trip. -/
theorem hjb_verification (F : ℝ → ℝ) (W : ℝ × ℝ → ℝ) (hF : StrictConvexOn ℝ (Ici 0) F)
    (hC1 : ContDiffOn ℝ 1 W {q | 0 < q.1 ∧ 0 < q.2})
    (hcont : ContinuousOn W {q | 0 < q.1 ∧ 0 ≤ q.2})
    (hzero : ∀ s, 0 ≤ s → W (s, 0) = 0)
    (hHJB : ∀ q : ℝ × ℝ, 0 < q.1 → 0 < q.2 →
      IsLeast ((fun u => F u - fderiv ℝ W q (0, 1) * u) '' Ici 0) (fderiv ℝ W q (1, 0)))
    {τ x : ℝ} (hτ : 0 < τ) (hx : 0 < x) :
    (∀ θ u X, AllowedTrip F τ x θ u X → W (τ, x) ≤ ∫ t in (0)..θ, F (u t)) ∧
    (∀ θ u X, AllowedTrip F τ x θ u X →
      (∀ t ∈ Ico 0 θ,
        F (u t) - fderiv ℝ W (τ - t, X t) (0, 1) * u t = fderiv ℝ W (τ - t, X t) (1, 0)) →
      Tendsto (fun t => W (τ - t, X t)) (𝓝[<] θ) (𝓝 0) →
      (∫ t in (0)..θ, F (u t)) = W (τ, x)) := by
  have hopen : IsOpen {q : ℝ × ℝ | 0 < q.1 ∧ 0 < q.2} :=
    (isOpen_lt continuous_const continuous_fst).inter (isOpen_lt continuous_const continuous_snd)
  constructor
  · rintro θ u X ⟨h0θ, hθτ, hX0, hXθ, hpos, hXc, hXd, hu, -, hFi⟩
    have hWc : ContinuousAt W (τ, x) := hC1.continuousOn.continuousAt (hopen.mem_nhds ⟨hτ, hx⟩)
    have hlim : Tendsto (fun T => W (T, x)) (𝓝[>] τ) (𝓝 (W (τ, x))) := by
      have : ContinuousAt (fun T => W (T, x)) τ :=
        ContinuousAt.comp (f := fun T : ℝ => ((T, x) : ℝ × ℝ)) hWc
          (continuous_id.prodMk continuous_const).continuousAt
      exact this.tendsto.mono_left nhdsWithin_le_nhds
    refine le_of_tendsto hlim (eventually_nhdsWithin_of_forall fun T hT => ?_)
    exact hjb_lower F W hC1 hcont hzero hHJB T θ x u X (lt_of_le_of_lt hθτ hT) h0θ hX0 hXθ hpos
      hXc hXd hu hFi
  · rintro θ u X ⟨h0θ, hθτ, hX0, hXθ, hpos, hXc, hXd, hu, -, hFi⟩ hEq hT
    have hθpos : 0 < θ := by
      rcases h0θ.lt_or_eq with h | h
      · exact h
      · rw [← h, hX0] at hXθ; linarith
    -- On `[0, s]` with `s < θ`, the fuel used equals the drop in `W` along the trip.
    have hstep : ∀ s ∈ Ioo 0 θ,
        (∫ t in (0)..s, F (u t)) + W (τ - s, X s) = W (τ, x) := by
      intro s hs
      have hgc : ContinuousOn (fun t => W (τ - t, X t)) (Icc 0 s) := by
        refine hcont.comp ((continuousOn_const.sub continuousOn_id).prodMk
          (hXc.mono (Icc_subset_Icc_right hs.2.le))) ?_
        intro t ht
        exact ⟨by simp only; linarith [ht.2, hs.2], (hpos t ⟨ht.1, by linarith [ht.2, hs.2]⟩).le⟩
      have key := intervalIntegral.integral_eq_sub_of_hasDeriv_right_of_le (f' := fun t => -F (u t))
        hs.1.le hgc
        (fun t ht => (hjb_path_deriv W hC1 τ X (u t) t (hXd t ⟨ht.1.le, by linarith [ht.2, hs.2]⟩)
          (by linarith [ht.2, hs.2]) (hpos t ⟨ht.1.le, by linarith [ht.2, hs.2]⟩)).congr_deriv
          (by rw [← hEq t ⟨ht.1.le, by linarith [ht.2, hs.2]⟩]; ring))
        (hFi.mono_set (by
          rw [uIcc_of_le hs.1.le, uIcc_of_le h0θ]; exact Icc_subset_Icc_right hs.2.le)).neg
      simp only [intervalIntegral.integral_neg, sub_zero, hX0] at key
      linarith
    have hprim : Tendsto (fun s => ∫ t in (0)..s, F (u t)) (𝓝[<] θ)
        (𝓝 (∫ t in (0)..θ, F (u t))) := by
      have hc := intervalIntegral.continuousOn_primitive_interval' hFi left_mem_uIcc θ
        right_mem_uIcc
      refine (hc.mono_of_mem_nhdsWithin ?_).tendsto
      refine mem_of_superset (Ioo_mem_nhdsLT hθpos) ?_
      rw [uIcc_of_le h0θ]
      exact Ioo_subset_Icc_self
    have h1 := hprim.add hT
    rw [add_zero] at h1
    have h2 : Tendsto (fun s => (∫ t in (0)..s, F (u t)) + W (τ - s, X s)) (𝓝[<] θ)
        (𝓝 (W (τ, x))) :=
      tendsto_const_nhds.congr' (eventually_of_mem (Ioo_mem_nhdsLT hθpos)
        fun s hs => (hstep s hs).symm)
    exact tendsto_nhds_unique h1 h2

/-- Where the deadline binds, the guess `W (τ, x) = τ F(x/τ)` (drive at the speed `x/τ` that
arrives exactly on time) solves the HJB equation for the fuel rate `F(u) = a + c u + b u³` with
drag `b > 0`: at the price `W_x`, the least value of `F(u) - W_x u` over speeds `u ≥ 0` is `W_τ`,
reached at the arrival speed `x/τ`. -/
theorem hjb_deadline_binds (a c b : ℝ) (hb : 0 < b) {τ x : ℝ} (hτ : 0 < τ) (hx : 0 < x) :
    let F : ℝ → ℝ := fun u => a + c * u + b * u ^ 3
    let W : ℝ × ℝ → ℝ := fun q => q.1 * F (q.2 / q.1)
    IsLeast ((fun u => F u - fderiv ℝ W (τ, x) (0, 1) * u) '' Ici 0)
        (fderiv ℝ W (τ, x) (1, 0)) ∧
      F (x / τ) - fderiv ℝ W (τ, x) (0, 1) * (x / τ) = fderiv ℝ W (τ, x) (1, 0) := by
  intro F W
  obtain ⟨h1, h2⟩ := hjb_db_derivs a c b τ x hτ
  have e1 : fderiv ℝ W (τ, x) (1, 0) = a - 2 * b * (x / τ) ^ 3 := h1
  have e2 : fderiv ℝ W (τ, x) (0, 1) = c + 3 * b * (x / τ) ^ 2 := h2
  rw [e1, e2]
  have hv : 0 < x / τ := div_pos hx hτ
  refine ⟨⟨⟨x / τ, hv.le, ?_⟩, ?_⟩, ?_⟩
  · simp only [F]; ring
  · rintro _ ⟨w, hw, rfl⟩
    have hw' : (0 : ℝ) ≤ w := hw
    simp only [F]
    nlinarith [mul_nonneg (mul_nonneg hb.le (sq_nonneg (w - x / τ))) (by linarith : 0 ≤ w + 2 * (x / τ))]
  · simp only [F]; ring

/-- With time to spare, the guess `W (τ, x) = c_eco x` solves the HJB equation for the fuel rate
`F(u) = a + c u + b u³` with `a, b > 0`, where the economy speed `u_eco` solves
`u_eco³ = a / (2 b)` and `c_eco = F(u_eco) / u_eco` is the least fuel per kilometre:
the least value of `F(u) - c_eco u` over speeds `u ≥ 0` is `W_τ = 0`, reached at `u_eco`. -/
theorem hjb_time_to_spare (a c b ue : ℝ) (ha : 0 < a) (hb : 0 < b) (hue : 0 < ue)
    (heco : ue ^ 3 = a / (2 * b)) {τ x : ℝ} :
    let F : ℝ → ℝ := fun u => a + c * u + b * u ^ 3
    let W : ℝ × ℝ → ℝ := fun q => F ue / ue * q.2
    IsLeast ((fun u => F u - fderiv ℝ W (τ, x) (0, 1) * u) '' Ici 0)
        (fderiv ℝ W (τ, x) (1, 0)) ∧
      F ue - fderiv ℝ W (τ, x) (0, 1) * ue = fderiv ℝ W (τ, x) (1, 0) := by
  intro F W
  have ha2 : a = 2 * b * ue ^ 3 := by
    rw [heco]; field_simp
  have hk : F ue / ue = c + 3 * b * ue ^ 2 := by
    simp only [F]
    rw [ha2]
    field_simp
    ring
  have hf : HasFDerivAt W ((F ue / ue) • ContinuousLinearMap.snd ℝ ℝ ℝ) (τ, x) :=
    (hasFDerivAt_snd).const_mul (F ue / ue)
  rw [hf.fderiv]
  simp only [smul_apply, ContinuousLinearMap.coe_snd', smul_eq_mul, mul_one,
    mul_zero]
  rw [hk]
  refine ⟨⟨⟨ue, hue.le, ?_⟩, ?_⟩, ?_⟩
  · simp only [F]; rw [ha2]; ring
  · rintro _ ⟨w, hw, rfl⟩
    have hw' : (0 : ℝ) ≤ w := hw
    simp only [F]
    rw [ha2]
    nlinarith [mul_nonneg (mul_nonneg hb.le (sq_nonneg (w - ue))) (by linarith : 0 ≤ w + 2 * ue)]
  · simp only [F]; rw [ha2]; ring

-- The card's car, in exact fractions: a = 27/25 L/h, c = 1/50 L/km, b = 1/400000 L h²/km³.
-- Economy speed: u³ = a / (2 b) = 60³ km³/h³.
example : (27 / 25 : ℚ) / (2 * (1 / 400000)) = 60 ^ 3 := by norm_num
-- Fuel rate at 60 km/h is 2.82 L/h, so 0.047 L/km there.
example : (27 / 25 : ℚ) + 1 / 50 * 60 + 1 / 400000 * 60 ^ 3 = 141 / 50 := by norm_num
example : ((27 / 25 : ℚ) + 1 / 50 * 60 + 1 / 400000 * 60 ^ 3) / 60 = 47 / 1000 := by norm_num
-- Fuel rate at 80 km/h is 3.96 L/h; for 1.25 h that is the least fuel, 4.95 L.
example : (27 / 25 : ℚ) + 1 / 50 * 80 + 1 / 400000 * 80 ^ 3 = 99 / 25 := by norm_num
example : (5 / 4 : ℚ) * (99 / 25) = 99 / 20 := by norm_num
-- Its parts: idling 1.35 L, rolling 2.00 L, drag 1.60 L.
example : (5 / 4 : ℚ) * (27 / 25) = 27 / 20 ∧ (100 : ℚ) * (1 / 50) = 2 ∧
    (5 / 4 : ℚ) * (1 / 400000) * 80 ^ 3 = 8 / 5 := by norm_num
-- Price of a km V_x = c + 3 b 80² = 0.068 L/km; value of slack V_τ = a - 2 b 80³ = -1.48 L/h.
example : (1 / 50 : ℚ) + 3 * (1 / 400000) * 80 ^ 2 = 17 / 250 := by norm_num
example : (27 / 25 : ℚ) - 2 * (1 / 400000) * 80 ^ 3 = -37 / 25 := by norm_num
-- On the seam, at 60 km/h, V_τ = a - 2 b 60³ = 0.
example : (27 / 25 : ℚ) - 2 * (1 / 400000) * 60 ^ 3 = 0 := by norm_num
-- With 2 h left: 100 km at 0.047 L/km is 4.70 L; arriving exactly at 2 h costs 2 F(50) = 4.785 L.
example : (100 : ℚ) * (47 / 1000) = 47 / 10 := by norm_num
example : 2 * ((27 / 25 : ℚ) + 1 / 50 * 50 + 1 / 400000 * 50 ^ 3) = 957 / 200 := by norm_num
-- Dynamic programming over the first 0.5 h: 1.98 L, then 2.97 L for 60 km in 0.75 h.
example : (1 / 2 : ℚ) * (99 / 25) + (3 / 4) * ((27 / 25) + 1 / 50 * (60 / (3 / 4)) +
    1 / 400000 * (60 / (3 / 4)) ^ 3) = 99 / 20 := by norm_num
-- The seam at 75 km: both pieces give 3.525 L; W_xx jumps from 0 to 6 b 75 / 1.25² = 0.00072.
example : (47 / 1000 : ℚ) * 75 = 5 / 4 * ((27 / 25) + 1 / 50 * (75 / (5 / 4)) +
    1 / 400000 * (75 / (5 / 4)) ^ 3) := by norm_num
example : 6 * (1 / 400000 : ℚ) * 75 / (5 / 4) ^ 2 = 9 / 12500 := by norm_num
-- 45 min at 60 km/h, then 110 km/h for the last 55 km, costs more than 4.95 L.
example : (45 : ℚ) * (47 / 1000) + 1 / 2 * ((27 / 25) + 1 / 50 * 110 + 1 / 400000 * 110 ^ 3)
    > 99 / 20 := by norm_num

#print axioms hjb_verification
#print axioms hjb_deadline_binds
#print axioms hjb_time_to_spare
