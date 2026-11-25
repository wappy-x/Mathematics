-- Littlewood-Paley: for a periodic signal cut into frequency bands, the square function has exactly the signal's 2-norm and the bands' powers add up to the signal's power, and averaging over all band sign flips gives Khintchine's exact fourth-power formula, which pins the 4-norm of the flipped signals between the square function's and 3^(1/4) times it.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Tactic.NormNum

/-! Setting, in the card's notation.
* Time `t : ℝ` in seconds; the period is `T > 0` (the card's `T₀` = 32 ms).
* A signal is a finite sum of harmonics `n ∈ s`, each `n ≥ 1`, harmonic `n` at frequency `n / T`:
  `f(t) = ∑_{n ∈ s} (aₙ cos(2πnt/T) + bₙ sin(2πnt/T))`. The card's click is `s = {1, …, 724}`,
  `aₙ = 0.01/√n`, `bₙ = 0`, `T = 32 ms`.
* `band : ℕ → Fin m` sends each harmonic to one of `m` bands (the card's ten octave bands, or any
  other split). `bandPiece … k` is the card's `Δ_k f`: the harmonics of band `k`, the rest dropped.
* `squareFn` is the card's `Sf(t) = (∑_k |Δ_k f(t)|²)^(1/2)`.
* `meanPow T p g = (1/T) ∫₀ᵀ |g t|^p dt` is the mean p-th power and `pNorm T p g` its p-th root,
  the card's `‖g‖_p`, a time average over one period.
* A sign pattern is `ε : Fin m → Bool` (`true` flips the band); `flipped … ε` is the card's
  `T_ε f = ∑_k ε_k Δ_k f`, and `(1/2^m) ∑_ε` is the card's average `𝔼` over sign patterns. -/

open Real MeasureTheory Finset

namespace LittlewoodPaleyCard

/-- The signal `f(t) = ∑_{n ∈ s} (aₙ cos(2πnt/T) + bₙ sin(2πnt/T))`. -/
noncomputable def trigSignal (T : ℝ) (s : Finset ℕ) (a b : ℕ → ℝ) (t : ℝ) : ℝ :=
  ∑ n ∈ s, (a n * cos (2 * π * n * t / T) + b n * sin (2 * π * n * t / T))

/-- The band piece `Δ_k f`: keep the harmonics that `band` sends to band `k`, drop the rest. -/
noncomputable def bandPiece {m : ℕ} (T : ℝ) (s : Finset ℕ) (a b : ℕ → ℝ) (band : ℕ → Fin m)
    (k : Fin m) (t : ℝ) : ℝ :=
  trigSignal T (s.filter (fun n => band n = k)) a b t

/-- The square function `Sf(t) = (∑_k |Δ_k f(t)|²)^(1/2)`: the pieces combined instant by instant
as a root sum of squares. -/
noncomputable def squareFn {m : ℕ} (T : ℝ) (s : Finset ℕ) (a b : ℕ → ℝ) (band : ℕ → Fin m)
    (t : ℝ) : ℝ :=
  Real.sqrt (∑ k : Fin m, bandPiece T s a b band k t ^ 2)

/-- The mean p-th power over one period, `(1/T) ∫₀ᵀ |g t|^p dt`. -/
noncomputable def meanPow (T : ℝ) (p : ℕ) (g : ℝ → ℝ) : ℝ :=
  (1 / T) * ∫ t in (0 : ℝ)..T, |g t| ^ p

/-- The p-norm over one period, `‖g‖_p = ((1/T) ∫₀ᵀ |g t|^p dt)^(1/p)`. -/
noncomputable def pNorm (T : ℝ) (p : ℕ) (g : ℝ → ℝ) : ℝ :=
  meanPow T p g ^ ((1 : ℝ) / p)

/-- A slider sign: `true` flips the band (`−1`), `false` leaves it (`+1`). -/
def signOf (e : Bool) : ℝ := if e then -1 else 1

/-- The sign-flipped signal `T_ε f = ∑_k ε_k Δ_k f`. -/
noncomputable def flipped {m : ℕ} (T : ℝ) (s : Finset ℕ) (a b : ℕ → ℝ) (band : ℕ → Fin m)
    (ε : Fin m → Bool) (t : ℝ) : ℝ :=
  ∑ k : Fin m, signOf (ε k) * bandPiece T s a b band k t

/-- Harmonic `n` lies in the card's octave band `k` (centre `2^k` harmonics, edges `2^k/√2` and
`2^k √2`) when `4^k ≤ 2n² < 4^(k+1)`, that is `4^k/2 ≤ n² < 2·4^k`. -/
def inOctaveBand (k n : ℕ) : Prop := 4 ^ k ≤ 2 * n ^ 2 ∧ n ^ 2 < 2 * 4 ^ k

