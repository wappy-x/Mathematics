-- The Hardy space H¹: a finite sum of atoms paired with a function of mean oscillation at most M on every interval gives at most M times the total size of the weights, the balanced pulse has a Hilbert partner of finite area (8/π) ln(1 + √2) and total 0, and the pulse paired with ln|x − 1/2| gives exactly −(3/2) ln 3.
import Mathlib.MeasureTheory.Integral.Average
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.MeasureTheory.Measure.Lebesgue.Integral

open MeasureTheory Set Real Filter Topology

/-- One atom against `φ`: the pairing is integrable and at most `M` in size. -/
theorem atom_pairing_le_bmo
    (φ : ℝ → ℝ) (hφ : ∀ a b : ℝ, IntegrableOn φ (Icc a b))
    (M : ℝ)
    (hM : ∀ a b : ℝ, a < b →
      ⨍ t in Icc a b, |φ t - ⨍ s in Icc a b, φ s| ≤ M)
    (α : ℝ → ℝ) (c d : ℝ) (hcd : c < d)
    (hmeas : AEStronglyMeasurable α volume)
    (hsupp : ∀ x ∉ Icc c d, α x = 0)
    (hcap : ∀ x, |α x| ≤ 1 / (d - c))
    (hzero : ∫ x, α x = 0) :
    Integrable (fun x => α x * φ x) volume ∧ |∫ x, α x * φ x| ≤ M := by
  set I := Icc c d with hI
  set m := ⨍ s in I, φ s with hm
  have hL : 0 < d - c := sub_pos.2 hcd
  have hvol : volume.real I = d - c := Real.volume_real_Icc_of_le hcd.le
  have hbdd : ∀ᵐ x ∂(volume.restrict I), ‖α x‖ ≤ 1 / (d - c) :=
    Eventually.of_forall fun x => by rw [Real.norm_eq_abs]; exact hcap x
  have hαI : IntegrableOn α I := by
    refine Measure.integrableOn_of_bounded (M := 1 / (d - c)) ?_ hmeas hbdd
    simp [hI, Real.volume_Icc]
  have hαφI : IntegrableOn (fun x => α x * φ x) I :=
    (hφ c d).bdd_mul hmeas.restrict hbdd
  have hzeroφ : ∀ x ∉ I, α x * φ x = 0 := fun x hx => by rw [hsupp x hx, zero_mul]
  have hint : Integrable (fun x => α x * φ x) volume := by
    have : (fun x => α x * φ x) = I.indicator (fun x => α x * φ x) := by
      funext x
      by_cases hx : x ∈ I
      · simp [hx]
      · simp [hx, hzeroφ x hx]
    rw [this]
    exact (integrable_indicator_iff measurableSet_Icc).2 hαφI
  refine ⟨hint, ?_⟩
  have hφmI : IntegrableOn (fun x => φ x - m) I := (hφ c d).sub (integrableOn_const (by simp))
  have hαφm : IntegrableOn (fun x => α x * (φ x - m)) I := hφmI.bdd_mul hmeas.restrict hbdd
  have h0 : ∫ x in I, α x = 0 := by
    rw [setIntegral_eq_integral_of_forall_compl_eq_zero hsupp, hzero]
  have hshift : ∫ x, α x * φ x = ∫ x in I, α x * (φ x - m) := by
    rw [← setIntegral_eq_integral_of_forall_compl_eq_zero hzeroφ]
    have : (fun x => α x * (φ x - m)) = fun x => α x * φ x - m * α x := by
      funext x; ring
    rw [this, integral_sub hαφI (hαI.const_mul m), integral_const_mul, h0, mul_zero, sub_zero]
  rw [hshift]
  have hbound : ∀ x, |α x * (φ x - m)| ≤ 1 / (d - c) * |φ x - m| := fun x => by
    rw [abs_mul]; exact mul_le_mul_of_nonneg_right (hcap x) (abs_nonneg _)
  calc |∫ x in I, α x * (φ x - m)| = ‖∫ x in I, α x * (φ x - m)‖ := (Real.norm_eq_abs _).symm
    _ ≤ ∫ x in I, ‖α x * (φ x - m)‖ := norm_integral_le_integral_norm _
    _ ≤ ∫ x in I, 1 / (d - c) * |φ x - m| := by
        refine integral_mono hαφm.norm (hφmI.abs.const_mul _) fun x => ?_
        simp only [Real.norm_eq_abs]; exact hbound x
    _ = ⨍ t in I, |φ t - m| := by
        rw [integral_const_mul, setAverage_eq, hvol, smul_eq_mul, one_div]
    _ ≤ M := hM c d hcd

