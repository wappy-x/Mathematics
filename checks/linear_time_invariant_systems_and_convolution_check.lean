-- Linear and time-invariant: a linear, time-invariant, causal system on records that end is convolution with its pulse response, every convolution is such a system, and bounded inputs give bounded outputs exactly when the pulse response is absolutely summable.
import Mathlib.LinearAlgebra.Finsupp.Defs
import Mathlib.Algebra.Module.LinearMap.Defs
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Topology.Algebra.InfiniteSum.Real
import Mathlib.Analysis.Normed.Operator.BanachSteinhaus
import Mathlib.Topology.ContinuousMap.Bounded.Normed
import Mathlib.Algebra.BigOperators.Finsupp.Basic

open Finset

/-! Records are real sequences indexed by whole-number seconds `n ≥ 0`, zero before 0.
An input record that ends (zero after some finite time) is a finitely supported
function `ℕ →₀ ℝ`. A system `S` takes a whole input record and returns a whole output
record `ℕ → ℝ`. Delaying a record by `n₀` seconds is `u.mapDomain (· + n₀)`: its value
at `n + n₀` is `u n`, and it is zero before `n₀`. The unit pulse is `Finsupp.single 0 1`,
and the pulse response is `h = S (Finsupp.single 0 1)`. -/

/-- A system that is linear (it is a linear map: scaling and adding inputs scales and adds
outputs), time-invariant (delaying the input by `n₀` delays the output by `n₀`) and causal
(the output at time `n` depends only on the input up to time `n`), acting on input records
that end, is completely described by its response `h` to the unit pulse: its output is the
input convolved with `h`, `y[n] = ∑_{k=0}^{n} h[k] u[n - k]`. -/
theorem lti_output_eq_convolution_with_pulse_response
    (S : (ℕ →₀ ℝ) →ₗ[ℝ] (ℕ → ℝ))
    (time_invariant : ∀ (u : ℕ →₀ ℝ) (n₀ n : ℕ), S (u.mapDomain (· + n₀)) (n + n₀) = S u n)
    (causal : ∀ (u v : ℕ →₀ ℝ) (n : ℕ), (∀ k ≤ n, u k = v k) → S u n = S v n) :
    ∀ (u : ℕ →₀ ℝ) (n : ℕ),
      S u n = ∑ k ∈ range (n + 1), S (Finsupp.single 0 1) k * u (n - k) := by
  intro u n
  have hshift : ∀ j ≤ n, S (Finsupp.single j 1) n = S (Finsupp.single 0 1) (n - j) := by
    intro j hj
    have := time_invariant (Finsupp.single 0 1) j (n - j)
    rw [Finsupp.mapDomain_single, zero_add, Nat.sub_add_cancel hj] at this
    exact this
  have htrunc : S u n = S (∑ j ∈ range (n + 1), Finsupp.single j (u j)) n := by
    apply causal
    intro k hk
    rw [Finsupp.finsetSum_apply, sum_eq_single k]
    · simp
    · intro b _ hb; simp [hb]
    · intro hk'; exact absurd (mem_range.2 (by omega)) hk'
  rw [htrunc, map_sum]
  rw [← sum_range_reflect]
  simp only [Finset.sum_apply]
  apply sum_congr rfl
  intro j hj
  have hj' : j < n + 1 := mem_range.1 hj
  have hsingle : Finsupp.single (n + 1 - 1 - j) (u (n + 1 - 1 - j))
      = u (n - j) • Finsupp.single (n - j) (1 : ℝ) := by
    rw [Finsupp.smul_single, smul_eq_mul, mul_one]; simp
  rw [hsingle, map_smul, Pi.smul_apply, smul_eq_mul, hshift _ (by omega)]
  rw [show n - (n - j) = j by omega]
  ring

