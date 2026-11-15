-- Three model operators: a continuous kernel operator's peak gain on [0, 1] is its largest row integral, a mask's energy gain is the essential sup of its gain function, and the delay line keeps every 2-norm on the endless list.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Function.LpSeminorm.Basic
import Mathlib.Analysis.Normed.Lp.lpSpace
import Mathlib.MeasureTheory.Function.LpSeminorm.CompareExp
import Mathlib.MeasureTheory.Function.LpSeminorm.Indicator
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Data.Matrix.Mul
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open MeasureTheory Matrix
open scoped ENNReal

/-- Clamping `t / ε` to `[-1, 1]` loses at most `ε` against `|t|`. -/
theorem abs_sub_mul_clamp_le (t ε : ℝ) (hε : 0 < ε) :
    |t| - t * max (-1) (min 1 (t / ε)) ≤ ε := by
  rcases le_or_gt ε t with h | h
  · have h1 : 1 ≤ t / ε := by rw [le_div_iff₀ hε]; linarith
    rw [min_eq_left h1, max_eq_right (by norm_num), abs_of_nonneg (by linarith)]
    linarith
  · rcases le_or_gt t (-ε) with h' | h'
    · have h1 : t / ε ≤ -1 := by rw [div_le_iff₀ hε]; linarith
      rw [min_eq_right (by linarith), max_eq_left h1, abs_of_neg (by linarith)]
      linarith
    · have h1 : t / ε ≤ 1 := by rw [div_le_iff₀ hε]; linarith
      have h2 : -1 ≤ t / ε := by rw [le_div_iff₀ hε]; linarith
      rw [min_eq_right h1, max_eq_right h2]
      have : 0 ≤ t * (t / ε) := by
        rw [← mul_div_assoc]; exact div_nonneg (mul_self_nonneg t) hε.le
      have : |t| ≤ ε := abs_le.2 ⟨by linarith, by linarith⟩
      linarith

#print axioms abs_sub_mul_clamp_le

