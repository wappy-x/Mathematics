-- How big must n be: the exact facts behind the Berry-Esseen bound and the Edgeworth term for a six-or-not count, namely one roll's mean, variance, third moments and skewness, the bell height's second and third derivatives that shape the Edgeworth term, and the whole-number threshold n = 339 at which the bound 0.4748 ρ/(σ³√n) for sixes first drops to one twentieth.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.Analysis.Calculus.IteratedDeriv.Lemmas
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum

open MeasureTheory ProbabilityTheory Finset
open scoped Real NNReal

theorem two_point_integral (p : ℝ) (hp0 : 0 < p) (hp1 : p < 1) (f : ℝ → ℝ) :
    ∫ x, f x ∂(ENNReal.ofReal p • Measure.dirac (1:ℝ) + ENNReal.ofReal (1 - p) • Measure.dirac (0:ℝ))
      = p * f 1 + (1 - p) * f 0 := by
  have h1 : Integrable f (ENNReal.ofReal p • Measure.dirac (1:ℝ)) :=
    (integrable_dirac (by simp)).smul_measure ENNReal.ofReal_ne_top
  have h0 : Integrable f (ENNReal.ofReal (1 - p) • Measure.dirac (0:ℝ)) :=
    (integrable_dirac (by simp)).smul_measure ENNReal.ofReal_ne_top
  rw [integral_add_measure h1 h0, integral_smul_measure, integral_smul_measure,
    integral_dirac, integral_dirac, ENNReal.toReal_ofReal hp0.le,
    ENNReal.toReal_ofReal (by linarith), smul_eq_mul, smul_eq_mul]

#print axioms two_point_integral