/-- The converse: for any record `h`, the rule `y = h * u` is a linear, time-invariant,
causal system whose pulse response is `h` itself. So linear time-invariant causal systems
and convolutions with a fixed pulse response are the same thing. -/
theorem convolution_is_linear_time_invariant (h : ℕ → ℝ) :
    ∃ S : (ℕ →₀ ℝ) →ₗ[ℝ] (ℕ → ℝ),
      (∀ (u : ℕ →₀ ℝ) (n : ℕ), S u n = ∑ k ∈ range (n + 1), h k * u (n - k)) ∧
      (∀ (u : ℕ →₀ ℝ) (n₀ n : ℕ), S (u.mapDomain (· + n₀)) (n + n₀) = S u n) ∧
      (∀ (u v : ℕ →₀ ℝ) (n : ℕ), (∀ k ≤ n, u k = v k) → S u n = S v n) ∧
      S (Finsupp.single 0 1) = h := by
  let S : (ℕ →₀ ℝ) →ₗ[ℝ] (ℕ → ℝ) :=
    { toFun := fun u n => ∑ k ∈ range (n + 1), h k * u (n - k)
      map_add' := by
        intro u v; funext n
        simp [mul_add, sum_add_distrib]
      map_smul' := by
        intro c u; funext n
        simp [mul_sum, mul_left_comm] }
  have hS : ∀ (u : ℕ →₀ ℝ) (n : ℕ), S u n = ∑ k ∈ range (n + 1), h k * u (n - k) :=
    fun _ _ => rfl
  refine ⟨S, hS, ?_, ?_, ?_⟩
  · intro u n₀ n
    rw [hS, hS, show n + n₀ + 1 = (n + 1) + n₀ by omega, sum_range_add]
    have h2 : ∑ x ∈ range n₀, h (n + 1 + x) * (u.mapDomain (· + n₀)) (n + n₀ - (n + 1 + x)) = 0 := by
      apply sum_eq_zero
      intro x hx
      have hx' := mem_range.1 hx
      rw [Finsupp.mapDomain_of_notMem_range, mul_zero]
      rintro ⟨y, hy⟩
      simp at hy
      omega
    rw [h2, add_zero]
    apply sum_congr rfl
    intro k hk
    have hk' := mem_range.1 hk
    rw [show n + n₀ - k = (n - k) + n₀ by omega]
    rw [Finsupp.mapDomain_apply_of_injective (add_left_injective n₀)]
  · intro u v n huv
    rw [hS, hS]
    apply sum_congr rfl
    intro k _
    rw [huv _ (Nat.sub_le _ _)]
  · funext n
    rw [hS, sum_eq_single n]
    · simp
    · intro b hb hbn
      have := mem_range.1 hb
      rw [Finsupp.single_apply, ite_eq_right_iff.mpr (fun h => absurd h (by omega)), mul_zero]
    · intro hn; exact absurd (mem_range.2 (by omega)) hn