instance (k n : ℕ) : Decidable (inOctaveBand k n) := by
  unfold inOctaveBand; infer_instance

theorem integral_cos_int (T : ℝ) (hT : T ≠ 0) (k : ℤ) :
    ∫ t in (0 : ℝ)..T, cos (2 * π * k * t / T) = if k = 0 then T else 0 := by
  split_ifs with hk
  · simp [hk]
  · have hc : 2 * π * k / T ≠ 0 := by
      have : (k : ℝ) ≠ 0 := by exact_mod_cast hk
      have := Real.pi_pos
      positivity
    have hf : (fun t => cos (2 * π * k * t / T)) = fun t => cos ((2 * π * k / T) * t) := by
      funext t; ring_nf
    rw [hf, intervalIntegral.integral_comp_mul_left (fun x => cos x) hc, integral_cos]
    have : 2 * π * k / T * T = ((2 * k : ℤ) : ℝ) * π := by push_cast; field_simp
    rw [this, sin_int_mul_pi]
    simp

theorem integral_sin_int (T : ℝ) (hT : T ≠ 0) (k : ℤ) :
    ∫ t in (0 : ℝ)..T, sin (2 * π * k * t / T) = 0 := by
  by_cases hk : k = 0
  · simp [hk]
  · have hc : 2 * π * k / T ≠ 0 := by
      have : (k : ℝ) ≠ 0 := by exact_mod_cast hk
      have := Real.pi_pos
      positivity
    have hf : (fun t => sin (2 * π * k * t / T)) = fun t => sin ((2 * π * k / T) * t) := by
      funext t; ring_nf
    rw [hf, intervalIntegral.integral_comp_mul_left (fun x => sin x) hc, integral_sin]
    have : 2 * π * k / T * T = (k : ℝ) * (2 * π) := by field_simp
    rw [this, cos_int_mul_two_pi]
    simp

theorem integral_harmonic_mul (T : ℝ) (hT : T ≠ 0) (a b : ℕ → ℝ) (n m : ℕ)
    (hn : 1 ≤ n) (hm : 1 ≤ m) :
    ∫ t in (0 : ℝ)..T, (a n * cos (2 * π * n * t / T) + b n * sin (2 * π * n * t / T)) *
        (a m * cos (2 * π * m * t / T) + b m * sin (2 * π * m * t / T)) =
      if n = m then T * ((a n ^ 2 + b n ^ 2) / 2) else 0 := by
  set kd : ℤ := (n : ℤ) - m with hkd
  set ks : ℤ := (n : ℤ) + m with hks
  have hpt : ∀ t : ℝ, (a n * cos (2 * π * n * t / T) + b n * sin (2 * π * n * t / T)) *
        (a m * cos (2 * π * m * t / T) + b m * sin (2 * π * m * t / T)) =
      (a n * a m + b n * b m) / 2 * cos (2 * π * kd * t / T) +
      ((a n * a m - b n * b m) / 2 * cos (2 * π * ks * t / T) +
      ((a n * b m + b n * a m) / 2 * sin (2 * π * ks * t / T) +
      (b n * a m - a n * b m) / 2 * sin (2 * π * kd * t / T))) := by
    intro t
    have e1 : 2 * π * (kd : ℝ) * t / T = 2 * π * n * t / T - 2 * π * m * t / T := by
      rw [hkd]; push_cast; ring
    have e2 : 2 * π * (ks : ℝ) * t / T = 2 * π * n * t / T + 2 * π * m * t / T := by
      rw [hks]; push_cast; ring
    rw [e1, e2, cos_sub, cos_add, sin_add, sin_sub]
    ring
  simp_rw [hpt]
  have hi : ∀ (c : ℝ) (k : ℤ), IntervalIntegrable (fun t => c * cos (2 * π * k * t / T))
      volume 0 T := fun c k => (by fun_prop : Continuous _).intervalIntegrable _ _
  have hi' : ∀ (c : ℝ) (k : ℤ), IntervalIntegrable (fun t => c * sin (2 * π * k * t / T))
      volume 0 T := fun c k => (by fun_prop : Continuous _).intervalIntegrable _ _
  rw [intervalIntegral.integral_add (hi _ _) ((hi _ _).add ((hi' _ _).add (hi' _ _))),
    intervalIntegral.integral_add (hi _ _) ((hi' _ _).add (hi' _ _)),
    intervalIntegral.integral_add (hi' _ _) (hi' _ _)]
  simp only [intervalIntegral.integral_const_mul, integral_cos_int T hT, integral_sin_int T hT]
  have hks0 : ks ≠ 0 := by omega
  have hkd0 : kd = 0 ↔ n = m := by omega
  simp only [hks0, ite_false, mul_zero, add_zero]
  by_cases h : n = m
  · subst h; simp [hkd0]; ring
  · simp [hkd0, h]

