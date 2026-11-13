-- Parseval's identity: for every signal on one cycle (−π, π] whose square has a finite integral, the energy (1/π)∫f² equals a₀²/2 plus the sum of aₙ² + bₙ² over all harmonics; after N harmonics the energy is the ledger so far plus the leftover's energy; and the sawtooth f(x) = x turns the balance into 1 + 1/4 + 1/9 + ⋯ = π²/6.
import Mathlib.MeasureTheory.Function.LpSpace.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Analysis.Fourier.AddCircle
import Mathlib.NumberTheory.ZetaValues
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic

/-! Setting, in the card's notation.
* A signal is a function `f : ℝ → ℝ`; one cycle is the phase range from `−π` to `π`.
* "Finite energy" is `MemLp f 2` on `(−π, π]`: `f` is measurable and `∫ f²` over a cycle is finite.
* `cosAmount f n` is the card's `aₙ = (1/π) ∫_{−π}^{π} f(x) cos(nx) dx`.
* `sinAmount f n` is the card's `bₙ = (1/π) ∫_{−π}^{π} f(x) sin(nx) dx`.
* `energy f` is the card's `E = (1/π) ∫_{−π}^{π} f(x)² dx`.
* `partialSum f N x` is the card's `S_N(x) = a₀/2 + ∑_{n=1}^{N} (aₙ cos nx + bₙ sin nx)`. -/

open Real MeasureTheory Finset

namespace ParsevalCard

/-- The cosine amount of harmonic `n`: `aₙ = (1/π) ∫_{−π}^{π} f(x) cos(nx) dx`. -/
noncomputable def cosAmount (f : ℝ → ℝ) (n : ℕ) : ℝ :=
  (1 / π) * ∫ x in (-π)..π, f x * cos (n * x)

/-- The sine amount of harmonic `n`: `bₙ = (1/π) ∫_{−π}^{π} f(x) sin(nx) dx`. -/
noncomputable def sinAmount (f : ℝ → ℝ) (n : ℕ) : ℝ :=
  (1 / π) * ∫ x in (-π)..π, f x * sin (n * x)

/-- The energy of a signal: the integral of its square over one cycle, divided by π. -/
noncomputable def energy (f : ℝ → ℝ) : ℝ :=
  (1 / π) * ∫ x in (-π)..π, f x ^ 2

/-- The series cut after harmonic `N`: `S_N(x) = a₀/2 + ∑_{n=1}^{N} (aₙ cos nx + bₙ sin nx)`. -/
noncomputable def partialSum (f : ℝ → ℝ) (N : ℕ) (x : ℝ) : ℝ :=
  cosAmount f 0 / 2 + ∑ n ∈ Icc 1 N, (cosAmount f n * cos (n * x) + sinAmount f n * sin (n * x))

/-! Helper lemmas for the proofs below. -/

lemma integral_odd_eq_zero (g : ℝ → ℝ) (hg : ∀ x, g (-x) = -g x) :
    ∫ x in (-π)..π, g x = 0 := by
  have h := intervalIntegral.integral_comp_neg (a := -π) (b := π) g
  simp only [neg_neg, hg, intervalIntegral.integral_neg] at h
  linarith

