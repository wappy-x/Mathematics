-- Strichartz estimates: the free Schrödinger kernel gives the dispersive bound, the free bell's space-time 6-norm is exactly 12^(-1/12) times its L² size, and Glassey's virial argument sets a deadline for blow-up.
import Mathlib.Analysis.SpecialFunctions.Gaussian.GaussianIntegral
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.Calculus.Deriv.Basic

open Real MeasureTheory

lemma free_bell_norm_six (t x : ℝ) :
    ‖(1 + 4 * Complex.I * (t : ℂ)) ^ (-(1 / 2 : ℂ)) *
        Complex.exp (-(x : ℂ) ^ 2 / (1 + 4 * Complex.I * (t : ℂ)))‖ ^ 6 =
      ((1 + 16 * t ^ 2) * √(1 + 16 * t ^ 2))⁻¹ * Real.exp (-(6 / (1 + 16 * t ^ 2)) * x ^ 2) := by
  set s : ℝ := 1 + 16 * t ^ 2 with hs
  have hs0 : 0 < s := by positivity
  have hz : (1 + 4 * Complex.I * (t : ℂ)) = ((1 : ℝ) : ℂ) + ((4 * t : ℝ) : ℂ) * Complex.I := by
    push_cast; ring
  have hnz : ‖(1 + 4 * Complex.I * (t : ℂ))‖ = √s := by
    rw [hz, Complex.norm_add_mul_I, hs]; ring_nf
  have h12 : (-(1 / 2 : ℂ)) = ((-(1 / 2) : ℝ) : ℂ) := by push_cast; ring
  have hre : (-(x : ℂ) ^ 2 / (1 + 4 * Complex.I * (t : ℂ))).re = -x ^ 2 / s := by
    rw [Complex.div_re, Complex.normSq_apply]
    simp [hs, ← Complex.ofReal_pow]
    ring
  rw [norm_mul, h12, Complex.norm_cpow_real, hnz, Complex.norm_exp, hre, mul_pow,
    ← Real.rpow_natCast (√s ^ _), ← Real.rpow_mul (Real.sqrt_nonneg _)]
  have hsq : 0 < √s := Real.sqrt_pos.mpr hs0
  have h3 : √s ^ ((-(1 / 2) : ℝ) * ((6 : ℕ) : ℝ)) = (s * √s)⁻¹ := by
    have : ((-(1 / 2) : ℝ) * ((6 : ℕ) : ℝ)) = -((3 : ℕ) : ℝ) := by norm_num
    rw [this, Real.rpow_neg hsq.le, Real.rpow_natCast]
    congr 1
    rw [pow_succ, Real.sq_sqrt hs0.le]
  rw [h3, ← Real.exp_nat_mul]
  congr 2
  push_cast
  field_simp

#print axioms free_bell_norm_six

lemma free_bell_integral :
    (∫ t : ℝ, ∫ x : ℝ, ‖(1 + 4 * Complex.I * (t : ℂ)) ^ (-(1 / 2 : ℂ)) *
        Complex.exp (-(x : ℂ) ^ 2 / (1 + 4 * Complex.I * (t : ℂ)))‖ ^ 6) =
        π ^ (3 / 2 : ℝ) / (4 * √6) := by
  have hin : ∀ t : ℝ, (∫ x : ℝ, ‖(1 + 4 * Complex.I * (t : ℂ)) ^ (-(1 / 2 : ℂ)) *
        Complex.exp (-(x : ℂ) ^ 2 / (1 + 4 * Complex.I * (t : ℂ)))‖ ^ 6) =
        √(π / 6) * (1 + (4 * t) ^ 2)⁻¹ := by
    intro t
    simp_rw [free_bell_norm_six]
    rw [integral_const_mul, integral_gaussian]
    have hs0 : 0 < 1 + 16 * t ^ 2 := by positivity
    have hsq : 0 < √(1 + 16 * t ^ 2) := Real.sqrt_pos.mpr hs0
    have : π / (6 / (1 + 16 * t ^ 2)) = (π / 6) * (1 + 16 * t ^ 2) := by field_simp
    rw [this, Real.sqrt_mul (by positivity)]
    have h4 : (1 + (4 * t) ^ 2) = 1 + 16 * t ^ 2 := by ring
    rw [h4]
    field_simp
  simp_rw [hin]
  rw [integral_const_mul, Measure.integral_comp_mul_left (fun y : ℝ => (1 + y ^ 2)⁻¹) 4,
    integral_univ_inv_one_add_sq]
  have hp : π ^ (3 / 2 : ℝ) = π * √π := by
    rw [show (3 / 2 : ℝ) = 1 + 1 / 2 by norm_num, Real.rpow_add pi_pos, Real.rpow_one,
      Real.sqrt_eq_rpow]
  rw [hp, Real.sqrt_div pi_pos.le]
  have h6 : 0 < √(6 : ℝ) := by positivity
  norm_num
  field_simp

