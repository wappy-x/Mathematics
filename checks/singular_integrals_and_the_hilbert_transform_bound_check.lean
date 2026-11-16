-- Singular integrals: a multiplier operator's energy is at most the multiplier's largest size times the input's energy, the Hilbert transform keeps energy exactly, and a gate's Hilbert partner is the log formula with level sets of length 2W/sinh(πα), infinite area and no ceiling.
import Mathlib.Analysis.Fourier.LpSpace
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Basic.Real.Sign
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.NonIntegrable
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp

open MeasureTheory Filter Topology FourierTransform Real

/-- The energy bound by the multiplier. If an operator turns the finite-energy signal `f` into
`Tf` by multiplying its Fourier transform by `m(ξ)`, frequency by frequency, and `|m(ξ)| ≤ M`
at every frequency, then `‖Tf‖₂ ≤ M ‖f‖₂`. For the Hilbert transform, whose multiplier is
`-i sgn(ξ)`, the energy is kept exactly: `‖Hf‖₂ = ‖f‖₂`. -/
theorem energy_bound_by_multiplier :
    (∀ (f Tf : Lp (α := ℝ) ℂ 2) (m : ℝ → ℂ) (M : ℝ),
        (∀ ξ, ‖m ξ‖ ≤ M) →
        ((𝓕 Tf : Lp (α := ℝ) ℂ 2) : ℝ → ℂ) =ᵐ[volume]
          (fun ξ => m ξ * ((𝓕 f : Lp (α := ℝ) ℂ 2) : ℝ → ℂ) ξ) →
        ‖Tf‖ ≤ M * ‖f‖) ∧
    (∀ (f Hf : Lp (α := ℝ) ℂ 2),
        ((𝓕 Hf : Lp (α := ℝ) ℂ 2) : ℝ → ℂ) =ᵐ[volume]
          (fun ξ => (-Complex.I * (Real.sign ξ : ℂ)) * ((𝓕 f : Lp (α := ℝ) ℂ 2) : ℝ → ℂ) ξ) →
        ‖Hf‖ = ‖f‖) := by
  refine ⟨fun f Tf m M hm h => ?_, fun f Hf h => ?_⟩
  · rw [← Lp.norm_fourier_eq Tf, ← Lp.norm_fourier_eq f]
    apply Lp.norm_le_mul_norm_of_ae_le_mul
    filter_upwards [h] with ξ hξ
    rw [hξ, norm_mul]
    exact mul_le_mul_of_nonneg_right (hm ξ) (norm_nonneg _)
  · rw [← Lp.norm_fourier_eq Hf, ← Lp.norm_fourier_eq f]
    have h0 : ∀ᵐ ξ ∂(volume : Measure ℝ), ξ ≠ 0 := by
      have : (volume : Measure ℝ) {(0:ℝ)} = 0 := Real.volume_singleton
      exact measure_eq_zero_iff_ae_notMem.mp this |>.mono fun x hx => by simpa using hx
    have key : ∀ᵐ ξ ∂(volume : Measure ℝ),
        ‖((𝓕 Hf : Lp ℂ 2 (volume : Measure ℝ)) : ℝ → ℂ) ξ‖ = ‖((𝓕 f : Lp ℂ 2 (volume : Measure ℝ)) : ℝ → ℂ) ξ‖ := by
      filter_upwards [h, h0] with ξ hξ hne
      rw [hξ, norm_mul, norm_mul, norm_neg, Complex.norm_I, one_mul]
      rcases lt_or_gt_of_ne hne with hl | hl
      · simp [Real.sign_of_neg hl]
      · simp [Real.sign_of_pos hl]
    apply le_antisymm
    · exact Lp.norm_le_norm_of_ae_le (key.mono fun x hx => hx.le)
    · exact Lp.norm_le_norm_of_ae_le (key.mono fun x hx => hx.ge)