lemma integral_cos_int (k : ℤ) :
    ∫ x in (-π)..π, cos (k * x) = if k = 0 then 2 * π else 0 := by
  split_ifs with hk
  · subst hk; simp; ring
  · have hk' : (k : ℝ) ≠ 0 := by exact_mod_cast hk
    rw [intervalIntegral.integral_comp_mul_left (fun x => cos x) hk', integral_cos]
    simp [mul_neg, sin_neg, sin_int_mul_pi]

lemma integral_cos_nat (m : ℕ) (hm : 1 ≤ m) : ∫ x in (-π)..π, cos (m * x) = 0 := by
  simp [show m ≠ 0 by omega]

lemma integral_sin_nat (m : ℕ) : ∫ x in (-π)..π, sin (m * x) = 0 :=
  integral_odd_eq_zero _ (fun x => by simp [sin_neg])

lemma integral_cos_mul_cos (m n : ℕ) (hm : 1 ≤ m) (hn : 1 ≤ n) :
    ∫ x in (-π)..π, cos (m * x) * cos (n * x) = if m = n then π else 0 := by
  have h : ∀ x : ℝ, cos (m * x) * cos (n * x) =
      (cos (((m - n : ℤ) : ℝ) * x) + cos (((m + n : ℤ) : ℝ) * x)) / 2 := by
    intro x; push_cast; rw [sub_mul, add_mul, cos_sub, cos_add]; ring
  simp_rw [h]
  rw [intervalIntegral.integral_div, intervalIntegral.integral_add
    ((by fun_prop : Continuous fun x : ℝ => cos (((m - n : ℤ) : ℝ) * x)).intervalIntegrable _ _)
    ((by fun_prop : Continuous fun x : ℝ => cos (((m + n : ℤ) : ℝ) * x)).intervalIntegrable _ _),
    integral_cos_int, integral_cos_int]
  have h2 : ((m : ℤ) + n) ≠ 0 := by omega
  by_cases hmn : m = n
  · subst hmn
    have hm0 : m ≠ 0 := by omega
    simp [hm0]
  · have h1 : ((m : ℤ) - n) ≠ 0 := by omega
    simp [h1, h2, hmn]

lemma integral_sin_mul_sin (m n : ℕ) (hm : 1 ≤ m) (hn : 1 ≤ n) :
    ∫ x in (-π)..π, sin (m * x) * sin (n * x) = if m = n then π else 0 := by
  have h : ∀ x : ℝ, sin (m * x) * sin (n * x) =
      (cos (((m - n : ℤ) : ℝ) * x) - cos (((m + n : ℤ) : ℝ) * x)) / 2 := by
    intro x; push_cast; rw [sub_mul, add_mul, cos_sub, cos_add]; ring
  simp_rw [h]
  rw [intervalIntegral.integral_div, intervalIntegral.integral_sub
    ((by fun_prop : Continuous fun x : ℝ => cos (((m - n : ℤ) : ℝ) * x)).intervalIntegrable _ _)
    ((by fun_prop : Continuous fun x : ℝ => cos (((m + n : ℤ) : ℝ) * x)).intervalIntegrable _ _),
    integral_cos_int, integral_cos_int]
  have h2 : ((m : ℤ) + n) ≠ 0 := by omega
  by_cases hmn : m = n
  · subst hmn
    have hm0 : m ≠ 0 := by omega
    simp [hm0]
  · have h1 : ((m : ℤ) - n) ≠ 0 := by omega
    simp [h1, h2, hmn]

lemma integral_cos_mul_sin (m n : ℕ) : ∫ x in (-π)..π, cos (m * x) * sin (n * x) = 0 :=
  integral_odd_eq_zero _ (fun x => by simp [sin_neg, cos_neg])

lemma integral_sin_mul_cos (m n : ℕ) : ∫ x in (-π)..π, sin (m * x) * cos (n * x) = 0 :=
  integral_odd_eq_zero _ (fun x => by simp [sin_neg, cos_neg])

lemma integral_mul_partialSum (f g : ℝ → ℝ) (N : ℕ)
    (h0 : IntervalIntegrable g volume (-π) π)
    (hc : ∀ n : ℕ, IntervalIntegrable (fun x => g x * cos (n * x)) volume (-π) π)
    (hs : ∀ n : ℕ, IntervalIntegrable (fun x => g x * sin (n * x)) volume (-π) π) :
    ∫ x in (-π)..π, g x * partialSum f N x =
      cosAmount f 0 / 2 * (∫ x in (-π)..π, g x) +
      ∑ n ∈ Icc 1 N, (cosAmount f n * (∫ x in (-π)..π, g x * cos (n * x)) +
        sinAmount f n * ∫ x in (-π)..π, g x * sin (n * x)) := by
  have e : ∀ x, g x * partialSum f N x = cosAmount f 0 / 2 * g x +
      ∑ n ∈ Icc 1 N, (cosAmount f n * (g x * cos (n * x)) + sinAmount f n * (g x * sin (n * x))) := by
    intro x
    simp only [partialSum, mul_add, Finset.mul_sum]
    congr 1
    · ring
    · apply sum_congr rfl; intros; ring
  simp_rw [e]
  have hsum : IntervalIntegrable (fun x => ∑ n ∈ Icc 1 N,
      (cosAmount f n * (g x * cos (n * x)) + sinAmount f n * (g x * sin (n * x)))) volume (-π) π := by
    have := IntervalIntegrable.sum (Icc 1 N)
      (f := fun n x => cosAmount f n * (g x * cos (n * x)) + sinAmount f n * (g x * sin (n * x)))
      (fun n _ => ((hc n).const_mul _).add ((hs n).const_mul _))
    convert this using 1
    ext x
    simp [Finset.sum_apply]
  rw [intervalIntegral.integral_add (h0.const_mul _) hsum,
    intervalIntegral.integral_const_mul,
    intervalIntegral.integral_finsetSum fun n _ => ((hc n).const_mul _).add ((hs n).const_mul _)]
  congr 1
  apply sum_congr rfl
  intro n _
  rw [intervalIntegral.integral_add ((hc n).const_mul _) ((hs n).const_mul _),
    intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul]

lemma intervalIntegrable_of_memLp (f : ℝ → ℝ)
    (hf : MemLp f 2 (volume.restrict (Set.Ioc (-π) π))) {g : ℝ → ℝ} (hg : Continuous g) :
    IntervalIntegrable (fun x => f x * g x) volume (-π) π := by
  have hfI : IntegrableOn f (Set.Ioc (-π) π) := hf.integrable one_le_two
  rw [intervalIntegrable_iff_integrableOn_Ioc_of_le (by linarith [pi_pos])]
  exact hfI.mul_continuousOn_of_subset hg.continuousOn measurableSet_Ioc isCompact_Icc
    Set.Ioc_subset_Icc_self

lemma continuous_partialSum (f : ℝ → ℝ) (N : ℕ) : Continuous (partialSum f N) := by
  unfold partialSum; fun_prop

lemma fourierCoeffOn_real (f : ℝ → ℝ) (hf : MemLp f 2 (volume.restrict (Set.Ioc (-π) π)))
    (k : ℤ) :
    fourierCoeffOn (neg_lt_self pi_pos) (fun x => (f x : ℂ)) k =
      (((∫ x in (-π)..π, f x * cos (k * x)) / (2 * π) : ℝ) : ℂ) +
      ((-(∫ x in (-π)..π, f x * sin (k * x)) / (2 * π) : ℝ) : ℂ) * Complex.I := by
  rw [fourierCoeffOn_eq_integral]
  have e : ∀ x : ℝ, fourier (-k) (x : AddCircle (π - -π)) • ((f x : ℂ)) =
      ((f x * cos (k * x) : ℝ) : ℂ) - ((f x * sin (k * x) : ℝ) : ℂ) * Complex.I := by
    intro x
    rw [fourier_coe_apply, smul_eq_mul]
    have hpi : (π : ℂ) ≠ 0 := Complex.ofReal_ne_zero.mpr pi_ne_zero
    have : 2 * (π : ℂ) * Complex.I * ((-k : ℤ) : ℂ) * (x : ℂ) / ((π - -π : ℝ) : ℂ) =
        ((-(k * x) : ℝ) : ℂ) * Complex.I := by
      push_cast
      field_simp
      ring
    rw [this, Complex.exp_mul_I]
    push_cast
    simp only [Complex.cos_neg, Complex.sin_neg]
    ring
  simp_rw [e]
  have hc : IntervalIntegrable (fun x => f x * cos (k * x)) volume (-π) π :=
    intervalIntegrable_of_memLp f hf (by fun_prop)
  have hs : IntervalIntegrable (fun x => f x * sin (k * x)) volume (-π) π :=
    intervalIntegrable_of_memLp f hf (by fun_prop)
  have hc' : IntervalIntegrable (fun x => ((f x * cos (k * x) : ℝ) : ℂ)) volume (-π) π :=
    ⟨hc.1.ofReal, hc.2.ofReal⟩
  have hs' : IntervalIntegrable (fun x => ((f x * sin (k * x) : ℝ) : ℂ)) volume (-π) π :=
    ⟨hs.1.ofReal, hs.2.ofReal⟩
  rw [intervalIntegral.integral_sub hc' (hs'.mul_const _), intervalIntegral.integral_mul_const,
    intervalIntegral.integral_ofReal, intervalIntegral.integral_ofReal, Complex.real_smul]
  have hpi : (π : ℂ) ≠ 0 := Complex.ofReal_ne_zero.mpr pi_ne_zero
  push_cast
  field_simp
  ring

