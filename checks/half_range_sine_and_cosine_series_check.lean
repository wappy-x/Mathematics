-- Half-range series: reflecting f on [0, L] as odd keeps only sines and as even keeps only cosines, each coefficient being (2/L) times the integral of f against its mode; sine sums vanish at both ends and cosine sums are flat there; and the plucked triangle has b_n = 8 sin(nπ/2)/(n²π²), a_n = 4(2cos(nπ/2) − 1 − (−1)^n)/(n²π²), a_0 = 1, with both series giving its middle value.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.NumberTheory.ZetaValues
import Mathlib.Tactic.NormNum

open Real MeasureTheory

/-- The odd extension of f: f itself for x ≥ 0, and −f(−x) for x < 0. -/
noncomputable def oddExt (f : ℝ → ℝ) (x : ℝ) : ℝ := if 0 ≤ x then f x else -f (-x)

/-- The even extension of f: f itself for x ≥ 0, and f(−x) for x < 0. -/
noncomputable def evenExt (f : ℝ → ℝ) (x : ℝ) : ℝ := if 0 ≤ x then f x else f (-x)

/-- The half-range sine coefficient b_n = (2/L) ∫₀ᴸ f(x) sin(nπx/L) dx. -/
noncomputable def halfSineCoeff (L : ℝ) (f : ℝ → ℝ) (n : ℕ) : ℝ :=
  (2 / L) * ∫ x in (0 : ℝ)..L, f x * Real.sin (n * π * x / L)

/-- The half-range cosine coefficient a_n = (2/L) ∫₀ᴸ f(x) cos(nπx/L) dx. -/
noncomputable def halfCosineCoeff (L : ℝ) (f : ℝ → ℝ) (n : ℕ) : ℝ :=
  (2 / L) * ∫ x in (0 : ℝ)..L, f x * Real.cos (n * π * x / L)

/-- The plucked string on [0, 1]: 2x up to the middle, 2(1 − x) after it, peak 1 at x = 1/2. -/
noncomputable def pluck (x : ℝ) : ℝ := if x ≤ 1 / 2 then 2 * x else 2 * (1 - x)

lemma intervalIntegrable_congr_Ioo {g h : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b)
    (hg : IntervalIntegrable g volume a b) (heq : Set.EqOn g h (Set.Ioo a b)) :
    IntervalIntegrable h volume a b := by
  rw [intervalIntegrable_iff_integrableOn_Ioo_of_le hab] at hg ⊢
  exact hg.congr_fun heq measurableSet_Ioo