/-- The integral of `1/(t - u)` over an open interval that stays on one side of `u = t`. -/
lemma hilbert_gate_integral_Ioo (t p q : ℝ) (hpq : p ≤ q) (h0 : (0 : ℝ) ∉ Set.uIcc (t - q) (t - p)) :
    ∫ u in Set.Ioo p q, 1 / (t - u) = Real.log ((t - p) / (t - q)) := by
  rw [← integral_Ioc_eq_integral_Ioo, ← intervalIntegral.integral_of_le hpq]
  have := intervalIntegral.integral_comp_sub_left (fun x : ℝ => 1 / x) (a := p) (b := q) t
  rw [this, integral_one_div h0]

#print axioms hilbert_gate_integral_Ioo

/-- `1/(t - u)` is integrable on an open interval whose closure avoids `u = t`. -/
lemma hilbert_gate_integrableOn (t p q : ℝ) (h : ∀ u ∈ Set.Icc p q, t - u ≠ 0) :
    IntegrableOn (fun u : ℝ => 1 / (t - u)) (Set.Ioo p q) := by
  have hc : ContinuousOn (fun u : ℝ => 1 / (t - u)) (Set.Icc p q) :=
    ContinuousOn.div continuousOn_const (by fun_prop) h
  exact (hc.integrableOn_Icc).mono_set Set.Ioo_subset_Icc_self

#print axioms hilbert_gate_integrableOn

/-- The ratio test `q |t - a| < |t + a|` holds exactly on the interval
`(a (q-1)/(q+1), a (q+1)/(q-1))`. -/
lemma hilbert_gate_ratio_iff (a q t : ℝ) (ha : 0 < a) (hq : 1 < q) :
    q * |t - a| < |t + a| ↔ a * (q - 1) / (q + 1) < t ∧ t < a * (q + 1) / (q - 1) := by
  rw [div_lt_iff₀ (by linarith), lt_div_iff₀ (by linarith)]
  have h1 : q * |t - a| = |q * (t - a)| := by
    rw [abs_mul, abs_of_pos (by linarith : (0:ℝ) < q)]
  rw [h1, ← sq_lt_sq]
  have hfac : (t + a) ^ 2 - (q * (t - a)) ^ 2 =
      (a * (q + 1) - t * (q - 1)) * (t * (q + 1) - a * (q - 1)) := by ring
  have hsum : (q + 1) * (a * (q + 1) - t * (q - 1)) + (q - 1) * (t * (q + 1) - a * (q - 1))
      = 4 * a * q := by ring
  constructor
  · intro h
    have hPQ : 0 < (a * (q + 1) - t * (q - 1)) * (t * (q + 1) - a * (q - 1)) := by
      rw [← hfac]; linarith
    rcases mul_pos_iff.mp hPQ with ⟨hP, hQ⟩ | ⟨hP, hQ⟩
    · constructor <;> linarith
    · exfalso
      have e1 := mul_neg_of_pos_of_neg (by linarith : (0:ℝ) < q + 1) hP
      have e2 := mul_neg_of_pos_of_neg (by linarith : (0:ℝ) < q - 1) hQ
      have : 0 < 4 * a * q := by positivity
      linarith
  · rintro ⟨h1, h2⟩
    have : 0 < (a * (q + 1) - t * (q - 1)) * (t * (q + 1) - a * (q - 1)) :=
      mul_pos (by linarith) (by linarith)
    linarith

#print axioms hilbert_gate_ratio_iff