/-- The easy half of Fefferman's duality, on finite sums of atoms. An atom `α j` lives on one
interval `I_j = [c_j, d_j]` (it is 0 off `I_j`), is never taller than `1/|I_j|`, and totals 0.
Let `φ` have a finite average on every interval, and let `M` bound its mean oscillation on every
interval: for all `a < b`, the average over `[a, b]` of `|φ(t) − φ_I|`, where `φ_I` is the average
of `φ` over `I = [a, b]`, is at most `M` (the least such `M` is `‖φ‖_BMO`). Then for every finite
sum `f = Σ θ_j α_j` of atoms, `|∫ f φ| ≤ (Σ |θ_j|) · M`. Taking the smallest total over all
decompositions gives `|∫ f φ| ≤ ‖f‖_{H¹} ‖φ‖_BMO`. -/
theorem atom_sum_pairing_le_bmo
    (φ : ℝ → ℝ) (hφ : ∀ a b : ℝ, IntegrableOn φ (Icc a b))
    (M : ℝ)
    (hM : ∀ a b : ℝ, a < b →
      ⨍ t in Icc a b, |φ t - ⨍ s in Icc a b, φ s| ≤ M)
    {ι : Type*} (S : Finset ι) (θ : ι → ℝ) (α : ι → ℝ → ℝ) (c d : ι → ℝ)
    (hcd : ∀ j ∈ S, c j < d j)
    (hmeas : ∀ j ∈ S, AEStronglyMeasurable (α j) volume)
    (hsupp : ∀ j ∈ S, ∀ x ∉ Icc (c j) (d j), α j x = 0)
    (hcap : ∀ j ∈ S, ∀ x, |α j x| ≤ 1 / (d j - c j))
    (hzero : ∀ j ∈ S, ∫ x, α j x = 0) :
    |∫ x, (∑ j ∈ S, θ j * α j x) * φ x| ≤ (∑ j ∈ S, |θ j|) * M := by
  have key := fun j (hj : j ∈ S) => atom_pairing_le_bmo φ hφ M hM (α j) (c j) (d j) (hcd j hj)
    (hmeas j hj) (hsupp j hj) (hcap j hj) (hzero j hj)
  have hfun : (fun x => (∑ j ∈ S, θ j * α j x) * φ x)
      = fun x => ∑ j ∈ S, θ j * (α j x * φ x) := by
    funext x; rw [Finset.sum_mul]; exact Finset.sum_congr rfl fun j _ => by ring
  rw [hfun, integral_finsetSum S fun j hj => (key j hj).1.const_mul (θ j)]
  simp_rw [integral_const_mul]
  calc |∑ j ∈ S, θ j * ∫ x, α j x * φ x| ≤ ∑ j ∈ S, |θ j * ∫ x, α j x * φ x| :=
        Finset.abs_sum_le_sum_abs _ _
    _ ≤ ∑ j ∈ S, |θ j| * M := Finset.sum_le_sum fun j hj => by
        rw [abs_mul]; exact mul_le_mul_of_nonneg_left (key j hj).2 (abs_nonneg _)
    _ = (∑ j ∈ S, |θ j|) * M := (Finset.sum_mul _ _ _).symm

/-- The partner's log, `ln (x² / |x² − 1|)`, without the factor `1/π`. -/
noncomputable def pulseG (x : ℝ) : ℝ := Real.log (x ^ 2 / |x ^ 2 - 1|)

/-- An antiderivative of `pulseG`, continuous on the whole line. -/
noncomputable def pulseF (x : ℝ) : ℝ :=
  2 * (x * Real.log x) - (x - 1) * Real.log (x - 1) - (x + 1) * Real.log (x + 1)

theorem pulseG_eq (x : ℝ) (h0 : x ≠ 0) (h1 : x ≠ 1) (h2 : x ≠ -1) :
    pulseG x = 2 * Real.log x - Real.log (x - 1) - Real.log (x + 1) := by
  have a1 : x - 1 ≠ 0 := sub_ne_zero.2 h1
  have a2 : x + 1 ≠ 0 := by intro h; apply h2; linarith
  unfold pulseG
  rw [Real.log_div (pow_ne_zero 2 h0) (abs_ne_zero.2 (by
      rw [show x ^ 2 - 1 = (x - 1) * (x + 1) by ring]; exact mul_ne_zero a1 a2)),
    Real.log_abs, show x ^ 2 - 1 = (x - 1) * (x + 1) by ring, Real.log_mul a1 a2, Real.log_pow]
  push_cast; ring

theorem pulseG_abs (x : ℝ) : pulseG |x| = pulseG x := by
  unfold pulseG; rw [sq_abs]

theorem pulseF_continuous : Continuous pulseF := by
  unfold pulseF
  have h := Real.continuous_mul_log
  have h1 : Continuous fun x : ℝ => (x - 1) * Real.log (x - 1) :=
    h.comp (continuous_id.sub continuous_const)
  have h2 : Continuous fun x : ℝ => (x + 1) * Real.log (x + 1) :=
    h.comp (continuous_id.add continuous_const)
  exact ((continuous_const.mul h).sub h1).sub h2