lemma integral_x_sin (n : ℕ) (hn : 1 ≤ n) :
    ∫ x in (-π)..π, x * sin (n * x) = 2 * π * (-1) ^ (n + 1) / n := by
  have hn' : (n : ℝ) ≠ 0 := by exact_mod_cast (by omega : n ≠ 0)
  have hd : ∀ x, HasDerivAt (fun x => -x * cos (n * x) / n + sin (n * x) / n ^ 2)
      (x * sin (n * x)) x := by
    intro x
    have h1 : HasDerivAt (fun x : ℝ => (n : ℝ) * x) n x := by
      simpa using (hasDerivAt_id x).const_mul (n : ℝ)
    have hc : HasDerivAt (fun x => cos (n * x)) (-sin (n * x) * n) x := h1.cos
    have hs : HasDerivAt (fun x => sin (n * x)) (cos (n * x) * n) x := h1.sin
    have := (((hasDerivAt_id' x).neg.mul hc).div_const (n : ℝ)).add (hs.div_const ((n : ℝ) ^ 2))
    convert this using 1
    simp only [Pi.neg_apply]
    field_simp
    ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt (fun x _ => hd x)
    ((by fun_prop : Continuous fun x : ℝ => x * sin (n * x)).intervalIntegrable _ _)]
  simp only [mul_neg, cos_neg, sin_neg, cos_nat_mul_pi, sin_nat_mul_pi]
  field_simp
  ring

/-- **Parseval's identity.** For every signal with finite energy on one cycle (its square has a
finite integral from −π to π), the squared amounts of all the harmonics add up, and the energy
equals half the constant term squared plus the squares of every cosine and sine amount:
`(1/π) ∫_{−π}^{π} f² = a₀²/2 + ∑_{n≥1} (aₙ² + bₙ²)`. Nothing is lost. -/
theorem energy_eq_sum_sq_coefficients (f : ℝ → ℝ)
    (hf : MemLp f 2 (volume.restrict (Set.Ioc (-π) π))) :
    Summable (fun n : ℕ => cosAmount f (n + 1) ^ 2 + sinAmount f (n + 1) ^ 2) ∧
      energy f = cosAmount f 0 ^ 2 / 2 +
        ∑' n : ℕ, (cosAmount f (n + 1) ^ 2 + sinAmount f (n + 1) ^ 2) := by
  have hab : -π < π := neg_lt_self pi_pos
  have hF : MemLp (fun x => (f x : ℂ)) 2 (volume.restrict (Set.Ioc (-π) π)) := hf.ofReal
  have H := hasSum_sq_fourierCoeffOn hab hF
  set c := fun i : ℤ => ‖fourierCoeffOn hab (fun x => (f x : ℂ)) i‖ ^ 2 with hc
  have hval : ((π - -π)⁻¹ • ∫ x in (-π)..π, ‖(f x : ℂ)‖ ^ 2) = energy f / 2 := by
    simp only [Complex.norm_real, Real.norm_eq_abs, sq_abs, smul_eq_mul, energy]
    field_simp
    ring
  rw [hval] at H
  have H2 := H.nat_add_neg
  have hterm : ∀ n : ℕ, c n + c (-(n : ℤ)) = (cosAmount f n ^ 2 + sinAmount f n ^ 2) / 2 := by
    intro n
    simp only [hc]
    rw [fourierCoeffOn_real f hf, fourierCoeffOn_real f hf, Complex.sq_norm, Complex.sq_norm,
      Complex.normSq_add_mul_I, Complex.normSq_add_mul_I]
    push_cast
    simp only [neg_mul, cos_neg, sin_neg, mul_neg, intervalIntegral.integral_neg, cosAmount,
      sinAmount]
    field_simp
    ring
  have hs0 : sinAmount f 0 = 0 := by simp [sinAmount]
  have hc0 : c 0 = cosAmount f 0 ^ 2 / 4 := by
    have := hterm 0
    simp only [Nat.cast_zero, neg_zero, hs0] at this
    linarith
  rw [hc0, funext hterm] at H2
  have H3 := ((hasSum_nat_add_iff' 1).mpr H2).mul_left 2
  simp only [Finset.range_one, Finset.sum_singleton, hs0] at H3
  have H4 : HasSum (fun n : ℕ => cosAmount f (n + 1) ^ 2 + sinAmount f (n + 1) ^ 2)
      (energy f - cosAmount f 0 ^ 2 / 2) := by
    convert H3 using 1
    · ext n; ring
    · ring
  refine ⟨H4.summable, ?_⟩
  rw [H4.tsum_eq]
  ring

/-- **The leftover is perpendicular to what was kept (Steps 1 and 2, Bessel).** For every
signal with finite energy and every number of harmonics `N`, the energy splits exactly into the
ledger so far, `a₀²/2 + ∑_{n=1}^{N} (aₙ² + bₙ²)`, plus the energy of the leftover `f − S_N`.
The leftover's energy is never negative, so the ledger never exceeds the energy. -/
theorem energy_eq_partial_ledger_add_leftover (f : ℝ → ℝ)
    (hf : MemLp f 2 (volume.restrict (Set.Ioc (-π) π))) (N : ℕ) :
    energy f = (cosAmount f 0 ^ 2 / 2 + ∑ n ∈ Icc 1 N, (cosAmount f n ^ 2 + sinAmount f n ^ 2)) +
        energy (fun x => f x - partialSum f N x) ∧
      cosAmount f 0 ^ 2 / 2 + ∑ n ∈ Icc 1 N, (cosAmount f n ^ 2 + sinAmount f n ^ 2) ≤ energy f := by
  set L := cosAmount f 0 ^ 2 / 2 + ∑ n ∈ Icc 1 N, (cosAmount f n ^ 2 + sinAmount f n ^ 2) with hL
  set S := partialSum f N with hS
  have hpi : π ≠ 0 := pi_ne_zero
  have hSc : Continuous S := continuous_partialSum f N
  have hf1 : IntervalIntegrable f volume (-π) π := by
    simpa using intervalIntegrable_of_memLp f hf (g := fun _ => 1) continuous_const
  have hfc : ∀ n : ℕ, IntervalIntegrable (fun x => f x * cos (n * x)) volume (-π) π :=
    fun n => intervalIntegrable_of_memLp f hf (by fun_prop)
  have hfs : ∀ n : ℕ, IntervalIntegrable (fun x => f x * sin (n * x)) volume (-π) π :=
    fun n => intervalIntegrable_of_memLp f hf (by fun_prop)
  have hfS : IntervalIntegrable (fun x => f x * S x) volume (-π) π :=
    intervalIntegrable_of_memLp f hf hSc
  have hf2 : IntervalIntegrable (fun x => f x ^ 2) volume (-π) π := by
    rw [intervalIntegrable_iff_integrableOn_Ioc_of_le (by linarith [pi_pos])]
    exact hf.integrable_sq
  have cont : ∀ g : ℝ → ℝ, Continuous g → IntervalIntegrable g volume (-π) π :=
    fun g hg => hg.intervalIntegrable _ _
  -- coefficient integrals of f
  have fc : ∀ n : ℕ, ∫ x in (-π)..π, f x * cos (n * x) = π * cosAmount f n := by
    intro n; rw [cosAmount, ← mul_assoc, mul_one_div_cancel hpi, one_mul]
  have fs : ∀ n : ℕ, ∫ x in (-π)..π, f x * sin (n * x) = π * sinAmount f n := by
    intro n; rw [sinAmount, ← mul_assoc, mul_one_div_cancel hpi, one_mul]
  have f0 : ∫ x in (-π)..π, f x = π * cosAmount f 0 := by
    rw [← fc 0]; simp
  -- coefficient integrals of S
  have S0 : ∫ x in (-π)..π, S x = π * cosAmount f 0 := by
    have := integral_mul_partialSum f (fun _ => 1) N (cont _ continuous_const)
      (fun n => cont _ (by fun_prop)) (fun n => cont _ (by fun_prop))
    simp only [one_mul] at this
    rw [hS, this, sum_eq_zero]
    · simp; ring
    · intro n hn
      rw [Finset.mem_Icc] at hn
      rw [integral_cos_nat n hn.1, integral_sin_nat]; ring
  have Sc : ∀ m ∈ Icc 1 N, ∫ x in (-π)..π, S x * cos (m * x) = π * cosAmount f m := by
    intro m hm
    have hm1 := (Finset.mem_Icc.mp hm).1
    simp_rw [mul_comm (S _)]
    rw [hS, integral_mul_partialSum f _ N (cont _ (by fun_prop))
      (fun n => cont _ (by fun_prop)) (fun n => cont _ (by fun_prop)), integral_cos_nat m hm1]
    rw [sum_congr rfl (g := fun n => if m = n then cosAmount f n * π else 0)]
    · rw [sum_ite_eq]; simp [hm]; ring
    · intro n hn
      rw [integral_cos_mul_cos m n hm1 (Finset.mem_Icc.mp hn).1, integral_cos_mul_sin]
      split_ifs <;> ring
  have Ss : ∀ m ∈ Icc 1 N, ∫ x in (-π)..π, S x * sin (m * x) = π * sinAmount f m := by
    intro m hm
    have hm1 := (Finset.mem_Icc.mp hm).1
    simp_rw [mul_comm (S _)]
    rw [hS, integral_mul_partialSum f _ N (cont _ (by fun_prop))
      (fun n => cont _ (by fun_prop)) (fun n => cont _ (by fun_prop)), integral_sin_nat m]
    rw [sum_congr rfl (g := fun n => if m = n then sinAmount f n * π else 0)]
    · rw [sum_ite_eq]; simp [hm]; ring
    · intro n hn
      rw [integral_sin_mul_sin m n hm1 (Finset.mem_Icc.mp hn).1, integral_sin_mul_cos]
      split_ifs <;> ring
  -- the two cross integrals
  have IfS : ∫ x in (-π)..π, f x * S x = π * L := by
    rw [hS, integral_mul_partialSum f f N hf1 hfc hfs, f0, hL, mul_add, mul_sum]
    congr 1
    · ring
    · apply sum_congr rfl; intro n _; rw [fc, fs]; ring
  have ISS : ∫ x in (-π)..π, S x * S x = π * L := by
    have := integral_mul_partialSum f S N (cont _ hSc) (fun n => cont _ (by fun_prop))
      (fun n => cont _ (by fun_prop))
    rw [← hS] at this
    rw [this, S0, hL, mul_add, mul_sum]
    congr 1
    · ring
    · apply sum_congr rfl; intro n hn; rw [Sc n hn, Ss n hn]; ring
  have key : energy (fun x => f x - S x) = energy f - L := by
    unfold energy
    have e : ∀ x, (f x - S x) ^ 2 = (f x ^ 2 - 2 * (f x * S x)) + S x * S x := by
      intro x; ring
    simp_rw [e]
    rw [intervalIntegral.integral_add (hf2.sub (hfS.const_mul 2)) (cont _ (by fun_prop)),
      intervalIntegral.integral_sub hf2 (hfS.const_mul 2), intervalIntegral.integral_const_mul,
      IfS, ISS]
    field_simp
    ring
  have hnn : 0 ≤ energy (fun x => f x - S x) := by
    unfold energy
    exact mul_nonneg (by positivity)
      (intervalIntegral.integral_nonneg (by linarith [pi_pos]) fun _ _ => sq_nonneg _)
  constructor
  · rw [key]; ring
  · linarith

/-- **The sawtooth sums 1/n² (Step 4).** The sawtooth `f(x) = x` has energy `2π²/3`, every
cosine amount `0`, and sine amounts `bₙ = 2(−1)^(n+1)/n` for `n ≥ 1`; so the balance
`4 ∑ 1/n² = 2π²/3` gives `1 + 1/4 + 1/9 + ⋯ = π²/6`. -/
theorem sawtooth_parseval_sum_inv_sq :
    energy (fun x => x) = 2 * π ^ 2 / 3 ∧
      (∀ n : ℕ, cosAmount (fun x => x) n = 0) ∧
      (∀ n : ℕ, 1 ≤ n → sinAmount (fun x => x) n = 2 * (-1) ^ (n + 1) / n) ∧
      HasSum (fun n : ℕ => 1 / ((n : ℝ) + 1) ^ 2) (π ^ 2 / 6) := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · unfold energy
    rw [integral_pow]
    field_simp [pi_ne_zero]
    ring
  · intro n
    unfold cosAmount
    rw [integral_odd_eq_zero (fun x => x * cos (n * x)) (fun x => by simp [cos_neg])]
    simp
  · intro n hn
    unfold sinAmount
    rw [integral_x_sin n hn]
    field_simp [pi_ne_zero]
  · have h := (hasSum_nat_add_iff' 1).mpr hasSum_zeta_two
    simpa using h

-- The sawtooth's harmonic shares bₙ² = (2(−1)^(n+1)/n)² for n = 1, 2, 3, 4: 4, 1, 4/9, 1/4.
example : ((2 : ℚ) * (-1) ^ 2 / 1) ^ 2 = 4 ∧ ((2 : ℚ) * (-1) ^ 3 / 2) ^ 2 = 1 ∧
    ((2 : ℚ) * (-1) ^ 4 / 3) ^ 2 = 4 / 9 ∧ ((2 : ℚ) * (-1) ^ 5 / 4) ^ 2 = 1 / 4 := by norm_num
-- Ledger after three harmonics: 4 + 1 + 4/9 = 49/9 (the card's 5.4444).
example : (4 : ℚ) + 1 + 4 / 9 = 49 / 9 := by norm_num
-- Sawtooth energy: (1/π) × 2π³/3 = 2π²/3.
example : (1 / π) * (2 * π ^ 3 / 3) = 2 * π ^ 2 / 3 := by
  field_simp [Real.pi_ne_zero]
-- The balance: 4 × π²/6 = 2π²/3, and in the 1-ohm reading half of each side: 2π²/3 / 2 = π²/3.
example : 4 * (π ^ 2 / 6) = 2 * π ^ 2 / 3 ∧ 2 * π ^ 2 / 3 / 2 = π ^ 2 / 3 := by
  constructor <;> ring
-- Harmonic powers into 1 ohm, bₙ²/2 for n = 1, 2, 3: 2, 1/2, 2/9 watts.
example : (4 : ℚ) / 2 = 2 ∧ (1 : ℚ) / 2 = 1 / 2 ∧ (4 / 9 : ℚ) / 2 = 2 / 9 := by norm_num
-- Decay of the sawtooth: n |bₙ| = 2 for n = 1, 9, 99.
example : (1 : ℚ) * |2 / 1| = 2 ∧ (9 : ℚ) * |2 / 9| = 2 ∧ (99 : ℚ) * |2 / 99| = 2 := by norm_num
-- Triangle wave: odd terms are 15/16 of ∑ 1/n⁴ (1 − 1/2⁴ = 15/16), so π⁴/96 × 16/15 = π⁴/90.
example : (1 : ℚ) - 1 / 2 ^ 4 = 15 / 16 := by norm_num
example : π ^ 4 / 96 * (16 / 15) = π ^ 4 / 90 := by ring

#print axioms integral_odd_eq_zero
#print axioms integral_cos_int
#print axioms integral_cos_nat
#print axioms integral_sin_nat
#print axioms integral_cos_mul_cos
#print axioms integral_sin_mul_sin
#print axioms integral_cos_mul_sin
#print axioms integral_sin_mul_cos
#print axioms integral_mul_partialSum
#print axioms intervalIntegrable_of_memLp
#print axioms continuous_partialSum
#print axioms fourierCoeffOn_real
#print axioms integral_x_sin
#print axioms energy_eq_sum_sq_coefficients
#print axioms energy_eq_partial_ledger_add_leftover
#print axioms sawtooth_parseval_sum_inv_sq

end ParsevalCard