/-- Membership in the level set of `|log |(t + a)/(t - a)||` above `s`. -/
lemma hilbert_gate_level_mem (a s t : ℝ) (ha : 0 < a) (hs : 0 < s) :
    s < abs (Real.log |(t + a) / (t - a)|) ↔
      t ≠ a ∧ t ≠ -a ∧
        ((a * (exp s - 1) / (exp s + 1) < t ∧ t < a * (exp s + 1) / (exp s - 1)) ∨
         (-(a * (exp s + 1) / (exp s - 1)) < t ∧ t < -(a * (exp s - 1) / (exp s + 1)))) := by
  have hq : 1 < exp s := Real.one_lt_exp_iff.mpr hs
  have hq0 : 0 < exp s := exp_pos s
  by_cases hta : t = a
  · subst hta; simp; linarith
  by_cases htb : t = -a
  · subst htb; simp; linarith
  have hd : 0 < |t - a| := abs_pos.mpr (sub_ne_zero.mpr hta)
  have hn : t + a ≠ 0 := by intro h; apply htb; linarith
  have hx : 0 < |(t + a) / (t - a)| := abs_pos.mpr (div_ne_zero hn (sub_ne_zero.mpr hta))
  simp only [ne_eq, hta, htb, not_false_eq_true, true_and]
  rw [lt_abs, Real.lt_log_iff_exp_lt hx, lt_neg, Real.log_lt_iff_lt_exp hx, abs_div,
    lt_div_iff₀ hd, div_lt_iff₀ hd, Real.exp_neg]
  have h2 : |t + a| < (exp s)⁻¹ * |t - a| ↔ exp s * |t + a| < |t - a| := by
    rw [inv_mul_eq_div, lt_div_iff₀ hq0, mul_comm]
  rw [h2, hilbert_gate_ratio_iff a (exp s) t ha hq]
  have h3 := hilbert_gate_ratio_iff a (exp s) (-t) ha hq
  rw [show -t - a = -(t + a) by ring, show -t + a = -(t - a) by ring, abs_neg, abs_neg] at h3
  rw [h3]
  constructor
  · rintro (⟨h1, h2⟩ | ⟨h1, h2⟩)
    · exact Or.inl ⟨h1, h2⟩
    · exact Or.inr ⟨by linarith, by linarith⟩
  · rintro (⟨h1, h2⟩ | ⟨h1, h2⟩)
    · exact Or.inl ⟨h1, h2⟩
    · exact Or.inr ⟨by linarith, by linarith⟩

#print axioms hilbert_gate_level_mem

/-- The length of the level set of the gate's Hilbert partner. -/
lemma hilbert_gate_level_volume (W α : ℝ) (hW : 0 < W) (hα : 0 < α) :
    volume {t : ℝ | α < abs ((1 / π) * Real.log |(t + W / 2) / (t - W / 2)|)} =
        ENNReal.ofReal (2 * W / Real.sinh (π * α)) := by
  set a := W / 2 with ha_def
  have ha : 0 < a := by positivity
  set s := π * α with hs_def
  have hs : 0 < s := by positivity
  set q := exp s with hq_def
  have hq : 1 < q := Real.one_lt_exp_iff.mpr hs
  set A := a * (q - 1) / (q + 1) with hA
  set B := a * (q + 1) / (q - 1) with hB
  have hA0 : 0 < A := by rw [hA]; apply div_pos <;> nlinarith
  have hAB : A < B := by
    rw [hA, hB, div_lt_div_iff₀ (by linarith) (by linarith)]
    nlinarith
  have hset : {t : ℝ | α < abs ((1 / π) * Real.log |(t + a) / (t - a)|)} =
      (Set.Ioo A B ∪ Set.Ioo (-B) (-A)) \ {a, -a} := by
    ext t
    simp only [Set.mem_ofPred_eq, Set.mem_sdiff, Set.mem_union, Set.mem_Ioo, Set.mem_insert_iff,
      Set.mem_singleton_iff, not_or]
    rw [abs_mul, abs_of_pos (by positivity : (0:ℝ) < 1 / π), one_div, ← div_eq_inv_mul,
      lt_div_iff₀ pi_pos, mul_comm, hilbert_gate_level_mem a s t ha hs]
    tauto
  rw [hset, measure_sdiff_null ((Set.toFinite _).measure_zero _),
    measure_union _ measurableSet_Ioo, Real.volume_Ioo, Real.volume_Ioo,
    ← ENNReal.ofReal_add (by linarith) (by linarith)]
  · congr 1
    rw [Real.sinh_eq, Real.exp_neg, ← hq_def, hA, hB, ha_def]
    have h1 : q - 1 ≠ 0 := by linarith
    have h2 : q + 1 ≠ 0 := by linarith
    have hq0 : q ≠ 0 := by linarith
    have h3 : q - q⁻¹ ≠ 0 := by
      have : q⁻¹ < 1 := inv_lt_one_of_one_lt₀ hq
      linarith
    rw [show q - q⁻¹ = (q - 1) * (q + 1) / q by field_simp; ring]
    field_simp
    ring
  · rw [Set.disjoint_left]
    rintro u ⟨h1, _⟩ ⟨_, h2⟩
    linarith

