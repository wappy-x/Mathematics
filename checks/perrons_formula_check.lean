-- Perron's formula: the half-at-a-jump running total of a Dirichlet series that converges absolutely on the line Re s = c equals its line integral against x^s/s cut at height T, up to an error bounded term by term by (x/n)^c min(1, 1/(πT |log(x/n)|)).
import Mathlib.NumberTheory.LSeries.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Complex
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Arctan
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Analysis.Complex.HasPrimitives
import Mathlib.Analysis.Complex.RemovableSingularity
import Mathlib.Analysis.SpecialFunctions.Complex.LogDeriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.MeasureTheory.Integral.DominatedConvergence

open Complex
open scoped Real

/-- The perfect switch δ(y): 1 if y > 1, 1/2 if y = 1, 0 if y < 1. -/
noncomputable def perronStep (y : ℝ) : ℝ :=
  if 1 < y then 1 else if y = 1 then 1 / 2 else 0

/-- The cut switch integral I(y, T) = (1/2πi) ∫ y^s/s ds up the line from c − iT to c + iT,
parametrised by s = c + it, so ds = i dt. -/
noncomputable def switchIntegral (c T y : ℝ) : ℂ :=
  1 / (2 * π * I) * ∫ t in (-T)..T, (y : ℂ) ^ ((c : ℂ) + t * I) / ((c : ℂ) + t * I) * I

/-- A₀(x): the running total of a(1), a(2), … up to x, with the last term counted half
when x is a whole number. -/
noncomputable def runningTotalHalf (a : ℕ → ℂ) (x : ℝ) : ℂ :=
  (∑ n ∈ Finset.Icc 1 ⌊x⌋₊, a n) - (if (⌊x⌋₊ : ℝ) = x then a ⌊x⌋₊ / 2 else 0)

/-- J(T): the cut Perron integral (1/2πi) ∫ F(s) x^s/s ds up the line from c − iT to c + iT,
where F = Σ a(n) n^(−s) is Mathlib's `LSeries a`. -/
noncomputable def perronCut (a : ℕ → ℂ) (c T x : ℝ) : ℂ :=
  1 / (2 * π * I) *
    ∫ t in (-T)..T, LSeries a ((c : ℂ) + t * I) * (x : ℂ) ^ ((c : ℂ) + t * I) / ((c : ℂ) + t * I) * I

/-- The card's error bound: the sum over n ≥ 1 with n ≠ x of |a(n)| (x/n)^c min(1, 1/(πT |log(x/n)|)),
plus c |a(x)|/(πT) when x is the whole number n. -/
noncomputable def perronErrorBound (a : ℕ → ℂ) (c T x : ℝ) : ℝ :=
  ∑' n : ℕ,
    if n = 0 then 0
    else if (n : ℝ) = x then c * ‖a n‖ / (π * T)
    else ‖a n‖ * (x / n) ^ c * min 1 (1 / (π * T * |Real.log (x / n)|))