#print axioms free_bell_integral

lemma gauss_l2_sq : (∫ x : ℝ, ‖Complex.exp (-(x : ℂ) ^ 2)‖ ^ 2) = √(π / 2) := by
  have : ∀ x : ℝ, ‖Complex.exp (-(x : ℂ) ^ 2)‖ ^ 2 = Real.exp (-2 * x ^ 2) := by
    intro x
    rw [Complex.norm_exp, ← Complex.ofReal_pow, ← Complex.ofReal_neg, Complex.ofReal_re, sq,
      ← Real.exp_add]
    ring_nf
  simp_rw [this]
  exact integral_gaussian 2

#print axioms gauss_l2_sq

/-- The dispersive bound on the line: for every time `t ≠ 0` and every starting wave `f` with
finite 1-norm, the free Schrödinger flow, written as the kernel `e^{i(x-y)²/(4t)} / (4πit)^{1/2}`
integrated against `f`, is at every place `x` no higher than `(4π|t|)^{-1/2}` times `∫|f|`. -/
theorem dispersive_bound (t : ℝ) (ht : t ≠ 0) (f : ℝ → ℂ) (hf : Integrable f) (x : ℝ) :
    ‖∫ y : ℝ, Complex.exp (Complex.I * (((x - y) ^ 2 / (4 * t) : ℝ) : ℂ)) /
        (4 * (π : ℂ) * Complex.I * (t : ℂ)) ^ (1 / 2 : ℂ) * f y‖ ≤
      (4 * π * |t|) ^ (-(1 / 2 : ℝ)) * ∫ y : ℝ, ‖f y‖ := by
  have hk : ∀ y : ℝ, ‖Complex.exp (Complex.I * (((x - y) ^ 2 / (4 * t) : ℝ) : ℂ)) /
        (4 * (π : ℂ) * Complex.I * (t : ℂ)) ^ (1 / 2 : ℂ) * f y‖ =
        (4 * π * |t|) ^ (-(1 / 2 : ℝ)) * ‖f y‖ := by
    intro y
    have h12 : (1 / 2 : ℂ) = ((1 / 2 : ℝ) : ℂ) := by push_cast; ring
    rw [norm_mul, norm_div, Complex.norm_exp_I_mul_ofReal, h12, Complex.norm_cpow_real]
    have : ‖4 * (π : ℂ) * Complex.I * (t : ℂ)‖ = 4 * π * |t| := by
      simp [Complex.norm_real, abs_of_pos pi_pos]
    rw [this, Real.rpow_neg (by positivity), one_div]
  calc _ ≤ ∫ y : ℝ, ‖Complex.exp (Complex.I * (((x - y) ^ 2 / (4 * t) : ℝ) : ℂ)) /
        (4 * (π : ℂ) * Complex.I * (t : ℂ)) ^ (1 / 2 : ℂ) * f y‖ := norm_integral_le_integral_norm _
    _ = _ := by simp_rw [hk]; exact integral_const_mul _ _

