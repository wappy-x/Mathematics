-- Convolution: the convolution of real signals on the line commutes, associates when all three have finite area, and obeys Young's inequality whenever 1/p + 1/q = 1 + 1/r.
import Mathlib.Analysis.Convolution
import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.EqHaar
import Mathlib.MeasureTheory.Measure.Haar.Unique
import Mathlib.MeasureTheory.Integral.MeanInequalities

open MeasureTheory
open scoped Convolution ENNReal

theorem lintegral_three_holder {α : Type*} [MeasurableSpace α] {μ : Measure α}
    {X Y Z : α → ℝ≥0∞} (hX : AEMeasurable X μ) (hY : AEMeasurable Y μ) (hZ : AEMeasurable Z μ)
    {a b c : ℝ} (ha : 0 ≤ a) (hb : 0 ≤ b) (hc : 0 ≤ c) (habc : a + b + c = 1) :
    ∫⁻ t, X t ^ a * Y t ^ b * Z t ^ c ∂μ ≤
      (∫⁻ t, X t ∂μ) ^ a * (∫⁻ t, Y t ∂μ) ^ b * (∫⁻ t, Z t ∂μ) ^ c := by
  have h := ENNReal.lintegral_prod_norm_pow_le (μ := μ) (Finset.univ : Finset (Fin 3))
    (f := ![X, Y, Z]) (p := ![a, b, c]) (by intro i _; fin_cases i <;> simpa)
    (by simpa [Fin.sum_univ_three] using habc) (by intro i _; fin_cases i <;> simpa)
  simpa [Fin.prod_univ_three, mul_assoc] using h