/-- The peak gain of a kernel operator is its largest row integral. Let k(x, y) be a kernel that
is continuous on the square [0, 1] × [0, 1], and let K send a signal f on [0, 1] to
(Kf)(x) = ∫₀¹ k(x, y) f(y) dy. Over all continuous inputs f with peak |f| ≤ 1 on [0, 1] and all
output times x in [0, 1], the least upper bound of the output size |(Kf)(x)| is
α = sup over x in [0, 1] of ∫₀¹ |k(x, y)| dy: the sup-norm gain ‖K‖_{∞→∞} equals α. -/
theorem kernel_peak_gain_eq_largest_row_integral (k : ℝ × ℝ → ℝ)
    (hk : ContinuousOn k (Set.Icc (0 : ℝ) 1 ×ˢ Set.Icc (0 : ℝ) 1)) :
    IsLUB {c : ℝ | ∃ f : ℝ → ℝ, ContinuousOn f (Set.Icc 0 1) ∧
        (∀ y ∈ Set.Icc (0 : ℝ) 1, |f y| ≤ 1) ∧
        ∃ x ∈ Set.Icc (0 : ℝ) 1, c = |∫ y in (0 : ℝ)..1, k (x, y) * f y|}
      (sSup ((fun x => ∫ y in (0 : ℝ)..1, |k (x, y)|) '' Set.Icc 0 1)) := by
  have hI : Set.uIcc (0 : ℝ) 1 = Set.Icc 0 1 := Set.uIcc_of_le zero_le_one
  have hrow : ∀ x ∈ Set.Icc (0 : ℝ) 1, ContinuousOn (fun y => k (x, y)) (Set.Icc 0 1) :=
    fun x hx => hk.comp (continuous_const.prodMk continuous_id).continuousOn
      (fun y hy => ⟨hx, hy⟩)
  obtain ⟨C, hC⟩ := (isCompact_Icc.prod isCompact_Icc).exists_bound_of_continuousOn hk
  have hbdd : BddAbove ((fun x => ∫ y in (0 : ℝ)..1, |k (x, y)|) '' Set.Icc 0 1) := by
    refine ⟨C, ?_⟩
    rintro _ ⟨x, hx, rfl⟩
    have h := intervalIntegral.integral_mono_on (a := 0) (b := 1) (f := fun y => |k (x, y)|)
      (g := fun _ => C) zero_le_one
      (ContinuousOn.intervalIntegrable (by rw [hI]; exact (hrow x hx).abs))
      (intervalIntegrable_const (μ := volume))
      (fun y hy => by simpa [Real.norm_eq_abs] using hC (x, y) ⟨hx, hy⟩)
    simpa using h
  have hne : ((fun x => ∫ y in (0 : ℝ)..1, |k (x, y)|) '' Set.Icc 0 1).Nonempty :=
    ⟨_, ⟨0, ⟨le_rfl, zero_le_one⟩, rfl⟩⟩
  constructor
  · rintro c ⟨f, hf, hf1, x, hx, rfl⟩
    have hkf : IntervalIntegrable (fun y => |k (x, y) * f y|) volume 0 1 :=
      ContinuousOn.intervalIntegrable (by rw [hI]; exact ((hrow x hx).mul hf).abs)
    have hka : IntervalIntegrable (fun y => |k (x, y)|) volume 0 1 :=
      ContinuousOn.intervalIntegrable (by rw [hI]; exact (hrow x hx).abs)
    calc |∫ y in (0 : ℝ)..1, k (x, y) * f y|
        ≤ ∫ y in (0 : ℝ)..1, |k (x, y) * f y| :=
          intervalIntegral.abs_integral_le_integral_abs zero_le_one
      _ ≤ ∫ y in (0 : ℝ)..1, |k (x, y)| := by
          apply intervalIntegral.integral_mono_on zero_le_one hkf hka
          intro y hy
          rw [abs_mul]
          exact mul_le_of_le_one_right (abs_nonneg _) (hf1 y hy)
      _ ≤ _ := le_csSup hbdd ⟨x, hx, rfl⟩
  · intro b hb
    refine csSup_le hne ?_
    rintro _ ⟨x, hx, rfl⟩
    refine le_of_forall_pos_le_add fun ε hε => ?_
    set f : ℝ → ℝ := fun y => max (-1) (min 1 (k (x, y) / ε))
    have hf : ContinuousOn f (Set.Icc 0 1) :=
      (continuous_const.max (continuous_const.min continuous_id)).comp_continuousOn
        ((hrow x hx).div_const ε)
    have hf1 : ∀ y ∈ Set.Icc (0 : ℝ) 1, |f y| ≤ 1 := fun y _ =>
      abs_le.2 ⟨le_max_left _ _, max_le (by norm_num) (min_le_left _ _)⟩
    have hmem := hb ⟨f, hf, hf1, x, hx, rfl⟩
    have hkf : IntervalIntegrable (fun y => k (x, y) * f y) volume 0 1 :=
      ContinuousOn.intervalIntegrable (by rw [hI]; exact (hrow x hx).mul hf)
    have hka : IntervalIntegrable (fun y => |k (x, y)|) volume 0 1 :=
      ContinuousOn.intervalIntegrable (by rw [hI]; exact (hrow x hx).abs)
    have hdiff : ∫ y in (0 : ℝ)..1, (|k (x, y)| - k (x, y) * f y) ≤ ∫ _ in (0 : ℝ)..1, ε :=
      intervalIntegral.integral_mono_on zero_le_one (hka.sub hkf) intervalIntegrable_const
        (fun y _ => abs_sub_mul_clamp_le _ _ hε)
    rw [intervalIntegral.integral_sub hka hkf] at hdiff
    simp only [intervalIntegral.integral_const, sub_zero, smul_eq_mul, one_mul] at hdiff
    have := le_abs_self (∫ y in (0 : ℝ)..1, k (x, y) * f y)
    linarith