@[fun_prop]
theorem trigSignal_continuous (T : ℝ) (s : Finset ℕ) (a b : ℕ → ℝ) :
    Continuous (trigSignal T s a b) := by
  unfold trigSignal; fun_prop

theorem integral_trigSignal_sq (T : ℝ) (hT : T ≠ 0) (s : Finset ℕ) (hs : ∀ n ∈ s, 1 ≤ n)
    (a b : ℕ → ℝ) :
    ∫ t in (0 : ℝ)..T, trigSignal T s a b t ^ 2 = T * ∑ n ∈ s, (a n ^ 2 + b n ^ 2) / 2 := by
  unfold trigSignal
  simp_rw [sq, Finset.sum_mul_sum]
  rw [intervalIntegral.integral_finsetSum (fun i _ =>
    (by fun_prop : Continuous _).intervalIntegrable _ _)]
  rw [Finset.mul_sum]
  refine Finset.sum_congr rfl fun n hn => ?_
  rw [intervalIntegral.integral_finsetSum (fun i _ =>
    (by fun_prop : Continuous _).intervalIntegrable _ _)]
  rw [Finset.sum_congr rfl fun m hm => integral_harmonic_mul T hT a b n m (hs n hn) (hs m hm)]
  rw [Finset.sum_ite_eq]
  simp only [hn, ite_true]
  ring

@[fun_prop]
theorem bandPiece_continuous {m : ℕ} (T : ℝ) (s : Finset ℕ) (a b : ℕ → ℝ) (band : ℕ → Fin m)
    (k : Fin m) : Continuous (bandPiece T s a b band k) :=
  trigSignal_continuous T _ a b

@[fun_prop]
theorem flipped_continuous {m : ℕ} (T : ℝ) (s : Finset ℕ) (a b : ℕ → ℝ) (band : ℕ → Fin m)
    (ε : Fin m → Bool) : Continuous (flipped T s a b band ε) := by
  unfold flipped
  fun_prop

@[fun_prop]
theorem squareFn_continuous {m : ℕ} (T : ℝ) (s : Finset ℕ) (a b : ℕ → ℝ) (band : ℕ → Fin m) :
    Continuous (squareFn T s a b band) := by
  unfold squareFn
  fun_prop