/-- FTC along a path: a primitive turns a path integral into a difference of end values. -/
theorem perron_path_ftc {H F : ℂ → ℂ} {U : Set ℂ} (hH : ∀ z ∈ U, HasDerivAt H (F z) z)
    (hF : ContinuousOn F U) {γ γ' : ℝ → ℂ} {a b : ℝ}
    (hγ : ∀ t ∈ Set.uIcc a b, HasDerivAt γ (γ' t) t) (hγ' : ContinuousOn γ' (Set.uIcc a b))
    (hU : ∀ t ∈ Set.uIcc a b, γ t ∈ U) :
    ∫ t in a..b, F (γ t) * γ' t = H (γ b) - H (γ a) := by
  apply intervalIntegral.integral_eq_sub_of_hasDerivAt
  · intro t ht
    exact (hH _ (hU t ht)).comp t (hγ t ht)
  · apply ContinuousOn.intervalIntegrable
    apply ContinuousOn.mul _ hγ'
    exact hF.comp (fun t ht => (hγ t ht).continuousAt.continuousWithinAt) (fun t ht => hU t ht)

theorem perron_hasDerivAt_line (p d : ℂ) (t : ℝ) :
    HasDerivAt (fun t : ℝ => p + (t : ℂ) * d) d t := by
  have h := ((hasDerivAt_id t).ofReal_comp.mul_const d).const_add p
  simpa using h

/-- FTC along a straight segment. -/
theorem perron_segment_ftc {H F : ℂ → ℂ} {U : Set ℂ} (hH : ∀ z ∈ U, HasDerivAt H (F z) z)
    (hF : ContinuousOn F U) (p d : ℂ) {a b : ℝ}
    (hU : ∀ t ∈ Set.uIcc a b, p + (t : ℂ) * d ∈ U) :
    ∫ t in a..b, F (p + (t : ℂ) * d) * d = H (p + (b : ℂ) * d) - H (p + (a : ℂ) * d) :=
  perron_path_ftc (γ := fun t : ℝ => p + (t : ℂ) * d) (γ' := fun _ => d) hH hF
    (fun t _ => perron_hasDerivAt_line p d t) continuousOn_const hU

/-- The integrand e^{Ls}/s. -/
noncomputable def perronE (L : ℝ) (s : ℂ) : ℂ := Complex.exp (L * s) / s

theorem perronE_continuousOn (L : ℝ) : ContinuousOn (perronE L) {z | z ≠ 0} := by
  unfold perronE
  apply ContinuousOn.div
  · fun_prop
  · exact continuousOn_id
  · intro z hz; exact hz

/-- An entire primitive for the removable part (e^{Ls} - 1)/s. -/
theorem perron_entire_part (L : ℝ) :
    ∃ G : ℂ → ℂ, ∀ z : ℂ, z ≠ 0 → HasDerivAt G (perronE L z - z⁻¹) z := by
  set g := dslope (fun s : ℂ => Complex.exp (L * s)) 0
  have hd : Differentiable ℂ g := by
    have : DifferentiableOn ℂ g Set.univ :=
      (differentiableOn_dslope Filter.univ_mem).2 (by fun_prop)
    exact fun z => (this z (Set.mem_univ z)).differentiableAt Filter.univ_mem
  obtain ⟨G, hG⟩ := hd.isExactOn_univ
  refine ⟨G, fun z hz => ?_⟩
  have : g z = perronE L z - z⁻¹ := by
    simp only [g, dslope_of_ne _ hz, slope_def_field, perronE]
    field_simp
    simp
  rw [← this]
  exact hG z (Set.mem_univ z)


theorem perron_prims (L : ℝ) : ∃ H1 H2 : ℂ → ℂ,
    (∀ z ∈ slitPlane, HasDerivAt H1 (perronE L z) z) ∧
    (∀ z, -z ∈ slitPlane → HasDerivAt H2 (perronE L z) z) ∧
    ∀ z w, H1 z - H1 w - (H2 z - H2 w) =
      Complex.log z - Complex.log w - (Complex.log (-z) - Complex.log (-w)) := by
  obtain ⟨G, hG⟩ := perron_entire_part L
  refine ⟨fun z => G z + Complex.log z, fun z => G z + Complex.log (-z), ?_, ?_, ?_⟩
  · intro z hz
    have hz0 : z ≠ 0 := slitPlane_ne_zero hz
    have h := (hG z hz0).add (hasDerivAt_log hz)
    convert h using 1
    ring
  · intro z hz
    have hz0 : z ≠ 0 := by
      intro h; rw [h, neg_zero] at hz; exact slitPlane_ne_zero hz rfl
    have h2 : HasDerivAt (fun w => Complex.log (-w)) ((-z)⁻¹ * -1) z :=
      (hasDerivAt_log hz).comp z (hasDerivAt_neg z)
    have h := (hG z hz0).add h2
    convert h using 1
    rw [inv_neg]; ring
  · intro z w; ring

theorem perron_log_identity {c T : ℝ} (hT : 0 < T) :
    Complex.log ((c:ℂ) + (T:ℂ) * I) - Complex.log ((c:ℂ) + ((-T:ℝ):ℂ) * I) -
      (Complex.log (-((c:ℂ) + (T:ℂ) * I)) - Complex.log (-((c:ℂ) + ((-T:ℝ):ℂ) * I))) =
      2 * π * I := by
  set z : ℂ := (c:ℂ) + (T:ℂ) * I with hz
  have hzc : (c:ℂ) + ((-T:ℝ):ℂ) * I = (starRingEnd ℂ) z := by
    apply Complex.ext <;> simp [hz]
  have him : 0 < z.im := by simp [hz, hT]
  have harg : arg ((starRingEnd ℂ) z) = - arg z := by
    rw [arg_conj]
    split_ifs with h
    · rw [arg_eq_pi_iff] at h; linarith [h.2]
    · rfl
  have h1 : arg (-z) = arg z - π := arg_neg_eq_arg_sub_pi_of_im_pos him
  have h2 : arg (-(starRingEnd ℂ) z) = arg ((starRingEnd ℂ) z) + π :=
    arg_neg_eq_arg_add_pi_of_im_neg (by simp; linarith)
  rw [hzc]
  apply Complex.ext
  · simp [log_re, norm_neg]
  · simp only [sub_im, log_im, h1, h2, harg]
    simp
    ring

theorem perronE_norm (L : ℝ) (z : ℂ) : ‖perronE L z‖ = Real.exp (L * z.re) / ‖z‖ := by
  simp [perronE, norm_exp]

/-- The segment integral S = ∫_{-T}^{T} e^{L(c+it)}/(c+it) · i dt. -/
noncomputable def perronS (c T L : ℝ) : ℂ :=
  ∫ t in (-T)..T, perronE L ((c:ℂ) + (t:ℂ) * I) * I

theorem perron_horiz_norm (L σ T t : ℝ) (hT : 0 < T) (hσ : |σ| = T) :
    ‖perronE L ((σ:ℂ) * I + (t:ℂ) * 1) * 1‖ ≤ Real.exp (L * t) / T := by
  rw [mul_one, perronE_norm]
  have hre : ((σ:ℂ) * I + (t:ℂ) * 1).re = t := by simp
  have him : |((σ:ℂ) * I + (t:ℂ) * 1).im| = T := by simp [hσ]
  rw [hre]
  apply div_le_div_of_nonneg_left (Real.exp_pos _).le hT
  rw [← him]; exact abs_im_le_norm _

theorem perron_vert_norm (L X t : ℝ) (hX : 0 < |X|) :
    ‖perronE L ((X:ℂ) + (t:ℂ) * I) * I‖ ≤ Real.exp (L * X) / |X| := by
  rw [norm_mul, norm_I, mul_one, perronE_norm]
  have hre : ((X:ℂ) + (t:ℂ) * I).re = X := by simp
  rw [hre]
  apply div_le_div_of_nonneg_left (Real.exp_pos _).le hX
  have : |((X:ℂ) + (t:ℂ) * I).re| ≤ ‖(X:ℂ) + (t:ℂ) * I‖ := abs_re_le_norm _
  rwa [hre] at this

theorem perron_exp_integral (L T a b : ℝ) (hL : L ≠ 0) (hT : T ≠ 0) :
    ∫ t in a..b, Real.exp (L * t) / T = (Real.exp (L * b) - Real.exp (L * a)) / (L * T) := by
  have hd : ∀ t ∈ Set.uIcc a b,
      HasDerivAt (fun t => Real.exp (L * t) / (L * T)) (Real.exp (L * t) / T) t := by
    intro t _
    have h : HasDerivAt (fun t => Real.exp (L * t) / (L * T)) (Real.exp (L * t) * L / (L * T)) t :=
      by simpa using (((hasDerivAt_id t).const_mul L).exp).div_const (L * T)
    rw [show Real.exp (L * t) / T = Real.exp (L * t) * L / (L * T) by field_simp]
    exact h
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hd
    (by apply Continuous.intervalIntegrable; fun_prop)]
  ring

theorem perron_horiz_int (L σ T a b : ℝ) (hT : 0 < T) (hσ : |σ| = T) (hab : a ≤ b)
    (hL : L ≠ 0) :
    ‖∫ t in a..b, perronE L ((σ:ℂ) * I + (t:ℂ) * 1) * 1‖ ≤
      (Real.exp (L * b) - Real.exp (L * a)) / (L * T) := by
  rw [← perron_exp_integral L T a b hL hT.ne']
  apply intervalIntegral.norm_integral_le_of_norm_le hab
  · exact Filter.Eventually.of_forall (fun t _ => perron_horiz_norm L σ T t hT hσ)
  · apply Continuous.intervalIntegrable; fun_prop

theorem perron_limit {q B K c : ℝ} (h : ∀ X, c < X → q ≤ B + K / X) :
    q ≤ B := by
  apply le_of_forall_pos_le_add
  intro ε hε
  set X := max (c + 1) (max 1 (K / ε)) + 1 with hXdef
  have h1 : c + 1 ≤ max (c + 1) (max 1 (K / ε)) := le_max_left _ _
  have h2 : 1 ≤ max (c + 1) (max 1 (K / ε)) := (le_max_left _ _).trans (le_max_right _ _)
  have h3 : K / ε ≤ max (c + 1) (max 1 (K / ε)) := (le_max_right _ _).trans (le_max_right _ _)
  have hX : c < X := by linarith
  have hXpos : 0 < X := by linarith
  have hq := h X hX
  have hKX : K / X ≤ ε := by
    rw [div_le_iff₀ hXpos]
    have : K / ε ≤ X := by linarith
    rw [div_le_iff₀ hε] at this
    linarith
  linarith

theorem perron_S_right {L c T X : ℝ} (hc : 0 < c) (hT : 0 < T) (hX : c < X) :
    perronS c T L = (∫ t in c..X, perronE L (((-T:ℝ):ℂ) * I + (t:ℂ) * 1) * 1)
      + (∫ t in (-T)..T, perronE L ((X:ℂ) + (t:ℂ) * I) * I)
      - (∫ t in c..X, perronE L ((T:ℂ) * I + (t:ℂ) * 1) * 1) := by
  obtain ⟨H1, -, hH1, -, -⟩ := perron_prims L
  have hF : ContinuousOn (perronE L) slitPlane :=
    (perronE_continuousOn L).mono (fun z hz => slitPlane_ne_zero hz)
  have e1 := perron_segment_ftc hH1 hF (c:ℂ) I (a := -T) (b := T)
    (by intro t _; rw [mem_slitPlane_iff]; left; simp [hc])
  have e2 := perron_segment_ftc hH1 hF (((-T:ℝ):ℂ) * I) 1 (a := c) (b := X)
    (by intro t _; rw [mem_slitPlane_iff]; right; simp; exact hT.ne')
  have e3 := perron_segment_ftc hH1 hF (X:ℂ) I (a := -T) (b := T)
    (by intro t _; rw [mem_slitPlane_iff]; left; simp; linarith)
  have e4 := perron_segment_ftc hH1 hF ((T:ℂ) * I) 1 (a := c) (b := X)
    (by intro t _; rw [mem_slitPlane_iff]; right; simp; exact hT.ne')
  unfold perronS
  rw [e1, e2, e3, e4]
  rw [show ((-T:ℝ):ℂ) * I + (c:ℂ) * 1 = (c:ℂ) + ((-T:ℝ):ℂ) * I by ring,
    show ((-T:ℝ):ℂ) * I + (X:ℂ) * 1 = (X:ℂ) + ((-T:ℝ):ℂ) * I by ring,
    show (T:ℂ) * I + (X:ℂ) * 1 = (X:ℂ) + (T:ℂ) * I by ring,
    show (T:ℂ) * I + (c:ℂ) * 1 = (c:ℂ) + (T:ℂ) * I by ring]
  ring

theorem perron_S_lt_small {L c T : ℝ} (hc : 0 < c) (hT : 0 < T) (hL : L < 0) :
    ‖perronS c T L‖ ≤ 4 * Real.exp (L * c) := by
  rw [perron_S_right (X := c + T) hc hT (by linarith)]
  set e := Real.exp (L * c)
  have hhor : ∀ σ : ℝ, |σ| = T →
      ‖∫ t in c..(c + T), perronE L ((σ:ℂ) * I + (t:ℂ) * 1) * 1‖ ≤ e := by
    intro σ hσ
    have := intervalIntegral.norm_integral_le_of_norm_le_const (a := c) (b := c + T)
      (C := e / T) (f := fun t => perronE L ((σ:ℂ) * I + (t:ℂ) * 1) * 1) (by
        intro t ht
        rw [Set.uIoc_of_le (by linarith)] at ht
        refine (perron_horiz_norm L σ T t hT hσ).trans ?_
        apply div_le_div_of_nonneg_right _ hT.le
        apply Real.exp_le_exp.2
        nlinarith [ht.1])
    rw [show c + T - c = T by ring, abs_of_pos hT, div_mul_cancel₀ _ hT.ne'] at this
    exact this
  have hb := hhor (-T) (by simp [abs_of_pos hT])
  have ht := hhor T (abs_of_pos hT)
  have hv : ‖∫ t in (-T)..T, perronE L (((c + T : ℝ) : ℂ) + (t:ℂ) * I) * I‖ ≤ 2 * e := by
    have := intervalIntegral.norm_integral_le_of_norm_le_const (a := -T) (b := T)
      (C := Real.exp (L * (c + T)) / |c + T|)
      (f := fun t => perronE L (((c + T : ℝ) : ℂ) + (t:ℂ) * I) * I)
      (fun t _ => perron_vert_norm L (c + T) t (by rw [abs_of_pos (by linarith)]; linarith))
    refine this.trans ?_
    rw [abs_of_pos (show (0:ℝ) < c + T by linarith), show T - -T = 2 * T by ring,
      abs_of_pos (show (0:ℝ) < 2 * T by linarith)]
    have h1 : Real.exp (L * (c + T)) ≤ e := Real.exp_le_exp.2 (by nlinarith)
    have h2 : 0 < e := Real.exp_pos _
    rw [div_mul_eq_mul_div, div_le_iff₀ (by linarith)]
    nlinarith
  have := norm_add_le (∫ t in c..(c + T), perronE L (((-T:ℝ):ℂ) * I + (t:ℂ) * 1) * 1)
    (∫ t in (-T)..T, perronE L (((c + T : ℝ) : ℂ) + (t:ℂ) * I) * I)
  have := norm_sub_le ((∫ t in c..(c + T), perronE L (((-T:ℝ):ℂ) * I + (t:ℂ) * 1) * 1)
    + (∫ t in (-T)..T, perronE L (((c + T : ℝ) : ℂ) + (t:ℂ) * I) * I))
    (∫ t in c..(c + T), perronE L ((T:ℂ) * I + (t:ℂ) * 1) * 1)
  linarith

theorem perron_S_lt_large {L c T : ℝ} (hc : 0 < c) (hT : 0 < T) (hL : L < 0) :
    ‖perronS c T L‖ ≤ 2 * Real.exp (L * c) / (T * (-L)) := by
  set e := Real.exp (L * c)
  have hB : 2 * e / (T * (-L)) = e / (T * (-L)) + e / (T * (-L)) := by ring
  apply perron_limit (K := 2 * T) (c := c)
  intro X hX
  rw [perron_S_right hc hT hX]
  have hhor : ∀ σ : ℝ, |σ| = T →
      ‖∫ t in c..X, perronE L ((σ:ℂ) * I + (t:ℂ) * 1) * 1‖ ≤ e / (T * (-L)) := by
    intro σ hσ
    refine (perron_horiz_int L σ T c X hT hσ hX.le hL.ne).trans ?_
    rw [show (Real.exp (L * X) - e) / (L * T) = (e - Real.exp (L * X)) / (T * (-L)) by
      field_simp; ring]
    apply div_le_div_of_nonneg_right _ (by nlinarith)
    linarith [Real.exp_pos (L * X)]
  have hb := hhor (-T) (by simp [abs_of_pos hT])
  have ht := hhor T (abs_of_pos hT)
  have hXpos : 0 < X := by linarith
  have hv : ‖∫ t in (-T)..T, perronE L ((X : ℂ) + (t:ℂ) * I) * I‖ ≤ 2 * T / X := by
    have := intervalIntegral.norm_integral_le_of_norm_le_const (a := -T) (b := T)
      (C := Real.exp (L * X) / |X|)
      (f := fun t => perronE L ((X : ℂ) + (t:ℂ) * I) * I)
      (fun t _ => perron_vert_norm L X t (by rw [abs_of_pos hXpos]; exact hXpos))
    refine this.trans ?_
    rw [abs_of_pos hXpos, show T - -T = 2 * T by ring,
      abs_of_pos (show (0:ℝ) < 2 * T by linarith)]
    have h1 : Real.exp (L * X) ≤ 1 := Real.exp_le_one_iff.2 (by nlinarith)
    rw [div_mul_eq_mul_div]
    apply div_le_div_of_nonneg_right _ hXpos.le
    nlinarith
  have := norm_add_le (∫ t in c..X, perronE L (((-T:ℝ):ℂ) * I + (t:ℂ) * 1) * 1)
    (∫ t in (-T)..T, perronE L ((X:ℂ) + (t:ℂ) * I) * I)
  have := norm_sub_le ((∫ t in c..X, perronE L (((-T:ℝ):ℂ) * I + (t:ℂ) * 1) * 1)
    + (∫ t in (-T)..T, perronE L ((X:ℂ) + (t:ℂ) * I) * I))
    (∫ t in c..X, perronE L ((T:ℂ) * I + (t:ℂ) * 1) * 1)
  linarith

theorem perron_S_left {L c T X : ℝ} (hc : 0 < c) (hT : 0 < T) (hX : 0 < X) :
    perronS c T L - 2 * π * I =
      -(∫ t in (-X)..c, perronE L (((-T:ℝ):ℂ) * I + (t:ℂ) * 1) * 1)
      + (∫ t in (-T)..T, perronE L (((-X:ℝ):ℂ) + (t:ℂ) * I) * I)
      + (∫ t in (-X)..c, perronE L ((T:ℂ) * I + (t:ℂ) * 1) * 1) := by
  obtain ⟨H1, H2, hH1, hH2, hdiff⟩ := perron_prims L
  have hF : ContinuousOn (perronE L) slitPlane :=
    (perronE_continuousOn L).mono (fun z hz => slitPlane_ne_zero hz)
  have hH2' : ∀ z ∈ {z : ℂ | -z ∈ slitPlane}, HasDerivAt H2 (perronE L z) z :=
    fun z hz => hH2 z hz
  have hF2 : ContinuousOn (perronE L) {z : ℂ | -z ∈ slitPlane} :=
    (perronE_continuousOn L).mono (fun z hz h0 => by
      simp only [Set.mem_ofPred_eq, h0, neg_zero] at hz; exact slitPlane_ne_zero hz rfl)
  have e1 := perron_segment_ftc hH1 hF (c:ℂ) I (a := -T) (b := T)
    (by intro t _; rw [mem_slitPlane_iff]; left; simp [hc])
  have e2 := perron_segment_ftc hH2' hF2 (((-T:ℝ):ℂ) * I) 1 (a := -X) (b := c)
    (by intro t _; show _ ∈ slitPlane; rw [mem_slitPlane_iff]; right; simp; exact hT.ne')
  have e3 := perron_segment_ftc hH2' hF2 ((-X:ℝ):ℂ) I (a := -T) (b := T)
    (by intro t _; show _ ∈ slitPlane; rw [mem_slitPlane_iff]; left; simp; linarith)
  have e4 := perron_segment_ftc hH2' hF2 ((T:ℂ) * I) 1 (a := -X) (b := c)
    (by intro t _; show _ ∈ slitPlane; rw [mem_slitPlane_iff]; right; simp; exact hT.ne')
  unfold perronS
  rw [e1, e2, e3, e4]
  rw [show ((-T:ℝ):ℂ) * I + (c:ℂ) * 1 = (c:ℂ) + ((-T:ℝ):ℂ) * I by ring,
    show ((-T:ℝ):ℂ) * I + ((-X:ℝ):ℂ) * 1 = ((-X:ℝ):ℂ) + ((-T:ℝ):ℂ) * I by ring,
    show (T:ℂ) * I + ((-X:ℝ):ℂ) * 1 = ((-X:ℝ):ℂ) + (T:ℂ) * I by ring,
    show (T:ℂ) * I + (c:ℂ) * 1 = (c:ℂ) + (T:ℂ) * I by ring]
  linear_combination (hdiff ((c:ℂ) + (T:ℂ) * I) ((c:ℂ) + ((-T:ℝ):ℂ) * I)) +
    perron_log_identity hT

theorem perron_S_gt_large {L c T : ℝ} (hc : 0 < c) (hT : 0 < T) (hL : 0 < L) :
    ‖perronS c T L - 2 * π * I‖ ≤ 2 * Real.exp (L * c) / (T * L) := by
  set e := Real.exp (L * c)
  have hB : 2 * e / (T * L) = e / (T * L) + e / (T * L) := by ring
  apply perron_limit (K := 2 * T) (c := 0)
  intro X hX
  rw [perron_S_left hc hT hX]
  have hhor : ∀ σ : ℝ, |σ| = T →
      ‖∫ t in (-X)..c, perronE L ((σ:ℂ) * I + (t:ℂ) * 1) * 1‖ ≤ e / (T * L) := by
    intro σ hσ
    refine (perron_horiz_int L σ T (-X) c hT hσ (by linarith) hL.ne').trans ?_
    rw [show L * T = T * L by ring]
    apply div_le_div_of_nonneg_right _ (by positivity)
    linarith [Real.exp_pos (L * -X)]
  have hb := hhor (-T) (by simp [abs_of_pos hT])
  have ht := hhor T (abs_of_pos hT)
  have hv : ‖∫ t in (-T)..T, perronE L (((-X:ℝ) : ℂ) + (t:ℂ) * I) * I‖ ≤ 2 * T / X := by
    have := intervalIntegral.norm_integral_le_of_norm_le_const (a := -T) (b := T)
      (C := Real.exp (L * (-X)) / |(-X)|)
      (f := fun t => perronE L (((-X:ℝ) : ℂ) + (t:ℂ) * I) * I)
      (fun t _ => perron_vert_norm L (-X) t (by rw [abs_neg, abs_of_pos hX]; exact hX))
    refine this.trans ?_
    rw [abs_neg, abs_of_pos hX, show T - -T = 2 * T by ring,
      abs_of_pos (show (0:ℝ) < 2 * T by linarith)]
    have h1 : Real.exp (L * (-X)) ≤ 1 := Real.exp_le_one_iff.2 (by nlinarith)
    rw [div_mul_eq_mul_div]
    apply div_le_div_of_nonneg_right _ hX.le
    nlinarith
  have h1 := norm_add_le (-(∫ t in (-X)..c, perronE L (((-T:ℝ):ℂ) * I + (t:ℂ) * 1) * 1))
    (∫ t in (-T)..T, perronE L (((-X:ℝ):ℂ) + (t:ℂ) * I) * I)
  have h2 := norm_add_le (-(∫ t in (-X)..c, perronE L (((-T:ℝ):ℂ) * I + (t:ℂ) * 1) * 1)
    + (∫ t in (-T)..T, perronE L (((-X:ℝ):ℂ) + (t:ℂ) * I) * I))
    (∫ t in (-X)..c, perronE L ((T:ℂ) * I + (t:ℂ) * 1) * 1)
  rw [norm_neg] at h1
  linarith

theorem perron_S_gt_small {L c T : ℝ} (hc : 0 < c) (hT : 0 < T) (hL : 0 < L) :
    ‖perronS c T L - 2 * π * I‖ ≤ 2 * π * Real.exp (L * c) := by
  obtain ⟨H1, H2, hH1, hH2, hdiff⟩ := perron_prims L
  have hF : ContinuousOn (perronE L) slitPlane :=
    (perronE_continuousOn L).mono (fun z hz => slitPlane_ne_zero hz)
  have hF2 : ContinuousOn (perronE L) {z : ℂ | -z ∈ slitPlane} :=
    (perronE_continuousOn L).mono (fun z hz h0 => by
      simp only [Set.mem_ofPred_eq, h0, neg_zero] at hz; exact slitPlane_ne_zero hz rfl)
  set z0 : ℂ := (c:ℂ) + (T:ℂ) * I with hz0def
  set z1 : ℂ := (c:ℂ) + ((-T:ℝ):ℂ) * I with hz1def
  have hz0 : z0 ≠ 0 := by
    intro h; have := congrArg Complex.re h; simp [hz0def] at this; linarith
  set R := ‖z0‖ with hRdef
  have hR : 0 < R := norm_pos_iff.2 hz0
  set θ0 := arg z0 with hθ0def
  have hθpos : 0 < θ0 := by
    rcases (arg_nonneg_iff.2 (by simp [hz0def]; linarith : 0 ≤ z0.im)).lt_or_eq with h | h
    · exact h
    · exfalso
      have := (arg_eq_zero_iff.1 h.symm).2
      simp [hz0def] at this; linarith
  have hθlt : θ0 < π / 2 := by
    have := abs_arg_lt_pi_div_two_iff.2 (Or.inl (by simp [hz0def]; exact hc) : 0 < z0.re ∨ z0 = 0)
    exact (abs_lt.1 this).2
  have hcos0 : Real.cos θ0 = c / R := by rw [hθ0def, cos_arg hz0]; congr 1; simp [hz0def]
  have hsin0 : Real.sin θ0 = T / R := by rw [hθ0def, sin_arg]; congr 1; simp [hz0def]
  set γ : ℝ → ℂ := fun θ => (R:ℂ) * Complex.exp ((θ:ℂ) * I) with hγdef
  set γ' : ℝ → ℂ := fun θ => (R:ℂ) * Complex.exp ((θ:ℂ) * I) * I with hγ'def
  have hγ : ∀ θ : ℝ, HasDerivAt γ (γ' θ) θ := by
    intro θ
    have := (((hasDerivAt_id θ).ofReal_comp.mul_const I).cexp).const_mul (R:ℂ)
    convert this using 1
    · rfl
    · simp only [hγ'def, id, Complex.ofReal_one, one_mul, mul_assoc]
  have hγre : ∀ θ : ℝ, (γ θ).re = R * Real.cos θ := by
    intro θ; simp [hγdef, exp_ofReal_mul_I_re]
  have hγim : ∀ θ : ℝ, (γ θ).im = R * Real.sin θ := by
    intro θ; simp [hγdef, exp_ofReal_mul_I_im]
  have hγ0 : γ θ0 = z0 := norm_mul_exp_arg_mul_I z0
  have hγ1 : γ (2 * π - θ0) = z1 := by
    apply Complex.ext
    · rw [hγre, Real.cos_two_pi_sub, hcos0]; simp [hz1def]; field_simp
    · rw [hγim, Real.sin_two_pi_sub, hsin0]; simp [hz1def]; field_simp
  have hle : θ0 ≤ 2 * π - θ0 := by linarith [Real.pi_pos]
  have hmem : ∀ θ ∈ Set.uIcc θ0 (2 * π - θ0), γ θ ∈ {z : ℂ | -z ∈ slitPlane} := by
    intro θ hθ
    rw [Set.uIcc_of_le hle] at hθ
    show -(γ θ) ∈ slitPlane
    rw [mem_slitPlane_iff, neg_re, neg_im, hγre, hγim]
    rcases lt_trichotomy θ π with h | h | h
    · right
      have := Real.sin_pos_of_pos_of_lt_pi (by linarith [hθ.1]) h
      have : 0 < R * Real.sin θ := mul_pos hR this
      linarith
    · left; rw [h, Real.cos_pi]; linarith
    · right
      have := Real.sin_neg_of_neg_of_neg_pi_lt (x := θ - 2 * π) (by linarith [hθ.2])
        (by linarith)
      rw [Real.sin_sub_two_pi] at this
      have : R * Real.sin θ < 0 := mul_neg_of_pos_of_neg hR this
      linarith
  have e1 := perron_segment_ftc hH1 hF (c:ℂ) I (a := -T) (b := T)
    (by intro t _; rw [mem_slitPlane_iff]; left; simp [hc])
  have e2 := perron_path_ftc (U := {z : ℂ | -z ∈ slitPlane}) (fun z hz => hH2 z hz) hF2
    (γ := γ) (γ' := γ') (a := θ0) (b := 2 * π - θ0) (fun θ _ => hγ θ)
    (by rw [hγ'def]; fun_prop) hmem
  rw [hγ0, hγ1] at e2
  have hS : perronS c T L - 2 * π * I =
      -(∫ θ in θ0..(2 * π - θ0), perronE L (γ θ) * γ' θ) := by
    unfold perronS
    rw [e1, e2]
    linear_combination (hdiff z0 z1) + perron_log_identity hT
  rw [hS, norm_neg]
  have hbound := intervalIntegral.norm_integral_le_of_norm_le_const (a := θ0) (b := 2 * π - θ0)
    (C := Real.exp (L * c)) (f := fun θ => perronE L (γ θ) * γ' θ) (by
      intro θ hθ
      rw [Set.uIoc_of_le hle] at hθ
      have hnγ : ‖γ θ‖ = R := by
        simp [hγdef, norm_exp_ofReal_mul_I, abs_of_pos hR]
      have hnγ' : ‖γ' θ‖ = R := by
        simp [hγ'def, norm_exp_ofReal_mul_I, abs_of_pos hR]
      rw [norm_mul, perronE_norm, hnγ, hnγ', hγre, div_mul_cancel₀ _ hR.ne']
      apply Real.exp_le_exp.2
      have hcos : Real.cos θ ≤ Real.cos θ0 := by
        rcases le_or_gt θ π with h | h
        · exact Real.cos_le_cos_of_nonneg_of_le_pi hθpos.le h hθ.1.le
        · rw [← Real.cos_two_pi_sub θ]
          exact Real.cos_le_cos_of_nonneg_of_le_pi hθpos.le (by linarith) (by linarith [hθ.2])
      have : R * Real.cos θ ≤ c := by
        calc R * Real.cos θ ≤ R * Real.cos θ0 := mul_le_mul_of_nonneg_left hcos hR.le
          _ = c := by rw [hcos0]; field_simp
      nlinarith)
  refine hbound.trans ?_
  rw [abs_of_nonneg (by linarith)]
  have := Real.exp_pos (L * c)
  nlinarith

theorem perron_switch_eq {c T y : ℝ} (hy : 0 < y) :
    switchIntegral c T y = 1 / (2 * π * I) * perronS c T (Real.log y) := by
  unfold switchIntegral perronS
  congr 1
  apply intervalIntegral.integral_congr
  intro t _
  simp only [perronE]
  rw [cpow_def_of_ne_zero (ofReal_ne_zero.2 hy.ne'), ← ofReal_log hy.le]

theorem perron_finish {N e T L : ℝ} (hT : 0 < T) (hL : 0 < |L|) (he : 0 ≤ e)
    (h1 : N ≤ 2 * π * e) (h2 : N ≤ 2 * e / (T * |L|)) :
    N / (2 * π) ≤ e * min 1 (1 / (π * T * |L|)) := by
  rw [mul_min_of_nonneg _ _ he]
  apply le_min
  · rw [div_le_iff₀ (by positivity)]; linarith
  · calc N / (2 * π) ≤ (2 * e / (T * |L|)) / (2 * π) := by gcongr
      _ = e * (1 / (π * T * |L|)) := by field_simp

theorem perron_switch_bound {c T y : ℝ} (hc : 0 < c) (hT : 0 < T) (hy : 0 < y)
    (hy1 : y ≠ 1) :
    ‖switchIntegral c T y - (perronStep y : ℂ)‖ ≤ y ^ c * min 1 (1 / (π * T * |Real.log y|)) := by
  have h2pi : (2 * π * I : ℂ) ≠ 0 := by simp [Real.pi_ne_zero]
  have hn2pi : ‖(2 * π * I : ℂ)‖ = 2 * π := by simp [abs_of_pos Real.pi_pos]
  rw [Real.rpow_def_of_pos hy, perron_switch_eq hy]
  set L := Real.log y with hLdef
  rw [show L * c = c * L by ring] at *
  rcases lt_or_gt_of_ne hy1 with h | h
  · have hL : L < 0 := Real.log_neg hy h
    have hstep : perronStep y = 0 := by
      simp [perronStep, not_lt.2 h.le, h.ne]
    rw [hstep]
    have heq : 1 / (2 * π * I) * perronS c T L - ((0:ℝ):ℂ) = perronS c T L / (2 * π * I) := by
      rw [ofReal_zero, sub_zero, one_div, div_eq_inv_mul]
    rw [heq, norm_div, hn2pi]
    have habs : |L| = -L := abs_of_neg hL
    apply perron_finish hT (by rw [habs]; linarith) (Real.exp_pos _).le
    · have := perron_S_lt_small hc hT hL
      rw [show L * c = c * L by ring] at this
      nlinarith [Real.two_le_pi, Real.exp_pos (c * L)]
    · have := perron_S_lt_large hc hT hL
      rw [show L * c = c * L by ring] at this
      rwa [habs]
  · have hL : 0 < L := Real.log_pos h
    have hstep : perronStep y = 1 := by simp [perronStep, h]
    rw [hstep]
    have heq : 1 / (2 * π * I) * perronS c T L - ((1:ℝ):ℂ) =
        (perronS c T L - 2 * π * I) / (2 * π * I) := by
      field_simp
      simp
    rw [heq, norm_div, hn2pi]
    have habs : |L| = L := abs_of_pos hL
    apply perron_finish hT (by rw [habs]; linarith) (Real.exp_pos _).le
    · have := perron_S_gt_small hc hT hL
      rwa [show L * c = c * L by ring] at this
    · have := perron_S_gt_large hc hT hL
      rw [show L * c = c * L by ring] at this
      rwa [habs]

theorem perron_switch_one {c T : ℝ} (hc : 0 < c) (hT : 0 < T) :
    switchIntegral c T 1 = (Real.arctan (T / c) / π : ℝ) ∧
      ‖switchIntegral c T 1 - 1 / 2‖ ≤ c / (π * T) := by
  set z0 : ℂ := (c:ℂ) + (T:ℂ) * I with hz0def
  have hS : perronS c T 0 = Complex.log z0 - Complex.log ((c:ℂ) + ((-T:ℝ):ℂ) * I) := by
    have hH : ∀ z ∈ slitPlane, HasDerivAt Complex.log (perronE 0 z) z := by
      intro z hz
      rw [show perronE 0 z = z⁻¹ by simp [perronE]]
      exact hasDerivAt_log hz
    have hF : ContinuousOn (perronE 0) slitPlane :=
      (perronE_continuousOn 0).mono (fun z hz => slitPlane_ne_zero hz)
    exact perron_segment_ftc hH hF (c:ℂ) I (a := -T) (b := T)
      (by intro t _; rw [mem_slitPlane_iff]; left; simp [hc])
  have hzc : (c:ℂ) + ((-T:ℝ):ℂ) * I = (starRingEnd ℂ) z0 := by
    apply Complex.ext <;> simp [hz0def]
  have harg_ne : arg z0 ≠ π := by
    rw [Ne, arg_eq_pi_iff]; intro h; simp [hz0def] at h; linarith [h.1]
  have hlog : Complex.log z0 - Complex.log ((starRingEnd ℂ) z0) = 2 * (arg z0 : ℂ) * I := by
    rw [log_conj z0 harg_ne]
    apply Complex.ext <;> simp [log_re, log_im]
    ring
  have harctan : Real.arctan (T / c) = arg z0 := by
    have htan : Real.tan (arg z0) = T / c := by rw [tan_arg]; simp [hz0def]
    have hlt := abs_arg_lt_pi_div_two_iff.2 (Or.inl (by simp [hz0def]; exact hc) :
      0 < z0.re ∨ z0 = 0)
    rw [← htan, Real.arctan_tan (abs_lt.1 hlt).1 (abs_lt.1 hlt).2]
  have hval : switchIntegral c T 1 = (Real.arctan (T / c) / π : ℝ) := by
    rw [perron_switch_eq one_pos, Real.log_one, hS, hzc, hlog, harctan]
    have : (π : ℂ) ≠ 0 := ofReal_ne_zero.2 Real.pi_ne_zero
    push_cast
    field_simp
  refine ⟨hval, ?_⟩
  rw [hval]
  have hinv : Real.arctan (c / T) = π / 2 - Real.arctan (T / c) := by
    rw [← Real.arctan_inv_of_pos (div_pos hT hc), inv_div]
  have h1 : (((Real.arctan (T / c) / π : ℝ) : ℂ) - 1 / 2) =
      ((-(Real.arctan (c / T) / π) : ℝ) : ℂ) := by
    rw [hinv]; push_cast; field_simp; ring
  rw [h1, norm_real, Real.norm_eq_abs, abs_neg,
    abs_of_nonneg (div_nonneg (Real.arctan_nonneg.2 (div_pos hc hT).le) Real.pi_pos.le)]
  rw [show c / (π * T) = (c / T) / π by field_simp]
  gcongr
  exact Real.arctan_le_self (div_pos hc hT).le

theorem perron_step_zero (a : ℕ → ℂ) {x : ℝ} (hx : 0 < x) (n : ℕ)
    (hn : n ∉ Finset.Icc 1 ⌊x⌋₊) :
    (if n = 0 then 0 else a n * (perronStep (x / n) : ℂ)) = 0 := by
  rcases Nat.eq_zero_or_pos n with h0 | hpos
  · simp [h0]
  · have hn' : ⌊x⌋₊ < n := by
      simp only [Finset.mem_Icc, not_and, not_le] at hn
      exact hn hpos
    have hxn : x < n := (Nat.floor_lt hx.le).1 hn'
    have hnpos : (0:ℝ) < n := by exact_mod_cast hpos
    have hlt : x / n < 1 := (div_lt_one hnpos).2 hxn
    have : perronStep (x / n) = 0 := by
      simp [perronStep, not_lt.2 hlt.le, hlt.ne]
    simp [hpos.ne', this]

theorem perron_running_hasSum (a : ℕ → ℂ) {x : ℝ} (hx : 0 < x) :
    HasSum (fun n : ℕ => if n = 0 then 0 else a n * (perronStep (x / n) : ℂ))
      (runningTotalHalf a x) := by
  have hs : HasSum (fun n : ℕ => if n = 0 then 0 else a n * (perronStep (x / n) : ℂ))
      (∑ n ∈ Finset.Icc 1 ⌊x⌋₊, if n = 0 then 0 else a n * (perronStep (x / n) : ℂ)) :=
    hasSum_sum_of_ne_finset_zero (fun n hn => perron_step_zero a hx n hn)
  convert hs using 1
  unfold runningTotalHalf
  have hterm : ∀ n ∈ Finset.Icc 1 ⌊x⌋₊,
      (if n = 0 then 0 else a n * (perronStep (x / n) : ℂ)) =
      a n - (if (n:ℝ) = x then a n / 2 else 0) := by
    intro n hn
    rw [Finset.mem_Icc] at hn
    have hn0 : n ≠ 0 := by omega
    have hnpos : (0:ℝ) < n := by exact_mod_cast Nat.pos_of_ne_zero hn0
    have hnx : (n:ℝ) ≤ x := (Nat.le_floor_iff hx.le).1 hn.2
    rw [if_neg hn0]
    by_cases he : (n:ℝ) = x
    · have : x / n = 1 := by rw [← he, div_self hnpos.ne']
      rw [if_pos he, this]
      simp [perronStep] <;> ring
    · have hlt : 1 < x / n := (one_lt_div hnpos).2 (lt_of_le_of_ne hnx he)
      rw [if_neg he]; simp [perronStep, hlt]
  rw [Finset.sum_congr rfl hterm, Finset.sum_sub_distrib]
  congr 1
  split_ifs with hfl
  · rw [Finset.sum_eq_single ⌊x⌋₊]
    · rw [if_pos hfl]
    · intro b _ hb
      rw [if_neg]
      intro hbx
      apply hb
      rw [← hfl] at hbx
      exact_mod_cast hbx
    · intro hnot
      exfalso; apply hnot
      rw [Finset.mem_Icc]
      refine ⟨?_, le_refl _⟩
      by_contra h0
      push_neg at h0
      have h00 : ⌊x⌋₊ = 0 := by omega
      rw [h00] at hfl; simp at hfl; linarith
  · symm
    apply Finset.sum_eq_zero
    intro n _
    rw [if_neg]
    intro hnx
    apply hfl
    rw [← hnx, Nat.floor_natCast]

theorem perron_line_continuous (L c : ℝ) (hc : 0 < c) :
    Continuous fun t : ℝ => perronE L ((c:ℂ) + (t:ℂ) * I) * I := by
  apply Continuous.mul _ continuous_const
  apply (perronE_continuousOn L).comp_continuous (by fun_prop)
  intro t
  show _ ≠ 0
  intro h
  have := congrArg Complex.re h
  simp at this; linarith

theorem perron_cut_hasSum (a : ℕ → ℂ) {c T x : ℝ} (hc : 0 < c) (hT : 0 < T)
    (hx : 0 < x) (habs : Summable fun n : ℕ => ‖LSeries.term a c n‖) :
    HasSum (fun n : ℕ => if n = 0 then 0 else a n * switchIntegral c T (x / n))
      (perronCut a c T x) := by
  set μ := MeasureTheory.volume.restrict (Set.Ioc (-T) T) with hμ
  set F : ℕ → ℝ → ℂ := fun n t =>
    if n = 0 then 0 else a n * (perronE (Real.log (x / n)) ((c:ℂ) + (t:ℂ) * I) * I) with hF
  have hpt : ∀ t : ℝ, LSeries a ((c:ℂ) + (t:ℂ) * I) * (x:ℂ) ^ ((c:ℂ) + (t:ℂ) * I) /
      ((c:ℂ) + (t:ℂ) * I) * I = ∑' n, F n t := by
    intro t
    set s : ℂ := (c:ℂ) + (t:ℂ) * I
    have hterm : ∀ n, LSeries.term a s n * ((x:ℂ) ^ s / s * I) = F n t := by
      intro n
      rcases eq_or_ne n 0 with h0 | h0
      · simp [hF, h0]
      · have hnpos : (0:ℝ) < n := by exact_mod_cast Nat.pos_of_ne_zero h0
        simp only [hF, if_neg h0, LSeries.term_of_ne_zero h0, perronE]
        rw [show ((n:ℂ)) = ((n:ℝ):ℂ) by push_cast; rfl]
        rw [cpow_def_of_ne_zero (ofReal_ne_zero.2 hnpos.ne'),
          cpow_def_of_ne_zero (ofReal_ne_zero.2 hx.ne'), ← ofReal_log hnpos.le,
          ← ofReal_log hx.le, Real.log_div hx.ne' hnpos.ne']
        push_cast
        rw [sub_mul, Complex.exp_sub]
        ring
    rw [show LSeries a s * (x:ℂ) ^ s / s * I = LSeries a s * ((x:ℂ) ^ s / s * I) by ring]
    unfold LSeries
    rw [← tsum_mul_right]
    exact tsum_congr hterm
  have hle : -T ≤ T := by linarith
  have hcont : ∀ n, Continuous (F n) := by
    intro n
    rcases eq_or_ne n 0 with h0 | h0
    · simp only [hF, h0, if_true]; exact continuous_const
    · simp only [hF, if_neg h0]
      exact continuous_const.mul (perron_line_continuous _ c hc)
  have hint : ∀ n, MeasureTheory.Integrable (F n) μ := fun n => (hcont n).integrableOn_Ioc
  have hbound : ∀ n t, ‖F n t‖ ≤ x ^ c / c * ‖LSeries.term a c n‖ := by
    intro n t
    rcases eq_or_ne n 0 with h0 | h0
    · simp [hF, h0]
    · have hnpos : (0:ℝ) < n := by exact_mod_cast Nat.pos_of_ne_zero h0
      simp only [hF, if_neg h0]
      have hre : ((c:ℂ) + (t:ℂ) * I).re = c := by simp
      rw [norm_mul, norm_mul, norm_I, mul_one, perronE_norm, LSeries.norm_term_eq, if_neg h0,
        ofReal_re, hre]
      have hnorm : c ≤ ‖(c:ℂ) + (t:ℂ) * I‖ := by
        have := abs_re_le_norm ((c:ℂ) + (t:ℂ) * I)
        rwa [hre, abs_of_pos hc] at this
      rw [← Real.rpow_def_of_pos (div_pos hx hnpos), Real.div_rpow hx.le hnpos.le]
      have hxc : 0 < x ^ c := Real.rpow_pos_of_pos hx c
      have hnc : 0 < (n:ℝ) ^ c := Real.rpow_pos_of_pos hnpos c
      calc ‖a n‖ * (x ^ c / (n:ℝ) ^ c / ‖(c:ℂ) + (t:ℂ) * I‖)
          ≤ ‖a n‖ * (x ^ c / (n:ℝ) ^ c / c) := by gcongr
        _ = x ^ c / c * (‖a n‖ / (n:ℝ) ^ c) := by ring
  have hsum : Summable fun n => ∫ t, ‖F n t‖ ∂μ := by
    refine Summable.of_nonneg_of_le
      (fun n => MeasureTheory.integral_nonneg (fun t => norm_nonneg _)) (fun n => ?_)
      ((habs.mul_left (x ^ c / c)).mul_right (μ.real Set.univ))
    have := MeasureTheory.norm_integral_le_of_norm_le_const (μ := μ) (f := fun t => ‖F n t‖)
      (C := x ^ c / c * ‖LSeries.term a c n‖) (Filter.Eventually.of_forall (fun t => by
        rw [norm_norm]; exact hbound n t))
    exact (Real.le_norm_self _).trans this
  have hHS := MeasureTheory.hasSum_integral_of_summable_integral_norm hint hsum
  have hval : ∀ n, ∫ t, F n t ∂μ =
      if n = 0 then 0 else a n * perronS c T (Real.log (x / n)) := by
    intro n
    rcases eq_or_ne n 0 with h0 | h0
    · simp [hF, h0]
    · simp only [hF, if_neg h0]
      rw [MeasureTheory.integral_const_mul, perronS, intervalIntegral.integral_of_le hle]
  have hcut : perronCut a c T x = 1 / (2 * π * I) * ∫ t, (∑' n, F n t) ∂μ := by
    unfold perronCut
    rw [intervalIntegral.integral_of_le hle]
    congr 1
    apply MeasureTheory.integral_congr_ae
    exact Filter.Eventually.of_forall (fun t => hpt t)
  rw [hcut]
  have := hHS.mul_left (1 / (2 * π * I))
  convert this using 1
  funext n
  rw [hval n]
  rcases eq_or_ne n 0 with h0 | h0
  · simp [h0]
  · have hnpos : (0:ℝ) < n := by exact_mod_cast Nat.pos_of_ne_zero h0
    rw [if_neg h0, if_neg h0, perron_switch_eq (div_pos hx hnpos)]
    ring

theorem perron_main (a : ℕ → ℂ) {c T x : ℝ} (hc : 0 < c) (hT : 0 < T)
    (hx : 0 < x) (habs : Summable fun n : ℕ => ‖LSeries.term a c n‖) :
    ‖runningTotalHalf a x - perronCut a c T x‖ ≤ perronErrorBound a c T x := by
  have hB := perron_running_hasSum a hx
  have hP := perron_cut_hasSum a hc hT hx habs
  set bnd : ℕ → ℝ := fun n => if n = 0 then 0
    else if (n : ℝ) = x then c * ‖a n‖ / (π * T)
    else ‖a n‖ * (x / n) ^ c * min 1 (1 / (π * T * |Real.log (x / n)|)) with hbnd
  set K := x ^ c * (1 + c / (π * T)) with hK
  have hxc : 0 < x ^ c := Real.rpow_pos_of_pos hx c
  have hbnd_le : ∀ n, bnd n ≤ K * ‖LSeries.term a c n‖ := by
    intro n
    rcases eq_or_ne n 0 with h0 | h0
    · simp [hbnd, h0]
    · have hnpos : (0:ℝ) < n := by exact_mod_cast Nat.pos_of_ne_zero h0
      rw [LSeries.norm_term_eq, if_neg h0, ofReal_re]
      simp only [hbnd, if_neg h0]
      have hnc : 0 < (n:ℝ) ^ c := Real.rpow_pos_of_pos hnpos c
      have hcpt : 0 ≤ c / (π * T) := by positivity
      have hK1 : x ^ c ≤ K := by rw [hK]; nlinarith
      split_ifs with he
      · rw [he]
        have : K * (‖a n‖ / x ^ c) = ‖a n‖ + c * ‖a n‖ / (π * T) := by
          rw [hK]; field_simp
        rw [this]; linarith [norm_nonneg (a n)]
      · calc ‖a n‖ * (x / n) ^ c * min 1 (1 / (π * T * |Real.log (x / n)|))
            ≤ ‖a n‖ * (x / n) ^ c * 1 := by gcongr; exact min_le_left _ _
          _ = x ^ c * (‖a n‖ / (n:ℝ) ^ c) := by rw [Real.div_rpow hx.le hnpos.le]; ring
          _ ≤ K * (‖a n‖ / (n:ℝ) ^ c) := by gcongr
  have hbnd_nonneg : ∀ n, 0 ≤ bnd n := by
    intro n; simp only [hbnd]; split_ifs <;> positivity
  have hbsum : Summable bnd := Summable.of_nonneg_of_le hbnd_nonneg hbnd_le (habs.mul_left K)
  have hpt : ∀ n, ‖(if n = 0 then 0 else a n * (perronStep (x / n) : ℂ)) -
      (if n = 0 then 0 else a n * switchIntegral c T (x / n))‖ ≤ bnd n := by
    intro n
    rcases eq_or_ne n 0 with h0 | h0
    · simp [hbnd, h0]
    · have hnpos : (0:ℝ) < n := by exact_mod_cast Nat.pos_of_ne_zero h0
      simp only [hbnd, if_neg h0]
      rw [← mul_sub, norm_mul, norm_sub_rev]
      split_ifs with he
      · have h1 : x / n = 1 := by rw [← he, div_self hnpos.ne']
        rw [h1]
        have h3 := (perron_switch_one hc hT).2
        have hs1 : ((perronStep 1 : ℝ) : ℂ) = 1 / 2 := by simp [perronStep]
        rw [hs1]
        calc ‖a n‖ * ‖switchIntegral c T 1 - 1 / 2‖ ≤ ‖a n‖ * (c / (π * T)) := by gcongr
          _ = c * ‖a n‖ / (π * T) := by ring
      · have hne : x / n ≠ 1 := by
          intro h; exact he ((div_eq_one_iff_eq hnpos.ne').1 h).symm
        have h3 := perron_switch_bound hc hT (div_pos hx hnpos) hne
        calc ‖a n‖ * ‖switchIntegral c T (x / n) - (perronStep (x / n) : ℂ)‖
            ≤ ‖a n‖ * ((x / n) ^ c * min 1 (1 / (π * T * |Real.log (x / n)|))) := by gcongr
          _ = _ := by ring
  exact (hB.sub hP).norm_le_of_bounded hbsum.hasSum hpt

/-- Perron's formula with its truncation bound. If the Dirichlet series Σ a(n) n^(−s) converges
absolutely on the line Re s = c, with c > 0, then for every x > 0 and every height T > 0 the
running total A₀(x) (last term halved when x is a whole number) differs from the line integral
of the series times x^s/s, cut at height T and divided by 2πi, by at most
Σ_{n ≠ x} |a(n)| (x/n)^c min(1, 1/(πT |log(x/n)|)) + c |a(x)|/(πT). -/
theorem perron_formula_truncation_bound (a : ℕ → ℂ) {c T x : ℝ} (hc : 0 < c) (hT : 0 < T)
    (hx : 0 < x) (habs : Summable fun n : ℕ => ‖LSeries.term a c n‖) :
    ‖runningTotalHalf a x - perronCut a c T x‖ ≤ perronErrorBound a c T x := by
  exact perron_main a hc hT hx habs

/-- The switch, away from the jump: for c > 0, T > 0 and y > 0 with y ≠ 1, the cut integral of
y^s/s up the line Re s = c misses the perfect switch (1 for y > 1, 0 for y < 1) by at most
y^c min(1, 1/(πT |log y|)). -/
theorem switch_integral_error_bound {c T y : ℝ} (hc : 0 < c) (hT : 0 < T) (hy : 0 < y)
    (hy1 : y ≠ 1) :
    ‖switchIntegral c T y - (perronStep y : ℂ)‖ ≤ y ^ c * min 1 (1 / (π * T * |Real.log y|)) := by
  exact perron_switch_bound hc hT hy hy1

/-- The switch at the jump y = 1: the cut integral of 1/s up the line Re s = c equals
arctan(T/c)/π, and so misses the midpoint 1/2 by at most c/(πT). -/
theorem switch_integral_at_one {c T : ℝ} (hc : 0 < c) (hT : 0 < T) :
    switchIntegral c T 1 = (Real.arctan (T / c) / π : ℝ) ∧
      ‖switchIntegral c T 1 - 1 / 2‖ ≤ c / (π * T) := by
  exact perron_switch_one hc hT

/-- The 25 primes up to 100 that make θ(100). -/
example : ((Finset.range 101).filter Nat.Prime).card = 25 := by decide

/-- The prime powers p^k with k ≥ 2 up to 100: 2^2 … 2^6 (five), 3^2 … 3^4 (three), 5^2 and 7^2,
and none for 11 or larger, giving 5 log 2 + 3 log 3 + log 5 + log 7. -/
example : 2 ^ 6 ≤ 100 ∧ 100 < 2 ^ 7 ∧ 3 ^ 4 ≤ 100 ∧ 100 < 3 ^ 5 ∧ 5 ^ 2 ≤ 100 ∧ 100 < 5 ^ 3 ∧
    7 ^ 2 ≤ 100 ∧ 100 < 7 ^ 3 ∧ 100 < 11 ^ 2 := by norm_num

/-- The two terms that carry most of the bound at x = 100.5: 97 and 101 are prime. -/
example : Nat.Prime 97 ∧ Nat.Prime 101 := by norm_num

#print axioms perron_formula_truncation_bound
#print axioms switch_integral_error_bound
#print axioms switch_integral_at_one
#print axioms perron_path_ftc
#print axioms perron_hasDerivAt_line
#print axioms perron_segment_ftc
#print axioms perronE_continuousOn
#print axioms perron_entire_part
#print axioms perron_prims
#print axioms perron_log_identity
#print axioms perronE_norm
#print axioms perron_horiz_norm
#print axioms perron_vert_norm
#print axioms perron_exp_integral
#print axioms perron_horiz_int
#print axioms perron_limit
#print axioms perron_S_right
#print axioms perron_S_lt_small
#print axioms perron_S_lt_large
#print axioms perron_S_left
#print axioms perron_S_gt_large
#print axioms perron_S_gt_small
#print axioms perron_switch_eq
#print axioms perron_finish
#print axioms perron_switch_bound
#print axioms perron_switch_one
#print axioms perron_step_zero
#print axioms perron_running_hasSum
#print axioms perron_line_continuous
#print axioms perron_cut_hasSum
#print axioms perron_main
