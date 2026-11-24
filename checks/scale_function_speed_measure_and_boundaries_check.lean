-- One-dimensional diffusions: the generator of a one-dimensional diffusion is a derivative along the scale function followed by one along the speed measure, the speed density has zero probability current, and Feller's tests at zero sort a Cox-Ingersoll-Ross rate into regular, entrance or exit by its ratio 2κθ/σ² and its level θ.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Integrability.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

namespace ScaleSpeedBoundaries

open MeasureTheory Real Set

/-- The scale density of `dX = μ(X) dt + σ(X) dW` with reference point `x₀`:
`s(x) = exp(-∫_{x₀}^x 2μ(y)/σ(y)² dy)`. -/
noncomputable def scaleDensity (μ σ : ℝ → ℝ) (x₀ x : ℝ) : ℝ :=
  exp (-∫ y in x₀..x, 2 * μ y / σ y ^ 2)

/-- The speed density `m(x) = 2 / (σ(x)² s(x))`. -/
noncomputable def speedDensity (μ σ : ℝ → ℝ) (x₀ x : ℝ) : ℝ :=
  2 / (σ x ^ 2 * scaleDensity μ σ x₀ x)

theorem hasDerivAt_driftIntegral (μ σ : ℝ → ℝ) (I : Set ℝ) (hI : IsOpen I)
    (hσ : ∀ y ∈ I, 0 < σ y)
    (hint : ∀ a ∈ I, ∀ b ∈ I, IntervalIntegrable (fun y => 2 * μ y / σ y ^ 2) volume a b)
    {x₀ x : ℝ} (hx₀ : x₀ ∈ I) (hx : x ∈ I) (hμx : ContinuousAt μ x) (hσx : ContinuousAt σ x) :
    HasDerivAt (fun y => ∫ t in x₀..y, 2 * μ t / σ t ^ 2) (2 * μ x / σ x ^ 2) x := by
  obtain ⟨ε, hε, hball⟩ := Metric.isOpen_iff.mp hI x hx
  have ha : x - ε / 2 ∈ I := hball (by
    rw [Metric.mem_ball, Real.dist_eq, abs_lt]; constructor <;> linarith)
  have hb : x + ε / 2 ∈ I := hball (by
    rw [Metric.mem_ball, Real.dist_eq, abs_lt]; constructor <;> linarith)
  have hloc := hint _ ha _ hb
  rw [intervalIntegrable_iff_integrableOn_Ioc_of_le (by linarith)] at hloc
  refine intervalIntegral.integral_hasDerivAt_right (hint _ hx₀ _ hx) ?_ ?_
  · exact ⟨Ioc (x - ε / 2) (x + ε / 2), Ioc_mem_nhds (by linarith) (by linarith),
      hloc.aestronglyMeasurable⟩
  · exact (continuousAt_const.mul hμx).div (hσx.pow 2) (pow_ne_zero 2 (hσ x hx).ne')
#print axioms hasDerivAt_driftIntegral
theorem cir_scaleDensity_eq {κ θ σ x₀ z : ℝ} (hσ : 0 < σ) (hx₀ : 0 < x₀) (hz : 0 < z) :
    scaleDensity (fun y => κ * (θ - y)) (fun y => σ * √y) x₀ z =
      x₀ ^ (2 * κ * θ / σ ^ 2) * exp (-(2 * κ / σ ^ 2 * x₀)) * z ^ (-(2 * κ * θ / σ ^ 2)) *
        exp (2 * κ / σ ^ 2 * z) := by
  have hg : ∀ t ∈ uIcc x₀ z, 2 * (κ * (θ - t)) / (σ * √t) ^ 2 =
      2 * κ * θ / σ ^ 2 * t⁻¹ - 2 * κ / σ ^ 2 := by
    intro t ht
    have htpos : 0 < t := lt_of_lt_of_le (lt_min hx₀ hz) ht.1
    rw [mul_pow, sq_sqrt htpos.le]
    field_simp
  have hpos : ∀ t ∈ uIcc x₀ z, t ≠ 0 := fun t ht =>
    (lt_of_lt_of_le (lt_min hx₀ hz) ht.1).ne'
  have hI : ∫ t in x₀..z, 2 * (κ * (θ - t)) / (σ * √t) ^ 2 =
      2 * κ * θ / σ ^ 2 * log (z / x₀) - (z - x₀) * (2 * κ / σ ^ 2) := by
    rw [intervalIntegral.integral_congr hg, intervalIntegral.integral_sub,
      intervalIntegral.integral_const_mul, integral_inv_of_pos hx₀ hz,
      intervalIntegral.integral_const, smul_eq_mul]
    · exact (continuousOn_const.mul (continuousOn_inv₀.mono fun t ht => hpos t ht)).intervalIntegrable
    · exact intervalIntegrable_const
  show exp (-∫ t in x₀..z, 2 * (κ * (θ - t)) / (σ * √t) ^ 2) = _
  rw [hI, rpow_def_of_pos hx₀, rpow_def_of_pos hz, log_div hz.ne' hx₀.ne', ← exp_add, ← exp_add,
    ← exp_add]
  congr 1
  ring
#print axioms cir_scaleDensity_eq

theorem cir_speedDensity_eq {κ θ σ x₀ y : ℝ} (hσ : 0 < σ) (hx₀ : 0 < x₀) (hy : 0 < y) :
    speedDensity (fun y => κ * (θ - y)) (fun y => σ * √y) x₀ y =
      2 / (σ ^ 2 * (x₀ ^ (2 * κ * θ / σ ^ 2) * exp (-(2 * κ / σ ^ 2 * x₀)))) *
        y ^ (2 * κ * θ / σ ^ 2 - 1) * exp (-(2 * κ / σ ^ 2 * y)) := by
  rw [speedDensity, cir_scaleDensity_eq hσ hx₀ hy, mul_pow, sq_sqrt hy.le, rpow_sub_one hy.ne',
    rpow_neg hy.le, exp_neg (2 * κ / σ ^ 2 * y)]
  have h1 : 0 < x₀ ^ (2 * κ * θ / σ ^ 2) := rpow_pos_of_pos hx₀ _
  have h2 : 0 < y ^ (2 * κ * θ / σ ^ 2) := rpow_pos_of_pos hy _
  have h3 := exp_pos (-(2 * κ / σ ^ 2 * x₀))
  have h4 := exp_pos (2 * κ / σ ^ 2 * y)
  field_simp
#print axioms cir_speedDensity_eq

theorem feller_core {s m : ℝ → ℝ} {ν a K σ x₀ : ℝ} (hσ : 0 < σ) (hx₀ : 0 < x₀) (ha : 0 < a)
    (hK : 0 < K) (hν : 0 ≤ ν) (hspos : ∀ z, 0 < s z)
    (hs0 : ∀ z, 0 < z → s z = K * z ^ (-ν) * exp (a * z))
    (hm0 : ∀ y, 0 < y → m y = 2 / (σ ^ 2 * K) * y ^ (ν - 1) * exp (-(a * y))) :
    ((IntegrableOn s (Ioo 0 x₀) ∧
        IntegrableOn (fun y => (∫ z in (0 : ℝ)..y, s z) * m y) (Ioo 0 x₀)) ↔ ν < 1) ∧
    (IntegrableOn (fun y => (∫ z in y..x₀, s z) * m y) (Ioo 0 x₀) ↔ 0 < ν) := by
  have hsm : ∀ y z, 0 < y → 0 < z →
      s z * m y = 2 / σ ^ 2 * exp (a * (z - y)) * y ^ (ν - 1) * z ^ (-ν) := by
    intro y z hy hz
    rw [hs0 z hz, hm0 y hy, show a * (z - y) = a * z + -(a * y) by ring, exp_add]
    field_simp
  have hcontz : ∀ y, ContinuousOn (fun z => 2 / σ ^ 2 * exp (a * (z - y)) * y ^ (ν - 1) * z ^ (-ν))
      (Ioi 0) := fun y =>
    (Continuous.continuousOn (by fun_prop)).mul
      (continuousOn_id.rpow_const fun z hz => Or.inl (ne_of_gt hz))
  have hpos_uIcc : ∀ b c : ℝ, 0 < b → 0 < c → uIcc b c ⊆ Ioi 0 := fun b c hb hc t ht =>
    lt_of_lt_of_le (lt_min hb hc) ht.1
  have hs_cont : ContinuousOn s (Ioi 0) :=
    ((continuousOn_const.mul (continuousOn_id.rpow_const fun z hz => Or.inl (ne_of_gt hz))).mul
      (Continuous.continuousOn (by fun_prop))).congr fun z hz => hs0 z hz
  have hm_cont : ContinuousOn m (Ioi 0) :=
    ((continuousOn_const.mul (continuousOn_id.rpow_const fun z hz => Or.inl (ne_of_gt hz))).mul
      (Continuous.continuousOn (by fun_prop))).congr fun z hz => hm0 z hz
  have hF : ∀ y, 0 < y → y ≤ x₀ → (∫ z in y..x₀, s z) * m y =
      ∫ z in y..x₀, 2 / σ ^ 2 * exp (a * (z - y)) * y ^ (ν - 1) * z ^ (-ν) := by
    intro y hy0 hyx
    rw [← intervalIntegral.integral_mul_const]
    refine intervalIntegral.integral_congr fun z hz => ?_
    rw [uIcc_of_le hyx] at hz
    exact hsm y z hy0 (hy0.trans_le hz.1)
  constructor
  · constructor
    · rintro ⟨h1, -⟩
      have h2 : IntegrableOn (fun z : ℝ => z ^ (-ν)) (Ioo 0 x₀) := by
        refine Integrable.mono' (h1.const_mul K⁻¹)
          ((continuousOn_id.rpow_const fun z (hz : z ∈ Ioo (0:ℝ) x₀) => Or.inl (ne_of_gt hz.1)).aestronglyMeasurable
            measurableSet_Ioo) (ae_restrict_of_forall_mem measurableSet_Ioo fun z hz => ?_)
        have hz0 : 0 < z := hz.1
        rw [norm_of_nonneg (rpow_nonneg hz0.le _), hs0 z hz0]
        have he : 1 ≤ exp (a * z) := one_le_exp (by positivity)
        have hr := rpow_nonneg hz0.le (-ν)
        calc z ^ (-ν) ≤ z ^ (-ν) * exp (a * z) := le_mul_of_one_le_right hr he
          _ = K⁻¹ * (K * z ^ (-ν) * exp (a * z)) := by field_simp
      have := (intervalIntegral.integrableOn_Ioo_rpow_iff hx₀).mp h2
      linarith
    · intro hν1
      have hsI : IntegrableOn s (Ioo 0 x₀) := by
        refine Integrable.mono' (((intervalIntegral.integrableOn_Ioo_rpow_iff hx₀).mpr
            (by linarith : -1 < -ν)).const_mul (K * exp (a * x₀)))
          ((hs_cont.mono fun z (hz : z ∈ Ioo (0:ℝ) x₀) => hz.1).aestronglyMeasurable measurableSet_Ioo)
          (ae_restrict_of_forall_mem measurableSet_Ioo fun z hz => ?_)
        have hz0 : 0 < z := hz.1
        rw [hs0 z hz0, norm_of_nonneg (by positivity)]
        have he : exp (a * z) ≤ exp (a * x₀) :=
          exp_le_exp.mpr (mul_le_mul_of_nonneg_left hz.2.le ha.le)
        have hr := rpow_nonneg hz0.le (-ν)
        calc K * z ^ (-ν) * exp (a * z) ≤ K * z ^ (-ν) * exp (a * x₀) :=
              mul_le_mul_of_nonneg_left he (by positivity)
          _ = K * exp (a * x₀) * z ^ (-ν) := by ring
      have hsII : IntervalIntegrable s volume 0 x₀ :=
        (intervalIntegrable_iff_integrableOn_Ioo_of_le hx₀.le).mpr hsI
      refine ⟨hsI, ?_⟩
      have hG := intervalIntegral.continuousOn_primitive_interval' hsII left_mem_uIcc
      have hsub : Ioo 0 x₀ ⊆ uIcc 0 x₀ := by
        rw [uIcc_of_le hx₀.le]; exact Ioo_subset_Icc_self
      refine Integrable.mono' (integrableOn_const (C := 2 / σ ^ 2 / (1 - ν)) measure_Ioo_lt_top.ne)
        (((hG.mono hsub).mul (hm_cont.mono fun y (hy : y ∈ Ioo (0:ℝ) x₀) => hy.1)).aestronglyMeasurable
          measurableSet_Ioo) (ae_restrict_of_forall_mem measurableSet_Ioo fun y hy => ?_)
      have hy0 : 0 < y := hy.1
      have hP : (∫ z in (0 : ℝ)..y, s z) * m y =
          ∫ z in (0 : ℝ)..y, 2 / σ ^ 2 * exp (a * (z - y)) * y ^ (ν - 1) * z ^ (-ν) := by
        rw [← intervalIntegral.integral_mul_const]
        refine intervalIntegral.integral_congr_ae (ae_of_all _ fun z hz => ?_)
        rw [uIoc_of_le hy0.le] at hz
        exact hsm y z hy0 hz.1
      have hnn : 0 ≤ (∫ z in (0 : ℝ)..y, s z) * m y :=
        mul_nonneg (intervalIntegral.integral_nonneg hy0.le fun z _ => (hspos z).le)
          (by rw [hm0 y hy0]; positivity)
      rw [norm_of_nonneg hnn, hP]
      have hrI := intervalIntegral.intervalIntegrable_rpow' (a := 0) (b := y)
        (by linarith : -1 < -ν)
      calc ∫ z in (0 : ℝ)..y, 2 / σ ^ 2 * exp (a * (z - y)) * y ^ (ν - 1) * z ^ (-ν)
          ≤ ∫ z in (0 : ℝ)..y, 2 / σ ^ 2 * y ^ (ν - 1) * z ^ (-ν) := by
            apply intervalIntegral.integral_mono_on_of_le_Ioo hy0.le
            · exact hrI.continuousOn_mul (Continuous.continuousOn (by fun_prop))
            · exact hrI.const_mul _
            · intro z hz
              have he : exp (a * (z - y)) ≤ 1 :=
                exp_le_one_iff.mpr (mul_nonpos_of_nonneg_of_nonpos ha.le (by linarith [hz.2]))
              have h1 := rpow_nonneg hy0.le (ν - 1)
              have h2 := rpow_nonneg hz.1.le (-ν)
              calc 2 / σ ^ 2 * exp (a * (z - y)) * y ^ (ν - 1) * z ^ (-ν)
                  = 2 / σ ^ 2 * (y ^ (ν - 1) * z ^ (-ν)) * exp (a * (z - y)) := by ring
                _ ≤ 2 / σ ^ 2 * (y ^ (ν - 1) * z ^ (-ν)) * 1 :=
                  mul_le_mul_of_nonneg_left he (by positivity)
                _ = _ := by ring
        _ = 2 / σ ^ 2 / (1 - ν) := by
            rw [intervalIntegral.integral_const_mul, integral_rpow (Or.inl (by linarith)),
              zero_rpow (by linarith : (-ν + 1) ≠ 0)]
            have h1 : y ^ (ν - 1) * y ^ (-ν + 1) = 1 := by
              rw [← rpow_add hy0, show ν - 1 + (-ν + 1) = 0 by ring, rpow_zero]
            rw [show 2 / σ ^ 2 * y ^ (ν - 1) * ((y ^ (-ν + 1) - 0) / (-ν + 1)) =
              2 / σ ^ 2 * (y ^ (ν - 1) * y ^ (-ν + 1)) / (-ν + 1) by ring, h1]
            ring
  · constructor
    · intro h
      by_contra hν'
      have hν00 : ν = 0 := le_antisymm (not_lt.mp hν') hν
      subst hν00
      have hhalf : 0 < x₀ / 2 := half_pos hx₀
      have h2 : IntegrableOn (fun y : ℝ => y ^ (-1 : ℝ)) (Ioo 0 (x₀ / 2)) := by
        refine Integrable.mono' ((h.mono_set (Ioo_subset_Ioo_right (by linarith))).const_mul
            (σ ^ 2 / x₀))
          ((continuousOn_id.rpow_const fun z (hz : z ∈ Ioo (0:ℝ) (x₀ / 2)) => Or.inl (ne_of_gt hz.1)).aestronglyMeasurable
            measurableSet_Ioo) (ae_restrict_of_forall_mem measurableSet_Ioo fun y hy => ?_)
        have hy0 : 0 < y := hy.1
        have hyx : y ≤ x₀ := by linarith [hy.2]
        rw [norm_of_nonneg (rpow_nonneg hy0.le _)]
        have hlow : (x₀ / 2) * (2 / σ ^ 2 * y ^ (-1 : ℝ)) ≤ ∫ z in y..x₀,
            2 / σ ^ 2 * exp (a * (z - y)) * y ^ ((0 : ℝ) - 1) * z ^ (-(0 : ℝ)) := by
          have hyr := rpow_nonneg hy0.le (-1 : ℝ)
          calc (x₀ / 2) * (2 / σ ^ 2 * y ^ (-1 : ℝ))
              ≤ (x₀ - y) * (2 / σ ^ 2 * y ^ (-1 : ℝ)) :=
                mul_le_mul_of_nonneg_right (by linarith [hy.2]) (by positivity)
            _ = ∫ z in y..x₀, 2 / σ ^ 2 * y ^ (-1 : ℝ) := by
                rw [intervalIntegral.integral_const, smul_eq_mul]
            _ ≤ _ := by
                apply intervalIntegral.integral_mono_on hyx intervalIntegrable_const
                · exact ((hcontz y).mono (hpos_uIcc _ _ hy0 hx₀)).intervalIntegrable
                · intro z hz
                  have he : 1 ≤ exp (a * (z - y)) :=
                    one_le_exp (mul_nonneg ha.le (by linarith [hz.1]))
                  simp only [neg_zero, rpow_zero, mul_one, zero_sub]
                  calc 2 / σ ^ 2 * y ^ (-1 : ℝ) = 2 / σ ^ 2 * 1 * y ^ (-1 : ℝ) := by ring
                    _ ≤ 2 / σ ^ 2 * exp (a * (z - y)) * y ^ (-1 : ℝ) := by gcongr
        have hyr := rpow_nonneg hy0.le (-1 : ℝ)
        calc y ^ (-1 : ℝ) = σ ^ 2 / x₀ * ((x₀ / 2) * (2 / σ ^ 2 * y ^ (-1 : ℝ))) := by
              field_simp
          _ ≤ σ ^ 2 / x₀ * ((∫ z in y..x₀, s z) * m y) := by
              rw [hF y hy0 hyx]
              exact mul_le_mul_of_nonneg_left hlow (by positivity)
      have := (intervalIntegral.integrableOn_Ioo_rpow_iff hhalf).mp h2
      exact lt_irrefl _ this
    · intro hνpos
      set β := min ν (1 / 2) with hβ
      have hβpos : 0 < β := lt_min hνpos (by norm_num)
      have hβle : β ≤ ν := min_le_left _ _
      have hβhalf : β ≤ 1 / 2 := min_le_right _ _
      have hF_cont : ContinuousOn (fun y => ∫ z in y..x₀, s z) (Ioo 0 x₀) := by
        intro y hy
        have hy0 : 0 < y := hy.1
        have hint : IntegrableOn s (uIcc (y / 2) x₀) :=
          (hs_cont.mono (hpos_uIcc _ _ (half_pos hy0) hx₀)).integrableOn_uIcc
        have hc := intervalIntegral.continuousOn_primitive_interval_left hint
        have hmem : uIcc (y / 2) x₀ ∈ nhds y := by
          rw [uIcc_of_le (by linarith [hy.2])]; exact Icc_mem_nhds (by linarith) hy.2
        exact (hc.continuousAt hmem).continuousWithinAt
      refine Integrable.mono' (((intervalIntegral.integrableOn_Ioo_rpow_iff hx₀).mpr
          (by linarith : -1 < β - 1)).const_mul
            (2 / σ ^ 2 * exp (a * x₀) * (x₀ ^ (-β + 1) / (-β + 1))))
        ((hF_cont.mul (hm_cont.mono fun y (hy : y ∈ Ioo (0:ℝ) x₀) => hy.1)).aestronglyMeasurable measurableSet_Ioo)
        (ae_restrict_of_forall_mem measurableSet_Ioo fun y hy => ?_)
      have hy0 : 0 < y := hy.1
      have hyx : y ≤ x₀ := hy.2.le
      have hnn : 0 ≤ (∫ z in y..x₀, s z) * m y :=
        mul_nonneg (intervalIntegral.integral_nonneg hyx fun z _ => (hspos z).le)
          (by rw [hm0 y hy0]; positivity)
      rw [norm_of_nonneg hnn, hF y hy0 hyx]
      calc ∫ z in y..x₀, 2 / σ ^ 2 * exp (a * (z - y)) * y ^ (ν - 1) * z ^ (-ν)
          ≤ ∫ z in y..x₀, 2 / σ ^ 2 * exp (a * x₀) * y ^ (β - 1) * z ^ (-β) := by
            apply intervalIntegral.integral_mono_on hyx
            · exact ((hcontz y).mono (hpos_uIcc _ _ hy0 hx₀)).intervalIntegrable
            · exact (intervalIntegral.intervalIntegrable_rpow' (by linarith : -1 < -β)).const_mul _
            · intro z hz
              have hz0 : 0 < z := hy0.trans_le hz.1
              have hE : exp (a * (z - y)) ≤ exp (a * x₀) :=
                exp_le_exp.mpr (mul_le_mul_of_nonneg_left (by linarith [hz.2]) ha.le)
              have hY : y ^ (ν - 1) = y ^ (β - 1) * y ^ (ν - β) := by
                rw [← rpow_add hy0]; congr 1; ring
              have hZ : z ^ (-β) = z ^ (-ν) * z ^ (ν - β) := by
                rw [← rpow_add hz0]; congr 1; ring
              have hyz : y ^ (ν - β) ≤ z ^ (ν - β) := rpow_le_rpow hy0.le hz.1 (by linarith)
              have h1 := rpow_nonneg hy0.le (β - 1)
              have h2 := rpow_nonneg hz0.le (-ν)
              have h3 := rpow_nonneg hy0.le (ν - 1)
              have hYZ : y ^ (ν - 1) * z ^ (-ν) ≤ y ^ (β - 1) * z ^ (-β) := by
                rw [hY, hZ]
                calc y ^ (β - 1) * y ^ (ν - β) * z ^ (-ν) = (y ^ (β - 1) * z ^ (-ν)) * y ^ (ν - β) := by
                      ring
                  _ ≤ (y ^ (β - 1) * z ^ (-ν)) * z ^ (ν - β) := by gcongr
                  _ = _ := by ring
              calc 2 / σ ^ 2 * exp (a * (z - y)) * y ^ (ν - 1) * z ^ (-ν)
                  = 2 / σ ^ 2 * exp (a * (z - y)) * (y ^ (ν - 1) * z ^ (-ν)) := by ring
                _ ≤ 2 / σ ^ 2 * exp (a * x₀) * (y ^ (β - 1) * z ^ (-β)) := by gcongr
                _ = _ := by ring
        _ ≤ 2 / σ ^ 2 * exp (a * x₀) * (x₀ ^ (-β + 1) / (-β + 1)) * y ^ (β - 1) := by
            rw [intervalIntegral.integral_const_mul, integral_rpow (Or.inl (by linarith))]
            have h1 := rpow_nonneg hy0.le (-β + 1)
            have h2 : 0 < -β + 1 := by linarith
            have h3 := rpow_nonneg hy0.le (β - 1)
            calc 2 / σ ^ 2 * exp (a * x₀) * y ^ (β - 1) * ((x₀ ^ (-β + 1) - y ^ (-β + 1)) / (-β + 1))
                ≤ 2 / σ ^ 2 * exp (a * x₀) * y ^ (β - 1) * (x₀ ^ (-β + 1) / (-β + 1)) := by
                  gcongr; linarith
              _ = _ := by ring
#print axioms feller_core

/-- **The generator in two derivatives** (the card's Step 3). Let the diffusion
`dX = μ(X) dt + σ(X) dW` live on an open interval `I`, with noise size `σ > 0` inside `I` and
`2μ/σ²` integrable over every closed stretch inside `I`. Build the scale density `s` and the speed
density `m` from a reference point `x₀` in `I`. Then at every point `x` of `I` where the drift and
the noise size are continuous, and for every `f` whose slope `f'` has a derivative `f''` at `x`,
`μ f' + ½ σ² f'' = (1/m) · (f'/s)'`: the generator is a derivative along the new ruler, then a
derivative along the speed measure. -/
theorem generator_eq_speed_then_scale_derivative (μ σ f : ℝ → ℝ) (I : Set ℝ) (hI : IsOpen I)
    (hIc : I.OrdConnected) (hσ : ∀ y ∈ I, 0 < σ y)
    (hint : ∀ a ∈ I, ∀ b ∈ I, IntervalIntegrable (fun y => 2 * μ y / σ y ^ 2) volume a b)
    {x₀ x f₂ : ℝ} (hx₀ : x₀ ∈ I) (hx : x ∈ I) (hμx : ContinuousAt μ x) (hσx : ContinuousAt σ x)
    (hf : HasDerivAt (deriv f) f₂ x) :
    μ x * deriv f x + σ x ^ 2 / 2 * f₂ =
      1 / speedDensity μ σ x₀ x * deriv (fun y => deriv f y / scaleDensity μ σ x₀ y) x := by
  have hL := hasDerivAt_driftIntegral μ σ I hI hσ hint hx₀ hx hμx hσx
  have hs : HasDerivAt (fun y => scaleDensity μ σ x₀ y)
      (scaleDensity μ σ x₀ x * -(2 * μ x / σ x ^ 2)) x := hL.neg.exp
  have hspos : 0 < scaleDensity μ σ x₀ x := exp_pos _
  have hσ0 : σ x ≠ 0 := (hσ x hx).ne'
  have hq : HasDerivAt (fun y => deriv f y / scaleDensity μ σ x₀ y)
      ((f₂ * scaleDensity μ σ x₀ x - deriv f x * (scaleDensity μ σ x₀ x * -(2 * μ x / σ x ^ 2)))
        / scaleDensity μ σ x₀ x ^ 2) x := hf.div hs hspos.ne'
  rw [hq.deriv, speedDensity]
  field_simp
  ring

/-- **The speed density has zero probability current** (the card's Step 4). Under the same
conditions, the speed density `m` solves the stationary Fokker-Planck equation with zero current,
`½ (σ² m)' = μ m`, at every point of `I` where the drift and the noise size are continuous. So the
speed density, scaled to total 1 when its total is finite, is a stationary density. -/
theorem speed_density_has_zero_current (μ σ : ℝ → ℝ) (I : Set ℝ) (hI : IsOpen I)
    (hIc : I.OrdConnected) (hσ : ∀ y ∈ I, 0 < σ y)
    (hint : ∀ a ∈ I, ∀ b ∈ I, IntervalIntegrable (fun y => 2 * μ y / σ y ^ 2) volume a b)
    {x₀ x : ℝ} (hx₀ : x₀ ∈ I) (hx : x ∈ I) (hμx : ContinuousAt μ x) (hσx : ContinuousAt σ x) :
    HasDerivAt (fun y => σ y ^ 2 * speedDensity μ σ x₀ y / 2) (μ x * speedDensity μ σ x₀ x) x := by
  have hL := hasDerivAt_driftIntegral μ σ I hI hσ hint hx₀ hx hμx hσx
  have hE := hL.exp
  have hσ0 : σ x ≠ 0 := (hσ x hx).ne'
  have heq : (fun y => σ y ^ 2 * speedDensity μ σ x₀ y / 2) =ᶠ[nhds x]
      (fun y => exp (∫ t in x₀..y, 2 * μ t / σ t ^ 2)) := by
    filter_upwards [hI.mem_nhds hx] with y hy
    have hσy : σ y ≠ 0 := (hσ y hy).ne'
    simp only [speedDensity, scaleDensity, exp_neg]
    field_simp
  refine (hE.congr_of_eventuallyEq heq).congr_deriv ?_
  simp only [speedDensity, scaleDensity, exp_neg]
  field_simp

/-- **Feller's tests at zero for a CIR rate** (the card's Step 6). Take
`dr = κ(θ - r) dt + σ √r dW` with pull `κ > 0`, level `θ ≥ 0`, noise number `σ > 0`, and a
reference point `x₀ > 0`; let `s` and `m` be its scale and speed densities. Then:
* the scale distance to zero, `S(x₀) - S(0) = ∫_0^{x₀} s`, and the arrive test
  `A(0) = ∫_0^{x₀} (S(y) - S(0)) m(y) dy` are both finite exactly when Feller's ratio
  `2κθ/σ²` is below 1 (zero is reached);
* the depart test `D(0) = ∫_0^{x₀} (S(x₀) - S(y)) m(y) dy` is finite exactly when the level `θ`
  is above zero (a path started at zero can leave).
So zero is regular when `0 < 2κθ/σ² < 1`, an entrance when the ratio is 1 or more, and an exit
when the level is 0. -/
theorem cir_feller_tests_at_zero {κ θ σ x₀ : ℝ} (hκ : 0 < κ) (hθ : 0 ≤ θ) (hσ : 0 < σ)
    (hx₀ : 0 < x₀) :
    let s := scaleDensity (fun y => κ * (θ - y)) (fun y => σ * √y) x₀
    let m := speedDensity (fun y => κ * (θ - y)) (fun y => σ * √y) x₀
    ((IntegrableOn s (Ioo 0 x₀) ∧
        IntegrableOn (fun y => (∫ z in (0 : ℝ)..y, s z) * m y) (Ioo 0 x₀)) ↔
      2 * κ * θ / σ ^ 2 < 1) ∧
    (IntegrableOn (fun y => (∫ z in y..x₀, s z) * m y) (Ioo 0 x₀) ↔ 0 < θ) := by
  intro s m
  have hθν : 0 < θ ↔ 0 < 2 * κ * θ / σ ^ 2 := by
    constructor
    · intro h; positivity
    · intro h
      by_contra h'
      have : θ = 0 := le_antisymm (not_lt.mp h') hθ
      rw [this] at h; simp at h
  rw [hθν]
  exact feller_core hσ hx₀ (by positivity) (by positivity) (by positivity)
    (fun z => exp_pos _) (fun z hz => cir_scaleDensity_eq hσ hx₀ hz)
    (fun y hy => cir_speedDensity_eq hσ hx₀ hy)

/-! The card's worked numbers: pull 1/2 a year, level 4/100, noise 3/10 or 1/10. -/

-- Feller's ratio at noise 0.30 is 4/9, below 1: zero is reached.
example : 2 * (1 / 2 : ℚ) * (4 / 100) / (3 / 10) ^ 2 = 4 / 9 := by norm_num
example : (4 / 9 : ℚ) < 1 := by norm_num
-- Feller's ratio at noise 0.10 is 4: zero is never reached.
example : 2 * (1 / 2 : ℚ) * (4 / 100) / (1 / 10) ^ 2 = 4 := by norm_num
-- The mistake: forgetting the square at noise 0.10 gives 0.4.
example : 2 * (1 / 2 : ℚ) * (4 / 100) / (1 / 10) = 2 / 5 := by norm_num
-- Stationary mean ν σ²/(2κ) = θ at noise 0.30.
example : (4 / 9 : ℚ) * (3 / 10) ^ 2 / (2 * (1 / 2)) = 4 / 100 := by norm_num
-- Stationary variance θ σ²/(2κ): 0.0036 = 0.06² at noise 0.30, 0.0004 = 0.02² at noise 0.10.
example : (4 / 100 : ℚ) * (3 / 10) ^ 2 / (2 * (1 / 2)) = (6 / 100) ^ 2 := by norm_num
example : (4 / 100 : ℚ) * (1 / 10) ^ 2 / (2 * (1 / 2)) = (2 / 100) ^ 2 := by norm_num
-- The straight-line chance (8 - 4)/8 that ignores the drift.
example : ((8 - 4) / 8 : ℚ) = 1 / 2 := by norm_num

#print axioms generator_eq_speed_then_scale_derivative
#print axioms speed_density_has_zero_current
#print axioms cir_feller_tests_at_zero

end ScaleSpeedBoundaries