theorem young_lintegral_aux (F G : ℝ → ℝ≥0∞) (hF : Measurable F) (hG : Measurable G)
    {P Q R : ℝ} (hP : 1 ≤ P) (hQ : 1 ≤ Q) (hR : 1 ≤ R) (h : 1 / P + 1 / Q = 1 + 1 / R) :
    ∫⁻ x, (∫⁻ y, F y * G (x - y)) ^ R ≤
      (∫⁻ y, F y ^ P) ^ (R / P) * (∫⁻ y, G y ^ Q) ^ (R / Q) := by
  set A := ∫⁻ y, F y ^ P with hA
  set B := ∫⁻ y, G y ^ Q with hB
  have hP0 : 0 < P := by linarith
  have hQ0 : 0 < Q := by linarith
  have hR0 : 0 < R := by linarith
  have hPi : 1 / P ≤ 1 := by rw [div_le_one hP0]; exact hP
  have hQi : 1 / Q ≤ 1 := by rw [div_le_one hQ0]; exact hQ
  set a : ℝ := 1 / R with ha_def
  set b : ℝ := 1 - 1 / Q with hb_def
  set c : ℝ := 1 - 1 / P with hc_def
  have ha : 0 ≤ a := by positivity
  have hb : 0 ≤ b := by linarith
  have hc : 0 ≤ c := by linarith
  have habc : a + b + c = 1 := by linarith
  have hPab : P * a + P * b = 1 := by
    rw [← mul_add, show a + b = 1 / P by linarith]; field_simp
  have hQac : Q * a + Q * c = 1 := by
    rw [← mul_add, show a + c = 1 / Q by linarith]; field_simp
  have hid : ∀ x y, F y * G (x - y) =
      (F y ^ P * G (x - y) ^ Q) ^ a * (F y ^ P) ^ b * (G (x - y) ^ Q) ^ c := by
    intro x y
    rw [ENNReal.mul_rpow_of_nonneg _ _ ha, ← ENNReal.rpow_mul, ← ENNReal.rpow_mul,
      ← ENNReal.rpow_mul, ← ENNReal.rpow_mul]
    calc F y * G (x - y) = F y ^ (P * a + P * b) * G (x - y) ^ (Q * a + Q * c) := by
          rw [hPab, hQac]; simp
      _ = _ := by
          rw [ENNReal.rpow_add_of_nonneg _ _ (by positivity) (by positivity),
            ENNReal.rpow_add_of_nonneg _ _ (by positivity) (by positivity)]; ring
  have hpt : ∀ x, ∫⁻ y, F y * G (x - y) ≤
      (∫⁻ y, F y ^ P * G (x - y) ^ Q) ^ a * A ^ b * B ^ c := by
    intro x
    simp_rw [hid x]
    have hGx : Measurable fun y => G (x - y) := hG.comp (measurable_const.sub measurable_id)
    calc _ ≤ (∫⁻ y, F y ^ P * G (x - y) ^ Q) ^ a * A ^ b * (∫⁻ y, G (x - y) ^ Q) ^ c :=
          lintegral_three_holder (((hF.pow_const P).mul (hGx.pow_const Q)).aemeasurable)
            (hF.pow_const P).aemeasurable (hGx.pow_const Q).aemeasurable ha hb hc habc
      _ = _ := by rw [lintegral_sub_left_eq_self (fun z => G z ^ Q) x]
  have haR : a * R = 1 := by rw [ha_def]; field_simp
  have hpt2 : ∀ x, (∫⁻ y, F y * G (x - y)) ^ R ≤
      (∫⁻ y, F y ^ P * G (x - y) ^ Q) * (A ^ (b * R) * B ^ (c * R)) := by
    intro x
    calc _ ≤ ((∫⁻ y, F y ^ P * G (x - y) ^ Q) ^ a * A ^ b * B ^ c) ^ R :=
          ENNReal.rpow_le_rpow (hpt x) hR0.le
      _ = _ := by
          rw [ENNReal.mul_rpow_of_nonneg _ _ hR0.le, ENNReal.mul_rpow_of_nonneg _ _ hR0.le,
            ← ENNReal.rpow_mul, ← ENNReal.rpow_mul, ← ENNReal.rpow_mul, haR,
            ENNReal.rpow_one, mul_assoc]
  have hmeas : Measurable (Function.uncurry fun x y => F y ^ P * G (x - y) ^ Q) :=
    ((hF.comp measurable_snd).pow_const P).mul
      ((hG.comp (measurable_fst.sub measurable_snd)).pow_const Q)
  have hK : ∫⁻ x, ∫⁻ y, F y ^ P * G (x - y) ^ Q = A * B := by
    rw [lintegral_lintegral_swap hmeas.aemeasurable]
    have : ∀ y, ∫⁻ x, F y ^ P * G (x - y) ^ Q = F y ^ P * B := by
      intro y
      have hm : Measurable fun x => G (x - y) ^ Q :=
        (hG.comp (measurable_id.sub measurable_const)).pow_const Q
      rw [lintegral_const_mul _ hm]
      rw [lintegral_sub_right_eq_self (fun z => G z ^ Q) y]
    simp_rw [this]
    rw [lintegral_mul_const _ (hF.pow_const P)]
  have e1 : R / P = 1 + b * R := by
    rw [show R / P = R * (1 / P) by ring, show 1 / P = 1 + 1 / R - 1 / Q by linarith, hb_def]
    field_simp
    ring
  have e2 : R / Q = 1 + c * R := by
    rw [show R / Q = R * (1 / Q) by ring, show 1 / Q = 1 + 1 / R - 1 / P by linarith, hc_def]
    field_simp
    ring
  calc ∫⁻ x, (∫⁻ y, F y * G (x - y)) ^ R
      ≤ ∫⁻ x, (∫⁻ y, F y ^ P * G (x - y) ^ Q) * (A ^ (b * R) * B ^ (c * R)) :=
        lintegral_mono hpt2
    _ = A * B * (A ^ (b * R) * B ^ (c * R)) := by
        have hm : Measurable fun x => ∫⁻ y, F y ^ P * G (x - y) ^ Q :=
          hmeas.lintegral_prod_right'
        rw [lintegral_mul_const'' _ hm.aemeasurable, hK]
    _ = A ^ (R / P) * B ^ (R / Q) := by
        rw [e1, e2, ENNReal.rpow_add_of_nonneg _ _ zero_le_one (by positivity),
          ENNReal.rpow_add_of_nonneg _ _ zero_le_one (by positivity), ENNReal.rpow_one,
          ENNReal.rpow_one]
        ring