/-- For inputs that never stop: every bounded input record gives a bounded output
`y[n] = ∑_{k=0}^{n} h[k] u[n - k]` exactly when the `|h[k]|` add to a finite total. -/
theorem bounded_input_bounded_output_iff_summable (h : ℕ → ℝ) :
    (∀ u : ℕ → ℝ, (∃ B, ∀ n, |u n| ≤ B) →
        ∃ C, ∀ n, |∑ k ∈ range (n + 1), h k * u (n - k)| ≤ C) ↔
      Summable (fun k => |h k|) := by
  constructor
  · intro H
    let T : ℕ → (BoundedContinuousFunction ℕ ℝ) →L[ℝ] ℝ := fun n =>
      ∑ k ∈ range (n + 1), h k • BoundedContinuousFunction.evalCLM ℝ (n - k)
    have hT : ∀ n (x : BoundedContinuousFunction ℕ ℝ), T n x = ∑ k ∈ range (n + 1), h k * x (n - k) := by
      intro n x
      simp [T]
    obtain ⟨C', hC'⟩ := banach_steinhaus (g := T) (by
      intro x
      obtain ⟨C, hC⟩ := H x ⟨‖x‖, fun n => by
        rw [← Real.norm_eq_abs]; exact BoundedContinuousFunction.norm_coe_le_norm x n⟩
      exact ⟨C, fun n => by rw [Real.norm_eq_abs, hT]; exact hC n⟩)
    have hpart : ∀ n, ∑ k ∈ range (n + 1), |h k| ≤ C' := by
      intro n
      let v : BoundedContinuousFunction ℕ ℝ := BoundedContinuousFunction.ofNormedAddCommGroupDiscrete
        (fun m => if 0 ≤ h (n - m) then (1 : ℝ) else -1) 1
        (fun m => by split_ifs <;> simp)
      have hv : ‖v‖ ≤ 1 := BoundedContinuousFunction.norm_ofNormedAddCommGroup_le _ zero_le_one _
      have heq : T n v = ∑ k ∈ range (n + 1), |h k| := by
        rw [hT]
        apply sum_congr rfl
        intro k hk
        have := mem_range.1 hk
        simp only [v, BoundedContinuousFunction.coe_ofNormedAddCommGroupDiscrete]
        rw [show n - (n - k) = k by omega]
        split_ifs with hh
        · rw [abs_of_nonneg hh, mul_one]
        · rw [abs_of_neg (not_le.mp hh)]; ring
      calc ∑ k ∈ range (n + 1), |h k| = T n v := heq.symm
        _ ≤ ‖T n v‖ := le_abs_self _
        _ ≤ ‖T n‖ * ‖v‖ := (T n).le_opNorm v
        _ ≤ ‖T n‖ * 1 := mul_le_mul_of_nonneg_left hv (T n).opNorm_nonneg
        _ ≤ C' := by rw [mul_one]; exact hC' n
    apply summable_of_sum_range_le (c := C') (fun n => abs_nonneg _)
    intro n
    calc ∑ i ∈ range n, |h i| ≤ ∑ i ∈ range (n + 1), |h i| := by
          rw [sum_range_succ]; linarith [abs_nonneg (h n)]
      _ ≤ C' := hpart n
  · rintro hs u ⟨B, hB⟩
    refine ⟨(∑' k, |h k|) * B, fun n => ?_⟩
    have hB0 : 0 ≤ B := le_trans (abs_nonneg _) (hB 0)
    calc |∑ k ∈ range (n + 1), h k * u (n - k)|
        ≤ ∑ k ∈ range (n + 1), |h k * u (n - k)| := abs_sum_le_sum_abs _ _
      _ ≤ ∑ k ∈ range (n + 1), |h k| * B := by
          apply sum_le_sum; intro k _
          rw [abs_mul]; exact mul_le_mul_of_nonneg_left (hB _) (abs_nonneg _)
      _ = (∑ k ∈ range (n + 1), |h k|) * B := by rw [sum_mul]
      _ ≤ (∑' k, |h k|) * B :=
          mul_le_mul_of_nonneg_right (hs.sum_le_tsum _ (fun _ _ => abs_nonneg _)) hB0

/-- Step 0, the card's record: throttle +10, +10 and -5 % in seconds 0, 1 and 2 is
10 unit pulses at second 0, plus 10 delayed to second 1, plus -5 delayed to second 2. -/
example (n : ℕ) :
    (Finsupp.single 0 10 + Finsupp.single 1 10 + Finsupp.single 2 (-5) : ℕ →₀ ℤ) n =
      if n = 0 then 10 else if n = 1 then 10 else if n = 2 then -5 else 0 := by
  rcases n with _ | _ | _ | n <;> simp

/-- The hand-worked convolution at 3 s lines up by age (the flip): with `h[0] = 0`,
`y[3] = h[1] u[2] + h[2] u[1] + h[3] u[0]`. -/
example (h u : ℕ → ℝ) (h0 : h 0 = 0) :
    ∑ k ∈ range (3 + 1), h k * u (3 - k) = h 1 * u 2 + h 2 * u 1 + h 3 * u 0 := by
  simp [sum_range_succ, h0]

#print axioms lti_output_eq_convolution_with_pulse_response
#print axioms convolution_is_linear_time_invariant
#print axioms bounded_input_bounded_output_iff_summable