theorem pulseF_hasDerivAt (x : ℝ) (h0 : x ≠ 0) (h1 : x ≠ 1) (h2 : x ≠ -1) :
    HasDerivAt pulseF (pulseG x) x := by
  have a1 : x - 1 ≠ 0 := sub_ne_zero.2 h1
  have a2 : x + 1 ≠ 0 := by intro h; apply h2; linarith
  have d0 := Real.hasDerivAt_mul_log h0
  have d1 := HasDerivAt.comp_sub_const x 1 (Real.hasDerivAt_mul_log a1)
  have d2 := HasDerivAt.comp_add_const x 1 (Real.hasDerivAt_mul_log a2)
  have := ((d0.const_mul 2).sub d1).sub d2
  have h' : HasDerivAt pulseF (2 * (Real.log x + 1) - (Real.log (x - 1) + 1)
      - (Real.log (x + 1) + 1)) x := this
  rw [pulseG_eq x h0 h1 h2]
  exact h'.congr_deriv (by ring)

theorem pulseF_zero : pulseF 0 = 0 := by
  simp [pulseF]

theorem pulseF_sqrt_half : pulseF (Real.sqrt 2 / 2) = -2 * Real.log (1 + Real.sqrt 2) := by
  set c := Real.sqrt 2 / 2 with hc
  have hs : Real.sqrt 2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  have hs0 : 0 < Real.sqrt 2 := by positivity
  have hs1 : Real.sqrt 2 < 2 := by nlinarith
  have hc0 : 0 < c := by positivity
  have hc1 : 0 < 1 - c := by rw [hc]; linarith
  have hc2 : 0 < 1 + c := by linarith
  have e1 : Real.log c = -(Real.log 2) / 2 := by
    rw [hc, Real.log_div hs0.ne' (by norm_num), Real.log_sqrt (by norm_num)]; ring
  have e2 : Real.log (1 - c) + Real.log (1 + c) = -Real.log 2 := by
    rw [← Real.log_mul hc1.ne' hc2.ne', show (1 - c) * (1 + c) = 2⁻¹ by rw [hc]; nlinarith,
      Real.log_inv]
  have e3 : Real.log (1 + c) = Real.log (1 - c) + 2 * Real.log (1 + Real.sqrt 2) := by
    have hp : (0 : ℝ) < (1 + Real.sqrt 2) ^ 2 := by positivity
    rw [show (2 : ℝ) * Real.log (1 + Real.sqrt 2) = Real.log ((1 + Real.sqrt 2) ^ 2) by
      rw [Real.log_pow]; norm_num, ← Real.log_mul hc1.ne' hp.ne']
    congr 1
    rw [hc]; nlinarith
  have e4 : Real.log (c - 1) = Real.log (1 - c) := by
    rw [show c - 1 = -(1 - c) by ring, Real.log_neg_eq_log]
  unfold pulseF
  rw [e4, show c + 1 = 1 + c by ring]
  linear_combination (2 * c) * e1 - e3 - c * e2
    
theorem pulseG_nonpos (x : ℝ) (h : x ^ 2 ≤ 1 / 2) : pulseG x ≤ 0 := by
  unfold pulseG
  have h1 : x ^ 2 - 1 < 0 := by linarith
  rw [abs_of_neg h1]
  apply Real.log_nonpos (div_nonneg (sq_nonneg x) (by linarith))
  rw [div_le_one (by linarith)]; linarith

theorem pulseG_nonneg_mid (x : ℝ) (h : 1 / 2 ≤ x ^ 2) (h' : x ^ 2 ≤ 1) : 0 ≤ pulseG x := by
  unfold pulseG
  rcases h'.lt_or_eq with h' | h'
  · have h1 : x ^ 2 - 1 < 0 := by linarith
    rw [abs_of_neg h1]
    apply Real.log_nonneg
    rw [le_div_iff₀ (by linarith)]; linarith
  · rw [h']; simp

theorem pulseG_nonneg_big (x : ℝ) (h : 1 < x) : 0 ≤ pulseG x := by
  unfold pulseG
  have h1 : 0 < x ^ 2 - 1 := by nlinarith
  rw [abs_of_pos h1]
  apply Real.log_nonneg
  rw [le_div_iff₀ h1]; linarith

theorem pulseF_tendsto : Tendsto pulseF atTop (𝓝 0) := by
  have hlo : Tendsto (fun R : ℝ => -4 / R) atTop (𝓝 0) :=
    Tendsto.div_atTop tendsto_const_nhds tendsto_id
  have hhi : Tendsto (fun R : ℝ => 2 / R) atTop (𝓝 0) :=
    Tendsto.div_atTop tendsto_const_nhds tendsto_id
  have key : ∀ R : ℝ, 2 ≤ R → -4 / R ≤ pulseF R ∧ pulseF R ≤ 2 / R := by
    intro R hR
    have hR0 : 0 < R := by linarith
    have hm : 0 < R - 1 := by linarith
    have hp : 0 < R + 1 := by linarith
    have hq : 0 < R ^ 2 - 1 := by nlinarith
    have hsplit : pulseF R = R * pulseG R + (Real.log (R - 1) - Real.log (R + 1)) := by
      rw [pulseG_eq R hR0.ne' (by linarith) (by linarith)]; unfold pulseF; ring
    have hg0 : 0 ≤ pulseG R := pulseG_nonneg_big R (by linarith)
    have hg1 : pulseG R ≤ 1 / (R ^ 2 - 1) := by
      unfold pulseG
      rw [abs_of_pos hq]
      calc Real.log (R ^ 2 / (R ^ 2 - 1)) ≤ R ^ 2 / (R ^ 2 - 1) - 1 :=
            Real.log_le_sub_one_of_pos (div_pos (by positivity) hq)
        _ = 1 / (R ^ 2 - 1) := by field_simp; ring
    have hRg : R * pulseG R ≤ 2 / R := by
      calc R * pulseG R ≤ R * (1 / (R ^ 2 - 1)) := mul_le_mul_of_nonneg_left hg1 hR0.le
        _ = R / (R ^ 2 - 1) := by ring
        _ ≤ 2 / R := by rw [div_le_div_iff₀ hq hR0]; nlinarith
    have hl0 : Real.log (R - 1) ≤ Real.log (R + 1) := Real.log_le_log hm (by linarith)
    have hl1 : Real.log (R + 1) - Real.log (R - 1) ≤ 4 / R := by
      rw [← Real.log_div hp.ne' hm.ne']
      calc Real.log ((R + 1) / (R - 1)) ≤ (R + 1) / (R - 1) - 1 :=
            Real.log_le_sub_one_of_pos (div_pos hp hm)
        _ = 2 / (R - 1) := by field_simp; ring
        _ ≤ 4 / R := by rw [div_le_div_iff₀ hm hR0]; nlinarith
    have hRg0 : 0 ≤ R * pulseG R := mul_nonneg hR0.le hg0
    rw [hsplit]
    have : -4 / R = -(4 / R) := by ring
    constructor <;> linarith
  refine tendsto_of_tendsto_of_tendsto_of_le_of_le' hlo hhi ?_ ?_
  · filter_upwards [eventually_ge_atTop (2 : ℝ)] with R hR using (key R hR).1
  · filter_upwards [eventually_ge_atTop (2 : ℝ)] with R hR using (key R hR).2

/-- The three pieces of `(0, ∞)`: `(0, √2/2]` where `pulseG ≤ 0`, `(√2/2, 1]` and `(1, ∞)`. -/
theorem pulseG_pieces :
    IntegrableOn pulseG (Ioc 0 (Real.sqrt 2 / 2)) ∧
    ∫ x in Ioc 0 (Real.sqrt 2 / 2), pulseG x = pulseF (Real.sqrt 2 / 2) ∧
    IntegrableOn pulseG (Ioc (Real.sqrt 2 / 2) 1) ∧
    ∫ x in Ioc (Real.sqrt 2 / 2) 1, pulseG x = pulseF 1 - pulseF (Real.sqrt 2 / 2) ∧
    IntegrableOn pulseG (Ioi 1) ∧
    ∫ x in Ioi 1, pulseG x = - pulseF 1 := by
  set c := Real.sqrt 2 / 2 with hc
  have hs : Real.sqrt 2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  have hs0 : 0 < Real.sqrt 2 := by positivity
  have hc0 : 0 < c := by positivity
  have hc2 : c ^ 2 = 1 / 2 := by rw [hc]; nlinarith
  have hc1 : c < 1 := by nlinarith
  have hcont : ∀ s, ContinuousOn pulseF s := fun s => pulseF_continuous.continuousOn
  have hd1 : ∀ x ∈ Ioo 0 c, HasDerivAt pulseF (pulseG x) x := fun x hx =>
    pulseF_hasDerivAt x hx.1.ne' (by linarith [hx.2]) (by linarith [hx.1])
  have hd2 : ∀ x ∈ Ioo c 1, HasDerivAt pulseF (pulseG x) x := fun x hx =>
    pulseF_hasDerivAt x (by linarith [hx.1]) hx.2.ne (by linarith [hx.1])
  have hd3 : ∀ x ∈ Ioi (1 : ℝ), HasDerivAt pulseF (pulseG x) x := fun x hx =>
    pulseF_hasDerivAt x (by linarith [mem_Ioi.1 hx]) (mem_Ioi.1 hx).ne' (by linarith [mem_Ioi.1 hx])
  have i1 : IntegrableOn pulseG (Ioc 0 c) := by
    have h := intervalIntegral.integrableOn_deriv_of_nonneg (g := fun x => -pulseF x)
      (g' := fun x => -pulseG x) (a := 0) (b := c) (pulseF_continuous.neg.continuousOn)
      (fun x hx => (hd1 x hx).neg) (fun x hx => by
        have : x ^ 2 ≤ 1 / 2 := by nlinarith [hx.1, hx.2]
        linarith [pulseG_nonpos x this])
    simpa using h.neg
  have i2 : IntegrableOn pulseG (Ioc c 1) :=
    intervalIntegral.integrableOn_deriv_of_nonneg (hcont _) hd2 (fun x hx =>
      pulseG_nonneg_mid x (by nlinarith [hx.1, hx.2]) (by nlinarith [hx.1, hx.2]))
  have g3 : ∀ x ∈ Ioi (1 : ℝ), 0 ≤ pulseG x := fun x hx => pulseG_nonneg_big x hx
  have cw : ContinuousWithinAt pulseF (Ici 1) 1 := pulseF_continuous.continuousWithinAt
  refine ⟨i1, ?_, i2, ?_, integrableOn_Ioi_deriv_of_nonneg cw hd3 g3 pulseF_tendsto, ?_⟩
  · rw [← intervalIntegral.integral_of_le hc0.le,
      intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hc0.le (hcont _) hd1
        ((intervalIntegrable_iff_integrableOn_Ioc_of_le hc0.le).2 i1), pulseF_zero, sub_zero]
  · rw [← intervalIntegral.integral_of_le hc1.le,
      intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hc1.le (hcont _) hd2
        ((intervalIntegrable_iff_integrableOn_Ioc_of_le hc1.le).2 i2)]
  · rw [integral_Ioi_of_hasDerivAt_of_nonneg cw hd3 g3 pulseF_tendsto, zero_sub]

/-- An even function integrable on `(0, ∞)` is integrable on the whole line. -/
theorem integrable_of_even (f : ℝ → ℝ) (hf : ∀ x, f |x| = f x) (h : IntegrableOn f (Ioi 0)) :
    Integrable f volume := by
  have hf' : f = fun x => f |x| := funext fun x => (hf x).symm
  have hpos : IntegrableOn (fun x => f |x|) (Ioi 0) := by rw [← hf']; exact h
  have int_Iic : IntegrableOn (fun x ↦ f |x|) (Iic 0) := by
    rw [← Measure.map_neg_eq_self (volume : Measure ℝ)]
    let m : MeasurableEmbedding fun x : ℝ => -x := (Homeomorph.neg ℝ).measurableEmbedding
    rw [m.integrableOn_map_iff]
    simp_rw [Function.comp_def, abs_neg, neg_preimage, neg_Iic, neg_zero]
    exact Iff.mpr integrableOn_Ici_iff_integrableOn_Ioi hpos
  rw [hf', ← integrableOn_univ, ← Iic_union_Ioi (a := (0 : ℝ))]
  exact int_Iic.union hpos

/-- On `(0, ∞)`: `pulseG` is integrable, totals 0, and its absolute value totals `4 ln(1 + √2)`. -/
theorem pulseG_Ioi :
    IntegrableOn pulseG (Ioi 0) ∧ ∫ x in Ioi 0, pulseG x = 0 ∧
    ∫ x in Ioi 0, |pulseG x| = 4 * Real.log (1 + Real.sqrt 2) := by
  obtain ⟨i1, e1, i2, e2, i3, e3⟩ := pulseG_pieces
  set c := Real.sqrt 2 / 2 with hc
  have hs : Real.sqrt 2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  have hc0 : 0 < c := by positivity
  have hc2 : c ^ 2 = 1 / 2 := by rw [hc]; nlinarith
  have hc1 : c < 1 := by nlinarith
  have U1 : Ioc c 1 ∪ Ioi 1 = Ioi c := Ioc_union_Ioi_eq_Ioi hc1.le
  have U0 : Ioc 0 c ∪ Ioi c = Ioi 0 := Ioc_union_Ioi_eq_Ioi hc0.le
  have D1 : Disjoint (Ioc c 1) (Ioi 1) := Ioc_disjoint_Ioi_same
  have D0 : Disjoint (Ioc 0 c) (Ioi c) := Ioc_disjoint_Ioi_same
  have i23 : IntegrableOn pulseG (Ioi c) := by rw [← U1]; exact i2.union i3
  have iall : IntegrableOn pulseG (Ioi 0) := by rw [← U0]; exact i1.union i23
  refine ⟨iall, ?_, ?_⟩
  · rw [← U0, setIntegral_union D0 measurableSet_Ioi i1 i23, ← U1,
      setIntegral_union D1 measurableSet_Ioi i2 i3, e1, e2, e3]
    ring
  · have a1 : ∫ x in Ioc 0 c, |pulseG x| = -pulseF c := by
      rw [← e1, ← integral_neg]
      refine setIntegral_congr_fun measurableSet_Ioc fun x hx => ?_
      exact abs_of_nonpos (pulseG_nonpos x (by nlinarith [hx.1, hx.2]))
    have a2 : ∫ x in Ioc c 1, |pulseG x| = pulseF 1 - pulseF c := by
      rw [← e2]
      refine setIntegral_congr_fun measurableSet_Ioc fun x hx => ?_
      exact abs_of_nonneg (pulseG_nonneg_mid x (by nlinarith [hx.1, hx.2])
        (by nlinarith [hx.1, hx.2]))
    have a3 : ∫ x in Ioi 1, |pulseG x| = -pulseF 1 := by
      rw [← e3]
      refine setIntegral_congr_fun measurableSet_Ioi fun x hx => ?_
      exact abs_of_nonneg (pulseG_nonneg_big x hx)
    rw [← U0, setIntegral_union D0 measurableSet_Ioi i1.abs (i23.abs), ← U1,
      setIntegral_union D1 measurableSet_Ioi i2.abs i3.abs, a1, a2, a3, hc, pulseF_sqrt_half]
    ring

theorem inv_dist_Ioo (x a b : ℝ) (hab : a ≤ b) (hx : x ∉ Icc a b) :
    IntegrableOn (fun u => 1 / (x - u)) (Ioo a b) ∧
    ∫ u in Ioo a b, 1 / (x - u) = Real.log |x - a| - Real.log |x - b| := by
  have hne : ∀ u ∈ Icc a b, x - u ≠ 0 := fun u hu h => hx (by rw [sub_eq_zero.1 h]; exact hu)
  have hco : ContinuousOn (fun u => 1 / (x - u)) (Icc a b) :=
    continuousOn_const.div (continuousOn_const.sub continuousOn_id) hne
  refine ⟨hco.integrableOn_Icc.mono_set Ioo_subset_Icc_self, ?_⟩
  have hd : ∀ u ∈ uIcc a b, HasDerivAt (fun u => -Real.log (x - u)) (1 / (x - u)) u := by
    intro u hu
    rw [uIcc_of_le hab] at hu
    have h := (((hasDerivAt_id u).const_sub x).log (hne u hu)).neg
    exact h.congr_deriv (by simp; ring)
  rw [← integral_Ioc_eq_integral_Ioo, ← intervalIntegral.integral_of_le hab,
    intervalIntegral.integral_eq_sub_of_hasDerivAt hd
      ((hco.mono (uIcc_of_le hab).subset).intervalIntegrable), Real.log_abs, Real.log_abs]
  ring

theorem pv_piece (x p q ε : ℝ) (hpq : p < q) (hε : 0 < ε) (hp : ε < |x - p|)
    (hq : ε < |x - q|) :
    IntegrableOn (fun u => 1 / (x - u)) ({u | ε < |x - u|} ∩ Ioo p q) ∧
    ∫ u in {u | ε < |x - u|} ∩ Ioo p q, 1 / (x - u) = Real.log |x - p| - Real.log |x - q| := by
  rcases le_or_gt x p with hxp | hxp
  · have hset : {u | ε < |x - u|} ∩ Ioo p q = Ioo p q := by
      ext u
      simp only [mem_inter_iff, mem_ofPred_eq, mem_Ioo, and_iff_right_iff_imp]
      intro hu
      rw [abs_of_nonpos (by linarith)] at hp ⊢
      linarith [hu.1]
    rw [hset]
    exact inv_dist_Ioo x p q hpq.le fun h => by
      rw [abs_of_nonpos (by linarith [h.1])] at hp; linarith [h.1]
  rcases le_or_gt q x with hxq | hxq
  · have hset : {u | ε < |x - u|} ∩ Ioo p q = Ioo p q := by
      ext u
      simp only [mem_inter_iff, mem_ofPred_eq, mem_Ioo, and_iff_right_iff_imp]
      intro hu
      rw [abs_of_nonneg (by linarith)] at hq ⊢
      linarith [hu.2]
    rw [hset]
    exact inv_dist_Ioo x p q hpq.le fun h => by
      rw [abs_of_nonneg (by linarith [h.2])] at hq; linarith [h.2]
  rw [abs_of_pos (by linarith)] at hp
  rw [abs_of_neg (by linarith)] at hq
  have hset : {u | ε < |x - u|} ∩ Ioo p q = Ioo p (x - ε) ∪ Ioo (x + ε) q := by
    ext u
    simp only [mem_inter_iff, mem_ofPred_eq, mem_Ioo, mem_union, lt_abs]
    constructor
    · rintro ⟨h1 | h1, h2, h3⟩
      · exact Or.inl ⟨h2, by linarith⟩
      · exact Or.inr ⟨by linarith, h3⟩
    · rintro (⟨h2, h3⟩ | ⟨h2, h3⟩)
      · exact ⟨Or.inl (by linarith), h2, by linarith⟩
      · exact ⟨Or.inr (by linarith), by linarith, h3⟩
  have hD : Disjoint (Ioo p (x - ε)) (Ioo (x + ε) q) :=
    Set.disjoint_left.2 fun u h1 h2 => by linarith [h1.2, h2.1]
  obtain ⟨i1, e1⟩ := inv_dist_Ioo x p (x - ε) (by linarith) fun h => by linarith [h.2]
  obtain ⟨i2, e2⟩ := inv_dist_Ioo x (x + ε) q (by linarith) fun h => by linarith [h.1]
  rw [hset]
  refine ⟨i1.union i2, ?_⟩
  rw [setIntegral_union hD measurableSet_Ioo i1 i2, e1, e2,
    show x - (x - ε) = ε by ring, show x - (x + ε) = -ε by ring, abs_neg,
    abs_of_pos (by linarith : 0 < x - p), abs_of_neg (by linarith : x - q < 0)]
  ring

/-- The balanced pulse `a` (+1 on `(0, 1)`, −1 on `(−1, 0)`) has an integrable Hilbert partner.
At every `x` other than `−1, 0, 1`, the principal-value integral `(1/π) ∫ a(u)/(x − u) du`,
with a gap of half-width `ε` cut out around `u = x` and the gap then shrunk, tends to
`Ha(x) = (1/π) ln (x² / |x² − 1|)`. That partner has finite area, its area is
`‖Ha‖₁ = (8/π) ln(1 + √2)` (about 2.244399), and its total, with signs, is 0. -/
theorem balanced_pulse_hilbert_partner_integrable :
    (∀ x : ℝ, x ≠ -1 → x ≠ 0 → x ≠ 1 →
      Tendsto
        (fun ε : ℝ => (1 / π) * ∫ u in {u : ℝ | ε < |x - u|},
          (Set.indicator (Ioo 0 1) (fun _ => (1 : ℝ)) u
            - Set.indicator (Ioo (-1) 0) (fun _ => (1 : ℝ)) u) / (x - u))
        (𝓝[>] 0) (𝓝 ((1 / π) * Real.log (x ^ 2 / |x ^ 2 - 1|)))) ∧
    Integrable (fun x : ℝ => (1 / π) * Real.log (x ^ 2 / |x ^ 2 - 1|)) volume ∧
    ∫ x, |(1 / π) * Real.log (x ^ 2 / |x ^ 2 - 1|)| = (8 / π) * Real.log (1 + Real.sqrt 2) ∧
    ∫ x, (1 / π) * Real.log (x ^ 2 / |x ^ 2 - 1|) = 0 := by
  obtain ⟨iI, eI, aI⟩ := pulseG_Ioi
  have iG : Integrable pulseG volume := integrable_of_even pulseG pulseG_abs iI
  have hpi : 0 < 1 / π := by positivity
  refine ⟨?_, iG.const_mul (1 / π), ?_, ?_⟩
  · intro x hm1 h0 h1
    set δ := min (min |x| |x - 1|) |x + 1| with hδ
    have hx0 : 0 < |x| := abs_pos.2 h0
    have hx1 : 0 < |x - 1| := abs_pos.2 (sub_ne_zero.2 h1)
    have hx2 : 0 < |x + 1| := abs_pos.2 (by intro h; apply hm1; linarith)
    have hδ0 : 0 < δ := lt_min (lt_min hx0 hx1) hx2
    refine Tendsto.congr' ?_ tendsto_const_nhds
    filter_upwards [Ioo_mem_nhdsGT hδ0] with ε hε
    obtain ⟨hε0, hεδ⟩ := hε
    have b0 : ε < |x| := lt_of_lt_of_le hεδ ((min_le_left _ _).trans (min_le_left _ _))
    have b1 : ε < |x - 1| := lt_of_lt_of_le hεδ ((min_le_left _ _).trans (min_le_right _ _))
    have b2 : ε < |x + 1| := lt_of_lt_of_le hεδ (min_le_right _ _)
    set S := {u : ℝ | ε < |x - u|} with hS
    obtain ⟨j1, f1⟩ := pv_piece x 0 1 ε one_pos hε0 (by rwa [sub_zero]) b1
    obtain ⟨j2, f2⟩ := pv_piece x (-1) 0 ε (by norm_num) hε0 (by rwa [sub_neg_eq_add])
      (by rwa [sub_zero])
    have hfun : (fun u => (Set.indicator (Ioo 0 1) (fun _ => (1 : ℝ)) u
            - Set.indicator (Ioo (-1) 0) (fun _ => (1 : ℝ)) u) / (x - u))
        = fun u => Set.indicator (Ioo 0 1) (fun u => 1 / (x - u)) u
            - Set.indicator (Ioo (-1) 0) (fun u => 1 / (x - u)) u := by
      funext u
      simp only [Set.indicator_apply]
      split_ifs <;> ring
    have k1 : IntegrableOn (Set.indicator (Ioo 0 1) (fun u => 1 / (x - u))) S := by
      refine (integrable_indicator_iff measurableSet_Ioo).2 ?_
      rw [IntegrableOn, Measure.restrict_restrict measurableSet_Ioo, inter_comm]; exact j1
    have k2 : IntegrableOn (Set.indicator (Ioo (-1) 0) (fun u => 1 / (x - u))) S := by
      refine (integrable_indicator_iff measurableSet_Ioo).2 ?_
      rw [IntegrableOn, Measure.restrict_restrict measurableSet_Ioo, inter_comm]; exact j2
    show (1 / π) * Real.log (x ^ 2 / |x ^ 2 - 1|) = _
    rw [hfun, integral_sub k1 k2, setIntegral_indicator measurableSet_Ioo,
      setIntegral_indicator measurableSet_Ioo, f1, f2]
    congr 1
    rw [show Real.log (x ^ 2 / |x ^ 2 - 1|) = pulseG x from rfl, pulseG_eq x h0 h1 hm1,
      sub_zero, sub_neg_eq_add, Real.log_abs, Real.log_abs, Real.log_abs]
    ring
  · have h1 : (fun x : ℝ => |(1 / π) * Real.log (x ^ 2 / |x ^ 2 - 1|)|)
        = fun x => (1 / π) * |pulseG (|x|)| := by
      funext x; rw [pulseG_abs, abs_mul, abs_of_pos hpi]; rfl
    rw [h1, integral_const_mul, integral_comp_abs (f := fun x => |pulseG x|), aI]
    ring
  · have h1 : (fun x : ℝ => (1 / π) * Real.log (x ^ 2 / |x ^ 2 - 1|))
        = fun x => (1 / π) * pulseG |x| := by
      funext x; rw [pulseG_abs]; rfl
    rw [h1, integral_const_mul, integral_comp_abs (f := pulseG), eI]
    ring

theorem log_shift_Ioo (p q s : ℝ) (hpq : p ≤ q) :
    IntegrableOn (fun x : ℝ => Real.log |x - s|) (Ioo p q) ∧
    ∫ x in Ioo p q, Real.log |x - s|
      = (q - s) * Real.log (q - s) - (p - s) * Real.log (p - s) - (q - s) + (p - s) := by
  have hii : IntervalIntegrable (fun x : ℝ => Real.log (x - s)) volume p q := by
    have := (intervalIntegral.intervalIntegrable_log' (a := p - s) (b := q - s)).comp_sub_right s
    simpa using this
  have habs : (fun x : ℝ => Real.log |x - s|) = fun x => Real.log (x - s) := by
    funext x; exact Real.log_abs _
  rw [habs]
  refine ⟨((intervalIntegrable_iff_integrableOn_Ioc_of_le hpq).1 hii).mono_set Ioo_subset_Ioc_self, ?_⟩
  rw [← integral_Ioc_eq_integral_Ioo, ← intervalIntegral.integral_of_le hpq,
    intervalIntegral.integral_comp_sub_right (fun x => Real.log x) s, integral_log]

/-- The balanced pulse against the unbounded BMO function `φ(x) = ln|x − 1/2|`: the pairing
`∫ a φ` is finite and equals `−(3/2) ln 3` (about −1.647918). -/
theorem balanced_pulse_pairing_log_spike :
    ∫ x, (Set.indicator (Ioo 0 1) (fun _ => (1 : ℝ)) x
        - Set.indicator (Ioo (-1) 0) (fun _ => (1 : ℝ)) x) * Real.log |x - 1 / 2|
      = -(3 / 2) * Real.log 3 := by
  have hfun : (fun x : ℝ => (Set.indicator (Ioo 0 1) (fun _ => (1 : ℝ)) x
        - Set.indicator (Ioo (-1) 0) (fun _ => (1 : ℝ)) x) * Real.log |x - 1 / 2|)
      = fun x => Set.indicator (Ioo 0 1) (fun x => Real.log |x - 1 / 2|) x
        - Set.indicator (Ioo (-1) 0) (fun x => Real.log |x - 1 / 2|) x := by
    funext x
    simp only [Set.indicator_apply]
    split_ifs <;> ring
  obtain ⟨i1, e1⟩ := log_shift_Ioo 0 1 (1 / 2) (by norm_num)
  obtain ⟨i2, e2⟩ := log_shift_Ioo (-1) 0 (1 / 2) (by norm_num)
  rw [hfun, integral_sub ((integrable_indicator_iff measurableSet_Ioo).2 i1)
    ((integrable_indicator_iff measurableSet_Ioo).2 i2), integral_indicator measurableSet_Ioo,
    integral_indicator measurableSet_Ioo, e1, e2]
  have h1 : Real.log (0 - 1 / 2) = - Real.log 2 := by
    rw [show (0 : ℝ) - 1 / 2 = -(2⁻¹) by norm_num, Real.log_neg_eq_log, Real.log_inv]
  have h2 : Real.log (1 - 1 / 2) = - Real.log 2 := by
    rw [show (1 : ℝ) - 1 / 2 = 2⁻¹ by norm_num, Real.log_inv]
  have h3 : Real.log (-1 - 1 / 2) = Real.log 3 - Real.log 2 := by
    rw [show (-1 : ℝ) - 1 / 2 = -(3 / 2) by norm_num, Real.log_neg_eq_log,
      Real.log_div (by norm_num) (by norm_num)]
  rw [h1, h2, h3]
  ring

-- The height cap on I = (−1, 1), of length 2, is 1/(1 − (−1)) = 1/2, so the pulse of height 1
-- is twice an atom: a = 2α with α = a/2.
example : (1 : ℚ) / (1 - (-1)) = 1 / 2 ∧ (2 : ℚ) * (1 / 2) = 1 := by norm_num

#print axioms atom_pairing_le_bmo
#print axioms pulseG_eq
#print axioms pulseG_abs
#print axioms pulseF_continuous
#print axioms pulseF_hasDerivAt
#print axioms pulseF_zero
#print axioms pulseF_sqrt_half
#print axioms pulseG_nonpos
#print axioms pulseG_nonneg_mid
#print axioms pulseG_nonneg_big
#print axioms pulseF_tendsto
#print axioms pulseG_pieces
#print axioms integrable_of_even
#print axioms pulseG_Ioi
#print axioms inv_dist_Ioo
#print axioms pv_piece
#print axioms log_shift_Ioo
#print axioms atom_sum_pairing_le_bmo
#print axioms balanced_pulse_hilbert_partner_integrable
#print axioms balanced_pulse_pairing_log_spike
