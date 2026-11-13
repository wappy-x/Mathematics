-- The eight single barriers in one table: in the Garman-Kohlhagen model every knock-out is its payoff integrated against the plain-minus-mirror density on the live side of the wall, which equals the table's sum of blocks A to D for all sixteen cases, every knock-in is the plain option minus its knock-out in any model, and the rebate paid at the touch is block F.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Probability.CDF
import Mathlib.MeasureTheory.Integral.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Topology.Algebra.Order.Field

open Real MeasureTheory ProbabilityTheory Set

namespace EightBarriers

/-- `N(x)`: the bell-curve area to the left of `x` (the standard normal CDF). -/
noncomputable def N (x : ℝ) : ℝ := cdf (gaussianReal 0 1) x

/-- `μ = (r_d - r_f - σ²/2) / σ²`: the drift of log EURUSD in units of its variance. -/
noncomputable def mu (rd rf σ : ℝ) : ℝ := (rd - rf - σ ^ 2 / 2) / σ ^ 2

/-- `λ = √(μ² + 2 r_d / σ²)`: the exponent that discounts money paid at the touch. -/
noncomputable def lam (rd rf σ : ℝ) : ℝ := √(mu rd rf σ ^ 2 + 2 * rd / σ ^ 2)

/-- `x₁ = ln(S/K)/s + (1 + μ)s` with `s = σ√T`: the Garman-Kohlhagen `d₁`. -/
noncomputable def x1 (S K rd rf σ T : ℝ) : ℝ :=
  log (S / K) / (σ * √T) + (1 + mu rd rf σ) * (σ * √T)

/-- `x₂ = ln(S/H)/s + (1 + μ)s`: `x₁` with the wall in place of the strike. -/
noncomputable def x2 (S H rd rf σ T : ℝ) : ℝ :=
  log (S / H) / (σ * √T) + (1 + mu rd rf σ) * (σ * √T)

/-- `y₁ = ln(H²/(SK))/s + (1 + μ)s`: `x₁` measured from the mirror spot `H²/S`. -/
noncomputable def y1 (S K H rd rf σ T : ℝ) : ℝ :=
  log (H ^ 2 / (S * K)) / (σ * √T) + (1 + mu rd rf σ) * (σ * √T)

/-- `y₂ = ln(H/S)/s + (1 + μ)s`: `x₂` measured from the mirror spot. -/
noncomputable def y2 (S H rd rf σ T : ℝ) : ℝ :=
  log (H / S) / (σ * √T) + (1 + mu rd rf σ) * (σ * √T)

/-- `z = ln(H/S)/s + λs`. -/
noncomputable def z (S H rd rf σ T : ℝ) : ℝ :=
  log (H / S) / (σ * √T) + lam rd rf σ * (σ * √T)

/-- Block `A = φ S e^{-r_f T} N(φx₁) - φ K e^{-r_d T} N(φ(x₁ - s))`: the plain option. -/
noncomputable def blockA (φ S K rd rf σ T : ℝ) : ℝ :=
  φ * S * exp (-(rf * T)) * N (φ * x1 S K rd rf σ T)
    - φ * K * exp (-(rd * T)) * N (φ * (x1 S K rd rf σ T - σ * √T))

/-- Block `B = φ S e^{-r_f T} N(φx₂) - φ K e^{-r_d T} N(φ(x₂ - s))`:
the plain option counted only beyond the wall. -/
noncomputable def blockB (φ S K H rd rf σ T : ℝ) : ℝ :=
  φ * S * exp (-(rf * T)) * N (φ * x2 S H rd rf σ T)
    - φ * K * exp (-(rd * T)) * N (φ * (x2 S H rd rf σ T - σ * √T))

/-- Block `C = φ S e^{-r_f T} (H/S)^{2μ+2} N(ηy₁) - φ K e^{-r_d T} (H/S)^{2μ} N(η(y₁ - s))`:
the mirror copy of `A`. -/
noncomputable def blockC (φ η S K H rd rf σ T : ℝ) : ℝ :=
  φ * S * exp (-(rf * T)) * (H / S) ^ (2 * mu rd rf σ + 2) * N (η * y1 S K H rd rf σ T)
    - φ * K * exp (-(rd * T)) * (H / S) ^ (2 * mu rd rf σ)
        * N (η * (y1 S K H rd rf σ T - σ * √T))

/-- Block `D = φ S e^{-r_f T} (H/S)^{2μ+2} N(ηy₂) - φ K e^{-r_d T} (H/S)^{2μ} N(η(y₂ - s))`:
the mirror copy of `B`. -/
noncomputable def blockD (φ η S K H rd rf σ T : ℝ) : ℝ :=
  φ * S * exp (-(rf * T)) * (H / S) ^ (2 * mu rd rf σ + 2) * N (η * y2 S H rd rf σ T)
    - φ * K * exp (-(rd * T)) * (H / S) ^ (2 * mu rd rf σ)
        * N (η * (y2 S H rd rf σ T - σ * √T))

/-- Block `F = R [(H/S)^{μ+λ} N(ηz) + (H/S)^{μ-λ} N(η(z - 2λs))]`:
the rebate `R` paid the moment the wall is touched. -/
noncomputable def blockF (η R S H rd rf σ T : ℝ) : ℝ :=
  R * ((H / S) ^ (mu rd rf σ + lam rd rf σ) * N (η * z S H rd rf σ T)
    + (H / S) ^ (mu rd rf σ - lam rd rf σ)
        * N (η * (z S H rd rf σ T - 2 * lam rd rf σ * (σ * √T))))