#print axioms hilbert_gate_level_volume

/-- The gate's partner, by the kernel. For the gate of width `W` (1 on `|u| < W/2`, 0 elsewhere),
the principal-value integral `(1/π) ∫ g(u)/(t - u) du`, with a gap of equal half-width `ε`
cut out on both sides of `u = t` and the gap then shrunk, tends to
`(1/π) ln |(t + W/2)/(t - W/2)|` at every `t` off the two edges. -/
theorem gate_hilbert_partner (W t : ℝ) (hW : 0 < W) (ht₁ : t ≠ W / 2) (ht₂ : t ≠ -(W / 2)) :
    Tendsto
      (fun ε : ℝ => (1 / π) * ∫ u in {u : ℝ | ε < |t - u|},
        Set.indicator (Set.Ioo (-(W / 2)) (W / 2)) (fun _ => (1 : ℝ)) u / (t - u))
      (𝓝[>] 0) (𝓝 ((1 / π) * Real.log |(t + W / 2) / (t - W / 2)|)) := by
  set a := W / 2 with ha_def
  have ha : 0 < a := by positivity
  have hd1 : 0 < |t - a| := abs_pos.mpr (sub_ne_zero.mpr ht₁)
  have hd2 : 0 < |t + a| := abs_pos.mpr (by intro h; apply ht₂; linarith)
  refine tendsto_const_nhds.congr' ?_
  filter_upwards [Ioo_mem_nhdsGT (lt_min hd1 hd2)] with ε hε
  obtain ⟨hε0, hεδ⟩ := hε
  have hε1 : ε < |t - a| := lt_of_lt_of_le hεδ (min_le_left _ _)
  have hε2 : ε < |t + a| := lt_of_lt_of_le hεδ (min_le_right _ _)
  congr 1
  have hind : (fun u => Set.indicator (Set.Ioo (-a) a) (fun _ => (1 : ℝ)) u / (t - u)) =
      Set.indicator (Set.Ioo (-a) a) (fun u => 1 / (t - u)) := by
    funext u
    by_cases hu : u ∈ Set.Ioo (-a) a
    · simp [Set.indicator_of_mem hu]
    · simp [Set.indicator_of_notMem hu]
  rw [hind, setIntegral_indicator measurableSet_Ioo]
  rcases lt_trichotomy t (-a) with hlt | heq | hgt
  · -- the gate lies wholly to the right of `t`
    have hset : {u : ℝ | ε < |t - u|} ∩ Set.Ioo (-a) a = Set.Ioo (-a) a := by
      ext u
      simp only [Set.mem_inter_iff, Set.mem_ofPred_eq, Set.mem_Ioo, and_iff_right_iff_imp]
      rintro ⟨h1, h2⟩
      rw [abs_of_neg (by linarith : t + a < 0)] at hε2
      rw [abs_of_neg (by linarith : t - u < 0)]
      linarith
    rw [hset, hilbert_gate_integral_Ioo t (-a) a (by linarith)]
    · rw [Real.log_abs, sub_neg_eq_add]
    · rw [Set.uIcc_of_le (by linarith)]
      simp only [Set.mem_Icc, not_and, not_le]
      intro _; linarith
  · exact absurd heq ht₂
  · rcases lt_trichotomy t a with hlt' | heq' | hgt'
    · -- `t` inside the gate: two pieces
      rw [abs_of_neg (by linarith : t - a < 0)] at hε1
      rw [abs_of_pos (by linarith : 0 < t + a)] at hε2
      have hset : {u : ℝ | ε < |t - u|} ∩ Set.Ioo (-a) a =
          Set.Ioo (-a) (t - ε) ∪ Set.Ioo (t + ε) a := by
        ext u
        simp only [Set.mem_inter_iff, Set.mem_ofPred_eq, Set.mem_Ioo, Set.mem_union, lt_abs]
        constructor
        · rintro ⟨h | h, h1, h2⟩
          · left; constructor <;> linarith
          · right; constructor <;> linarith
        · rintro (⟨h1, h2⟩ | ⟨h1, h2⟩)
          · exact ⟨Or.inl (by linarith), by linarith, by linarith⟩
          · exact ⟨Or.inr (by linarith), by linarith, by linarith⟩
      have hdisj : Disjoint (Set.Ioo (-a) (t - ε)) (Set.Ioo (t + ε) a) := by
        rw [Set.disjoint_left]
        rintro u ⟨_, h1⟩ ⟨h2, _⟩
        linarith
      rw [hset, setIntegral_union hdisj measurableSet_Ioo
        (hilbert_gate_integrableOn t _ _ (fun u hu => by
          have := hu.2; intro h; linarith))
        (hilbert_gate_integrableOn t _ _ (fun u hu => by
          have := hu.1; intro h; linarith))]
      rw [hilbert_gate_integral_Ioo t (-a) (t - ε) (by linarith),
        hilbert_gate_integral_Ioo t (t + ε) a (by linarith)]
      · rw [← Real.log_mul (by
            apply div_ne_zero <;> · intro h; linarith)
          (by apply div_ne_zero <;> · intro h; linarith)]
        rw [abs_of_neg (div_neg_of_pos_of_neg (by linarith) (by linarith))]
        congr 1
        have h1 : t - (t - ε) ≠ 0 := by intro h; linarith
        have h2 : t - a ≠ 0 := by intro h; linarith
        field_simp
        ring
      · rw [Set.uIcc_of_le (by linarith)]
        simp only [Set.mem_Icc, not_and, not_le]
        intro _; linarith
      · rw [Set.uIcc_of_le (by linarith)]
        simp only [Set.mem_Icc, not_and, not_le]
        intro h; linarith
    · exact absurd heq' ht₁
    · -- the gate lies wholly to the left of `t`
      have hset : {u : ℝ | ε < |t - u|} ∩ Set.Ioo (-a) a = Set.Ioo (-a) a := by
        ext u
        simp only [Set.mem_inter_iff, Set.mem_ofPred_eq, Set.mem_Ioo, and_iff_right_iff_imp]
        rintro ⟨h1, h2⟩
        rw [abs_of_pos (by linarith : 0 < t - a)] at hε1
        rw [abs_of_pos (by linarith : 0 < t - u)]
        linarith
      rw [hset, hilbert_gate_integral_Ioo t (-a) a (by linarith)]
      · rw [Real.log_abs, sub_neg_eq_add]
      · rw [Set.uIcc_of_le (by linarith)]
        simp only [Set.mem_Icc, not_and, not_le]
        intro h; linarith