lemma integral_symm_split (L : ℝ) (F : ℝ → ℝ) (h0 : IntervalIntegrable F volume 0 L)
    (h1 : IntervalIntegrable (fun x => F (-x)) volume 0 L) :
    (∫ x in (-L)..L, F x) = (∫ x in (0 : ℝ)..L, F (-x)) + ∫ x in (0 : ℝ)..L, F x := by
  have h1' : IntervalIntegrable F volume (-L) 0 := by
    have := (IntervalIntegrable.iff_comp_neg (f := fun x => F (-x))).mp h1
    simpa using this.symm
  rw [← intervalIntegral.integral_add_adjacent_intervals h1' h0, intervalIntegral.integral_comp_neg]
  simp

lemma pluck_eq_min : pluck = fun x => min (2 * x) (2 * (1 - x)) := by
  ext x; unfold pluck
  split_ifs with h
  · rw [min_eq_left (by linarith)]
  · rw [min_eq_right (by linarith)]

lemma pluck_continuous : Continuous pluck := by
  rw [pluck_eq_min]; fun_prop

lemma pluck_integral (g : ℝ → ℝ) (hg : Continuous g) (F G : ℝ → ℝ)
    (hF : ∀ x, HasDerivAt F (2 * x * g x) x) (hG : ∀ x, HasDerivAt G (2 * (1 - x) * g x) x) :
    (∫ x in (0:ℝ)..1, pluck x * g x) = (F (1 / 2) - F 0) + (G 1 - G (1 / 2)) := by
  have hc : Continuous (fun x => pluck x * g x) := pluck_continuous.mul hg
  rw [← intervalIntegral.integral_add_adjacent_intervals (b := 1 / 2)
    (hc.intervalIntegrable _ _) (hc.intervalIntegrable _ _)]
  have e1 : (∫ x in (0:ℝ)..1 / 2, pluck x * g x) = ∫ x in (0:ℝ)..1 / 2, 2 * x * g x := by
    apply intervalIntegral.integral_congr
    intro x hx
    rw [Set.uIcc_of_le (by norm_num)] at hx
    have hx2 : x ≤ 1 / 2 := hx.2
    simp only [pluck, hx2, ↓reduceIte]
  have e2 : (∫ x in (1 / 2 : ℝ)..1, pluck x * g x) = ∫ x in (1 / 2 : ℝ)..1, 2 * (1 - x) * g x := by
    apply intervalIntegral.integral_congr
    intro x hx
    rw [Set.uIcc_of_le (by norm_num)] at hx
    simp only [pluck]
    split_ifs with h
    · have : x = 1 / 2 := le_antisymm h hx.1
      subst this; ring
    · rfl
  rw [e1, e2, intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hF x)
      ((by fun_prop : Continuous fun x => 2 * x * g x).intervalIntegrable _ _),
    intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hG x)
      ((by fun_prop : Continuous fun x => 2 * (1 - x) * g x).intervalIntegrable _ _)]