theorem bell_hasDerivAt (x : ℝ) :
    HasDerivAt (gaussianPDFReal 0 1) (-x * gaussianPDFReal 0 1 x) x := by
  have h : HasDerivAt (fun y : ℝ => -(y - 0) ^ 2 / (2 * ((1 : ℝ≥0) : ℝ))) (-x) x := by
    have := (((hasDerivAt_id' x).sub_const (0:ℝ)).pow 2).neg.div_const (2 * ((1 : ℝ≥0) : ℝ))
    convert this using 1
    simp only [NNReal.coe_one]; ring
  have := (h.exp).const_mul (√(2 * π * ((1 : ℝ≥0) : ℝ)))⁻¹
  rw [gaussianPDFReal_def]
  convert this using 1
  ring

#print axioms bell_hasDerivAt


/-- **One roll's numbers for the bound and the term.** A roll's count `X` is 1 with chance `p`
and 0 otherwise, for a chance `p` strictly between 0 and 1 (for a six, `p = 1/6`). Its law is
`p • δ₁ + (1 - p) • δ₀`. Then its mean is `μ = p`, its variance is `σ² = p(1 - p)`, its third
absolute central moment is `ρ = E|X - μ|³ = p(1 - p)(p² + (1 - p)²)`, and its third central
moment is `E(X - μ)³ = p(1 - p)(1 - 2p)`. So the Berry-Esseen ratio is
`ρ/σ³ = (p² + (1 - p)²)/√(p(1 - p))` and the skewness is `γ = (1 - 2p)/√(p(1 - p))`. -/
theorem six_count_moments_and_ratio (p : ℝ) (hp0 : 0 < p) (hp1 : p < 1) :
    let law : Measure ℝ :=
      ENNReal.ofReal p • Measure.dirac 1 + ENNReal.ofReal (1 - p) • Measure.dirac 0
    let σ : ℝ := √(∫ x, (x - p) ^ 2 ∂law)
    (∫ x, x ∂law = p) ∧
    (∫ x, (x - p) ^ 2 ∂law = p * (1 - p)) ∧
    (∫ x, |x - p| ^ 3 ∂law = p * (1 - p) * (p ^ 2 + (1 - p) ^ 2)) ∧
    (∫ x, (x - p) ^ 3 ∂law = p * (1 - p) * (1 - 2 * p)) ∧
    ((∫ x, |x - p| ^ 3 ∂law) / σ ^ 3 = (p ^ 2 + (1 - p) ^ 2) / √(p * (1 - p))) ∧
    ((∫ x, (x - p) ^ 3 ∂law) / σ ^ 3 = (1 - 2 * p) / √(p * (1 - p))) := by
  intro law σ
  have hq : 0 < 1 - p := by linarith
  have hI := two_point_integral p hp0 hp1
  have e1 : ∫ x, x ∂law = p := by rw [hI]; ring
  have e2 : ∫ x, (x - p) ^ 2 ∂law = p * (1 - p) := by rw [hI]; ring
  have e3 : ∫ x, |x - p| ^ 3 ∂law = p * (1 - p) * (p ^ 2 + (1 - p) ^ 2) := by
    rw [hI, abs_of_pos (by linarith : (0:ℝ) < 1 - p), abs_of_neg (by linarith : (0:ℝ) - p < 0)]
    ring
  have e4 : ∫ x, (x - p) ^ 3 ∂law = p * (1 - p) * (1 - 2 * p) := by rw [hI]; ring
  have hv : 0 < p * (1 - p) := mul_pos hp0 hq
  have hs : 0 < √(p * (1 - p)) := Real.sqrt_pos.mpr hv
  have hσ : σ ^ 3 = p * (1 - p) * √(p * (1 - p)) := by
    show (√(∫ x, (x - p) ^ 2 ∂law)) ^ 3 = _
    rw [e2, pow_succ, pow_two, Real.mul_self_sqrt hv.le]
  refine ⟨e1, e2, e3, e4, ?_, ?_⟩
  · rw [e3, hσ]; field_simp
  · rw [e4, hσ]; field_simp

/-- **The shape of the Edgeworth term.** Write `Φ'(z) = e^(-z²/2)/√(2π)` for the bell's
height. Differentiating it twice gives `(Φ')''(z) = (z² - 1) Φ'(z)`, the factor in the
Edgeworth term `-γ (z² - 1) Φ'(z)/(6√n)`, and differentiating once more gives
`(Φ')'''(z) = -(z³ - 3z) Φ'(z)`, the corrected density's extra piece. -/
theorem bell_height_derivatives (z : ℝ) :
    iteratedDeriv 2 (gaussianPDFReal 0 1) z = (z ^ 2 - 1) * gaussianPDFReal 0 1 z ∧
    iteratedDeriv 3 (gaussianPDFReal 0 1) z = -(z ^ 3 - 3 * z) * gaussianPDFReal 0 1 z := by
  have d1 : deriv (gaussianPDFReal 0 1) = fun x => -x * gaussianPDFReal 0 1 x := funext fun x => (bell_hasDerivAt x).deriv
  have h2 : ∀ x, HasDerivAt (fun y => -y * gaussianPDFReal 0 1 y) ((x ^ 2 - 1) * gaussianPDFReal 0 1 x) x := by
    intro x
    have := (hasDerivAt_neg x).mul (bell_hasDerivAt x)
    exact this.congr_deriv (by ring)
  have d2 : deriv (fun y => -y * gaussianPDFReal 0 1 y) = fun x => (x ^ 2 - 1) * gaussianPDFReal 0 1 x :=
    funext fun x => (h2 x).deriv
  have h3 : ∀ x, HasDerivAt (fun y => (y ^ 2 - 1) * gaussianPDFReal 0 1 y) (-(x ^ 3 - 3 * x) * gaussianPDFReal 0 1 x) x := by
    intro x
    have := (((hasDerivAt_id' x).pow 2).sub_const (1:ℝ)).mul (bell_hasDerivAt x)
    exact this.congr_deriv (by simp; ring)
  have d3 : deriv (fun y => (y ^ 2 - 1) * gaussianPDFReal 0 1 y) = fun x => -(x ^ 3 - 3 * x) * gaussianPDFReal 0 1 x :=
    funext fun x => (h3 x).deriv
  have i2 : iteratedDeriv 2 (gaussianPDFReal 0 1) = fun x => (x ^ 2 - 1) * gaussianPDFReal 0 1 x := by
    rw [iteratedDeriv_succ, iteratedDeriv_one, d1, d2]
  refine ⟨by rw [i2], ?_⟩
  rw [iteratedDeriv_succ, i2, d3]

/-- **Berry-Esseen promises one twentieth from n = 339.** For the six-or-not count,
`ρ = 65/648` and `σ = √(5/36)`. With the constant `C = 0.4748`, the bound
`C ρ/(σ³√n)` on the worst gap for `n` rolls is at most `1/20` exactly when `n ≥ 339`. -/
theorem berry_esseen_sixes_threshold (n : ℕ) (hn : 0 < n) :
    (4748 / 10000 : ℝ) * ((65 / 648) / (√(5 / 36)) ^ 3) / √(n : ℝ) ≤ 1 / 20 ↔ 339 ≤ n := by
  set K : ℝ := (4748 / 10000 : ℝ) * ((65 / 648) / (√(5 / 36)) ^ 3) with hK
  have hs : 0 < √(5 / 36 : ℝ) := by positivity
  have hs2 : (√(5 / 36 : ℝ)) ^ 2 = 5 / 36 := Real.sq_sqrt (by norm_num)
  have hKpos : 0 < K := by positivity
  have hK2 : (20 * K) ^ 2 = (4748 / 10000) ^ 2 * (169 / 45) * 20 ^ 2 := by
    rw [hK]
    have : (√(5 / 36 : ℝ)) ^ 6 = (5/36) ^ 3 := by
      rw [show (6:ℕ) = 2 * 3 from rfl, pow_mul, hs2]
    field_simp
    rw [show (√(5 / 36 : ℝ)) ^ (3 * 2) = (√(5 / 36 : ℝ)) ^ 6 from rfl, this]
    norm_num
  have hnpos : (0:ℝ) < n := by exact_mod_cast hn
  have hsn : 0 < √(n : ℝ) := Real.sqrt_pos.mpr hnpos
  rw [div_le_iff₀ hsn]
  constructor
  · intro h
    have h' : 20 * K ≤ √(n:ℝ) := by linarith
    have : (20 * K) ^ 2 ≤ (n:ℝ) := by
      calc (20 * K) ^ 2 ≤ (√(n:ℝ)) ^ 2 := pow_le_pow_left₀ (by positivity) h' 2
        _ = n := Real.sq_sqrt hnpos.le
    rw [hK2] at this
    by_contra hc
    have h338 : (n:ℝ) ≤ 338 := by exact_mod_cast (by omega : n ≤ 338)
    norm_num at this
    linarith
  · intro h
    have hn' : (339:ℝ) ≤ n := by exact_mod_cast h
    have : (20 * K) ^ 2 ≤ (√(n:ℝ)) ^ 2 := by
      rw [Real.sq_sqrt hnpos.le, hK2]; norm_num; linarith
    have := (pow_le_pow_iff_left₀ (by positivity) hsn.le (by norm_num : (2:ℕ) ≠ 0)).mp this
    linarith

-- One roll, p = 1/6: variance (1/6)(5/6) = 5/36.
example : (1 / 6 : ℚ) * (5 / 6) = 5 / 36 := by norm_num
-- One roll: ρ = (1/6)(5/6)[(5/6)² + (1/6)²] = 65/648.
example : (1 / 6 : ℚ) * (5 / 6) * ((5 / 6) ^ 2 + (1 / 6) ^ 2) = 65 / 648 := by norm_num
-- The ratio squared: (ρ/σ³)² = (65/648)²/(5/36)³ = 169/45.
example : (65 / 648 : ℚ) ^ 2 / (5 / 36) ^ 3 = 169 / 45 := by norm_num
-- Third central moment (1/6)(5/6)(1 - 2/6) = 5/54, and skewness squared γ² = (2/3)²/(5/36) = 16/5.
example : (1 / 6 : ℚ) * (5 / 6) * (1 - 2 * (1 / 6)) = 5 / 54 := by norm_num
example : (5 / 54 : ℚ) ^ 2 / (5 / 36) ^ 3 = 16 / 5 := by norm_num
-- Twenty rolls: mean 20/6 = 10/3, variance 20 × 5/36 = 25/9, so standard deviation 5/3.
example : (20 : ℚ) * (1 / 6) = 10 / 3 ∧ (20 : ℚ) * (5 / 36) = (5 / 3) ^ 2 := by norm_num
-- k = 3: z = (3 - 10/3)/(5/3) = -1/5; half step z = (3.5 - 10/3)/(5/3) = 1/10.
example : ((3 : ℚ) - 10 / 3) / (5 / 3) = -1 / 5 := by norm_num
example : ((7 / 2 : ℚ) - 10 / 3) / (5 / 3) = 1 / 10 := by norm_num
-- Exact count: the sequences with 3 sixes or fewer in 20 rolls number 2,071,380,615,234,375 of 6^20.
example : (∑ k ∈ range 4, Nat.choose 20 k * 5 ^ (20 - k)) = 2071380615234375 := by decide
example : (6 : ℕ) ^ 20 = 3656158440062976 := by norm_num
-- Berry-Esseen for 1/20: (C ρ/σ³)² × 20² lies between 338 and 339, with C = 4748/10000.
example : (338 : ℚ) < (4748 / 10000) ^ 2 * (169 / 45) * 20 ^ 2 ∧
    (4748 / 10000 : ℚ) ^ 2 * (169 / 45) * 20 ^ 2 ≤ 339 := by norm_num
-- Target 1/100: (C ρ/σ³)² × 100² lies between 8466 and 8467.
example : (8466 : ℚ) < (4748 / 10000) ^ 2 * (169 / 45) * 100 ^ 2 ∧
    (4748 / 10000 : ℚ) ^ 2 * (169 / 45) * 100 ^ 2 ≤ 8467 := by norm_num
-- What breaks: a fair coin has third central moment (1/2)(1/2)(1 - 2 × 1/2) = 0, so zero skewness
-- and no Edgeworth gain; its ρ = 1/8 and σ² = 1/4 give ρ² = (σ²)³, so its ratio ρ/σ³ is 1.
example : (1 / 2 : ℚ) * (1 / 2) * (1 - 2 * (1 / 2)) = 0 := by norm_num
example : ((1 / 2 : ℚ) * (1 / 2) * ((1 / 2) ^ 2 + (1 / 2) ^ 2)) ^ 2 = ((1 / 2) * (1 / 2)) ^ 3 := by
  norm_num

#print axioms six_count_moments_and_ratio
#print axioms bell_height_derivatives
#print axioms berry_esseen_sixes_threshold