/-- The energy gain of a mask is the largest value of its gain function, ignoring sets of length
zero. Let g be a measurable gain function on the clip [0, 1] and let M_g multiply a signal by g.
Over all finite-energy inputs f ≠ 0 on [0, 1], the least upper bound of the ratio
‖g f‖₂ / ‖f‖₂ is the essential sup of |g| on [0, 1] (wing 10's sup "almost everywhere"). -/
theorem mask_gain_eq_ess_sup (g : ℝ → ℝ)
    (hg : AEStronglyMeasurable g (volume.restrict (Set.Icc (0 : ℝ) 1))) :
    IsLUB {c : ℝ≥0∞ | ∃ f : ℝ → ℝ, MemLp f 2 (volume.restrict (Set.Icc (0 : ℝ) 1)) ∧
        eLpNorm f 2 (volume.restrict (Set.Icc (0 : ℝ) 1)) ≠ 0 ∧
        c = eLpNorm (fun x => g x * f x) 2 (volume.restrict (Set.Icc (0 : ℝ) 1)) /
          eLpNorm f 2 (volume.restrict (Set.Icc (0 : ℝ) 1))}
      (eLpNorm g ∞ (volume.restrict (Set.Icc (0 : ℝ) 1))) := by
  set μ := volume.restrict (Set.Icc (0 : ℝ) 1) with hμ
  constructor
  · rintro c ⟨f, -, -, rfl⟩
    apply ENNReal.div_le_of_le_mul
    have := eLpNorm_le_eLpNorm_top_mul_eLpNorm (μ := μ) (f := g) (g := f) 2 (fun a b : ℝ => a * b) 1
      continuous_mul hg (Filter.Eventually.of_forall fun x => by simp [nnnorm_mul])
    simpa using this
  · intro b hb
    by_contra hlt
    rw [not_le] at hlt
    obtain ⟨b', hbb', hb'g⟩ := ENNReal.lt_iff_exists_nnreal_btwn.1 hlt
    set g' := hg.mk g
    have hg'm : StronglyMeasurable g' := hg.stronglyMeasurable_mk
    have hgg' : g =ᵐ[μ] g' := hg.ae_eq_mk
    set A := {x | (b' : ℝ≥0∞) < ‖g' x‖ₑ}
    have hA : MeasurableSet A := measurableSet_lt measurable_const hg'm.measurable.enorm
    have hAμ : μ A ≠ 0 := by
      intro h0
      have hae : ∀ᵐ x ∂μ, ‖g' x‖ₑ ≤ (b' : ℝ≥0∞) := by
        rw [ae_iff]
        simpa [A, not_le] using h0
      have : eLpNorm g ∞ μ ≤ b' := by
        rw [eLpNorm_congr_ae hgg', eLpNorm_exponent_top hg'm.aestronglyMeasurable]
        exact essSup_le_of_ae_le _ hae
      exact absurd hb'g (not_lt.2 this)
    have hAfin : μ A ≠ ∞ := measure_ne_top μ A
    set f : ℝ → ℝ := A.indicator fun _ => (1 : ℝ)
    have hfm : MemLp f 2 μ := memLp_indicator_const 2 hA.nullMeasurableSet 1 (Or.inr hAfin)
    have hfn : eLpNorm f 2 μ = μ A ^ (1 / (2 : ℝ≥0∞).toReal) := by
      simp only [f]
      rw [eLpNorm_indicator_const hA.nullMeasurableSet (by norm_num) (by norm_num)]
      simp
    have hf0 : eLpNorm f 2 μ ≠ 0 := by
      rw [hfn]; exact (ENNReal.rpow_pos (pos_iff_ne_zero.2 hAμ) hAfin).ne'
    have hftop : eLpNorm f 2 μ ≠ ∞ := hfm.eLpNorm_ne_top
    have hlow : (b' : ℝ≥0∞) * eLpNorm f 2 μ ≤ eLpNorm (fun x => g x * f x) 2 μ := by
      have h1 : eLpNorm (fun x => (b' : ℝ) * f x) 2 μ = (b' : ℝ≥0∞) * eLpNorm f 2 μ := by
        have := eLpNorm_const_smul (b' : ℝ) f 2 μ
        rw [show (fun x => (b' : ℝ) * f x) = (b' : ℝ) • f from rfl, this]
        simp
      rw [← h1]
      apply eLpNorm_mono_enorm_ae (by fun_prop)
      filter_upwards [hgg'] with x hx
      rw [hx]
      by_cases hxA : x ∈ A
      · simp only [f, Set.indicator_of_mem hxA, mul_one]
        have : ‖(b' : ℝ)‖ₑ = (b' : ℝ≥0∞) := by simp
        rw [this]; exact le_of_lt hxA
      · simp [f, Set.indicator_of_notMem hxA]
    have hmem := hb ⟨f, hfm, hf0, rfl⟩
    have : (b' : ℝ≥0∞) ≤ eLpNorm (fun x => g x * f x) 2 μ / eLpNorm f 2 μ := by
      rw [ENNReal.le_div_iff_mul_le (Or.inl hf0) (Or.inl hftop)]
      exact hlow
    exact absurd (this.trans hmem) (not_le.2 hbb')

/-- The delay line keeps every size. For every finite-energy endless list u = (u₁, u₂, …) in ℓ²,
the delayed list Su = (0, u₁, u₂, …) is again in ℓ² and has exactly the same 2-norm:
‖Su‖₂ = ‖u‖₂. -/
theorem shift_keeps_two_norm (u : lp (fun _ : ℕ => ℝ) 2) :
    ∃ v : lp (fun _ : ℕ => ℝ) 2, v 0 = 0 ∧ (∀ n, v (n + 1) = u n) ∧ ‖v‖ = ‖u‖ := by
  have hp : (0 : ℝ) < (2 : ℝ≥0∞).toReal := by norm_num
  let w : ℕ → ℝ := fun n => Nat.casesOn n 0 (fun m => u m)
  have hu : Summable fun i => ‖u i‖ ^ (2 : ℝ≥0∞).toReal := (memℓp_gen_iff hp).1 (lp.memℓp u)
  have hw : Summable fun i => ‖w i‖ ^ (2 : ℝ≥0∞).toReal := by
    rw [← summable_nat_add_iff 1]
    simpa [w] using hu
  refine ⟨⟨w, (memℓp_gen_iff hp).2 hw⟩, rfl, fun n => rfl, ?_⟩
  rw [lp.norm_eq_tsum_rpow hp, lp.norm_eq_tsum_rpow hp]
  congr 1
  change ∑' i, ‖w i‖ ^ (2 : ℝ≥0∞).toReal = _
  rw [hw.tsum_eq_zero_add]
  simp [w]

/-- The blur on 5 samples, weights 1/4, 1/2, 1/4 and zero beyond both ends, sends the click
(0, 0, 4, 0, 0) to (0, 1, 2, 1, 0). -/
example : (!![1/2, 1/4, 0, 0, 0; 1/4, 1/2, 1/4, 0, 0; 0, 1/4, 1/2, 1/4, 0;
      0, 0, 1/4, 1/2, 1/4; 0, 0, 0, 1/4, 1/2] : Matrix (Fin 5) (Fin 5) ℚ) *ᵥ ![0, 0, 4, 0, 0] =
    (![0, 1, 2, 1, 0] : Fin 5 → ℚ) := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_five] <;> norm_num

/-- The 5-sample blur's row sums are 3/4, 1, 1, 1, 3/4, so its peak gain is 1. -/
example : (fun i => ∑ j, (!![1/2, 1/4, 0, 0, 0; 1/4, 1/2, 1/4, 0, 0; 0, 1/4, 1/2, 1/4, 0;
      0, 0, 1/4, 1/2, 1/4; 0, 0, 0, 1/4, 1/2] : Matrix (Fin 5) (Fin 5) ℚ) i j) =
    ![3/4, 1, 1, 1, 3/4] := by
  ext i; fin_cases i <;> simp [Fin.sum_univ_five] <;> norm_num

/-- The click's total is 4 before and after the blur, and its energy falls from 16 to 6. -/
example : ((0 : ℚ) + 0 + 4 + 0 + 0 = 0 + 1 + 2 + 1 + 0) ∧
    ((0 : ℚ) ^ 2 + 0 ^ 2 + 4 ^ 2 + 0 ^ 2 + 0 ^ 2 = 16) ∧
    ((0 : ℚ) ^ 2 + 1 ^ 2 + 2 ^ 2 + 1 ^ 2 + 0 ^ 2 = 6) := by
  norm_num

/-- The cut delay on 5 samples sends (3, 1, 4, 1, 5) to (0, 3, 1, 4, 1): energy 52 falls to 27. -/
example : (0 :: [3, 1, 4, 1, 5]).dropLast = [0, 3, 1, 4, 1] ∧
    ([3, 1, 4, 1, 5].map (· ^ 2)).sum = 52 ∧ ([0, 3, 1, 4, 1].map (· ^ 2)).sum = 27 := by
  decide

/-- Five cut delays on 5 samples give silence: S⁵ (3, 1, 4, 1, 5) = (0, 0, 0, 0, 0). -/
example : (fun l : List ℕ => (0 :: l).dropLast)^[5] [3, 1, 4, 1, 5] = [0, 0, 0, 0, 0] := by
  decide

/-- On the endless list nothing falls off: (0, 3, 1, 4, 1, 5) keeps energy 52; advance after
delay gives the list back, and delay after advance gives (0, 1, 4, 1, 5). -/
example : ([0, 3, 1, 4, 1, 5].map (· ^ 2)).sum = 52 ∧
    (0 :: [3, 1, 4, 1, 5]).tail = [3, 1, 4, 1, 5] ∧
    0 :: [3, 1, 4, 1, 5].tail = [0, 1, 4, 1, 5] := by
  decide

#print axioms kernel_peak_gain_eq_largest_row_integral
#print axioms mask_gain_eq_ess_sup
#print axioms shift_keeps_two_norm