/-- The gate's partner `Hg(t) = (1/π) ln |(t + W/2)/(t - W/2)|` exceeds the level `α > 0` in size
on a set of total length `2W / sinh(πα)` (weak type at `p = 1`), yet it has infinite area
(it is not integrable, so `p = 1` fails) and no ceiling (it is not essentially bounded,
so `p = ∞` fails). -/
theorem gate_partner_level_sets_and_failure (W α : ℝ) (hW : 0 < W) (hα : 0 < α) :
    volume {t : ℝ | α < abs ((1 / π) * Real.log |(t + W / 2) / (t - W / 2)|)} =
        ENNReal.ofReal (2 * W / Real.sinh (π * α)) ∧
    ¬ Integrable (fun t : ℝ => (1 / π) * Real.log |(t + W / 2) / (t - W / 2)|) volume ∧
    ¬ MemLp (fun t : ℝ => (1 / π) * Real.log |(t + W / 2) / (t - W / 2)|) ⊤ volume := by
  refine ⟨hilbert_gate_level_volume W α hW hα, ?_, ?_⟩
  · intro hint
    set a := W / 2 with ha_def
    have ha : 0 < a := by positivity
    have hinv : IntegrableOn (fun t : ℝ => t⁻¹) (Set.Ioi a) := by
      refine Integrable.mono' ((hint.const_mul (π / a)).integrableOn)
        measurable_inv.aestronglyMeasurable ?_
      refine ae_restrict_of_forall_mem measurableSet_Ioi fun t ht => ?_
      have ht : a < t := ht
      have ht0 : 0 < t := by linarith
      have hpos : 0 < (t + a) / (t - a) := div_pos (by linarith) (by linarith)
      have hlog := Real.one_sub_inv_le_log_of_pos hpos
      have heq : 1 - ((t + a) / (t - a))⁻¹ = 2 * a / (t + a) := by
        have : t - a ≠ 0 := by linarith
        have : t + a ≠ 0 := by linarith
        field_simp
        ring
      have hle : a / t ≤ 2 * a / (t + a) := by
        rw [div_le_div_iff₀ ht0 (by linarith)]
        nlinarith
      rw [Real.norm_eq_abs, abs_of_pos (inv_pos.mpr ht0), abs_of_pos hpos]
      have : π / a * (1 / π * Real.log ((t + a) / (t - a))) = Real.log ((t + a) / (t - a)) / a := by
        field_simp
      rw [this, le_div_iff₀ ha, ← div_eq_inv_mul]
      linarith
    exact not_integrableOn_Ioi_inv hinv
  · intro hmem
    set g := fun t : ℝ => (1 / π) * Real.log |(t + W / 2) / (t - W / 2)| with hg
    have hlt : eLpNormEssSup g volume < ⊤ := by
      have := hmem.eLpNorm_lt_top
      rwa [eLpNorm_exponent_top hmem.aestronglyMeasurable] at this
    set C := (eLpNormEssSup g volume).toReal with hC
    have hae : ∀ᵐ t ∂(volume : Measure ℝ), |g t| ≤ C := by
      filter_upwards [ae_le_eLpNormEssSup (μ := volume) (f := g)] with t ht
      rw [← Real.norm_eq_abs, hC]
      rw [← ofReal_norm] at ht
      exact (ENNReal.ofReal_le_iff_le_toReal hlt.ne).mp ht
    have hC0 : 0 ≤ C := ENNReal.toReal_nonneg
    have hpos := hilbert_gate_level_volume W (C + 1) hW (by linarith)
    have hzero : volume {t : ℝ | C + 1 < abs ((1 / π) * Real.log |(t + W / 2) / (t - W / 2)|)} = 0 := by
      rw [ae_iff] at hae
      refine measure_mono_null (fun t ht => ?_) hae
      simp only [Set.mem_ofPred_eq, not_le] at ht ⊢
      show C < |g t|
      simp only [hg]
      linarith
    rw [hzero] at hpos
    have : 0 < 2 * W / Real.sinh (π * (C + 1)) :=
      div_pos (by positivity) (Real.sinh_pos_iff.mpr (by positivity))
    exact absurd hpos.symm (ENNReal.ofReal_pos.mpr this).ne'

#print axioms energy_bound_by_multiplier
#print axioms gate_hilbert_partner
#print axioms gate_partner_level_sets_and_failure