theorem khintchine_moments_aux (m : ℕ) (a : Fin m → ℝ) :
    ∑ ε : Fin m → Bool, (∑ k, signOf (ε k) * a k) ^ 2 = 2 ^ m * ∑ k, a k ^ 2 ∧
    ∑ ε : Fin m → Bool, (∑ k, signOf (ε k) * a k) ^ 4 =
      2 ^ m * (3 * (∑ k, a k ^ 2) ^ 2 - 2 * ∑ k, a k ^ 4) := by
  induction m with
  | zero => simp
  | succ m ih =>
    obtain ⟨h2, h4⟩ := ih (fun i => a i.succ)
    have hsplit : ∀ g : (Fin (m + 1) → Bool) → ℝ,
        ∑ ε : Fin (m + 1) → Bool, g ε =
          ∑ e : Bool, ∑ ε' : Fin m → Bool, g (Fin.cons e ε') := by
      intro g
      rw [← (Fin.consEquiv fun _ => Bool).sum_comp, Fintype.sum_prod_type]
      rfl
    simp only [Fin.sum_univ_succ] at *
    refine ⟨?_, ?_⟩
    · rw [hsplit (fun ε => (signOf (ε 0) * a 0 + ∑ i : Fin m, signOf (ε i.succ) * a i.succ) ^ 2)]
      simp only [Fin.cons_zero, Fin.cons_succ, Fintype.sum_bool, signOf]
      simp only [ite_true, ite_false, Bool.false_eq_true]
      have : ∀ x : ℝ, (-1 * a 0 + x) ^ 2 + (1 * a 0 + x) ^ 2 = 2 * x ^ 2 + 2 * a 0 ^ 2 := by
        intro x; ring
      rw [← Finset.sum_add_distrib]
      simp only [this, Finset.sum_add_distrib, ← Finset.mul_sum]
      simp only [signOf] at h2
      rw [h2]
      simp
      ring
    · rw [hsplit (fun ε => (signOf (ε 0) * a 0 + ∑ i : Fin m, signOf (ε i.succ) * a i.succ) ^ 4)]
      simp only [Fin.cons_zero, Fin.cons_succ, Fintype.sum_bool, signOf]
      simp only [ite_true, ite_false, Bool.false_eq_true]
      have : ∀ x : ℝ, (-1 * a 0 + x) ^ 4 + (1 * a 0 + x) ^ 4 =
          2 * x ^ 4 + 12 * a 0 ^ 2 * x ^ 2 + 2 * a 0 ^ 4 := by
        intro x; ring
      rw [← Finset.sum_add_distrib]
      simp only [this, Finset.sum_add_distrib, ← Finset.mul_sum]
      simp only [signOf] at h2 h4
      rw [h2, h4]
      simp
      ring

#print axioms integral_cos_int
#print axioms integral_sin_int
#print axioms integral_harmonic_mul
#print axioms trigSignal_continuous
#print axioms integral_trigSignal_sq
#print axioms bandPiece_continuous
#print axioms flipped_continuous
#print axioms squareFn_continuous
#print axioms khintchine_moments_aux