lemma pluck_sine (n : ℕ) (hn : 1 ≤ n) :
    halfSineCoeff 1 pluck n = 8 * Real.sin (n * π / 2) / (n ^ 2 * π ^ 2) := by
  set k : ℝ := n * π with hk
  have hk0 : k ≠ 0 := by
    have : (n : ℝ) ≠ 0 := by exact_mod_cast (by omega : n ≠ 0)
    exact mul_ne_zero this pi_ne_zero
  have hlin : ∀ x, HasDerivAt (fun x : ℝ => k * x) k x := fun x => by
    simpa using (hasDerivAt_id x).const_mul k
  have hI := pluck_integral (fun x => Real.sin (k * x)) (by fun_prop)
    (fun x => 2 * (-(x * Real.cos (k * x)) / k + Real.sin (k * x) / k ^ 2))
    (fun x => 2 * ((x - 1) * Real.cos (k * x) / k - Real.sin (k * x) / k ^ 2))
    (fun x => by
      have := (((((hasDerivAt_id' x).mul (hlin x).cos).neg).div_const k).add
        ((hlin x).sin.div_const (k ^ 2))).const_mul 2
      convert this using 1
      field_simp; ring)
    (fun x => by
      have := (((((hasDerivAt_id' x).sub_const 1).mul (hlin x).cos).div_const k).sub
        ((hlin x).sin.div_const (k ^ 2))).const_mul 2
      convert this using 1
      field_simp; ring)
  unfold halfSineCoeff
  simp only [div_one]
  rw [hI]
  have h1 : Real.sin (k * 1) = 0 := by rw [mul_one, hk, Real.sin_nat_mul_pi]
  have h2 : k * (1 / 2) = n * π / 2 := by rw [hk]; ring
  simp only [h1, h2, mul_zero, Real.sin_zero, Real.cos_zero]
  rw [hk]
  field_simp
  ring

lemma pluck_cosine (n : ℕ) (hn : 1 ≤ n) :
    halfCosineCoeff 1 pluck n = 4 * (2 * Real.cos (n * π / 2) - 1 - (-1) ^ n) / (n ^ 2 * π ^ 2) := by
  set k : ℝ := n * π with hk
  have hk0 : k ≠ 0 := by
    have : (n : ℝ) ≠ 0 := by exact_mod_cast (by omega : n ≠ 0)
    exact mul_ne_zero this pi_ne_zero
  have hlin : ∀ x, HasDerivAt (fun x : ℝ => k * x) k x := fun x => by
    simpa using (hasDerivAt_id x).const_mul k
  have hI := pluck_integral (fun x => Real.cos (k * x)) (by fun_prop)
    (fun x => 2 * (x * Real.sin (k * x) / k + Real.cos (k * x) / k ^ 2))
    (fun x => 2 * (-((x - 1) * Real.sin (k * x)) / k - Real.cos (k * x) / k ^ 2))
    (fun x => by
      have := ((((hasDerivAt_id' x).mul (hlin x).sin).div_const k).add
        ((hlin x).cos.div_const (k ^ 2))).const_mul 2
      convert this using 1
      field_simp; ring)
    (fun x => by
      have := ((((((hasDerivAt_id' x).sub_const 1).mul (hlin x).sin).neg).div_const k).sub
        ((hlin x).cos.div_const (k ^ 2))).const_mul 2
      convert this using 1
      field_simp; ring)
  unfold halfCosineCoeff
  simp only [div_one]
  rw [hI]
  have h1 : Real.sin (k * 1) = 0 := by rw [mul_one, hk, Real.sin_nat_mul_pi]
  have h1' : Real.cos (k * 1) = (-1) ^ n := by rw [mul_one, hk, Real.cos_nat_mul_pi]
  have h2 : k * (1 / 2) = n * π / 2 := by rw [hk]; ring
  simp only [h1, h1', h2, mul_zero, Real.sin_zero, Real.cos_zero]
  rw [hk]
  field_simp
  ring

lemma pluck_cosine_zero : halfCosineCoeff 1 pluck 0 = 1 := by
  unfold halfCosineCoeff
  simp only [Nat.cast_zero, zero_mul, Real.cos_zero, mul_one, div_one]
  have hI := pluck_integral (fun _ => 1) continuous_const (fun x => x ^ 2) (fun x => 2 * x - x ^ 2)
    (fun x => by
      convert hasDerivAt_pow 2 x using 1; ring)
    (fun x => by
      convert ((hasDerivAt_id' x).const_mul 2).sub (hasDerivAt_pow 2 x) using 1
      norm_num; ring)
  simp only [mul_one] at hI
  rw [hI]; norm_num

lemma hasSum_odd_inv_sq : HasSum (fun k : ℕ => 1 / ((2 * k + 1 : ℕ) : ℝ) ^ 2) (π ^ 2 / 8) := by
  have hz := hasSum_zeta_two
  have he : HasSum (fun k : ℕ => (1 : ℝ) / ((2 * k : ℕ) : ℝ) ^ 2) (π ^ 2 / 24) := by
    have := hz.mul_left (1 / 4)
    convert this using 1
    · ext k; push_cast; ring
    · ring
  have ho : Summable (fun k : ℕ => (1 : ℝ) / ((2 * k + 1 : ℕ) : ℝ) ^ 2) :=
    hz.summable.comp_injective (f := fun n : ℕ => (1 : ℝ) / (n : ℝ) ^ 2)
      (i := fun k : ℕ => 2 * k + 1) (fun a b h => by simpa using h)
  have hs := HasSum.even_add_odd (f := fun n : ℕ => (1 : ℝ) / (n : ℝ) ^ 2) he ho.hasSum
  have := hs.unique hz
  convert ho.hasSum using 1
  linarith

lemma sin_odd_half (k : ℕ) : Real.sin (((2 * k + 1 : ℕ) : ℝ) * π / 2) = (-1) ^ k := by
  rw [show (((2 * k + 1 : ℕ) : ℝ)) * π / 2 = k * π + π / 2 by push_cast; ring,
    Real.sin_add_pi_div_two, Real.cos_nat_mul_pi]

lemma cos_odd_half (k : ℕ) : Real.cos (((2 * k + 1 : ℕ) : ℝ) * π / 2) = 0 := by
  rw [show (((2 * k + 1 : ℕ) : ℝ)) * π / 2 = k * π + π / 2 by push_cast; ring,
    Real.cos_add_pi_div_two, Real.sin_nat_mul_pi, neg_zero]

lemma neg_one_sq_pow (k : ℕ) : ((-1 : ℝ) ^ k) ^ 2 = 1 := by
  rw [← pow_mul, mul_comm, pow_mul]; norm_num

#print axioms intervalIntegrable_congr_Ioo
#print axioms integral_symm_split
#print axioms pluck_eq_min
#print axioms pluck_continuous
#print axioms pluck_integral
#print axioms pluck_sine
#print axioms pluck_cosine
#print axioms pluck_cosine_zero
#print axioms hasSum_odd_inv_sq
#print axioms sin_odd_half
#print axioms cos_odd_half
#print axioms neg_one_sq_pow

/-- **The reflection decides the modes, and each coefficient is twice the average of f times
its mode.** Let f be integrable on [0, L] with L > 0. Over one full period −L to L, the full
Fourier coefficients (1/L) ∫ F(x) cos(nπx/L) dx and (1/L) ∫ F(x) sin(nπx/L) dx behave so:
for the odd extension every cosine coefficient is 0 and every sine coefficient equals the
half-range b_n = (2/L) ∫₀ᴸ f(x) sin(nπx/L) dx; for the even extension every sine coefficient
is 0 and every cosine coefficient equals the half-range a_n = (2/L) ∫₀ᴸ f(x) cos(nπx/L) dx. -/
theorem half_range_coefficients_from_reflection (L : ℝ) (hL : 0 < L) (f : ℝ → ℝ)
    (hf : IntervalIntegrable f volume 0 L) (n : ℕ) :
    (1 / L) * (∫ x in (-L)..L, oddExt f x * Real.cos (n * π * x / L)) = 0 ∧
    (1 / L) * (∫ x in (-L)..L, oddExt f x * Real.sin (n * π * x / L)) = halfSineCoeff L f n ∧
    (1 / L) * (∫ x in (-L)..L, evenExt f x * Real.sin (n * π * x / L)) = 0 ∧
    (1 / L) * (∫ x in (-L)..L, evenExt f x * Real.cos (n * π * x / L)) = halfCosineCoeff L f n := by
  have hc : Continuous (fun x : ℝ => Real.cos (n * π * x / L)) := by fun_prop
  have hs : Continuous (fun x : ℝ => Real.sin (n * π * x / L)) := by fun_prop
  have hfc : IntervalIntegrable (fun x => f x * Real.cos (n * π * x / L)) volume 0 L :=
    hf.mul_continuousOn hc.continuousOn
  have hfs : IntervalIntegrable (fun x => f x * Real.sin (n * π * x / L)) volume 0 L :=
    hf.mul_continuousOn hs.continuousOn
  -- on (0, L): the extensions agree with f, reflected points see -f or f
  have pos : ∀ (E : ℝ → ℝ) (m : ℝ → ℝ), (E = oddExt f ∨ E = evenExt f) →
      Set.EqOn (fun x => f x * m x) (fun x => E x * m x) (Set.uIcc 0 L) := by
    intro E m hE x hx
    rw [Set.uIcc_of_le hL.le] at hx
    rcases hE with rfl | rfl <;> simp [oddExt, evenExt, hx.1]
  have negO : ∀ x ∈ Set.Ioc (0 : ℝ) L, oddExt f (-x) = -f x := by
    intro x hx; simp [oddExt, not_le.mpr (neg_neg_of_pos hx.1)]
  have negE : ∀ x ∈ Set.Ioc (0 : ℝ) L, evenExt f (-x) = f x := by
    intro x hx; simp [evenExt, not_le.mpr (neg_neg_of_pos hx.1)]
  have cneg : ∀ x : ℝ, Real.cos (n * π * -x / L) = Real.cos (n * π * x / L) := by
    intro x; rw [show (n:ℝ) * π * -x / L = -(n * π * x / L) by ring, Real.cos_neg]
  have sneg : ∀ x : ℝ, Real.sin (n * π * -x / L) = -Real.sin (n * π * x / L) := by
    intro x; rw [show (n:ℝ) * π * -x / L = -(n * π * x / L) by ring, Real.sin_neg]
  have ioo : Set.Ioo (0 : ℝ) L ⊆ Set.Ioc 0 L := Set.Ioo_subset_Ioc_self
  refine ⟨?_, ?_, ?_, ?_⟩
  · have h0 := intervalIntegrable_congr_Ioo hL.le hfc
      (fun x hx => pos (oddExt f) (fun x => Real.cos (n * π * x / L)) (Or.inl rfl)
        (Set.Ioo_subset_Icc_self.trans (Set.uIcc_of_le hL.le).symm.subset hx))
    have h1 := intervalIntegrable_congr_Ioo hL.le hfc.neg (g := fun x => -(f x * Real.cos (n * π * x / L)))
      (h := fun x => oddExt f (-x) * Real.cos (n * π * -x / L))
      (fun x hx => by simp only; rw [negO x (ioo hx), cneg]; ring)
    rw [integral_symm_split L _ h0 h1]
    have e1 : (∫ x in (0:ℝ)..L, oddExt f (-x) * Real.cos (n * π * -x / L)) =
        ∫ x in (0:ℝ)..L, -(f x * Real.cos (n * π * x / L)) := by
      apply intervalIntegral.integral_congr_ae
      refine Filter.Eventually.of_forall (fun x hx => ?_)
      rw [Set.uIoc_of_le hL.le] at hx
      rw [negO x hx, cneg]; ring
    have e2 : (∫ x in (0:ℝ)..L, oddExt f x * Real.cos (n * π * x / L)) =
        ∫ x in (0:ℝ)..L, f x * Real.cos (n * π * x / L) :=
      (intervalIntegral.integral_congr (pos _ (fun x => Real.cos (n * π * x / L)) (Or.inl rfl))).symm
    rw [e1, e2, intervalIntegral.integral_neg]; ring
  · have h0 := intervalIntegrable_congr_Ioo hL.le hfs
      (fun x hx => pos (oddExt f) (fun x => Real.sin (n * π * x / L)) (Or.inl rfl)
        (Set.Ioo_subset_Icc_self.trans (Set.uIcc_of_le hL.le).symm.subset hx))
    have h1 := intervalIntegrable_congr_Ioo hL.le hfs (g := fun x => (f x * Real.sin (n * π * x / L)))
      (h := fun x => oddExt f (-x) * Real.sin (n * π * -x / L))
      (fun x hx => by simp only; rw [negO x (ioo hx), sneg]; ring)
    rw [integral_symm_split L _ h0 h1]
    have e1 : (∫ x in (0:ℝ)..L, oddExt f (-x) * Real.sin (n * π * -x / L)) =
        ∫ x in (0:ℝ)..L, (f x * Real.sin (n * π * x / L)) := by
      apply intervalIntegral.integral_congr_ae
      refine Filter.Eventually.of_forall (fun x hx => ?_)
      rw [Set.uIoc_of_le hL.le] at hx
      rw [negO x hx, sneg]; ring
    have e2 : (∫ x in (0:ℝ)..L, oddExt f x * Real.sin (n * π * x / L)) =
        ∫ x in (0:ℝ)..L, f x * Real.sin (n * π * x / L) :=
      (intervalIntegral.integral_congr (pos _ (fun x => Real.sin (n * π * x / L)) (Or.inl rfl))).symm
    rw [e1, e2, halfSineCoeff]; ring
  · have h0 := intervalIntegrable_congr_Ioo hL.le hfs
      (fun x hx => pos (evenExt f) (fun x => Real.sin (n * π * x / L)) (Or.inr rfl)
        (Set.Ioo_subset_Icc_self.trans (Set.uIcc_of_le hL.le).symm.subset hx))
    have h1 := intervalIntegrable_congr_Ioo hL.le hfs.neg (g := fun x => -(f x * Real.sin (n * π * x / L)))
      (h := fun x => evenExt f (-x) * Real.sin (n * π * -x / L))
      (fun x hx => by simp only; rw [negE x (ioo hx), sneg]; ring)
    rw [integral_symm_split L _ h0 h1]
    have e1 : (∫ x in (0:ℝ)..L, evenExt f (-x) * Real.sin (n * π * -x / L)) =
        ∫ x in (0:ℝ)..L, -(f x * Real.sin (n * π * x / L)) := by
      apply intervalIntegral.integral_congr_ae
      refine Filter.Eventually.of_forall (fun x hx => ?_)
      rw [Set.uIoc_of_le hL.le] at hx
      rw [negE x hx, sneg]; ring
    have e2 : (∫ x in (0:ℝ)..L, evenExt f x * Real.sin (n * π * x / L)) =
        ∫ x in (0:ℝ)..L, f x * Real.sin (n * π * x / L) :=
      (intervalIntegral.integral_congr (pos _ (fun x => Real.sin (n * π * x / L)) (Or.inr rfl))).symm
    rw [e1, e2, intervalIntegral.integral_neg]; ring
  · have h0 := intervalIntegrable_congr_Ioo hL.le hfc
      (fun x hx => pos (evenExt f) (fun x => Real.cos (n * π * x / L)) (Or.inr rfl)
        (Set.Ioo_subset_Icc_self.trans (Set.uIcc_of_le hL.le).symm.subset hx))
    have h1 := intervalIntegrable_congr_Ioo hL.le hfc (g := fun x => (f x * Real.cos (n * π * x / L)))
      (h := fun x => evenExt f (-x) * Real.cos (n * π * -x / L))
      (fun x hx => by simp only; rw [negE x (ioo hx), cneg])
    rw [integral_symm_split L _ h0 h1]
    have e1 : (∫ x in (0:ℝ)..L, evenExt f (-x) * Real.cos (n * π * -x / L)) =
        ∫ x in (0:ℝ)..L, (f x * Real.cos (n * π * x / L)) := by
      apply intervalIntegral.integral_congr_ae
      refine Filter.Eventually.of_forall (fun x hx => ?_)
      rw [Set.uIoc_of_le hL.le] at hx
      rw [negE x hx, cneg]
    have e2 : (∫ x in (0:ℝ)..L, evenExt f x * Real.cos (n * π * x / L)) =
        ∫ x in (0:ℝ)..L, f x * Real.cos (n * π * x / L) :=
      (intervalIntegral.integral_congr (pos _ (fun x => Real.cos (n * π * x / L)) (Or.inr rfl))).symm
    rw [e1, e2, halfCosineCoeff]; ring

/-- **Sines fit ends held at zero; cosines fit sealed ends.** For any length L > 0, any
coefficients c_n and any number of modes N, the sine sum Σ c_n sin(nπx/L) is 0 at x = 0 and
at x = L, and the cosine sum Σ c_n cos(nπx/L) has slope 0 at x = 0 and at x = L. -/
theorem half_range_modes_fit_the_ends (L : ℝ) (hL : 0 < L) (c : ℕ → ℝ) (N : ℕ) :
    (∑ n ∈ Finset.range N, c n * Real.sin (n * π * 0 / L)) = 0 ∧
    (∑ n ∈ Finset.range N, c n * Real.sin (n * π * L / L)) = 0 ∧
    deriv (fun x => ∑ n ∈ Finset.range N, c n * Real.cos (n * π * x / L)) 0 = 0 ∧
    deriv (fun x => ∑ n ∈ Finset.range N, c n * Real.cos (n * π * x / L)) L = 0 := by
  have hd : ∀ x, HasDerivAt (fun x => ∑ n ∈ Finset.range N, c n * Real.cos (n * π * x / L))
      (∑ n ∈ Finset.range N, c n * (-Real.sin (n * π * x / L) * (n * π * 1 / L))) x := by
    intro x
    apply HasDerivAt.fun_sum
    intro n _
    exact ((((hasDerivAt_id x).const_mul ((n : ℝ) * π)).div_const L).cos).const_mul (c n)
  have hsin : ∀ n : ℕ, Real.sin (n * π * L / L) = 0 := by
    intro n
    rw [mul_div_assoc, div_self hL.ne', mul_one, Real.sin_nat_mul_pi]
  refine ⟨by simp, by simp [hsin], ?_, ?_⟩
  · rw [(hd 0).deriv]; simp
  · rw [(hd L).deriv]; simp [hsin]

/-- **The plucked triangle.** For the string of length 1 pulled to 1 at its middle, for every
n ≥ 1 the sine coefficient is b_n = 8 sin(nπ/2)/(n²π²) and the cosine coefficient is
a_n = 4(2cos(nπ/2) − 1 − (−1)^n)/(n²π²), and a_0 = 1. At the middle x = 1/2, the sine series
Σ b_n sin(nπ/2) adds up to the peak 1, and the cosine series a_0/2 + Σ a_n cos(nπ/2) adds up to
the same value 1. -/
theorem plucked_triangle_half_range_series :
    (∀ n : ℕ, 1 ≤ n →
        halfSineCoeff 1 pluck n = 8 * Real.sin (n * π / 2) / (n ^ 2 * π ^ 2)) ∧
    (∀ n : ℕ, 1 ≤ n →
        halfCosineCoeff 1 pluck n =
          4 * (2 * Real.cos (n * π / 2) - 1 - (-1) ^ n) / (n ^ 2 * π ^ 2)) ∧
    halfCosineCoeff 1 pluck 0 = 1 ∧
    HasSum (fun n : ℕ => halfSineCoeff 1 pluck n * Real.sin (n * π * (1 / 2) / 1))
      (pluck (1 / 2)) ∧
    HasSum (fun n : ℕ => halfCosineCoeff 1 pluck (n + 1) *
        Real.cos ((n + 1 : ℕ) * π * (1 / 2) / 1))
      (pluck (1 / 2) - halfCosineCoeff 1 pluck 0 / 2) := by
  have hp : pluck (1 / 2) = 1 := by norm_num [pluck]
  have hpi : π ≠ 0 := pi_ne_zero
  refine ⟨pluck_sine, pluck_cosine, pluck_cosine_zero, ?_, ?_⟩
  · rw [show pluck (1 / 2) = 0 + 1 by rw [hp]; norm_num]
    apply HasSum.even_add_odd
    · convert hasSum_zero with k
      rw [show ((2 * k : ℕ) : ℝ) * π * (1 / 2) / 1 = k * π by push_cast; ring,
        Real.sin_nat_mul_pi, mul_zero]
    · convert hasSum_odd_inv_sq.mul_left (8 / π ^ 2) using 1
      · ext k
        rw [pluck_sine _ (by omega),
          show ((2 * k + 1 : ℕ) : ℝ) * π * (1 / 2) / 1 = ((2 * k + 1 : ℕ) : ℝ) * π / 2 by ring,
          sin_odd_half]
        have h := neg_one_sq_pow k
        have hn : ((2 * k + 1 : ℕ) : ℝ) ≠ 0 := by positivity
        field_simp
        linear_combination h
      · field_simp
  · rw [show pluck (1 / 2) - halfCosineCoeff 1 pluck 0 / 2 = 0 + (1 / 2 + 0) by
      rw [hp, pluck_cosine_zero]; norm_num]
    apply HasSum.even_add_odd
    · convert hasSum_zero with k
      rw [show ((2 * k + 1 : ℕ) : ℝ) * π * (1 / 2) / 1 = ((2 * k + 1 : ℕ) : ℝ) * π / 2 by ring,
        cos_odd_half, mul_zero]
    · apply HasSum.even_add_odd
      · convert hasSum_odd_inv_sq.mul_left (4 / π ^ 2) using 1
        · ext j
          rw [pluck_cosine _ (by omega)]
          have hc : Real.cos (((2 * (2 * j) + 1 + 1 : ℕ) : ℝ) * π * (1 / 2) / 1) = -1 := by
            rw [show ((2 * (2 * j) + 1 + 1 : ℕ) : ℝ) * π * (1 / 2) / 1
              = ((2 * j + 1 : ℕ) : ℝ) * π by push_cast; ring, Real.cos_nat_mul_pi]
            rw [pow_succ, pow_mul]; norm_num
          have hc' : Real.cos (((2 * (2 * j) + 1 + 1 : ℕ) : ℝ) * π / 2) = -1 := by
            rw [← hc]; ring_nf
          have hpow : ((-1 : ℝ)) ^ (2 * (2 * j) + 1 + 1) = 1 := by
            rw [show 2 * (2 * j) + 1 + 1 = 2 * (2 * j + 1) by ring, pow_mul]; norm_num
          rw [hc, hc', hpow]
          have hn : ((2 * j + 1 : ℕ) : ℝ) ≠ 0 := by positivity
          push_cast
          field_simp
          ring
        · field_simp; ring
      · convert hasSum_zero with j
        rw [pluck_cosine _ (by omega)]
        have hc : Real.cos (((2 * (2 * j + 1) + 1 + 1 : ℕ) : ℝ) * π * (1 / 2) / 1) = 1 := by
          rw [show ((2 * (2 * j + 1) + 1 + 1 : ℕ) : ℝ) * π * (1 / 2) / 1
            = ((2 * (j + 1) : ℕ) : ℝ) * π by push_cast; ring, Real.cos_nat_mul_pi, pow_mul]
          norm_num
        have hc' : Real.cos (((2 * (2 * j + 1) + 1 + 1 : ℕ) : ℝ) * π / 2) = 1 := by
          rw [← hc]; ring_nf
        have hpow : ((-1 : ℝ)) ^ (2 * (2 * j + 1) + 1 + 1) = 1 := by
          rw [show 2 * (2 * j + 1) + 1 + 1 = 2 * (2 * j + 2) by ring, pow_mul]; norm_num
        rw [hc, hc', hpow]
        ring

-- a_0 is twice the triangle's area: 2 × (1/2 × 1 × 1) = 1, so the rod's average a_0/2 is 1/2.
example : (2 : ℚ) * (1 / 2 * 1 * 1) = 1 ∧ (1 : ℚ) / 2 = 1 / 2 := by norm_num
-- sin(nπ/2) runs 0, 1, 0, −1: it is nonzero exactly for odd n, so b_2, b_4, b_6 are 0.
example : ∀ n < 12, (([0, 1, 0, -1] : List ℤ).getD (n % 4) 0 ≠ 0 ↔ n % 2 = 1) := by decide
-- The cosine factor 2cos(nπ/2) − 1 − (−1)^n is nonzero exactly at n = 2, 6, 10.
example : ∀ n < 12,
    (2 * ([1, 0, -1, 0] : List ℤ).getD (n % 4) 0 - 1 - (-1) ^ n ≠ 0 ↔ n % 4 = 2) := by decide
-- At n = 2 the cosine factor times 4 is −16, so a_2 = −16/(4π²).
example : (4 : ℤ) * (2 * (-1) - 1 - (-1) ^ 2) = -16 := by norm_num
-- The bracket in the peak sums (8/π²)(1 + 1/9) and (8/π²)(1 + 1/9 + 1/25).
example : (1 : ℚ) + 1 / 9 = 10 / 9 ∧ (1 : ℚ) + 1 / 9 + 1 / 25 = 259 / 225 := by norm_num

#print axioms half_range_coefficients_from_reflection
#print axioms half_range_modes_fit_the_ends
#print axioms plucked_triangle_half_range_series