/-- The free bell `u(t, x) = (1 + 4it)^{-1/2} e^{-x²/(1 + 4it)}`, the free wave from `e^{-x²}`:
its space-time integral `∫∫|u|⁶ dx dt` over all time is `π^{3/2}/(4√6)`, and its sixth root is
exactly `12^{-1/12}` times the starting L² size `(∫|u(0, x)|² dx)^{1/2}`. -/
theorem free_bell_strichartz_ratio :
    (∫ t : ℝ, ∫ x : ℝ, ‖(1 + 4 * Complex.I * (t : ℂ)) ^ (-(1 / 2 : ℂ)) *
        Complex.exp (-(x : ℂ) ^ 2 / (1 + 4 * Complex.I * (t : ℂ)))‖ ^ 6) =
        π ^ (3 / 2 : ℝ) / (4 * √6) ∧
      (∫ t : ℝ, ∫ x : ℝ, ‖(1 + 4 * Complex.I * (t : ℂ)) ^ (-(1 / 2 : ℂ)) *
        Complex.exp (-(x : ℂ) ^ 2 / (1 + 4 * Complex.I * (t : ℂ)))‖ ^ 6) ^ (1 / 6 : ℝ) /
        (∫ x : ℝ, ‖Complex.exp (-(x : ℂ) ^ 2)‖ ^ 2) ^ (1 / 2 : ℝ) =
        (12 : ℝ) ^ (-(1 / 12 : ℝ)) := by
  refine ⟨free_bell_integral, ?_⟩
  rw [free_bell_integral, gauss_l2_sq]
  set A : ℝ := π ^ (3 / 2 : ℝ) / (4 * √6) with hA
  set B : ℝ := √(π / 2) with hB
  have hA0 : 0 < A := by positivity
  have hB0 : 0 < B := by positivity
  have hL0 : 0 ≤ A ^ (1 / 6 : ℝ) / B ^ (1 / 2 : ℝ) := by positivity
  have hA2 : A ^ 2 = π ^ 3 / 96 := by
    have hp : π ^ (3 / 2 : ℝ) = π * √π := by
      rw [show (3 / 2 : ℝ) = 1 + 1 / 2 by norm_num, Real.rpow_add pi_pos, Real.rpow_one,
        Real.sqrt_eq_rpow]
    rw [hA, hp, div_pow, mul_pow, mul_pow, Real.sq_sqrt pi_pos.le,
      Real.sq_sqrt (by norm_num : (0:ℝ) ≤ 6)]
    ring
  have hB6 : B ^ 6 = π ^ 3 / 8 := by
    have : B ^ 6 = (B ^ 2) ^ 3 := by ring
    rw [this, hB, Real.sq_sqrt (by positivity)]
    ring
  have h12 : (A ^ (1 / 6 : ℝ) / B ^ (1 / 2 : ℝ)) ^ (12 : ℕ) = 1 / 12 := by
    rw [div_pow, ← Real.rpow_natCast (A ^ (1 / 6 : ℝ)), ← Real.rpow_mul hA0.le,
      ← Real.rpow_natCast (B ^ (1 / 2 : ℝ)), ← Real.rpow_mul hB0.le]
    have e1 : (1 / 6 : ℝ) * ((12 : ℕ) : ℝ) = ((2 : ℕ) : ℝ) := by norm_num
    have e2 : (1 / 2 : ℝ) * ((12 : ℕ) : ℝ) = ((6 : ℕ) : ℝ) := by norm_num
    rw [e1, e2, Real.rpow_natCast, Real.rpow_natCast, hA2, hB6]
    have := pi_pos
    field_simp
    norm_num
  calc A ^ (1 / 6 : ℝ) / B ^ (1 / 2 : ℝ)
      = ((A ^ (1 / 6 : ℝ) / B ^ (1 / 2 : ℝ)) ^ (12 : ℕ)) ^ ((12 : ℕ)⁻¹ : ℝ) :=
        (Real.pow_rpow_inv_natCast hL0 (by norm_num)).symm
    _ = (12 : ℝ) ^ (-(1 / 12 : ℝ)) := by
        rw [h12, Real.rpow_neg (by norm_num), one_div, Real.inv_rpow (by norm_num)]
        norm_num

