-- The eight barrier formulas: in the Black-Scholes model the four Reiner-Rubinstein price blocks A, B, C, D are the plain and the mirror bell curves read over half-lines cut at the strike and at the barrier, the rebate block E is the discounted rebate times the chance of never touching, and the mirror's tilt is the constant (H/S)^(2μ).
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.Analysis.SpecialFunctions.Pow.Real

open Real MeasureTheory ProbabilityTheory Set

namespace ReinerRubinstein

/-- `N(x)`: the bell-curve area to the left of `x`, the standard normal's cumulative chance. -/
noncomputable def N (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- `μ = (r - q - σ²/2) / σ²`: the pretend-world drift in volatility units. -/
noncomputable def mu (r q σ : ℝ) : ℝ := (r - q - σ ^ 2 / 2) / σ ^ 2

/-- `λ = √(μ² + 2r/σ²)`: the rebate cousin of `μ`. -/
noncomputable def lam (r q σ : ℝ) : ℝ := √(mu r q σ ^ 2 + 2 * r / σ ^ 2)

/-- `x₁ = ln(S/K)/(σ√T) + (1 + μ)σ√T`, the Black-Scholes `d₁`. -/
noncomputable def x1 (S K r q σ T : ℝ) : ℝ :=
  log (S / K) / (σ * √T) + (1 + mu r q σ) * σ * √T

/-- `x₂ = ln(S/H)/(σ√T) + (1 + μ)σ√T`: the distance to the barrier. -/
noncomputable def x2 (S H r q σ T : ℝ) : ℝ :=
  log (S / H) / (σ * √T) + (1 + mu r q σ) * σ * √T

/-- `y₁ = ln(H²/(SK))/(σ√T) + (1 + μ)σ√T`: the distance to the strike from the mirror spot. -/
noncomputable def y1 (S K H r q σ T : ℝ) : ℝ :=
  log (H ^ 2 / (S * K)) / (σ * √T) + (1 + mu r q σ) * σ * √T

/-- `y₂ = ln(H/S)/(σ√T) + (1 + μ)σ√T`: the distance to the barrier from the mirror spot. -/
noncomputable def y2 (S H r q σ T : ℝ) : ℝ :=
  log (H / S) / (σ * √T) + (1 + mu r q σ) * σ * √T

/-- `z = ln(H/S)/(σ√T) + λσ√T`. -/
noncomputable def zz (S H r q σ T : ℝ) : ℝ :=
  log (H / S) / (σ * √T) + lam r q σ * σ * √T

/-- Block `A = φ S e^{-qT} N(φx₁) - φ K e^{-rT} N(φx₁ - φσ√T)`. -/
noncomputable def blockA (φ S K r q σ T : ℝ) : ℝ :=
  φ * S * exp (-(q * T)) * N (φ * x1 S K r q σ T)
    - φ * K * exp (-(r * T)) * N (φ * x1 S K r q σ T - φ * σ * √T)

/-- Block `B = φ S e^{-qT} N(φx₂) - φ K e^{-rT} N(φx₂ - φσ√T)`. -/
noncomputable def blockB (φ S K H r q σ T : ℝ) : ℝ :=
  φ * S * exp (-(q * T)) * N (φ * x2 S H r q σ T)
    - φ * K * exp (-(r * T)) * N (φ * x2 S H r q σ T - φ * σ * √T)

/-- Block `C = φ S e^{-qT} (H/S)^{2μ+2} N(ηy₁) - φ K e^{-rT} (H/S)^{2μ} N(ηy₁ - ησ√T)`. -/
noncomputable def blockC (φ η S K H r q σ T : ℝ) : ℝ :=
  φ * S * exp (-(q * T)) * (H / S) ^ (2 * mu r q σ + 2) * N (η * y1 S K H r q σ T)
    - φ * K * exp (-(r * T)) * (H / S) ^ (2 * mu r q σ)
        * N (η * y1 S K H r q σ T - η * σ * √T)

/-- Block `D = φ S e^{-qT} (H/S)^{2μ+2} N(ηy₂) - φ K e^{-rT} (H/S)^{2μ} N(ηy₂ - ησ√T)`. -/
noncomputable def blockD (φ η S K H r q σ T : ℝ) : ℝ :=
  φ * S * exp (-(q * T)) * (H / S) ^ (2 * mu r q σ + 2) * N (η * y2 S H r q σ T)
    - φ * K * exp (-(r * T)) * (H / S) ^ (2 * mu r q σ)
        * N (η * y2 S H r q σ T - η * σ * √T)

/-- Rebate block `E = R e^{-rT} [N(ηx₂ - ησ√T) - (H/S)^{2μ} N(ηy₂ - ησ√T)]`. -/
noncomputable def blockE (η R S H r q σ T : ℝ) : ℝ :=
  R * exp (-(r * T)) * (N (η * x2 S H r q σ T - η * σ * √T)
    - (H / S) ^ (2 * mu r q σ) * N (η * y2 S H r q σ T - η * σ * √T))

/-- Rebate block `F = R [(H/S)^{μ+λ} N(ηz) + (H/S)^{μ-λ} N(ηz - 2ηλσ√T)]`. -/
noncomputable def blockF (η R S H r q σ T : ℝ) : ℝ :=
  R * ((H / S) ^ (mu r q σ + lam r q σ) * N (η * zz S H r q σ T)
    + (H / S) ^ (mu r q σ - lam r q σ)
        * N (η * zz S H r q σ T - 2 * η * lam r q σ * σ * √T))

/-- The plain bell curve `f(u)`: the pretend-world density of the log price `u = ln(S_T/S)`,
centre `(r - q - σ²/2)T`, spread `σ√T`. -/
noncomputable def f (r q σ T u : ℝ) : ℝ :=
  gaussianPDFReal ((r - q - σ ^ 2 / 2) * T) (σ ^ 2 * T).toNNReal u

lemma gauss_set_eq (m c : ℝ) (v : NNReal) (hv : (v : ℝ) = c ^ 2) (hc : c ≠ 0) {A : Set ℝ}
    (hA : MeasurableSet A) :
    ∫ u in A, gaussianPDFReal m v u = (gaussianReal 0 1).real ((fun x => c * x + m) ⁻¹' A) := by
  have hv0 : v ≠ 0 := by
    intro h; rw [h] at hv; simp at hv; exact hc (pow_eq_zero_iff two_ne_zero |>.1 hv.symm)
  have hmap : (gaussianReal 0 1).map (fun x => c * x + m) = gaussianReal m v := by
    have : (fun x : ℝ => c * x + m) = (· + m) ∘ (c * ·) := rfl
    rw [this, ← Measure.map_map (measurable_add_const m) (measurable_const_mul c),
      gaussianReal_map_const_mul, gaussianReal_map_add_const]
    congr 1
    · simp
    · ext; simp [hv]
  have h1 : (gaussianReal m v).real A = ∫ u in A, gaussianPDFReal m v u := by
    rw [measureReal_def, gaussianReal_apply_eq_integral _ hv0, ENNReal.toReal_ofReal
      (setIntegral_nonneg hA (fun x _ => gaussianPDFReal_nonneg _ _ _))]
  rw [← h1, ← hmap, measureReal_def, measureReal_def, Measure.map_apply (by fun_prop) hA]

lemma half_int (η a m s : ℝ) (v : NNReal) (hv : (v : ℝ) = s ^ 2) (hs : 0 < s)
    (hη : η = 1 ∨ η = -1) :
    ∫ u in {u : ℝ | η * a < η * u}, gaussianPDFReal m v u = N (η * ((m - a) / s)) := by
  have := nullSingletonClass_gaussianReal (μ := (0 : ℝ)) (v := 1) one_ne_zero
  have hmeas : MeasurableSet {u : ℝ | η * a < η * u} := measurableSet_lt (by fun_prop) (by fun_prop)
  rcases hη with rfl | rfl
  · rw [gauss_set_eq m (-s) v (by rw [hv]; ring) (neg_ne_zero.2 hs.ne') hmeas]
    have : (fun x => -s * x + m) ⁻¹' {u : ℝ | 1 * a < 1 * u} = Iio ((m - a) / s) := by
      ext x
      simp only [mem_preimage, mem_ofPred_eq, mem_Iio, one_mul]
      rw [lt_div_iff₀ hs]
      constructor <;> intro h <;> linarith
    rw [this, N, cdf_eq_real, one_mul]
    exact measureReal_congr Iio_ae_eq_Iic
  · rw [gauss_set_eq m s v hv hs.ne' hmeas]
    have : (fun x => s * x + m) ⁻¹' {u : ℝ | -1 * a < -1 * u} = Iio ((a - m) / s) := by
      ext x
      simp only [mem_preimage, mem_ofPred_eq, mem_Iio]
      rw [lt_div_iff₀ hs]
      constructor <;> intro h <;> linarith
    rw [this, N, cdf_eq_real, show -1 * ((m - a) / s) = (a - m) / s by ring]
    exact measureReal_congr Iio_ae_eq_Iic

lemma exp_mul_pdf (m u s : ℝ) (v : NNReal) (hv : (v : ℝ) = s ^ 2) (hs : 0 < s) :
    exp u * gaussianPDFReal m v u = exp (m + s ^ 2 / 2) * gaussianPDFReal (m + s ^ 2) v u := by
  simp only [gaussianPDFReal, hv]
  rw [mul_left_comm, ← exp_add, mul_left_comm (exp _), ← exp_add]
  congr 2
  field_simp
  ring

lemma payoff_int (φ η a m c S K s : ℝ) (v : NNReal) (hv : (v : ℝ) = s ^ 2) (hs : 0 < s)
    (hη : η = 1 ∨ η = -1) :
    ∫ u in {u : ℝ | η * a < η * u}, φ * (S * exp u - K) * (c * gaussianPDFReal m v u)
      = c * (φ * S * exp (m + s ^ 2 / 2) * N (η * ((m + s ^ 2 - a) / s))
          - φ * K * N (η * ((m - a) / s))) := by
  have hfun : (fun u => φ * (S * exp u - K) * (c * gaussianPDFReal m v u))
      = fun u => (c * φ * S * exp (m + s ^ 2 / 2)) * gaussianPDFReal (m + s ^ 2) v u
          - (c * φ * K) * gaussianPDFReal m v u := by
    funext u
    rw [mul_assoc (c * φ * S), ← exp_mul_pdf m u s v hv hs]
    ring
  rw [hfun, integral_sub ((integrable_gaussianPDFReal _ _).restrict.const_mul _)
      ((integrable_gaussianPDFReal _ _).restrict.const_mul _),
    integral_const_mul, integral_const_mul, half_int η a _ s v hv hs hη,
    half_int η a _ s v hv hs hη]
  ring

lemma payoff_int1 (φ η a m S K s : ℝ) (v : NNReal) (hv : (v : ℝ) = s ^ 2) (hs : 0 < s)
    (hη : η = 1 ∨ η = -1) :
    ∫ u in {u : ℝ | η * a < η * u}, φ * (S * exp u - K) * gaussianPDFReal m v u
      = φ * S * exp (m + s ^ 2 / 2) * N (η * ((m + s ^ 2 - a) / s))
          - φ * K * N (η * ((m - a) / s)) := by
  simpa only [one_mul] using payoff_int φ η a m 1 S K s v hv hs hη

#print axioms gauss_set_eq
#print axioms half_int
#print axioms exp_mul_pdf
#print axioms payoff_int
#print axioms payoff_int1

/-- **Every block is one half-line of one bell curve** (the boxed claim; Why it works, Step 2).
Take the switches `φ` (call `+1`, put `-1`) and `η` (down `+1`, up `-1`), today's price `S > 0`,
strike `K > 0`, barrier `H > 0`, any bank rate `r` and dividend yield `q`, volatility `σ > 0` and
`T > 0` years. Write `f` for the plain bell curve of the log price, `b = ln(H/S)` for the barrier
in log units, and `(H/S)^{2μ} f(u - 2b)` for the mirror curve. The payoff of the option is
`φ(S e^u - K)`. Then, discounting by `e^{-rT}`:
* `A` is the plain curve over the side of the strike where the option pays, `φu > φ ln(K/S)`;
* `B` is the plain curve over the same side of the barrier instead, `φu > φ ln(H/S)`;
* `C` is the mirror curve over the `η`-side of the strike, `ηu > η ln(K/S)`;
* `D` is the mirror curve over the `η`-side of the barrier, `ηu > η ln(H/S)`. -/
theorem blocks_are_half_line_readings_of_two_bell_curves
    (φ η S K H r q σ T : ℝ) (hφ : φ = 1 ∨ φ = -1) (hη : η = 1 ∨ η = -1)
    (hS : 0 < S) (hK : 0 < K) (hH : 0 < H) (hσ : 0 < σ) (hT : 0 < T) :
    let b : ℝ := log (H / S)
    let tilt : ℝ := (H / S) ^ (2 * mu r q σ)
    blockA φ S K r q σ T
        = exp (-(r * T)) * ∫ u in {u : ℝ | φ * log (K / S) < φ * u},
            φ * (S * exp u - K) * f r q σ T u ∧
    blockB φ S K H r q σ T
        = exp (-(r * T)) * ∫ u in {u : ℝ | φ * b < φ * u},
            φ * (S * exp u - K) * f r q σ T u ∧
    blockC φ η S K H r q σ T
        = exp (-(r * T)) * ∫ u in {u : ℝ | η * log (K / S) < η * u},
            φ * (S * exp u - K) * (tilt * f r q σ T (u - 2 * b)) ∧
    blockD φ η S K H r q σ T
        = exp (-(r * T)) * ∫ u in {u : ℝ | η * b < η * u},
            φ * (S * exp u - K) * (tilt * f r q σ T (u - 2 * b)) := by
  dsimp only
  obtain ⟨t, ht0, rfl⟩ : ∃ t, 0 < t ∧ T = t ^ 2 :=
    ⟨√T, Real.sqrt_pos.2 hT, (Real.sq_sqrt hT.le).symm⟩
  have hsq : √(t ^ 2) = t := Real.sqrt_sq ht0.le
  have hs : 0 < σ * t := mul_pos hσ ht0
  have hv : ((σ ^ 2 * t ^ 2).toNNReal : ℝ) = (σ * t) ^ 2 := by
    rw [Real.coe_toNNReal _ (by positivity)]; ring
  have hHS : 0 < H / S := div_pos hH hS
  have lKS : log (K / S) = log K - log S := Real.log_div hK.ne' hS.ne'
  have lSK : log (S / K) = log S - log K := Real.log_div hS.ne' hK.ne'
  have lHS : log (H / S) = log H - log S := Real.log_div hH.ne' hS.ne'
  have lSH : log (S / H) = log S - log H := Real.log_div hS.ne' hH.ne'
  have lHH : log (H ^ 2 / (S * K)) = 2 * log H - log S - log K := by
    rw [Real.log_div (by positivity) (by positivity), Real.log_mul hS.ne' hK.ne', Real.log_pow]
    push_cast; ring
  have hσ0 : σ ≠ 0 := hσ.ne'
  have ht00 : t ≠ 0 := ht0.ne'
  simp only [f, gaussianPDFReal_sub]
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [payoff_int1 φ φ (log (K / S)) ((r - q - σ ^ 2 / 2) * t ^ 2) S K (σ * t) _ hv hs hφ]
    unfold blockA
    have hx' : x1 S K r q σ (t ^ 2)
        = ((r - q - σ ^ 2 / 2) * t ^ 2 + (σ * t) ^ 2 - log (K / S)) / (σ * t) := by
      unfold x1 mu; rw [hsq, lSK, lKS]; field_simp; ring
    have hy : φ * x1 S K r q σ (t ^ 2) - φ * σ * √(t ^ 2)
        = φ * (((r - q - σ ^ 2 / 2) * t ^ 2 - log (K / S)) / (σ * t)) := by
      rw [hsq, hx']; field_simp; ring
    have he : exp (-(r * t ^ 2)) * exp ((r - q - σ ^ 2 / 2) * t ^ 2 + (σ * t) ^ 2 / 2)
        = exp (-(q * t ^ 2)) := by rw [← exp_add]; congr 1; ring
    rw [hy, hx', ← he]; ring
  · rw [payoff_int1 φ φ (log (H / S)) ((r - q - σ ^ 2 / 2) * t ^ 2) S K (σ * t) _ hv hs hφ]
    unfold blockB
    have hx' : x2 S H r q σ (t ^ 2)
        = ((r - q - σ ^ 2 / 2) * t ^ 2 + (σ * t) ^ 2 - log (H / S)) / (σ * t) := by
      unfold x2 mu; rw [hsq, lSH, lHS]; field_simp; ring
    have hy : φ * x2 S H r q σ (t ^ 2) - φ * σ * √(t ^ 2)
        = φ * (((r - q - σ ^ 2 / 2) * t ^ 2 - log (H / S)) / (σ * t)) := by
      rw [hsq, hx']; field_simp; ring
    have he : exp (-(r * t ^ 2)) * exp ((r - q - σ ^ 2 / 2) * t ^ 2 + (σ * t) ^ 2 / 2)
        = exp (-(q * t ^ 2)) := by rw [← exp_add]; congr 1; ring
    rw [hy, hx', ← he]; ring
  · rw [payoff_int φ η (log (K / S)) ((r - q - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S))
      ((H / S) ^ (2 * mu r q σ)) S K (σ * t) _ hv hs hη]
    unfold blockC
    have hx' : y1 S K H r q σ (t ^ 2)
        = ((r - q - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S) + (σ * t) ^ 2 - log (K / S))
          / (σ * t) := by
      unfold y1 mu; rw [hsq, lHH, lHS, lKS]; field_simp; ring
    have hy : η * y1 S K H r q σ (t ^ 2) - η * σ * √(t ^ 2)
        = η * (((r - q - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S) - log (K / S)) / (σ * t)) := by
      rw [hsq, hx']; field_simp; ring
    have he : exp (-(r * t ^ 2)) * (H / S) ^ (2 * mu r q σ)
          * exp ((r - q - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S) + (σ * t) ^ 2 / 2)
        = exp (-(q * t ^ 2)) * (H / S) ^ (2 * mu r q σ + 2) := by
      simp only [rpow_def_of_pos hHS]
      rw [← exp_add, ← exp_add, ← exp_add]; congr 1; ring
    rw [hy, hx']
    linear_combination (-(φ * S * N (η * (((r - q - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S)
      + (σ * t) ^ 2 - log (K / S)) / (σ * t))))) * he
  · rw [payoff_int φ η (log (H / S)) ((r - q - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S))
      ((H / S) ^ (2 * mu r q σ)) S K (σ * t) _ hv hs hη]
    unfold blockD
    have hx' : y2 S H r q σ (t ^ 2)
        = ((r - q - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S) + (σ * t) ^ 2 - log (H / S))
          / (σ * t) := by
      unfold y2 mu; rw [hsq]; field_simp; ring
    have hy : η * y2 S H r q σ (t ^ 2) - η * σ * √(t ^ 2)
        = η * (((r - q - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S) - log (H / S)) / (σ * t)) := by
      rw [hsq, hx']; field_simp; ring
    have he : exp (-(r * t ^ 2)) * (H / S) ^ (2 * mu r q σ)
          * exp ((r - q - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S) + (σ * t) ^ 2 / 2)
        = exp (-(q * t ^ 2)) * (H / S) ^ (2 * mu r q σ + 2) := by
      simp only [rpow_def_of_pos hHS]
      rw [← exp_add, ← exp_add, ← exp_add]; congr 1; ring
    rw [hy, hx']
    linear_combination (-(φ * S * N (η * (((r - q - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S)
      + (σ * t) ^ 2 - log (H / S)) / (σ * t))))) * he

/-- **The rebate paid at expiry is the discounted chance of never touching** (Step 4). With
`η = ±1`, `S, H > 0`, `σ > 0`, `T > 0` and any cash rebate `R`: the never-touched weight on the
live side `ηu > ηb` of the barrier `b = ln(H/S)` is the plain curve minus the mirror curve,
`f(u) - (H/S)^{2μ} f(u - 2b)` (Step 1), and `R e^{-rT}` times its total is block `E`. -/
theorem blockE_eq_discounted_survival_chance
    (η R S H r q σ T : ℝ) (hη : η = 1 ∨ η = -1)
    (hS : 0 < S) (hH : 0 < H) (hσ : 0 < σ) (hT : 0 < T) :
    let b : ℝ := log (H / S)
    blockE η R S H r q σ T
      = R * exp (-(r * T)) * ∫ u in {u : ℝ | η * b < η * u},
          (f r q σ T u - (H / S) ^ (2 * mu r q σ) * f r q σ T (u - 2 * b)) := by
  dsimp only
  obtain ⟨t, ht0, rfl⟩ : ∃ t, 0 < t ∧ T = t ^ 2 :=
    ⟨√T, Real.sqrt_pos.2 hT, (Real.sq_sqrt hT.le).symm⟩
  have hsq : √(t ^ 2) = t := Real.sqrt_sq ht0.le
  have hs : 0 < σ * t := mul_pos hσ ht0
  have hv : ((σ ^ 2 * t ^ 2).toNNReal : ℝ) = (σ * t) ^ 2 := by
    rw [Real.coe_toNNReal _ (by positivity)]; ring
  have lHS : log (H / S) = log H - log S := Real.log_div hH.ne' hS.ne'
  have lSH : log (S / H) = log S - log H := Real.log_div hS.ne' hH.ne'
  have hσ0 : σ ≠ 0 := hσ.ne'
  have ht00 : t ≠ 0 := ht0.ne'
  simp only [f, gaussianPDFReal_sub]
  rw [integral_sub (integrable_gaussianPDFReal _ _).restrict
      ((integrable_gaussianPDFReal _ _).restrict.const_mul _), integral_const_mul,
    half_int η (log (H / S)) ((r - q - σ ^ 2 / 2) * t ^ 2) (σ * t) _ hv hs hη,
    half_int η (log (H / S)) ((r - q - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S)) (σ * t) _ hv hs hη]
  unfold blockE
  have hx : η * x2 S H r q σ (t ^ 2) - η * σ * √(t ^ 2)
      = η * (((r - q - σ ^ 2 / 2) * t ^ 2 - log (H / S)) / (σ * t)) := by
    unfold x2 mu; rw [hsq, lSH, lHS]; field_simp; ring
  have hy : η * y2 S H r q σ (t ^ 2) - η * σ * √(t ^ 2)
      = η * (((r - q - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S) - log (H / S)) / (σ * t)) := by
    unfold y2 mu; rw [hsq]; field_simp; ring
  rw [hx, hy]

/-- **The mirror's tilt** (Step 1, Detailed proof). Let the log price drift at
`ν = r - q - σ²/2` with volatility `σ > 0` over `T > 0` years, and let `b = ln(H/S)` with
`S, H > 0`. Take a driftless path that touched `b` and ended at `u`: by the reflection principle
its weight is the driftless bell curve at the mirror point `2b - u`. Reweight it for drift by
`exp(νu/σ² - ν²T/(2σ²))`. The result is one constant factor `(H/S)^{2μ}` times the drifted bell
curve at `u - 2b`: every `u` cancels. -/
theorem mirror_tilt_is_constant
    (S H r q σ T u : ℝ) (hS : 0 < S) (hH : 0 < H) (hσ : 0 < σ) (hT : 0 < T) :
    let ν : ℝ := r - q - σ ^ 2 / 2
    let b : ℝ := log (H / S)
    gaussianPDFReal 0 (σ ^ 2 * T).toNNReal (2 * b - u)
        * exp (ν * u / σ ^ 2 - ν ^ 2 * T / (2 * σ ^ 2))
      = (H / S) ^ (2 * mu r q σ) * f r q σ T (u - 2 * b) := by
  dsimp only
  have hv : ((σ ^ 2 * T).toNNReal : ℝ) = σ ^ 2 * T := Real.coe_toNNReal _ (by positivity)
  have hσ0 : σ ≠ 0 := hσ.ne'
  have hT0 : T ≠ 0 := hT.ne'
  simp only [f, gaussianPDFReal, hv, rpow_def_of_pos (div_pos hH hS)]
  rw [mul_assoc, ← exp_add, mul_left_comm (rexp _), ← exp_add]
  congr 2
  unfold mu
  field_simp
  ring

-- House market: r = 5%, q = 2%, σ = 20%, T = 1, S = K = 100.
-- μ = (0.05 - 0.02 - 0.02) / 0.04 = 0.25.
example : mu (5 / 100) (2 / 100) (20 / 100) = 1 / 4 := by
  unfold mu; norm_num
example : ((5 : ℚ) / 100 - 2 / 100 - (20 / 100) ^ 2 / 2) / (20 / 100) ^ 2 = 1 / 4 := by
  norm_num
-- λ = √(0.0625 + 2.5) = √41 / 4 ≈ 1.600781.
example : lam (5 / 100) (2 / 100) (20 / 100) = √41 / 4 := by
  unfold lam mu
  rw [eq_div_iff (by norm_num), ← Real.sqrt_sq (show (0 : ℝ) ≤ 4 by norm_num),
    ← Real.sqrt_mul (by norm_num)]
  norm_num
example : ((1 : ℚ) / 4) ^ 2 + 2 * (5 / 100) / (20 / 100) ^ 2 = 41 / 16 := by norm_num
-- x₁ = 0 + 1.25 × 0.20 = 0.25, the Black-Scholes d₁, at S = K = 100.
example : x1 100 100 (5 / 100) (2 / 100) (20 / 100) 1 = 1 / 4 := by
  simp [x1, mu]; norm_num
-- (1 + μ)σ² = r - q + σ²/2: 1.25 × 0.04 = 0.05 = 0.05 - 0.02 + 0.02.
example : (1 + (1 : ℚ) / 4) * (20 / 100) ^ 2 = 5 / 100 - 2 / 100 + (20 / 100) ^ 2 / 2 := by
  norm_num
-- At the $80 floor: H/S = 0.8, H²/(SK) = 0.64, tilt exponents 2μ + 2 = 2.5 and 2μ = 0.5.
example : (80 : ℚ) ^ 2 / (100 * 100) = 64 / 100 := by norm_num
example : 2 * ((1 : ℚ) / 4) + 2 = 5 / 2 ∧ 2 * ((1 : ℚ) / 4) = 1 / 2 := by norm_num
-- In-out parity is built into the table: in each column, every in-row plus its out-row is A,
-- rebates aside (E on the in-row, F on the out-row).
example (A B C D E F : ℝ) :
    -- strike above the barrier, K > H
    ((C + E) + (A - C + F) = A + E + F) ∧            -- DIC + DOC
    ((A + E) + F = A + E + F) ∧                      -- UIC + UOC
    ((B - C + D + E) + (A - B + C - D + F) = A + E + F) ∧  -- DIP + DOP
    ((A - B + D + E) + (B - D + F) = A + E + F) ∧    -- UIP + UOP
    -- strike below the barrier, K < H
    ((A - B + D + E) + (B - D + F) = A + E + F) ∧    -- DIC + DOC
    ((B - C + D + E) + (A - B + C - D + F) = A + E + F) ∧  -- UIC + UOC
    ((A + E) + F = A + E + F) ∧                      -- DIP + DOP
    ((C + E) + (A - C + F) = A + E + F) := by        -- UIP + UOP
  refine ⟨by ring, by ring, by ring, by ring, by ring, by ring, by ring, by ring⟩

#print axioms blocks_are_half_line_readings_of_two_bell_curves
#print axioms blockE_eq_discounted_survival_chance
#print axioms mirror_tilt_is_constant

end ReinerRubinstein