/-- **Littlewood-Paley at p = 2 (Plancherel).** Cut a periodic signal of harmonics `n ≥ 1` into
bands in any way. Then power adds exactly across the bands: the signal's mean power is the sum of
the band pieces' mean powers, and is `∑ₙ (aₙ² + bₙ²)/2`, half of each amplitude squared. And the
square function has exactly the signal's size, `‖Sf‖₂ = ‖f‖₂`, so `c₂ = C₂ = 1`. -/
theorem square_function_two_norm_eq {m : ℕ} (T : ℝ) (hT : 0 < T) (s : Finset ℕ)
    (hs : ∀ n ∈ s, 1 ≤ n) (a b : ℕ → ℝ) (band : ℕ → Fin m) :
    meanPow T 2 (trigSignal T s a b) = ∑ k : Fin m, meanPow T 2 (bandPiece T s a b band k) ∧
      meanPow T 2 (trigSignal T s a b) = ∑ n ∈ s, (a n ^ 2 + b n ^ 2) / 2 ∧
      pNorm T 2 (squareFn T s a b band) = pNorm T 2 (trigSignal T s a b) := by
  have hT0 : T ≠ 0 := hT.ne'
  have hmp : ∀ s' : Finset ℕ, (∀ n ∈ s', 1 ≤ n) →
      meanPow T 2 (trigSignal T s' a b) = ∑ n ∈ s', (a n ^ 2 + b n ^ 2) / 2 := by
    intro s' hs'
    unfold meanPow
    simp_rw [sq_abs]
    rw [integral_trigSignal_sq T hT0 s' hs' a b, ← mul_assoc, one_div_mul_cancel hT0, one_mul]
  have h1 : meanPow T 2 (trigSignal T s a b) =
      ∑ k : Fin m, meanPow T 2 (bandPiece T s a b band k) := by
    rw [hmp s hs]
    unfold bandPiece
    rw [Finset.sum_congr rfl fun k _ => hmp _ fun n hn => hs n (Finset.mem_filter.1 hn).1]
    exact (Finset.sum_fiberwise s band _).symm
  have h3 : meanPow T 2 (squareFn T s a b band) = meanPow T 2 (trigSignal T s a b) := by
    rw [h1]
    unfold meanPow squareFn
    have hpt : ∀ t, |Real.sqrt (∑ k : Fin m, bandPiece T s a b band k t ^ 2)| ^ 2 =
        ∑ k : Fin m, |bandPiece T s a b band k t| ^ 2 := by
      intro t
      rw [sq_abs, Real.sq_sqrt (Finset.sum_nonneg fun k _ => sq_nonneg _)]
      simp_rw [sq_abs]
    simp_rw [hpt]
    rw [intervalIntegral.integral_finsetSum (fun k _ =>
      (by fun_prop : Continuous _).intervalIntegrable _ _), Finset.mul_sum]
  refine ⟨h1, hmp s hs, ?_⟩
  unfold pNorm
  rw [h3]

/-- **Khintchine's inequality at p = 4.** For any real numbers `a₁, …, aₘ`, flip each sign at
random with even odds and average over all `2^m` sign patterns: the mean fourth power of
`∑ ε_k a_k` is exactly `3(∑ a_k²)² − 2∑ a_k⁴`. So it lies between `(∑ a_k²)²` and `3(∑ a_k²)²`:
the random-sign sum's typical size is the root sum of squares, within a factor `3^(1/4)`. -/
theorem khintchine_fourth_moment (m : ℕ) (a : Fin m → ℝ) :
    (1 / 2 ^ m : ℝ) * ∑ ε : Fin m → Bool, (∑ k, signOf (ε k) * a k) ^ 4 =
        3 * (∑ k, a k ^ 2) ^ 2 - 2 * ∑ k, a k ^ 4 ∧
      (∑ k, a k ^ 2) ^ 2 ≤ (1 / 2 ^ m : ℝ) * ∑ ε : Fin m → Bool, (∑ k, signOf (ε k) * a k) ^ 4 ∧
      (1 / 2 ^ m : ℝ) * ∑ ε : Fin m → Bool, (∑ k, signOf (ε k) * a k) ^ 4 ≤
        3 * (∑ k, a k ^ 2) ^ 2 := by
  have heq : (1 / 2 ^ m : ℝ) * ∑ ε : Fin m → Bool, (∑ k, signOf (ε k) * a k) ^ 4 =
      3 * (∑ k, a k ^ 2) ^ 2 - 2 * ∑ k, a k ^ 4 := by
    rw [(khintchine_moments_aux m a).2]
    field_simp
  have h1 : ∑ k, a k ^ 4 ≤ (∑ k, a k ^ 2) ^ 2 := by
    have := Finset.sum_sq_le_sq_sum_of_nonneg (s := Finset.univ) (f := fun k => a k ^ 2)
      (fun i _ => sq_nonneg (a i))
    simpa [← pow_mul] using this
  have h2 : 0 ≤ ∑ k, a k ^ 4 := Finset.sum_nonneg fun i _ => by positivity
  refine ⟨heq, ?_, ?_⟩ <;> rw [heq] <;> linarith

/-- **Flipping band signs, averaged (Step 4 at p = 4).** For a periodic signal cut into `m` bands,
the average over all `2^m` slider sign patterns of `‖T_ε f‖₄⁴` is exactly
`3‖Sf‖₄⁴ − 2∑_k ‖Δ_k f‖₄⁴`, and so lies between `‖Sf‖₄⁴` and `3‖Sf‖₄⁴`. -/
theorem flipped_fourth_power_mean {m : ℕ} (T : ℝ) (hT : 0 < T) (s : Finset ℕ) (a b : ℕ → ℝ)
    (band : ℕ → Fin m) :
    (1 / 2 ^ m : ℝ) * ∑ ε : Fin m → Bool, meanPow T 4 (flipped T s a b band ε) =
        3 * meanPow T 4 (squareFn T s a b band) -
          2 * ∑ k : Fin m, meanPow T 4 (bandPiece T s a b band k) ∧
      meanPow T 4 (squareFn T s a b band) ≤
        (1 / 2 ^ m : ℝ) * ∑ ε : Fin m → Bool, meanPow T 4 (flipped T s a b band ε) ∧
      (1 / 2 ^ m : ℝ) * ∑ ε : Fin m → Bool, meanPow T 4 (flipped T s a b band ε) ≤
        3 * meanPow T 4 (squareFn T s a b band) := by
  have h4 : ∀ x : ℝ, |x| ^ 4 = x ^ 4 := fun x => by
    rw [pow_abs, abs_of_nonneg (by positivity)]
  have hS : ∀ t, |squareFn T s a b band t| ^ 4 = (∑ k, bandPiece T s a b band k t ^ 2) ^ 2 := by
    intro t
    rw [h4]
    unfold squareFn
    rw [show (4 : ℕ) = 2 * 2 from rfl, pow_mul,
      Real.sq_sqrt (Finset.sum_nonneg fun k _ => sq_nonneg _)]
  obtain ⟨F, hFdef⟩ : ∃ F : ℝ → ℝ,
      F = fun t => (1 / 2 ^ m : ℝ) * ∑ ε : Fin m → Bool, |flipped T s a b band ε t| ^ 4 :=
    ⟨_, rfl⟩
  have hK := fun t => khintchine_fourth_moment m (fun k => bandPiece T s a b band k t)
  have hF : ∀ t, F t = 3 * |squareFn T s a b band t| ^ 4 -
      2 * ∑ k, |bandPiece T s a b band k t| ^ 4 := by
    intro t
    rw [hFdef, hS]
    simp only [h4]
    exact (hK t).1
  have hFlo : ∀ t, |squareFn T s a b band t| ^ 4 ≤ F t := by
    intro t
    rw [hFdef, hS]
    simp only [h4]
    exact (hK t).2.1
  have hFhi : ∀ t, F t ≤ 3 * |squareFn T s a b band t| ^ 4 := by
    intro t
    rw [hFdef, hS]
    simp only [h4]
    exact (hK t).2.2
  have hFc : Continuous F := by
    rw [hFdef]
    fun_prop
  have hSc : Continuous fun t => |squareFn T s a b band t| ^ 4 := by fun_prop
  have hLHS : (1 / 2 ^ m : ℝ) * ∑ ε : Fin m → Bool, meanPow T 4 (flipped T s a b band ε) =
      (1 / T) * ∫ t in (0 : ℝ)..T, F t := by
    unfold meanPow
    rw [hFdef, intervalIntegral.integral_const_mul, intervalIntegral.integral_finsetSum
      (fun ε _ => (by fun_prop : Continuous _).intervalIntegrable _ _),
      ← Finset.mul_sum]
    ring
  have hInt : ∫ t in (0 : ℝ)..T, F t = 3 * (∫ t in (0 : ℝ)..T, |squareFn T s a b band t| ^ 4) -
      2 * ∑ k : Fin m, ∫ t in (0 : ℝ)..T, |bandPiece T s a b band k t| ^ 4 := by
    rw [intervalIntegral.integral_congr fun t _ => hF t]
    rw [intervalIntegral.integral_sub ((by fun_prop : Continuous _).intervalIntegrable _ _)
        ((by fun_prop : Continuous _).intervalIntegrable _ _),
      intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul,
      intervalIntegral.integral_finsetSum
        (fun k _ => (by fun_prop : Continuous _).intervalIntegrable _ _)]
  have hTinv : (0 : ℝ) ≤ 1 / T := by positivity
  refine ⟨?_, ?_, ?_⟩
  · rw [hLHS, hInt]
    unfold meanPow
    rw [← Finset.mul_sum]
    ring
  · rw [hLHS]
    unfold meanPow
    exact mul_le_mul_of_nonneg_left (intervalIntegral.integral_mono_on hT.le
      (hSc.intervalIntegrable _ _) (hFc.intervalIntegrable _ _) fun t _ => hFlo t) hTinv
  · rw [hLHS]
    unfold meanPow
    rw [mul_left_comm]
    refine mul_le_mul_of_nonneg_left ?_ hTinv
    rw [← intervalIntegral.integral_const_mul]
    exact intervalIntegral.integral_mono_on hT.le (hFc.intervalIntegrable _ _)
      ((continuous_const.mul hSc).intervalIntegrable _ _) fun t _ => hFhi t

-- Band 3 (250 Hz) holds harmonics 6 to 11: 32 ≤ n² < 128.
set_option maxRecDepth 20000 in
example : ∀ n < 725, inOctaveBand 3 n ↔ 6 ≤ n ∧ n ≤ 11 := by decide
-- The ten octave bands of the click, harmonics 1 to 724: 1-1, 2-2, 3-5, 6-11, 12-22, 23-45,
-- 46-90, 91-181, 182-362, 363-724 (each band's first and last harmonic is in, its neighbours out).
example : inOctaveBand 0 1 ∧ ¬ inOctaveBand 0 2 ∧ inOctaveBand 1 2 ∧ ¬ inOctaveBand 1 3 ∧
    inOctaveBand 2 3 ∧ inOctaveBand 2 5 ∧ ¬ inOctaveBand 2 6 ∧
    inOctaveBand 3 6 ∧ inOctaveBand 3 11 ∧ ¬ inOctaveBand 3 12 ∧
    inOctaveBand 4 12 ∧ inOctaveBand 4 22 ∧ ¬ inOctaveBand 4 23 ∧
    inOctaveBand 5 23 ∧ inOctaveBand 5 45 ∧ ¬ inOctaveBand 5 46 ∧
    inOctaveBand 6 46 ∧ inOctaveBand 6 90 ∧ ¬ inOctaveBand 6 91 ∧
    inOctaveBand 7 91 ∧ inOctaveBand 7 181 ∧ ¬ inOctaveBand 7 182 ∧
    inOctaveBand 8 182 ∧ inOctaveBand 8 362 ∧ ¬ inOctaveBand 8 363 ∧
    inOctaveBand 9 363 ∧ inOctaveBand 9 724 ∧ ¬ inOctaveBand 9 725 := by decide
-- No band edge falls on a harmonic: 2n² is never 4^k for the click's bands and harmonics.
set_option maxRecDepth 20000 in
example : ∀ k < 10, ∀ n < 725, 2 * n ^ 2 ≠ 4 ^ k := by decide
-- Khintchine by hand, a = (3, 4): the four sign pairs give 7⁴, 1⁴, 1⁴, 7⁴, averaging 1201,
-- and 3 × 25² − 2 × (81 + 256) = 1201.
example : ((3 + 4) ^ 4 + (3 - 4) ^ 4 + (-3 + 4) ^ 4 + (-3 - 4) ^ 4 : ℤ) = 4 * 1201 ∧
    (3 : ℤ) ^ 2 + 4 ^ 2 = 25 ∧ (3 : ℤ) * 25 ^ 2 - 2 * (3 ^ 4 + 4 ^ 4) = 1201 := by norm_num
-- Band powers (amplitude 1/100 V at harmonic n, mean power (1/100)²/(2n) V²), in mV² = 10⁻⁶ V²:
-- 31.25 Hz band 50, 62.5 Hz band 25, 125 Hz band 50 × (1/3 + 1/4 + 1/5) = 235/6 (39.1667).
example : ((1 : ℚ) / 100) ^ 2 / 2 = 50 / 10 ^ 6 ∧ ((1 : ℚ) / 100) ^ 2 / (2 * 2) = 25 / 10 ^ 6 ∧
    ((1 : ℚ) / 100) ^ 2 / (2 * 3) + (1 / 100) ^ 2 / (2 * 4) + (1 / 100) ^ 2 / (2 * 5) =
      235 / 6 / 10 ^ 6 ∧ (50 : ℚ) * (1 / 3 + 1 / 4 + 1 / 5) = 235 / 6 := by norm_num
-- The click's top harmonic: 724 × 31.25 Hz = 22625 Hz; fourth powers reach harmonic 2896 < 4096.
example : (724 : ℚ) * (125 / 4) = 22625 ∧ 4 * 724 = 2896 ∧ 2896 < 4096 := by norm_num
-- Ten bands give 2^10 = 1024 sign patterns, 512 up to an overall sign.
example : 2 ^ 10 = 1024 ∧ 1024 / 2 = 512 := by norm_num
-- Burkholder's Haar constant at p = 4: p* = max(4, 4/3) = 4, so p* − 1 = 3.
example : max (4 : ℚ) (4 / (4 - 1)) - 1 = 3 := by norm_num

#print axioms square_function_two_norm_eq
#print axioms khintchine_fourth_moment
#print axioms flipped_fourth_power_mean

end LittlewoodPaleyCard