/-- Glassey's argument: if the spread `V(t)` has `V'' ≤ 16E` with negative energy `E < 0`
(focusing, `σd ≥ 2`), and `V'(0) = 0` (a real start), then `V` cannot stay positive on a time
span `[0, T]` that reaches the deadline `T* = √(V(0)/(8|E|))`: the wave blows up before `T*`. -/
theorem glassey_blowup_before_deadline (V V' V'' : ℝ → ℝ) (E T : ℝ) (hE : E < 0) (hT : 0 ≤ T)
    (hV : ∀ t ∈ Set.Icc 0 T, HasDerivAt V (V' t) t)
    (hV' : ∀ t ∈ Set.Icc 0 T, HasDerivAt V' (V'' t) t)
    (hV''_le : ∀ t ∈ Set.Icc 0 T, V'' t ≤ 16 * E)
    (hV'0 : V' 0 = 0) (hpos : ∀ t ∈ Set.Icc 0 T, 0 < V t) :
    T < √(V 0 / (8 * |E|)) := by
  have hD : Convex ℝ (Set.Icc (0:ℝ) T) := convex_Icc 0 T
  have h1 : AntitoneOn (fun t => V' t - 16 * E * t) (Set.Icc 0 T) := by
    have hd : ∀ t ∈ Set.Icc 0 T, HasDerivAt (fun t => V' t - 16 * E * t) (V'' t - 16 * E) t := by
      intro t ht
      have := (hV' t ht).sub ((hasDerivAt_id' t).const_mul (16 * E))
      convert this using 1
      ring
    refine antitoneOn_of_hasDerivWithinAt_nonpos hD
      (fun t ht => (hd t ht).continuousAt.continuousWithinAt)
      (fun t ht => (hd t (interior_subset ht)).hasDerivWithinAt)
      (fun t ht => by linarith [hV''_le t (interior_subset ht)])
  have h0 : (0:ℝ) ∈ Set.Icc 0 T := ⟨le_rfl, hT⟩
  have hV'le : ∀ t ∈ Set.Icc 0 T, V' t - 16 * E * t ≤ 0 := by
    intro t ht
    have := h1 h0 ht ht.1
    simp only [hV'0, mul_zero, sub_zero] at this
    exact this
  have h2 : AntitoneOn (fun t => V t - 8 * E * t ^ 2) (Set.Icc 0 T) := by
    have hd : ∀ t ∈ Set.Icc 0 T, HasDerivAt (fun t => V t - 8 * E * t ^ 2) (V' t - 16 * E * t) t := by
      intro t ht
      have := (hV t ht).sub ((hasDerivAt_pow 2 t).const_mul (8 * E))
      convert this using 1
      push_cast; ring
    refine antitoneOn_of_hasDerivWithinAt_nonpos hD
      (fun t ht => (hd t ht).continuousAt.continuousWithinAt)
      (fun t ht => (hd t (interior_subset ht)).hasDerivWithinAt)
      (fun t ht => hV'le t (interior_subset ht))
  have hTm : T ∈ Set.Icc 0 T := ⟨hT, le_rfl⟩
  have h3 := h2 h0 hTm hT
  simp only at h3
  have hVT := hpos T hTm
  have habs : |E| = -E := abs_of_neg hE
  have hlt : T ^ 2 < V 0 / (8 * |E|) := by
    rw [lt_div_iff₀ (by rw [habs]; linarith), habs]
    nlinarith
  calc T = √(T ^ 2) := (Real.sqrt_sq hT).symm
    _ < _ := Real.sqrt_lt_sqrt (sq_nonneg T) hlt

-- Admissible pairs on the line, 2/q + 1/r = 1/2: (6, 6) and (8, 4) are on the line, (4, 4) is not.
example : (2 : ℚ) / 6 + 1 / 6 = 1 / 2 := by norm_num
example : (2 : ℚ) / 8 + 1 / 4 = 1 / 2 := by norm_num
example : (2 : ℚ) / 4 + 1 / 4 ≠ 1 / 2 := by norm_num
-- The contraction constants: Lipschitz factor 10 K (2η)⁴ = 160 K η⁴, ball kept when 32 K η⁴ ≤ 1.
example : 10 * 2 ^ 4 = 160 ∧ 2 ^ 5 = 32 := by decide
-- The quintic bell's energy is negative once A⁸ > 27; amplitude 2 qualifies, 3/2 does not.
example : (27 : ℕ) < 2 ^ 8 := by decide
example : ((3 : ℚ) / 2) ^ 8 < 27 := by norm_num

#print axioms dispersive_bound
#print axioms free_bell_strichartz_ratio
#print axioms glassey_blowup_before_deadline