#print axioms lintegral_three_holder
#print axioms young_lintegral_aux

/-- **Young's inequality.** Let `p`, `q`, `r` be exponents from 1 to ∞ with
`1/p + 1/q = 1 + 1/r` (where `1/∞ = 0`). For every real signal `f` on the line of finite
p-size and every real signal `g` of finite q-size, the r-size of the convolution
`(f * g)(t) = ∫ f(s) g(t - s) ds` is at most the p-size of `f` times the q-size of `g`. -/
theorem youngs_inequality (p q r : ℝ≥0∞) (hp : 1 ≤ p) (hq : 1 ≤ q) (hr : 1 ≤ r)
    (hpqr : p⁻¹ + q⁻¹ = 1 + r⁻¹) (f g : ℝ → ℝ) (hf : MemLp f p) (hg : MemLp g q) :
    eLpNorm (f ⋆ g) r ≤ eLpNorm f p * eLpNorm g q := by
  by_cases hrtop : r = ⊤
  · subst hrtop
    simp only [ENNReal.inv_top, add_zero] at hpqr
    have : p.HolderConjugate q := ENNReal.holderConjugate_iff.mpr hpqr
    rw [eLpNorm_exponent_top (hf.aestronglyMeasurable.convolution _ hg.aestronglyMeasurable)]
    refine eLpNormEssSup_le_of_ae_enorm_bound (Filter.Eventually.of_forall fun x => ?_)
    have h1 := enorm_convolution_le (p := p) (q := q) (μ := volume)
      (ContinuousLinearMap.lsmul ℝ ℝ) hf.aestronglyMeasurable hg.aestronglyMeasurable x
    have h2 : ‖(ContinuousLinearMap.lsmul ℝ ℝ : ℝ →L[ℝ] ℝ →L[ℝ] ℝ)‖ₑ ≤ (1 : ℝ≥0∞) :=
      ContinuousLinearMap.opENorm_lsmul_le
    calc _ ≤ _ := h1
      _ ≤ 1 * eLpNorm f p * eLpNorm g q := by gcongr
      _ = _ := by rw [one_mul]
  have hr0 : r ≠ 0 := (lt_of_lt_of_le zero_lt_one hr).ne'
  have hp0 : p ≠ 0 := (lt_of_lt_of_le zero_lt_one hp).ne'
  have hq0 : q ≠ 0 := (lt_of_lt_of_le zero_lt_one hq).ne'
  have hq1 : q⁻¹ ≤ 1 := ENNReal.inv_le_one.mpr hq
  have hp1 : p⁻¹ ≤ 1 := ENNReal.inv_le_one.mpr hp
  have hptop : p ≠ ⊤ := by
    rintro rfl
    rw [ENNReal.inv_top, zero_add] at hpqr
    have h1 : 1 + r⁻¹ ≤ 1 + 0 := by rw [add_zero, ← hpqr]; exact hq1
    have h2 := (ENNReal.add_le_add_iff_left ENNReal.one_ne_top).1 h1
    exact hrtop (ENNReal.inv_eq_zero.1 (nonpos_iff_eq_zero.1 h2))
  have hqtop : q ≠ ⊤ := by
    rintro rfl
    rw [ENNReal.inv_top, add_zero] at hpqr
    have h1 : 1 + r⁻¹ ≤ 1 + 0 := by rw [add_zero, ← hpqr]; exact hp1
    have h2 := (ENNReal.add_le_add_iff_left ENNReal.one_ne_top).1 h1
    exact hrtop (ENNReal.inv_eq_zero.1 (nonpos_iff_eq_zero.1 h2))
  have hP : 1 ≤ p.toReal := by
    simpa using ENNReal.toReal_mono hptop hp
  have hQ : 1 ≤ q.toReal := by
    simpa using ENNReal.toReal_mono hqtop hq
  have hR : 1 ≤ r.toReal := by
    simpa using ENNReal.toReal_mono hrtop hr
  have h : 1 / p.toReal + 1 / q.toReal = 1 + 1 / r.toReal := by
    have := congrArg ENNReal.toReal hpqr
    rw [ENNReal.toReal_add (ENNReal.inv_ne_top.2 hp0) (ENNReal.inv_ne_top.2 hq0),
      ENNReal.toReal_add ENNReal.one_ne_top (ENNReal.inv_ne_top.2 hr0),
      ENNReal.toReal_inv, ENNReal.toReal_inv, ENNReal.toReal_inv, ENNReal.toReal_one] at this
    simpa [one_div] using this
  have hconv : f ⋆ g = hf.aestronglyMeasurable.mk f ⋆ hg.aestronglyMeasurable.mk g := convolution_congr _ hf.aestronglyMeasurable.ae_eq_mk hg.aestronglyMeasurable.ae_eq_mk
  rw [hconv, eLpNorm_congr_ae hf.aestronglyMeasurable.ae_eq_mk, eLpNorm_congr_ae hg.aestronglyMeasurable.ae_eq_mk]
  have hmf : StronglyMeasurable (hf.aestronglyMeasurable.mk f) := hf.aestronglyMeasurable.stronglyMeasurable_mk
  have hmg : StronglyMeasurable (hg.aestronglyMeasurable.mk g) := hg.aestronglyMeasurable.stronglyMeasurable_mk
  set f' := hf.aestronglyMeasurable.mk f
  set g' := hg.aestronglyMeasurable.mk g
  rw [eLpNorm_eq_lintegral_rpow_enorm_toReal hr0 hrtop
      (hmf.aestronglyMeasurable.convolution _ hmg.aestronglyMeasurable),
    eLpNorm_eq_lintegral_rpow_enorm_toReal hp0 hptop hmf.aestronglyMeasurable,
    eLpNorm_eq_lintegral_rpow_enorm_toReal hq0 hqtop hmg.aestronglyMeasurable]
  have hptwise : ∀ x, ‖(f' ⋆ g') x‖ₑ ≤ ∫⁻ y, ‖f' y‖ₑ * ‖g' (x - y)‖ₑ := by
    intro x
    rw [convolution_lsmul]
    refine (enorm_integral_le_lintegral_enorm _).trans_eq ?_
    simp [enorm_mul]
  have hR0 : 0 < r.toReal := by linarith
  calc (∫⁻ x, ‖(f' ⋆ g') x‖ₑ ^ r.toReal) ^ (1 / r.toReal)
      ≤ (∫⁻ x, (∫⁻ y, ‖f' y‖ₑ * ‖g' (x - y)‖ₑ) ^ r.toReal) ^ (1 / r.toReal) := by
        gcongr with x; exact hptwise x
    _ ≤ ((∫⁻ y, ‖f' y‖ₑ ^ p.toReal) ^ (r.toReal / p.toReal) *
          (∫⁻ y, ‖g' y‖ₑ ^ q.toReal) ^ (r.toReal / q.toReal)) ^ (1 / r.toReal) := by
        gcongr
        exact young_lintegral_aux _ _ hmf.measurable.enorm hmg.measurable.enorm hP hQ hR h
    _ = _ := by
        rw [ENNReal.mul_rpow_of_nonneg _ _ (by positivity), ← ENNReal.rpow_mul,
          ← ENNReal.rpow_mul]
        congr 2 <;> field_simp

/-- **Convolution commutes.** Sliding the lamp across the window gives the same reading as
sliding the window across the lamp: `f * g = g * f` for real signals on the line. -/
theorem convolution_comm_real (f g : ℝ → ℝ) : f ⋆ g = g ⋆ f := by
  refine convolution_symm _ ?_
  ext x y
  simp [mul_comm]

/-- **Convolution associates.** For three real signals on the line of finite area,
`(f * g) * u = f * (g * u)` at every time outside a set of total length zero. -/
theorem convolution_assoc_real (f g u : ℝ → ℝ) (hf : Integrable f) (hg : Integrable g)
    (hu : Integrable u) : (f ⋆ g) ⋆ u =ᵐ[volume] f ⋆ (g ⋆ u) := by
  have h1 := hf.ae_convolution_exists (ContinuousLinearMap.lsmul ℝ ℝ) hg
  have h2 := hg.norm.ae_convolution_exists (ContinuousLinearMap.mul ℝ ℝ) hu.norm
  have h3 := hf.norm.ae_convolution_exists (ContinuousLinearMap.mul ℝ ℝ)
    (hg.norm.integrable_convolution (ContinuousLinearMap.mul ℝ ℝ) hu.norm)
  filter_upwards [h3] with x hx
  exact convolution_assoc (ContinuousLinearMap.lsmul ℝ ℝ) (ContinuousLinearMap.lsmul ℝ ℝ)
    (ContinuousLinearMap.lsmul ℝ ℝ) (ContinuousLinearMap.lsmul ℝ ℝ)
    (fun a b c => by simp [mul_assoc]) hf.1 hg.1 hu.1 h1 h2 hx

/-! ### The card's whole-number worked examples -/

/-- The finite twin: discrete convolution of sequences indexed by sample number,
`(a * b)[k] = ∑_{i + j = k} a[i] b[j]`. -/
def dconv (a b : ℕ → ℤ) (k : ℕ) : ℤ := ∑ x ∈ Finset.antidiagonal k, a x.1 * b x.2

/-- A finite sequence, zero after its last entry. -/
def seqOf (l : List ℤ) (k : ℕ) : ℤ := l.getD k 0

-- gate * gate = 1, 2, 3, 4, 3, 2, 1: the triangle again.
example : (List.range 7).map (dconv (seqOf [1, 1, 1, 1]) (seqOf [1, 1, 1, 1])) =
    [1, 2, 3, 4, 3, 2, 1] := by decide

-- gate * ramp = ramp * gate = 1, 3, 6, 10, 9, 7, 4.
example : (List.range 7).map (dconv (seqOf [1, 1, 1, 1]) (seqOf [1, 2, 3, 4])) =
    [1, 3, 6, 10, 9, 7, 4] := by decide

example : (List.range 7).map (dconv (seqOf [1, 2, 3, 4]) (seqOf [1, 1, 1, 1])) =
    [1, 3, 6, 10, 9, 7, 4] := by decide

-- (gate * ramp) * u = gate * (ramp * u) = 1, 3, 8, 16, 21, 27, 22, 14, 8, with u = 1, 0, 2.
example : (List.range 9).map
    (dconv (dconv (seqOf [1, 1, 1, 1]) (seqOf [1, 2, 3, 4])) (seqOf [1, 0, 2])) =
    [1, 3, 8, 16, 21, 27, 22, 14, 8] := by decide

example : (List.range 9).map
    (dconv (seqOf [1, 1, 1, 1]) (dconv (seqOf [1, 2, 3, 4]) (seqOf [1, 0, 2]))) =
    [1, 3, 8, 16, 21, 27, 22, 14, 8] := by decide

-- The exponent rule at p = q = 4/3, r = 2: 3/4 + 3/4 = 1 + 1/2.
example : ((4 / 3 : ℚ))⁻¹ + (4 / 3 : ℚ)⁻¹ = 1 + (2 : ℚ)⁻¹ := by norm_num

-- The rule at p = 3, q = 6/5, r = 6: 1/3 + 5/6 = 1 + 1/6.
example : (3 : ℚ)⁻¹ + (6 / 5 : ℚ)⁻¹ = 1 + (6 : ℚ)⁻¹ := by norm_num

-- p = q = r = 2 breaks the rule: 1/2 + 1/2 is 1, not 3/2.
example : (2 : ℚ)⁻¹ + (2 : ℚ)⁻¹ ≠ 1 + (2 : ℚ)⁻¹ := by norm_num

#print axioms youngs_inequality
#print axioms convolution_comm_real
#print axioms convolution_assoc_real
