-- Poles and zeros: a sum of modes r e^(p t) with distinct poles and nonzero residues turns every bounded input into a bounded output exactly when every pole has negative real part.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Integral.IntegrableOn
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.IntegrationByParts
import Mathlib.MeasureTheory.Integral.IntegralEqImproper

open MeasureTheory Set

lemma pz_intervalIntegral_norm_le {g : ℝ → ℂ} (hgi : IntegrableOn g (Ioi 0)) {T : ℝ}
    (hT : 0 ≤ T) : ∫ t in (0 : ℝ)..T, ‖g t‖ ≤ ∫ t in Ioi 0, ‖g t‖ := by
  rw [intervalIntegral.integral_of_le hT]
  exact setIntegral_mono_set hgi.norm (ae_of_all _ fun _ => norm_nonneg _)
    (Ioc_subset_Ioi_self).eventuallyLE

lemma pz_core {n : ℕ} (p r : Fin n → ℂ) (hp : Function.Injective p) (k : Fin n)
    (hk : ∀ i, (p i).re ≤ (p k).re) (T : ℝ) (hT : 0 ≤ T) :
    T * ‖r k‖ ≤ ‖∫ t in (0 : ℝ)..T, (∑ i, r i * Complex.exp (p i * t)) * Complex.exp (-(p k) * t)‖
      + ∑ i ∈ Finset.univ.erase k, 2 * ‖r i‖ / ‖p i - p k‖ := by
  have hint : ∫ t in (0 : ℝ)..T, (∑ i, r i * Complex.exp (p i * t)) * Complex.exp (-(p k) * t)
      = ∑ i, r i * ∫ t in (0 : ℝ)..T, Complex.exp ((p i - p k) * t) := by
    have e : ∀ t : ℝ, (∑ i, r i * Complex.exp (p i * t)) * Complex.exp (-(p k) * t)
        = ∑ i, r i * Complex.exp ((p i - p k) * t) := by
      intro t
      rw [Finset.sum_mul]
      refine Finset.sum_congr rfl fun i _ => ?_
      rw [mul_assoc, ← Complex.exp_add]
      ring_nf
    simp_rw [e]
    rw [intervalIntegral.integral_finsetSum
      (fun i _ => (Continuous.intervalIntegrable (by fun_prop) _ _))]
    simp_rw [intervalIntegral.integral_const_mul]
  have hJk : ∫ t in (0 : ℝ)..T, Complex.exp ((p k - p k) * t) = T := by simp
  have hJ : ∀ i ∈ Finset.univ.erase k,
      ‖r i * ∫ t in (0 : ℝ)..T, Complex.exp ((p i - p k) * t)‖ ≤ 2 * ‖r i‖ / ‖p i - p k‖ := by
    intro i hi
    have hne : p i - p k ≠ 0 := sub_ne_zero.mpr (fun h => (Finset.ne_of_mem_erase hi) (hp h))
    rw [integral_exp_mul_complex hne, norm_mul, norm_div]
    have h2 : ‖Complex.exp ((p i - p k) * T) - Complex.exp ((p i - p k) * ((0 : ℝ) : ℂ))‖ ≤ 2 := by
      calc _ ≤ ‖Complex.exp ((p i - p k) * T)‖ + ‖Complex.exp ((p i - p k) * ((0 : ℝ) : ℂ))‖ :=
            norm_sub_le _ _
        _ ≤ 1 + 1 := by
          gcongr
          · rw [Complex.norm_exp, Real.exp_le_one_iff]
            simp only [Complex.mul_re, Complex.sub_re, Complex.ofReal_re, Complex.sub_im,
              Complex.ofReal_im, mul_zero, sub_zero]
            nlinarith [hk i]
          · simp
        _ = 2 := by norm_num
    have hq : 0 < ‖p i - p k‖ := norm_pos_iff.mpr hne
    rw [mul_div_assoc', div_le_div_iff_of_pos_right hq]
    nlinarith [norm_nonneg (r i)]
  rw [hint, ← Finset.add_sum_erase _ _ (Finset.mem_univ k), hJk]
  set S := ∑ i ∈ Finset.univ.erase k, r i * ∫ t in (0 : ℝ)..T, Complex.exp ((p i - p k) * t)
  have h1 : ‖r k * (T : ℂ)‖ = T * ‖r k‖ := by
    rw [norm_mul, Complex.norm_real, Real.norm_of_nonneg hT, mul_comm]
  have h2 : ‖S‖ ≤ ∑ i ∈ Finset.univ.erase k, 2 * ‖r i‖ / ‖p i - p k‖ :=
    (norm_sum_le _ _).trans (Finset.sum_le_sum hJ)
  have h3 : ‖r k * (T : ℂ)‖ ≤ ‖r k * (T : ℂ) + S‖ + ‖S‖ := by
    calc ‖r k * (T : ℂ)‖ = ‖(r k * (T : ℂ) + S) - S‖ := by rw [add_sub_cancel_right]
      _ ≤ _ := norm_sub_le _ _
  linarith

lemma pz_unbounded {c B : ℝ} (hc : 0 < c) (h : ∀ T : ℝ, 0 ≤ T → T * c ≤ B) : False := by
  have := h ((|B| + 1) / c) (by positivity)
  rw [div_mul_cancel₀ _ hc.ne'] at this
  linarith [le_abs_self B]

lemma pz_exists_max {n : ℕ} (p : Fin n → ℂ) (h : ¬ ∀ i, (p i).re < 0) :
    ∃ k, 0 ≤ (p k).re ∧ ∀ i, (p i).re ≤ (p k).re := by
  push Not at h
  obtain ⟨j, hj⟩ := h
  have : Nonempty (Fin n) := ⟨j⟩
  obtain ⟨k, hk⟩ := Finite.exists_max (fun i => (p i).re)
  exact ⟨k, le_trans hj (hk j), hk⟩

lemma pz_bibo_bound (g : ℝ → ℂ) (hg : Continuous g) :
    IntegrableOn g (Ioi 0) →
      ∀ (M : ℝ) (u : ℝ → ℂ) (T : ℝ), Measurable u → (∀ t, ‖u t‖ ≤ M) → 0 ≤ T →
        ‖∫ τ in (0 : ℝ)..T, g τ * u (T - τ)‖ ≤ M * ∫ t in Ioi 0, ‖g t‖ := by
  intro hI M u T _ hM hT
  have hM0 : 0 ≤ M := (norm_nonneg _).trans (hM 0)
  calc ‖∫ τ in (0 : ℝ)..T, g τ * u (T - τ)‖ ≤ ∫ τ in (0 : ℝ)..T, ‖g τ‖ * M := by
        apply intervalIntegral.norm_integral_le_of_norm_le hT
        · refine Filter.Eventually.of_forall fun τ _ => ?_
          rw [norm_mul]
          gcongr
          exact hM _
        · exact (hg.norm.mul continuous_const).intervalIntegrable _ _
    _ = (∫ τ in (0 : ℝ)..T, ‖g τ‖) * M := intervalIntegral.integral_mul_const _ _
    _ ≤ (∫ t in Ioi 0, ‖g t‖) * M := by
        gcongr
        exact pz_intervalIntegral_norm_le hI hT
    _ = M * ∫ t in Ioi 0, ‖g t‖ := mul_comm _ _

lemma pz_integrable_of_re_neg {n : ℕ} (p r : Fin n → ℂ) (hneg : ∀ i, (p i).re < 0) :
    IntegrableOn (fun t : ℝ => ∑ i, r i * Complex.exp (p i * t)) (Ioi 0) :=
  integrable_finsetSum _ fun i _ =>
    (integrableOn_exp_mul_complex_Ioi (hneg i) 0).const_mul (r i)

#print axioms pz_intervalIntegral_norm_le
#print axioms pz_core
#print axioms pz_unbounded
#print axioms pz_exists_max
#print axioms pz_bibo_bound
#print axioms pz_integrable_of_re_neg

/-- The bounded-input bounded-output test. Take a system whose kick response is one exponential
per pole, `g t = ∑ i, r i * e^(p i * t)`, with distinct poles (`p` injective) and no pole
cancelled by a zero (every residue `r i` nonzero), started from rest, so its output at time `T`
is the convolution `∫ τ in 0..T, g τ * u (T - τ)`. Then every bounded input gives a bounded
output exactly when every pole has negative real part. -/
theorem bibo_stable_iff_poles_in_left_half_plane {n : ℕ} (p r : Fin n → ℂ)
    (hp : Function.Injective p) (hr : ∀ i, r i ≠ 0) :
    (∀ u : ℝ → ℂ, Measurable u → (∃ M, ∀ t, ‖u t‖ ≤ M) →
      ∃ C, ∀ T : ℝ, 0 ≤ T →
        ‖∫ τ in (0 : ℝ)..T, (∑ i, r i * Complex.exp (p i * τ)) * u (T - τ)‖ ≤ C) ↔
    ∀ i, (p i).re < 0 := by
  have hgc : Continuous (fun t : ℝ => ∑ i, r i * Complex.exp (p i * t)) := by fun_prop
  constructor
  · intro hB
    by_contra hneg
    obtain ⟨k, hk0, hk⟩ := pz_exists_max p hneg
    obtain ⟨C, hC⟩ := hB (fun s => Complex.exp ((p k).im * s * Complex.I))
      (by fun_prop : Continuous fun s : ℝ => Complex.exp ((p k).im * s * Complex.I)).measurable
      ⟨1, fun t => by rw [Complex.norm_exp]; simp⟩
    have hΦ : Continuous (fun t : ℝ => (∑ i, r i * Complex.exp (p i * t))
        * Complex.exp (-((p k).im * t * Complex.I))) := by fun_prop
    have hG : ∀ T : ℝ, 0 ≤ T → ‖∫ τ in (0 : ℝ)..T, (∑ i, r i * Complex.exp (p i * τ))
        * Complex.exp (-((p k).im * τ * Complex.I))‖ ≤ C := by
      intro T hT
      have h : ‖∫ τ in (0 : ℝ)..T, (∑ i, r i * Complex.exp (p i * τ))
          * Complex.exp ((p k).im * ((T - τ : ℝ) : ℂ) * Complex.I)‖ ≤ C := hC T hT
      have e : ∫ τ in (0 : ℝ)..T, (∑ i, r i * Complex.exp (p i * τ))
            * Complex.exp ((p k).im * ((T - τ : ℝ) : ℂ) * Complex.I)
          = Complex.exp ((p k).im * T * Complex.I) * ∫ τ in (0 : ℝ)..T,
            (∑ i, r i * Complex.exp (p i * τ)) * Complex.exp (-((p k).im * τ * Complex.I)) := by
        rw [← intervalIntegral.integral_const_mul]
        refine intervalIntegral.integral_congr fun τ _ => ?_
        rw [mul_left_comm, ← Complex.exp_add]
        congr 2
        push_cast
        ring
      rw [e, norm_mul, Complex.norm_exp] at h
      simpa using h
    have hC0 : 0 ≤ C := (norm_nonneg _).trans (hG 0 le_rfl)
    have hF : ∀ T : ℝ, 0 ≤ T → ‖∫ t in (0 : ℝ)..T, (∑ i, r i * Complex.exp (p i * t))
        * Complex.exp (-(p k) * t)‖ ≤ 2 * C := by
      intro T hT
      let G : ℝ → ℂ := fun x => ∫ τ in (0 : ℝ)..x, (∑ i, r i * Complex.exp (p i * τ))
        * Complex.exp (-((p k).im * τ * Complex.I))
      have hGd : ∀ x : ℝ, HasDerivAt G ((∑ i, r i * Complex.exp (p i * x))
          * Complex.exp (-((p k).im * x * Complex.I))) x :=
        fun x => (hΦ.integral_hasStrictDerivAt 0 x).hasDerivAt
      have hvd : ∀ x : ℝ, HasDerivAt (fun y : ℝ => Complex.exp (-((p k).re : ℂ) * y))
          (-((p k).re : ℂ) * Complex.exp (-((p k).re : ℂ) * x)) x := by
        intro x
        have := (((hasDerivAt_id' x).ofReal_comp).const_mul (-((p k).re : ℂ))).cexp
        convert this using 1
        push_cast
        ring
      have ibp := intervalIntegral.integral_mul_deriv_eq_deriv_mul (a := 0) (b := T)
        (fun x _ => hGd x) (fun x _ => hvd x) (hΦ.intervalIntegrable _ _)
        ((by fun_prop : Continuous fun x : ℝ =>
          -((p k).re : ℂ) * Complex.exp (-((p k).re : ℂ) * x)).intervalIntegrable _ _)
      have hG0 : G 0 = 0 := intervalIntegral.integral_same
      rw [hG0] at ibp
      have hrw : ∫ t in (0 : ℝ)..T, (∑ i, r i * Complex.exp (p i * t)) * Complex.exp (-(p k) * t)
          = ∫ x in (0 : ℝ)..T, ((∑ i, r i * Complex.exp (p i * x))
            * Complex.exp (-((p k).im * x * Complex.I))) * Complex.exp (-((p k).re : ℂ) * x) := by
        refine intervalIntegral.integral_congr fun x _ => ?_
        rw [mul_assoc, ← Complex.exp_add]
        congr 2
        conv_lhs => rw [← Complex.re_add_im (p k)]
        ring
      have hsplit : ∫ x in (0 : ℝ)..T, ((∑ i, r i * Complex.exp (p i * x))
            * Complex.exp (-((p k).im * x * Complex.I))) * Complex.exp (-((p k).re : ℂ) * x)
          = G T * Complex.exp (-((p k).re : ℂ) * T)
            - ∫ x in (0 : ℝ)..T, G x * (-((p k).re : ℂ) * Complex.exp (-((p k).re : ℂ) * x)) := by
        linear_combination ibp
      have hv : ∀ x : ℝ, 0 ≤ x → ‖Complex.exp (-((p k).re : ℂ) * x)‖ = Real.exp (-(p k).re * x) := by
        intro x _
        rw [Complex.norm_exp]
        congr 1
        simp
      have hb1 : ‖G T * Complex.exp (-((p k).re : ℂ) * T)‖ ≤ C := by
        rw [norm_mul, hv T hT]
        calc ‖G T‖ * Real.exp (-(p k).re * T) ≤ C * 1 := by
              gcongr
              · exact hG T hT
              · rw [Real.exp_le_one_iff]; nlinarith
          _ = C := mul_one C
      have hreal : ∫ x in (0 : ℝ)..T, (p k).re * Real.exp (-(p k).re * x)
          = 1 - Real.exp (-(p k).re * T) := by
        rw [intervalIntegral.integral_eq_sub_of_hasDerivAt
          (f := fun x => -Real.exp (-(p k).re * x))]
        · simp
          ring
        · intro x _
          have := (((hasDerivAt_id' x).const_mul (-(p k).re)).exp).neg
          convert this using 1
          ring
        · exact (by fun_prop : Continuous fun x : ℝ =>
            (p k).re * Real.exp (-(p k).re * x)).intervalIntegrable _ _
      have hb2 : ‖∫ x in (0 : ℝ)..T, G x * (-((p k).re : ℂ) * Complex.exp (-((p k).re : ℂ) * x))‖
          ≤ C := by
        calc _ ≤ ∫ x in (0 : ℝ)..T, C * ((p k).re * Real.exp (-(p k).re * x)) := by
              apply intervalIntegral.norm_integral_le_of_norm_le hT
              · refine Filter.Eventually.of_forall fun x hx => ?_
                rw [norm_mul, norm_mul, hv x hx.1.le, norm_neg, Complex.norm_real,
                  Real.norm_of_nonneg hk0]
                gcongr
                exact hG x hx.1.le
              · exact (by fun_prop : Continuous fun x : ℝ =>
                  C * ((p k).re * Real.exp (-(p k).re * x))).intervalIntegrable _ _
          _ = C * (1 - Real.exp (-(p k).re * T)) := by
              rw [intervalIntegral.integral_const_mul, hreal]
          _ ≤ C := by
              have := Real.exp_pos (-(p k).re * T)
              nlinarith
      rw [hrw, hsplit]
      calc _ ≤ ‖G T * Complex.exp (-((p k).re : ℂ) * T)‖ + ‖∫ x in (0 : ℝ)..T,
            G x * (-((p k).re : ℂ) * Complex.exp (-((p k).re : ℂ) * x))‖ := norm_sub_le _ _
        _ ≤ C + C := add_le_add hb1 hb2
        _ = 2 * C := by ring
    refine pz_unbounded (c := ‖r k‖)
      (B := 2 * C + ∑ i ∈ Finset.univ.erase k, 2 * ‖r i‖ / ‖p i - p k‖)
      (norm_pos_iff.mpr (hr k)) ?_
    intro T hT
    have h1 := pz_core p r hp k hk T hT
    have h2 := hF T hT
    linarith
  · rintro hneg u hu ⟨M, hM⟩
    have hI := pz_integrable_of_re_neg p r hneg
    exact ⟨M * ∫ t : ℝ in Ioi 0, ‖∑ i, r i * Complex.exp (p i * t)‖,
      fun T hT => pz_bibo_bound _ hgc hI M u T hu hM hT⟩

/-- Step 4: for a continuous kick response `g`, if the area under `‖g‖` is finite then an input
never larger than `M` gives an output never larger than `M` times that area; and if some constant
`C` makes every input never larger than `M` give an output never larger than `M * C`, the area
under `‖g‖` is finite. -/
theorem bibo_iff_finite_area (g : ℝ → ℂ) (hg : Continuous g) :
    (IntegrableOn g (Ioi 0) →
      ∀ (M : ℝ) (u : ℝ → ℂ) (T : ℝ), Measurable u → (∀ t, ‖u t‖ ≤ M) → 0 ≤ T →
        ‖∫ τ in (0 : ℝ)..T, g τ * u (T - τ)‖ ≤ M * ∫ t in Ioi 0, ‖g t‖) ∧
    ((∃ C : ℝ, ∀ (M : ℝ) (u : ℝ → ℂ) (T : ℝ), Measurable u → (∀ t, ‖u t‖ ≤ M) → 0 ≤ T →
        ‖∫ τ in (0 : ℝ)..T, g τ * u (T - τ)‖ ≤ M * C) →
      IntegrableOn g (Ioi 0)) := by
  constructor
  · exact pz_bibo_bound g hg
  · rintro ⟨C, hC⟩
    refine integrableOn_Ioi_of_intervalIntegral_norm_bounded (l := Filter.atTop) (b := id) C 0
      (fun i => (hg.intervalIntegrable 0 (id i)).1) Filter.tendsto_id ?_
    filter_upwards [Filter.eventually_ge_atTop 0] with T hT
    let u : ℝ → ℂ := fun s => star (g (T - s)) / (‖g (T - s)‖ : ℂ)
    have hu : Measurable u := by
      have : Continuous fun s => g (T - s) := by fun_prop
      exact (continuous_star.comp this).measurable.div
        (Complex.continuous_ofReal.comp this.norm).measurable
    have hu1 : ∀ t, ‖u t‖ ≤ 1 := by
      intro t
      simp only [u, norm_div, norm_star, Complex.norm_real, norm_norm]
      exact div_self_le_one _
    have key : ∫ τ in (0 : ℝ)..T, g τ * u (T - τ) = ((∫ τ in (0 : ℝ)..T, ‖g τ‖ : ℝ) : ℂ) := by
      rw [← intervalIntegral.integral_ofReal]
      refine intervalIntegral.integral_congr fun τ _ => ?_
      simp only [u, sub_sub_cancel]
      by_cases h : g τ = 0
      · simp [h]
      · have hn : (‖g τ‖ : ℂ) ≠ 0 := by
          exact_mod_cast (norm_pos_iff.mpr h).ne'
        rw [mul_div_assoc', show star (g τ) = (starRingEnd ℂ) (g τ) from rfl, Complex.mul_conj',
          div_eq_iff hn]
        ring
    have := hC 1 u T hu hu1 hT
    rw [key, Complex.norm_real, Real.norm_of_nonneg
      (intervalIntegral.integral_nonneg hT (fun _ _ => norm_nonneg _)), one_mul] at this
    exact this

/-- Step 5: a sum of modes `∑ i, r i * e^(p i * t)` with distinct poles and nonzero residues has
finite area under its size on `t > 0` exactly when every pole has negative real part. -/
theorem finite_area_iff_poles_in_left_half_plane {n : ℕ} (p r : Fin n → ℂ)
    (hp : Function.Injective p) (hr : ∀ i, r i ≠ 0) :
    IntegrableOn (fun t : ℝ => ∑ i, r i * Complex.exp (p i * t)) (Ioi 0) ↔
    ∀ i, (p i).re < 0 := by
  constructor
  · intro hI
    by_contra hneg
    obtain ⟨k, hk0, hk⟩ := pz_exists_max p hneg
    have hf : Continuous (fun t : ℝ => ∑ i, r i * Complex.exp (p i * t)) := by fun_prop
    refine pz_unbounded (c := ‖r k‖)
      (B := (∫ t : ℝ in Ioi 0, ‖∑ i, r i * Complex.exp (p i * t)‖)
        + ∑ i ∈ Finset.univ.erase k, 2 * ‖r i‖ / ‖p i - p k‖) (norm_pos_iff.mpr (hr k)) ?_
    intro T hT
    have hc := pz_core p r hp k hk T hT
    have hb : ‖∫ t in (0 : ℝ)..T, (∑ i, r i * Complex.exp (p i * t)) * Complex.exp (-(p k) * t)‖
        ≤ ∫ t in (0 : ℝ)..T, ‖∑ i, r i * Complex.exp (p i * t)‖ := by
      apply intervalIntegral.norm_integral_le_of_norm_le hT
      · refine Filter.Eventually.of_forall fun t ht => ?_
        rw [norm_mul, Complex.norm_exp]
        have h0 : (-(p k) * (t : ℂ)).re ≤ 0 := by
          simp only [Complex.mul_re, Complex.neg_re, Complex.ofReal_re, Complex.neg_im,
            Complex.ofReal_im, mul_zero, sub_zero]
          nlinarith [ht.1, hk0]
        calc _ ≤ ‖∑ i, r i * Complex.exp (p i * t)‖ * 1 := by
              gcongr
              exact Real.exp_le_one_iff.mpr h0
          _ = _ := mul_one _
      · exact hf.norm.intervalIntegrable _ _
    have := pz_intervalIntegral_norm_le hI hT
    linarith
  · exact pz_integrable_of_re_neg p r

-- Step 1: the closed-loop coefficients k/m, (b + k)/m and k a/m for m = 1500, b = 60, k = 240,
-- a = 1/8 are 4/25, 1/5 and 1/50; G(0) = (1/50)/(1/50) = 1.
example : (240 : ℚ) / 1500 = 4 / 25 := by norm_num
example : ((60 : ℚ) + 240) / 1500 = 1 / 5 := by norm_num
example : (240 : ℚ) * (1 / 8) / 1500 = 1 / 50 := by norm_num
example : ((1 : ℚ) / 50) / (1 / 50) = 1 := by norm_num

-- Worked numbers: the discriminant 0.2^2 - 4 * 0.02 is -0.04.
example : ((1 : ℚ) / 5) ^ 2 - 4 * (1 / 50) = -1 / 25 := by norm_num

-- Step 2: p1 = -1/10 + (1/10) j is a root of s^2 + (1/5) s + 1/50.
example : ((-1 / 10 : ℂ) + (1 / 10) * Complex.I) ^ 2
    + (1 / 5) * ((-1 / 10 : ℂ) + (1 / 10) * Complex.I) + 1 / 50 = 0 := by
  apply Complex.ext <;> simp [sq] <;> norm_num

-- Step 3: the residue at p1 is r1 = 2/25 - (1/50) j, since r1 (p1 - p2) = (4/25) p1 + 1/50,
-- and the step residue is r1 / p1 = -1/2 - (3/10) j.
example : ((2 / 25 : ℂ) - (1 / 50) * Complex.I) * ((1 / 5) * Complex.I)
    = (4 / 25) * ((-1 / 10 : ℂ) + (1 / 10) * Complex.I) + 1 / 50 := by
  apply Complex.ext <;> simp <;> norm_num
example : ((-1 / 2 : ℂ) - (3 / 10) * Complex.I) * ((-1 / 10 : ℂ) + (1 / 10) * Complex.I)
    = (2 / 25 : ℂ) - (1 / 50) * Complex.I := by
  apply Complex.ext <;> simp <;> norm_num

-- What breaks: the integrator alone builds 240 * (1/8) * 100 = 3000 N in 100 s and 30000 N in
-- 1000 s; drag over a 10 m/s change is 60 * 10 = 600 N linear against (6/5)(35^2 - 25^2) = 720 N.
example : (240 : ℚ) * (1 / 8) * 100 = 3000 := by norm_num
example : (240 : ℚ) * (1 / 8) * 1000 = 30000 := by norm_num
example : (60 : ℕ) * 10 = 600 := by norm_num
example : (6 / 5 : ℚ) * (35 ^ 2 - 25 ^ 2) = 720 := by norm_num

#print axioms bibo_stable_iff_poles_in_left_half_plane
#print axioms bibo_iff_finite_area
#print axioms finite_area_iff_poles_in_left_half_plane