/-- The card's knock-out column. `φ` is the call-put switch (`+1` call, `-1` put), `η` the wall
switch (`+1` wall below today's rate, `-1` above); the inner `if` picks the column
"strike at or above the wall" (`H ≤ K`) or "strike below the wall". -/
noncomputable def knockOutRecipe (φ η K H A B C D : ℝ) : ℝ :=
  if η = 1 then
    (if φ = 1 then (if H ≤ K then A - C else B - D)          -- down-and-out call
     else (if H ≤ K then A - B + C - D else 0))              -- down-and-out put
  else
    (if φ = 1 then (if H ≤ K then 0 else A - B + C - D)      -- up-and-out call
     else (if H ≤ K then B - D else A - C))                  -- up-and-out put

/-- The card's knock-in column, row by row. -/
noncomputable def knockInRecipe (φ η K H A B C D : ℝ) : ℝ :=
  if η = 1 then
    (if φ = 1 then (if H ≤ K then C else A - B + D)          -- down-and-in call
     else (if H ≤ K then B - C + D else A))                  -- down-and-in put
  else
    (if φ = 1 then (if H ≤ K then A else B - C + D)          -- up-and-in call
     else (if H ≤ K then A - B + D else C))                  -- up-and-in put

/-- The bell curve of the log move `u = ln(S_T/S)` under the pricing measure:
centre `(r_d - r_f - σ²/2)T`, variance `σ²T`. -/
noncomputable def f (rd rf σ T u : ℝ) : ℝ :=
  gaussianPDFReal ((rd - rf - σ ^ 2 / 2) * T) (σ ^ 2 * T).toNNReal u

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

lemma payoff_fun (φ c m S K s : ℝ) (v : NNReal) (hv : (v : ℝ) = s ^ 2) (hs : 0 < s) :
    (fun u => φ * (S * exp u - K) * (c * gaussianPDFReal m v u))
      = fun u => (c * φ * S * exp (m + s ^ 2 / 2)) * gaussianPDFReal (m + s ^ 2) v u
          - (c * φ * K) * gaussianPDFReal m v u := by
  funext u
  rw [mul_assoc (c * φ * S), ← exp_mul_pdf m u s v hv hs]
  ring

lemma payoff_integrable (φ c m S K s : ℝ) (v : NNReal) (hv : (v : ℝ) = s ^ 2) (hs : 0 < s) :
    Integrable (fun u => φ * (S * exp u - K) * (c * gaussianPDFReal m v u)) := by
  rw [payoff_fun φ c m S K s v hv hs]
  exact ((integrable_gaussianPDFReal _ _).const_mul _).sub
    ((integrable_gaussianPDFReal _ _).const_mul _)

lemma payoff_int (φ η a m c S K s : ℝ) (v : NNReal) (hv : (v : ℝ) = s ^ 2) (hs : 0 < s)
    (hη : η = 1 ∨ η = -1) :
    ∫ u in {u : ℝ | η * a < η * u}, φ * (S * exp u - K) * (c * gaussianPDFReal m v u)
      = c * (φ * S * exp (m + s ^ 2 / 2) * N (η * ((m + s ^ 2 - a) / s))
          - φ * K * N (η * ((m - a) / s))) := by
  rw [payoff_fun φ c m S K s v hv hs,
    integral_sub ((integrable_gaussianPDFReal _ _).restrict.const_mul _)
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

lemma max_payoff (φ S K u : ℝ) (hφ : φ = 1 ∨ φ = -1) (hS : 0 < S) (hK : 0 < K) :
    max (φ * (S * exp u - K)) 0
      = {u : ℝ | φ * log (K / S) < φ * u}.indicator (fun u => φ * (S * exp u - K)) u := by
  have h1 : S * exp u - K = S * (exp u - exp (log (K / S))) := by
    rw [exp_log (div_pos hK hS)]; field_simp
  have key : 0 < φ * (S * exp u - K) ↔ φ * log (K / S) < φ * u := by
    rw [h1]
    rcases hφ with rfl | rfl
    · simp only [one_mul]
      constructor
      · intro h
        have : exp (log (K / S)) < exp u := by nlinarith
        exact exp_lt_exp.1 this
      · intro h
        have := exp_lt_exp.2 h
        nlinarith
    · constructor
      · intro h
        have : exp u < exp (log (K / S)) := by nlinarith
        have := exp_lt_exp.1 this
        linarith
      · intro h
        have := exp_lt_exp.2 (show u < log (K / S) by linarith)
        nlinarith
  by_cases h : φ * log (K / S) < φ * u
  · rw [indicator_of_mem (show u ∈ {u : ℝ | φ * log (K / S) < φ * u} from h)]
    exact max_eq_left (key.2 h).le
  · rw [indicator_of_notMem (show u ∉ {u : ℝ | φ * log (K / S) < φ * u} from h)]
    exact max_eq_right (not_lt.1 (mt key.1 h))

lemma int_Ioo_Ioi {g : ℝ → ℝ} (hg : Integrable g) {a c : ℝ} (h : a ≤ c) :
    ∫ u in Ioo a c, g u = (∫ u in Ioi a, g u) - ∫ u in Ioi c, g u := by
  rw [← Ioc_union_Ioi_eq_Ioi h, setIntegral_union
    (Set.disjoint_left.2 fun x (hx : x ∈ Ioc a c) (hx' : x ∈ Ioi c) => absurd hx.2 (not_le.2 hx')) measurableSet_Ioi
    hg.integrableOn hg.integrableOn, integral_Ioc_eq_integral_Ioo]
  ring

lemma int_Ioo_Iio {g : ℝ → ℝ} (hg : Integrable g) {a c : ℝ} (h : a ≤ c) :
    ∫ u in Ioo a c, g u = (∫ u in Iio c, g u) - ∫ u in Iio a, g u := by
  rw [← Iio_union_Ico_eq_Iio h, setIntegral_union
    (Set.disjoint_left.2 fun x (hx : x ∈ Iio a) (hx' : x ∈ Ico a c) => absurd hx'.1 (not_le.2 hx)) measurableSet_Ico
    hg.integrableOn hg.integrableOn, integral_Ico_eq_integral_Ioo]
  ring

lemma region_int (p q : ℝ → ℝ) (hp : Integrable p) (hq : Integrable q) (φ η b k : ℝ)
    (hφ : φ = 1 ∨ φ = -1) (hη : η = 1 ∨ η = -1) :
    ∫ u in {u : ℝ | η * b < η * u} ∩ {u : ℝ | φ * k < φ * u}, (p u - q u)
      = knockOutRecipe φ η k b
          (∫ u in {u : ℝ | φ * k < φ * u}, p u) (∫ u in {u : ℝ | φ * b < φ * u}, p u)
          (∫ u in {u : ℝ | η * k < η * u}, q u) (∫ u in {u : ℝ | η * b < η * u}, q u) := by
  have e1 : ∀ a : ℝ, {u : ℝ | 1 * a < 1 * u} = Ioi a := fun a => by ext u; simp
  have e2 : ∀ a : ℝ, {u : ℝ | -1 * a < -1 * u} = Iio a := fun a => by ext u; simp
  have hm : (-1 : ℝ) ≠ 1 := by norm_num
  have hsub : ∀ s : Set ℝ, ∫ u in s, (p u - q u) = (∫ u in s, p u) - ∫ u in s, q u :=
    fun s => integral_sub hp.integrableOn hq.integrableOn
  rcases hφ with rfl | rfl <;> rcases hη with rfl | rfl <;> simp only [e1, e2] <;>
    unfold knockOutRecipe <;> by_cases hbk : b ≤ k
  · rw [if_pos rfl, if_pos rfl, if_pos hbk, Ioi_inter_Ioi, max_eq_right hbk, hsub]
  · rw [if_pos rfl, if_pos rfl, if_neg hbk, Ioi_inter_Ioi, max_eq_left ((not_le.1 hbk).le), hsub]
  · rw [if_neg hm, if_pos rfl, if_pos hbk, Iio_inter_Ioi, Ioo_eq_empty (not_lt.2 hbk),
      setIntegral_empty]
  · rw [if_neg hm, if_pos rfl, if_neg hbk, Iio_inter_Ioi, hsub,
      int_Ioo_Ioi hp (not_le.1 hbk).le, int_Ioo_Iio hq (not_le.1 hbk).le]
    ring
  · rw [if_pos rfl, if_neg hm, if_pos hbk, Ioi_inter_Iio, hsub, int_Ioo_Iio hp hbk,
      int_Ioo_Ioi hq hbk]
    ring
  · rw [if_pos rfl, if_neg hm, if_neg hbk, Ioi_inter_Iio,
      Ioo_eq_empty (not_lt.2 (not_le.1 hbk).le), setIntegral_empty]
  · rw [if_neg hm, if_neg hm, if_pos hbk, Iio_inter_Iio, min_eq_left hbk, hsub]
  · rw [if_neg hm, if_neg hm, if_neg hbk, Iio_inter_Iio, min_eq_right (not_le.1 hbk).le,
      hsub]

lemma recipe_mul (c φ η K H K' H' A B C D : ℝ) (h : H ≤ K ↔ H' ≤ K') :
    c * knockOutRecipe φ η K H A B C D
      = knockOutRecipe φ η K' H' (c * A) (c * B) (c * C) (c * D) := by
  unfold knockOutRecipe
  simp only [h]
  split_ifs <;> ring

lemma in_add_out (φ η K H A B C D : ℝ) :
    knockInRecipe φ η K H A B C D + knockOutRecipe φ η K H A B C D = A := by
  unfold knockInRecipe knockOutRecipe
  split_ifs <;> ring

#print axioms gauss_set_eq
#print axioms half_int
#print axioms exp_mul_pdf
#print axioms payoff_fun
#print axioms payoff_integrable
#print axioms payoff_int
#print axioms payoff_int1
#print axioms max_payoff
#print axioms int_Ioo_Ioi
#print axioms int_Ioo_Iio
#print axioms region_int
#print axioms recipe_mul
#print axioms in_add_out

lemma blocks_as_integrals
    (φ η S K H rd rf σ T : ℝ) (hφ : φ = 1 ∨ φ = -1) (hη : η = 1 ∨ η = -1)
    (hS : 0 < S) (hK : 0 < K) (hH : 0 < H) (hσ : 0 < σ) (hT : 0 < T) :
    blockA φ S K rd rf σ T
        = exp (-(rd * T)) * ∫ u in {u : ℝ | φ * log (K / S) < φ * u},
            φ * (S * exp u - K) * f rd rf σ T u ∧
    blockB φ S K H rd rf σ T
        = exp (-(rd * T)) * ∫ u in {u : ℝ | φ * log (H / S) < φ * u},
            φ * (S * exp u - K) * f rd rf σ T u ∧
    blockC φ η S K H rd rf σ T
        = exp (-(rd * T)) * ∫ u in {u : ℝ | η * log (K / S) < η * u},
            φ * (S * exp u - K) * ((H / S) ^ (2 * mu rd rf σ) * f rd rf σ T (u - 2 * log (H / S))) ∧
    blockD φ η S K H rd rf σ T
        = exp (-(rd * T)) * ∫ u in {u : ℝ | η * log (H / S) < η * u},
            φ * (S * exp u - K) * ((H / S) ^ (2 * mu rd rf σ) * f rd rf σ T (u - 2 * log (H / S))) := by
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
  · rw [payoff_int1 φ φ (log (K / S)) ((rd - rf - σ ^ 2 / 2) * t ^ 2) S K (σ * t) _ hv hs hφ]
    unfold blockA
    have hx' : x1 S K rd rf σ (t ^ 2)
        = ((rd - rf - σ ^ 2 / 2) * t ^ 2 + (σ * t) ^ 2 - log (K / S)) / (σ * t) := by
      unfold x1 mu; rw [hsq, lSK, lKS]; field_simp; ring
    have hy : φ * (x1 S K rd rf σ (t ^ 2) - σ * √(t ^ 2))
        = φ * (((rd - rf - σ ^ 2 / 2) * t ^ 2 - log (K / S)) / (σ * t)) := by
      rw [hsq, hx']; field_simp; ring
    have he : exp (-(rd * t ^ 2)) * exp ((rd - rf - σ ^ 2 / 2) * t ^ 2 + (σ * t) ^ 2 / 2)
        = exp (-(rf * t ^ 2)) := by rw [← exp_add]; congr 1; ring
    rw [hy, hx', ← he]; ring
  · rw [payoff_int1 φ φ (log (H / S)) ((rd - rf - σ ^ 2 / 2) * t ^ 2) S K (σ * t) _ hv hs hφ]
    unfold blockB
    have hx' : x2 S H rd rf σ (t ^ 2)
        = ((rd - rf - σ ^ 2 / 2) * t ^ 2 + (σ * t) ^ 2 - log (H / S)) / (σ * t) := by
      unfold x2 mu; rw [hsq, lSH, lHS]; field_simp; ring
    have hy : φ * (x2 S H rd rf σ (t ^ 2) - σ * √(t ^ 2))
        = φ * (((rd - rf - σ ^ 2 / 2) * t ^ 2 - log (H / S)) / (σ * t)) := by
      rw [hsq, hx']; field_simp; ring
    have he : exp (-(rd * t ^ 2)) * exp ((rd - rf - σ ^ 2 / 2) * t ^ 2 + (σ * t) ^ 2 / 2)
        = exp (-(rf * t ^ 2)) := by rw [← exp_add]; congr 1; ring
    rw [hy, hx', ← he]; ring
  · rw [payoff_int φ η (log (K / S)) ((rd - rf - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S))
      ((H / S) ^ (2 * mu rd rf σ)) S K (σ * t) _ hv hs hη]
    unfold blockC
    have hx' : y1 S K H rd rf σ (t ^ 2)
        = ((rd - rf - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S) + (σ * t) ^ 2 - log (K / S))
          / (σ * t) := by
      unfold y1 mu; rw [hsq, lHH, lHS, lKS]; field_simp; ring
    have hy : η * (y1 S K H rd rf σ (t ^ 2) - σ * √(t ^ 2))
        = η * (((rd - rf - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S) - log (K / S)) / (σ * t)) := by
      rw [hsq, hx']; field_simp; ring
    have he : exp (-(rd * t ^ 2)) * (H / S) ^ (2 * mu rd rf σ)
          * exp ((rd - rf - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S) + (σ * t) ^ 2 / 2)
        = exp (-(rf * t ^ 2)) * (H / S) ^ (2 * mu rd rf σ + 2) := by
      simp only [rpow_def_of_pos hHS]
      rw [← exp_add, ← exp_add, ← exp_add]; congr 1; ring
    rw [hy, hx']
    linear_combination (-(φ * S * N (η * (((rd - rf - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S)
      + (σ * t) ^ 2 - log (K / S)) / (σ * t))))) * he
  · rw [payoff_int φ η (log (H / S)) ((rd - rf - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S))
      ((H / S) ^ (2 * mu rd rf σ)) S K (σ * t) _ hv hs hη]
    unfold blockD
    have hx' : y2 S H rd rf σ (t ^ 2)
        = ((rd - rf - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S) + (σ * t) ^ 2 - log (H / S))
          / (σ * t) := by
      unfold y2 mu; rw [hsq]; field_simp; ring
    have hy : η * (y2 S H rd rf σ (t ^ 2) - σ * √(t ^ 2))
        = η * (((rd - rf - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S) - log (H / S)) / (σ * t)) := by
      rw [hsq, hx']; field_simp; ring
    have he : exp (-(rd * t ^ 2)) * (H / S) ^ (2 * mu rd rf σ)
          * exp ((rd - rf - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S) + (σ * t) ^ 2 / 2)
        = exp (-(rf * t ^ 2)) * (H / S) ^ (2 * mu rd rf σ + 2) := by
      simp only [rpow_def_of_pos hHS]
      rw [← exp_add, ← exp_add, ← exp_add]; congr 1; ring
    rw [hy, hx']
    linear_combination (-(φ * S * N (η * (((rd - rf - σ ^ 2 / 2) * t ^ 2 + 2 * log (H / S)
      + (σ * t) ^ 2 - log (H / S)) / (σ * t))))) * he

lemma f_integrable_parts (φ c S K rd rf σ T sh : ℝ) (hσ : 0 < σ) (hT : 0 < T) :
    Integrable (fun u => φ * (S * exp u - K) * (c * f rd rf σ T (u - sh))) := by
  have hs : 0 < σ * √T := mul_pos hσ (Real.sqrt_pos.2 hT)
  have hv : ((σ ^ 2 * T).toNNReal : ℝ) = (σ * √T) ^ 2 := by
    rw [Real.coe_toNNReal _ (by positivity), mul_pow, Real.sq_sqrt hT.le]
  simp only [f, gaussianPDFReal_sub]
  exact payoff_integrable φ c _ S K _ _ hv hs

#print axioms blocks_as_integrals
#print axioms f_integrable_parts

lemma pdf_eq (x : ℝ) : gaussianPDFReal 0 1 x = (√(2 * π))⁻¹ * exp (-x ^ 2 / 2) := by
  simp [gaussianPDFReal]

lemma pdf_continuous : Continuous (gaussianPDFReal 0 1) := by
  rw [gaussianPDFReal_def]; fun_prop

lemma N_eq_integral (x : ℝ) : N x = ∫ t in Set.Iic x, gaussianPDFReal 0 1 t := by
  unfold N
  rw [cdf_eq_real, measureReal_def, gaussianReal_apply_eq_integral _ one_ne_zero,
    ENNReal.toReal_ofReal]
  exact setIntegral_nonneg measurableSet_Iic (fun t _ => gaussianPDFReal_nonneg _ _ _)

lemma N_sub (a b : ℝ) : N b - N a = ∫ t in a..b, gaussianPDFReal 0 1 t := by
  rw [N_eq_integral, N_eq_integral]
  exact intervalIntegral.integral_Iic_sub_Iic (integrable_gaussianPDFReal 0 1).integrableOn
    (integrable_gaussianPDFReal 0 1).integrableOn

lemma N_hasDerivAt (x : ℝ) : HasDerivAt N (gaussianPDFReal 0 1 x) x := by
  have h : N = fun y => N 0 + ∫ t in (0:ℝ)..y, gaussianPDFReal 0 1 t := by
    funext y; rw [← N_sub]; ring
  rw [h]
  exact (intervalIntegral.integral_hasDerivAt_right (pdf_continuous.intervalIntegrable _ _)
    (pdf_continuous.stronglyMeasurableAtFilter _ _) pdf_continuous.continuousAt).const_add _

lemma lin_hasDerivAt (c d σ t : ℝ) (hσ : 0 < σ) (ht : 0 < t) :
    HasDerivAt (fun t => c / (σ * √t) + d * (σ * √t))
      ((d * (σ * √t) - c / (σ * √t)) / (2 * t)) t := by
  have hs : HasDerivAt (fun t => σ * √t) (σ * (1 / (2 * √t))) t :=
    (Real.hasDerivAt_sqrt ht.ne').const_mul σ
  have hpos : σ * √t ≠ 0 := (mul_pos hσ (Real.sqrt_pos.2 ht)).ne'
  have h := ((hasDerivAt_const t c).div hs hpos).add (hs.const_mul d)
  convert h using 1
  obtain ⟨u, hu, rfl⟩ : ∃ u, 0 < u ∧ t = u ^ 2 :=
    ⟨√t, Real.sqrt_pos.2 ht, (Real.sq_sqrt ht.le).symm⟩
  rw [Real.sqrt_sq hu.le]
  have := hu.ne'
  have := hσ.ne'
  field_simp
  ring

open Filter Topology in
lemma tendsto_lin (c d σ : ℝ) (hc : c < 0) (hσ : 0 < σ) :
    Tendsto (fun t => c / (σ * √t) + d * (σ * √t)) (𝓝[>] 0) atBot := by
  have h0 : Tendsto (fun t : ℝ => σ * √t) (𝓝[>] 0) (𝓝 0) := by
    have : Tendsto (fun t : ℝ => σ * √t) (𝓝 0) (𝓝 (σ * √0)) :=
      (continuous_const.mul Real.continuous_sqrt).tendsto 0
    rw [Real.sqrt_zero, mul_zero] at this
    exact this.mono_left nhdsWithin_le_nhds
  have h1 : Tendsto (fun t : ℝ => σ * √t) (𝓝[>] 0) (𝓝[>] 0) := by
    apply tendsto_nhdsWithin_of_tendsto_nhds_of_eventually_within _ h0
    filter_upwards [self_mem_nhdsWithin] with t ht
    exact mul_pos hσ (Real.sqrt_pos.2 ht)
  have h2 : Tendsto (fun t : ℝ => (σ * √t)⁻¹) (𝓝[>] 0) atTop := tendsto_inv_nhdsGT_zero.comp h1
  have h3 : Tendsto (fun t : ℝ => c * (σ * √t)⁻¹) (𝓝[>] 0) atBot :=
    h2.const_mul_atTop_of_neg hc
  have h4 : Tendsto (fun t : ℝ => d * (σ * √t)) (𝓝[>] 0) (𝓝 (d * 0)) := h0.const_mul d
  exact (h3.atBot_add h4).congr fun t => by rw [div_eq_mul_inv]

lemma expo_id (η b μ l ν σ rd u : ℝ) (hη : η ^ 2 = 1) (hσ : σ ≠ 0) (hu : u ≠ 0)
    (hrd : rd = (l ^ 2 - μ ^ 2) * σ ^ 2 / 2) (hν : ν = μ * σ ^ 2) (e : ℝ) (he : e = 1 ∨ e = -1) :
    b * (μ + e * l) + -(η * b / (σ * u) + e * (η * l) * (σ * u)) ^ 2 / 2
      = -(rd * u ^ 2) + -(b - ν * u ^ 2) ^ 2 / (2 * σ ^ 2 * u ^ 2) := by
  have he2 : e ^ 2 = 1 := by rcases he with rfl | rfl <;> norm_num
  have : (η * b / (σ * u) + e * (η * l) * (σ * u)) ^ 2
      = η ^ 2 * (b / (σ * u)) ^ 2 + 2 * η ^ 2 * e * b * l + η ^ 2 * e ^ 2 * l ^ 2 * (σ * u) ^ 2 := by
    field_simp
    ring
  rw [this, hη, he2, hrd, hν]
  field_simp
  ring

lemma deriv_alg (η b μ l ν σ rd x : ℝ) (hη : η = 1 ∨ η = -1) (hb : η * b < 0) (hσ : 0 < σ)
    (hx : 0 < x) (hrd : rd = (l ^ 2 - μ ^ 2) * σ ^ 2 / 2) (hν : ν = μ * σ ^ 2) :
    exp (b * (μ + l)) * (gaussianPDFReal 0 1 (η * b / (σ * √x) + η * l * (σ * √x))
        * ((η * l * (σ * √x) - η * b / (σ * √x)) / (2 * x)))
      + exp (b * (μ - l)) * (gaussianPDFReal 0 1 (η * b / (σ * √x) + -(η * l) * (σ * √x))
        * ((-(η * l) * (σ * √x) - η * b / (σ * √x)) / (2 * x)))
      = exp (-(rd * x)) * (|b| / (σ * √(2 * π * x ^ 3)) * exp (-(b - ν * x) ^ 2 / (2 * σ ^ 2 * x))) := by
  obtain ⟨u, hu, rfl⟩ : ∃ u, 0 < u ∧ x = u ^ 2 :=
    ⟨√x, Real.sqrt_pos.2 hx, (Real.sq_sqrt hx.le).symm⟩
  have hη2 : η ^ 2 = 1 := by rcases hη with rfl | rfl <;> norm_num
  have habs : |b| = -(η * b) := by
    rcases hη with rfl | rfl
    · rw [abs_of_neg (by linarith)]; ring
    · rw [abs_of_pos (by linarith)]; ring
  have hsq : √(2 * π * (u ^ 2) ^ 3) = √(2 * π) * u ^ 3 := by
    rw [show (u ^ 2) ^ 3 = (u ^ 3) ^ 2 by ring, Real.sqrt_mul (by positivity),
      Real.sqrt_sq (by positivity)]
  rw [Real.sqrt_sq hu.le, hsq, habs, pdf_eq, pdf_eq]
  have e1 : exp (b * (μ + l)) * exp (-(η * b / (σ * u) + η * l * (σ * u)) ^ 2 / 2)
      = exp (-(rd * u ^ 2)) * exp (-(b - ν * u ^ 2) ^ 2 / (2 * σ ^ 2 * u ^ 2)) := by
    rw [← exp_add, ← exp_add]
    congr 1
    have := expo_id η b μ l ν σ rd u hη2 hσ.ne' hu.ne' hrd hν 1 (Or.inl rfl)
    simpa only [one_mul] using this
  have e2 : exp (b * (μ - l)) * exp (-(η * b / (σ * u) + -(η * l) * (σ * u)) ^ 2 / 2)
      = exp (-(rd * u ^ 2)) * exp (-(b - ν * u ^ 2) ^ 2 / (2 * σ ^ 2 * u ^ 2)) := by
    rw [← exp_add, ← exp_add]
    congr 1
    have := expo_id η b μ l ν σ rd u hη2 hσ.ne' hu.ne' hrd hν (-1) (Or.inr rfl)
    simpa only [neg_one_mul, neg_mul, one_mul, ← sub_eq_add_neg] using this
  have hu0 := hu.ne'
  have hσ0 := hσ.ne'
  have hpi : √(2 * π) ≠ 0 := (Real.sqrt_pos.2 (by positivity)).ne'
  linear_combination ((√(2 * π))⁻¹ * ((η * l * (σ * u) - η * b / (σ * u)) / (2 * u ^ 2)))
      * e1 + ((√(2 * π))⁻¹ * ((-(η * l) * (σ * u) - η * b / (σ * u)) / (2 * u ^ 2))) * e2

open Filter Topology in
lemma rebate_core (η b μ l ν σ rd T : ℝ) (hη : η = 1 ∨ η = -1) (hb : η * b < 0)
    (hσ : 0 < σ) (hT : 0 < T) (hrd : rd = (l ^ 2 - μ ^ 2) * σ ^ 2 / 2) (hν : ν = μ * σ ^ 2) :
    ∫ t in Ioc (0 : ℝ) T, exp (-(rd * t))
        * (|b| / (σ * √(2 * π * t ^ 3)) * exp (-(b - ν * t) ^ 2 / (2 * σ ^ 2 * t)))
      = exp (b * (μ + l)) * N (η * b / (σ * √T) + η * l * (σ * √T))
        + exp (b * (μ - l)) * N (η * b / (σ * √T) + -(η * l) * (σ * √T)) := by
  set g : ℝ → ℝ := fun t => exp (-(rd * t))
        * (|b| / (σ * √(2 * π * t ^ 3)) * exp (-(b - ν * t) ^ 2 / (2 * σ ^ 2 * t))) with hg
  set G : ℝ → ℝ := fun t => exp (b * (μ + l)) * N (η * b / (σ * √t) + η * l * (σ * √t))
        + exp (b * (μ - l)) * N (η * b / (σ * √t) + -(η * l) * (σ * √t)) with hG
  have hderiv : ∀ x, 0 < x → HasDerivAt G (g x) x := by
    intro x hx
    have hd1 := (N_hasDerivAt (η * b / (σ * √x) + η * l * (σ * √x))).comp x
      (lin_hasDerivAt (η * b) (η * l) σ x hσ hx)
    have hd2 := (N_hasDerivAt (η * b / (σ * √x) + -(η * l) * (σ * √x))).comp x
      (lin_hasDerivAt (η * b) (-(η * l)) σ x hσ hx)
    exact ((hd1.const_mul (exp (b * (μ + l)))).add (hd2.const_mul (exp (b * (μ - l))))).congr_deriv
      (deriv_alg η b μ l ν σ rd x hη hb hσ hx hrd hν)
  have hG0 : Tendsto G (𝓝[>] 0) (𝓝 0) := by
    have t1 := (tendsto_cdf_atBot (μ := gaussianReal 0 1)).comp (tendsto_lin (η * b) (η * l) σ hb hσ)
    have t2 := (tendsto_cdf_atBot (μ := gaussianReal 0 1)).comp
      (tendsto_lin (η * b) (-(η * l)) σ hb hσ)
    have := (t1.const_mul (exp (b * (μ + l)))).add (t2.const_mul (exp (b * (μ - l))))
    simp only [mul_zero, add_zero] at this
    exact this
  classical
  set F : ℝ → ℝ := Function.update G 0 0 with hF
  have hcont : ContinuousOn F (Icc 0 T) := by
    intro t ht
    rcases eq_or_lt_of_le ht.1 with h0 | hpos
    · subst h0
      rw [hF, continuousWithinAt_update_same]
      exact hG0.mono_left (nhdsWithin_mono _
        (fun x hx => lt_of_le_of_ne hx.1.1 (fun h => hx.2 h.symm)))
    · rw [hF, continuousWithinAt_update_of_ne hpos.ne']
      exact (hderiv t hpos).continuousAt.continuousWithinAt
  have hderivF : ∀ x ∈ Ioo 0 T, HasDerivAt F (g x) x := by
    intro x hx
    refine (hderiv x hx.1).congr_of_eventuallyEq ?_
    filter_upwards [lt_mem_nhds hx.1] with y hy
    rw [hF, Function.update_of_ne hy.ne']
  have hnn : ∀ x ∈ Ioo 0 T, 0 ≤ g x := by
    intro x _
    exact mul_nonneg (exp_pos _).le (mul_nonneg (div_nonneg (abs_nonneg _)
      (mul_nonneg hσ.le (Real.sqrt_nonneg _))) (exp_pos _).le)
  have hint : IntervalIntegrable g volume 0 T :=
    (intervalIntegrable_iff_integrableOn_Ioc_of_le hT.le).2
      (intervalIntegral.integrableOn_deriv_of_nonneg hcont hderivF hnn)
  rw [← intervalIntegral.integral_of_le hT.le,
    intervalIntegral.integral_eq_sub_of_hasDerivAt_of_le hT.le hcont hderivF hint, hF,
    Function.update_self, Function.update_of_ne hT.ne', sub_zero]

#print axioms pdf_eq
#print axioms pdf_continuous
#print axioms N_eq_integral
#print axioms N_sub
#print axioms N_hasDerivAt
#print axioms lin_hasDerivAt
#print axioms tendsto_lin
#print axioms expo_id
#print axioms deriv_alg
#print axioms rebate_core

/-- **The eight single barriers in one table** (the boxed claim; Why it works, Steps 0 to 4).
In the Garman-Kohlhagen model, take today's rate `S > 0`, strike `K > 0`, wall `H > 0`, any
dollar and euro rates `r_d`, `r_f`, volatility `σ > 0` and `T > 0` years. Take the call-put
switch `φ = ±1` and the wall switch `η = ±1`, with today's rate on the live side of the wall
(`S > H` for a wall below, `S < H` for a wall above). Write `b = ln(H/S)`.
A knock-out is worth `e^{-r_d T}` times its payoff `max(φ(S e^u - K), 0)` integrated, over the
live side `ηu > ηb` of the wall, against the density of paths that never touched: the plain bell
curve minus the mirror weight `(H/S)^{2μ}` times the bell curve shifted by `2b`. Then:
* every knock-out equals its entry in the table, a sum of blocks A to D; and
* every knock-in, priced as the plain option minus its knock-out, equals its entry in the
  table, where the plain option is its payoff integrated against the plain bell curve. -/
theorem eight_barriers_from_blocks
    (φ η S K H rd rf σ T : ℝ) (hφ : φ = 1 ∨ φ = -1) (hη : η = 1 ∨ η = -1)
    (hS : 0 < S) (hK : 0 < K) (hH : 0 < H) (hσ : 0 < σ) (hT : 0 < T)
    (hlive : 0 < η * (S - H)) :
    let b : ℝ := log (H / S)
    let payoff : ℝ → ℝ := fun u => max (φ * (S * exp u - K)) 0
    let plain : ℝ := exp (-(rd * T)) * ∫ u, payoff u * f rd rf σ T u
    let knockOut : ℝ := exp (-(rd * T)) * ∫ u in {u : ℝ | η * b < η * u},
        payoff u * (f rd rf σ T u - (H / S) ^ (2 * mu rd rf σ) * f rd rf σ T (u - 2 * b))
    let A := blockA φ S K rd rf σ T
    let B := blockB φ S K H rd rf σ T
    let C := blockC φ η S K H rd rf σ T
    let D := blockD φ η S K H rd rf σ T
    knockOut = knockOutRecipe φ η K H A B C D ∧
    plain - knockOut = knockInRecipe φ η K H A B C D := by
  intro b payoff plain knockOut A B C D
  obtain ⟨hA, hB, hC, hD⟩ := blocks_as_integrals φ η S K H rd rf σ T hφ hη hS hK hH hσ hT
  set c : ℝ := (H / S) ^ (2 * mu rd rf σ) with hc
  set k : ℝ := log (K / S) with hk
  set p : ℝ → ℝ := fun u => φ * (S * exp u - K) * f rd rf σ T u with hp
  set q : ℝ → ℝ := fun u => φ * (S * exp u - K) * (c * f rd rf σ T (u - 2 * b)) with hq
  have hpi : Integrable p := by
    have := f_integrable_parts φ 1 S K rd rf σ T 0 hσ hT
    simpa only [sub_zero, one_mul] using this
  have hqi : Integrable q := f_integrable_parts φ c S K rd rf σ T (2 * b) hσ hT
  have hmeas : MeasurableSet {u : ℝ | φ * k < φ * u} :=
    measurableSet_lt (by fun_prop) (by fun_prop)
  have hbk : (b ≤ k ↔ H ≤ K) := by
    rw [Real.log_le_log_iff (div_pos hH hS) (div_pos hK hS), div_le_div_iff_of_pos_right hS]
  have hout : knockOut = knockOutRecipe φ η K H A B C D := by
    have hfun : (fun u => payoff u * (f rd rf σ T u - c * f rd rf σ T (u - 2 * b)))
        = {u : ℝ | φ * k < φ * u}.indicator (fun u => p u - q u) := by
      funext u
      simp only [payoff, hp, hq]
      rw [max_payoff φ S K u hφ hS hK]
      by_cases h : u ∈ {u : ℝ | φ * k < φ * u}
      · rw [indicator_of_mem h, indicator_of_mem h]; ring
      · rw [indicator_of_notMem h, indicator_of_notMem h]; ring
    simp only [knockOut]
    rw [hfun, setIntegral_indicator hmeas, region_int p q hpi hqi φ η b k hφ hη,
      recipe_mul _ φ η k b K H _ _ _ _ hbk]
    simp only [A, B, C, D]
    rw [hA, hB, hC, hD]
  have hplain : plain = A := by
    have hfun : (fun u => payoff u * f rd rf σ T u) = {u : ℝ | φ * k < φ * u}.indicator p := by
      funext u
      simp only [payoff, hp]
      rw [max_payoff φ S K u hφ hS hK]
      by_cases h : u ∈ {u : ℝ | φ * k < φ * u}
      · rw [indicator_of_mem h, indicator_of_mem h]
      · rw [indicator_of_notMem h, indicator_of_notMem h]; ring
    simp only [plain]
    rw [hfun, integral_indicator hmeas]
    simp only [A]
    rw [hA]
  refine ⟨hout, ?_⟩
  rw [hout, hplain]
  linarith [in_add_out φ η K H A B C D]

/-- **In plus out is the plain option, in every model** (Step 1). Take any pricing world: paths
`Ω` with a pricing measure `Q`, the rate `X t ω` at each time `t` on each path `ω`, a strike `K`,
a wall `H`, an expiry `T`, a dollar rate `r_d`, the call-put switch `φ` and the wall switch `η`.
A path touches the wall when `η X_t ≤ η H` at some time `t` in `[0, T]` (a trade exactly at the
wall is a touch). The knock-in pays `max(φ(X_T - K), 0)` on touched paths, the knock-out pays it
on the others, and each is priced as its discounted average payoff. Then knock-in plus
knock-out is the plain option. The only requirement is that "touched" is an event of the
model (a measurable set); rebates are left out, as the card says. -/
theorem knock_in_add_knock_out_eq_plain
    {Ω : Type*} [MeasurableSpace Ω] (Q : Measure Ω) (X : ℝ → Ω → ℝ) (φ η K H T rd : ℝ)
    (h_event : MeasurableSet {ω | ∃ t ∈ Icc (0 : ℝ) T, η * X t ω ≤ η * H}) :
    let touched : Set Ω := {ω | ∃ t ∈ Icc (0 : ℝ) T, η * X t ω ≤ η * H}
    let payoff : Ω → ENNReal := fun ω => ENNReal.ofReal (max (φ * (X T ω - K)) 0)
    let disc : ENNReal := ENNReal.ofReal (exp (-(rd * T)))
    disc * ∫⁻ ω, touched.indicator payoff ω ∂Q
      + disc * ∫⁻ ω, touchedᶜ.indicator payoff ω ∂Q
      = disc * ∫⁻ ω, payoff ω ∂Q := by
  intro touched payoff disc
  rw [← mul_add, lintegral_indicator h_event, lintegral_indicator h_event.compl,
    lintegral_add_compl _ h_event]

/-- **The rebate paid at the touch is block F** (Step 5). Let log EURUSD drift at
`ν = r_d - r_f - σ²/2` with volatility `σ > 0`, and let the wall sit at `b = ln(H/S) ≠ 0` on the
`η` side (`η = 1` with `H < S`, or `η = -1` with `S < H`). The first time the log rate touches
`b` has density `|b| / (σ √(2π t³)) · exp(-(b - νt)² / (2σ²t))` at `t > 0`. A rebate `R` paid at
the touch, discounted at `r_d` from its own touch date, up to expiry `T > 0`, is worth block F.
The exponent `λ = √(μ² + 2r_d/σ²)` must be a real number, so its radicand is not negative. -/
theorem rebate_at_touch_eq_blockF
    (η R S H rd rf σ T : ℝ) (hη : η = 1 ∨ η = -1)
    (hS : 0 < S) (hH : 0 < H) (hσ : 0 < σ) (hT : 0 < T) (hlive : 0 < η * (S - H))
    (hlam : 0 ≤ mu rd rf σ ^ 2 + 2 * rd / σ ^ 2) :
    let b : ℝ := log (H / S)
    let ν : ℝ := rd - rf - σ ^ 2 / 2
    R * ∫ t in Ioc (0 : ℝ) T, exp (-(rd * t))
        * (|b| / (σ * √(2 * π * t ^ 3)) * exp (-(b - ν * t) ^ 2 / (2 * σ ^ 2 * t)))
      = blockF η R S H rd rf σ T := by
  dsimp only
  have hHS : 0 < H / S := div_pos hH hS
  have hb : η * log (H / S) < 0 := by
    rcases hη with rfl | rfl
    · rw [one_mul]
      exact Real.log_neg hHS ((div_lt_one hS).2 (by linarith))
    · have : 0 < log (H / S) := Real.log_pos ((one_lt_div hS).2 (by linarith))
      linarith
  have hl2 : lam rd rf σ ^ 2 = mu rd rf σ ^ 2 + 2 * rd / σ ^ 2 := Real.sq_sqrt hlam
  have hrd : rd = (lam rd rf σ ^ 2 - mu rd rf σ ^ 2) * σ ^ 2 / 2 := by
    rw [hl2]; field_simp; ring
  have hν : rd - rf - σ ^ 2 / 2 = mu rd rf σ * σ ^ 2 := by
    unfold mu; field_simp
  rw [rebate_core η (log (H / S)) (mu rd rf σ) (lam rd rf σ) (rd - rf - σ ^ 2 / 2) σ rd T hη hb
    hσ hT hrd hν]
  unfold blockF z
  rw [rpow_def_of_pos hHS, rpow_def_of_pos hHS,
    show ∀ X Y Z : ℝ, η * (X / Y + Z * Y) = η * X / Y + η * Z * Y by intros; ring,
    show ∀ X Y Z : ℝ, η * (X / Y + Z * Y - 2 * Z * Y) = η * X / Y + -(η * Z) * Y by intros; ring]

-- House market: r_d = 5%, r_f = 3%, σ = 10%, so μ = (0.05 - 0.03 - 0.005) / 0.01 = 3/2.
example : mu (5 / 100) (3 / 100) (1 / 10) = 3 / 2 := by
  unfold mu; norm_num
-- λ = √(2.25 + 0.10/0.01) = √(49/4) = 7/2.
example : mu (5 / 100) (3 / 100) (1 / 10) ^ 2 + 2 * (5 / 100) / (1 / 10) ^ 2 = 49 / 4 := by
  unfold mu; norm_num
example : lam (5 / 100) (3 / 100) (1 / 10) = 7 / 2 := by
  unfold lam mu
  rw [show (((5 : ℝ) / 100 - 3 / 100 - (1 / 10) ^ 2 / 2) / (1 / 10) ^ 2) ^ 2
      + 2 * (5 / 100) / (1 / 10) ^ 2 = (7 / 2) ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
-- Mirror exponents: 2μ = 3, 2μ + 2 = 5, μ + λ = 5, μ - λ = -2.
example : 2 * ((3 : ℚ) / 2) = 3 ∧ 2 * ((3 : ℚ) / 2) + 2 = 5 ∧
    (3 : ℚ) / 2 + 7 / 2 = 5 ∧ (3 : ℚ) / 2 - 7 / 2 = -2 := by norm_num
-- Wall 1.20, spot 1.10: mirror weights (12/11)^3 and (12/11)^5, and H²/(SK) = 1.44/1.21.
example : ((6 : ℚ) / 5 / (11 / 10)) ^ 3 = 1728 / 1331 := by norm_num
example : ((6 : ℚ) / 5 / (11 / 10)) ^ 5 = 248832 / 161051 := by norm_num
example : ((6 : ℚ) / 5) ^ 2 / (11 / 10 * (11 / 10)) = 144 / 121 := by norm_num
-- The reverse knock-out pays at most the gap 1.20 - 1.10 = 10 cents; at 1.175 it pays 7.50 cents.
example : 100 * ((6 : ℚ) / 5 - 11 / 10) = 10 := by norm_num
example : 100 * ((47 : ℚ) / 40 - 11 / 10) = 15 / 2 := by norm_num
-- Three switches give 2 × 2 × 2 = 8 types; each with the strike on either side is 16 cases.
example : Fintype.card (Bool × Bool × Bool) = 8 := by decide
example : Fintype.card (Bool × Bool × Bool × Bool) = 16 := by decide
-- In-plus-out parity is built into the table: in every row pair, in plus out is A.
example (φ η K H A B C D : ℝ) :
    knockInRecipe φ η K H A B C D + knockOutRecipe φ η K H A B C D = A := by
  unfold knockInRecipe knockOutRecipe
  split_ifs <;> ring

#print axioms eight_barriers_from_blocks
#print axioms knock_in_add_knock_out_eq_plain
#print axioms rebate_at_touch_eq_blockF

end EightBarriers
