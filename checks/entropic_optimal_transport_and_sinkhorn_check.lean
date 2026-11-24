-- Sinkhorn: a feasible plan of scaled-kernel form u_i e^(-C_ij/ε) v_j is the one and only best plan of entropic transport, every feasible plan's entropic value is at least the dual value, and the entropic plan's moving cost exceeds the exact transport cost by at most ε times the smaller histogram entropy.
import Mathlib.Analysis.SpecialFunctions.Log.NegMulLog
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases

open Finset Real

/-! ### How the card's objects are written here

Bins of last year are a finite type `ι` (rows), bins of this year a finite type `κ` (columns).
`a i` and `b j` are the shares, `C i j` the cost of moving one unit of share from `i` to `j`.

A plan is a table `P : ι → κ → ℝ`. It is feasible when every entry is `≥ 0`, its row sums are
`a` (`∀ i, ∑ j, P i j = a i`) and its column sums are `b` (`∀ j, ∑ i, P i j = b j`).

The entropy of a plan is `H(P) = ∑ i, ∑ j, negMulLog (P i j)`, where Mathlib's
`Real.negMulLog x = -x * log x` (natural log, with `negMulLog 0 = 0`). The entropic objective is
the moving cost minus `ε` times the entropy:
`∑ i, ∑ j, C i j * P i j - ε * ∑ i, ∑ j, negMulLog (P i j)`.

The kernel is `K i j = exp (-C i j / ε)`; a scaled-kernel plan is `u i * exp (-C i j / ε) * v j`
with row factors `u i > 0` and column factors `v j > 0`.

The dual value at row prices `φ` and column prices `ψ` is
`q(φ, ψ) = ∑ i, a i * φ i + ∑ j, b j * ψ j - ε * ∑ i, ∑ j, exp ((φ i + ψ j - C i j) / ε - 1)`. -/

/-- Gibbs' pointwise inequality: `q log q - q log p - q + p ≥ 0` for `p > 0`, `q ≥ 0`. -/
lemma eot_gibbs_nonneg (p q : ℝ) (hp : 0 < p) (hq : 0 ≤ q) :
    0 ≤ q * log q - q * log p - q + p := by
  rcases hq.eq_or_lt with h | h
  · subst h; simp; linarith
  · have h1 := Real.log_le_sub_one_of_pos (div_pos hp h)
    rw [Real.log_div hp.ne' h.ne'] at h1
    have h2 : q * (log p - log q) ≤ q * (p / q - 1) := mul_le_mul_of_nonneg_left h1 h.le
    have h3 : q * (p / q - 1) = p - q := by field_simp
    nlinarith

#print axioms eot_gibbs_nonneg

/-- Equality case of Gibbs' pointwise inequality. -/
lemma eot_gibbs_eq (p q : ℝ) (hp : 0 < p) (hq : 0 ≤ q)
    (h0 : q * log q - q * log p - q + p = 0) : q = p := by
  by_contra hne
  rcases hq.eq_or_lt with h | h
  · subst h; simp at h0; linarith
  · have hx : p / q ≠ 1 := by
      intro h'; rw [div_eq_one_iff_eq h.ne'] at h'; exact hne h'.symm
    have h1 := Real.log_lt_sub_one_of_pos (div_pos hp h) hx
    rw [Real.log_div hp.ne' h.ne'] at h1
    have h2 : q * (log p - log q) < q * (p / q - 1) := mul_lt_mul_of_pos_left h1 h
    have h3 : q * (p / q - 1) = p - q := by field_simp
    nlinarith

#print axioms eot_gibbs_eq

/-- One entry of the entropic objective, compared with a scaled-kernel entry. -/
lemma eot_entry (c ε q u v : ℝ) (hε : 0 < ε) (hu : 0 < u) (hv : 0 < v) :
    (c * q - ε * negMulLog q) - (c * (u * exp (-c / ε) * v) - ε * negMulLog (u * exp (-c / ε) * v))
      = ε * (q - u * exp (-c / ε) * v) * (log u + log v + 1)
        + ε * (q * log q - q * log (u * exp (-c / ε) * v) - q + u * exp (-c / ε) * v) := by
  have hlog : log (u * exp (-c / ε) * v) = log u + (-c / ε) + log v := by
    rw [Real.log_mul (by positivity) hv.ne', Real.log_mul hu.ne' (exp_pos _).ne', Real.log_exp]
  have hc : ε * (-c / ε) = -c := by field_simp
  simp only [negMulLog, hlog]
  linear_combination (q - u * exp (-c / ε) * v) * hc

#print axioms eot_entry

/-- Pointwise Fenchel inequality behind weak duality. -/
lemma eot_fenchel (q t : ℝ) (hq : 0 ≤ q) : q * t - exp (t - 1) ≤ q * log q := by
  rcases hq.eq_or_lt with h | h
  · subst h; simp; exact (exp_pos _).le
  · have h1 := Real.add_one_le_exp (t - 1 - log q)
    rw [Real.exp_sub, Real.exp_log h] at h1
    have h2 : q * (t - 1 - log q + 1) ≤ q * (exp (t - 1) / q) := mul_le_mul_of_nonneg_left h1 h.le
    have h3 : q * (exp (t - 1) / q) = exp (t - 1) := by field_simp
    nlinarith

#print axioms eot_fenchel

/-- An entry of a plan is at most its row total. -/
lemma eot_entry_le_row {ι κ : Type*} [Fintype ι] [Fintype κ] (a : ι → ℝ) (P : ι → κ → ℝ)
    (hP : ∀ i j, 0 ≤ P i j) (hrow : ∀ i, ∑ j, P i j = a i) (i : ι) (j : κ) : P i j ≤ a i := by
  rw [← hrow i]; exact Finset.single_le_sum (fun j _ => hP i j) (Finset.mem_univ j)

#print axioms eot_entry_le_row

/-- A plan's entropy is at least the entropy of its row totals. -/
lemma eot_row_entropy_le {ι κ : Type*} [Fintype ι] [Fintype κ] (a : ι → ℝ) (P : ι → κ → ℝ)
    (hP : ∀ i j, 0 ≤ P i j) (hrow : ∀ i, ∑ j, P i j = a i) :
    ∑ i, negMulLog (a i) ≤ ∑ i, ∑ j, negMulLog (P i j) := by
  refine Finset.sum_le_sum fun i _ => ?_
  have e : negMulLog (a i) = ∑ j, -(P i j * log (a i)) := by
    rw [Finset.sum_neg_distrib, ← Finset.sum_mul, hrow i, negMulLog, neg_mul]
  rw [e]
  refine Finset.sum_le_sum fun j _ => ?_
  rcases (hP i j).eq_or_lt with h | h
  · rw [← h]; simp
  · have hle := eot_entry_le_row a P hP hrow i j
    have hl : log (P i j) ≤ log (a i) := Real.log_le_log h hle
    rw [negMulLog]
    nlinarith

#print axioms eot_row_entropy_le

/-- A plan's entropy is at most the sum of the entropies of its row and column totals. -/
lemma eot_joint_entropy_le {ι κ : Type*} [Fintype ι] [Fintype κ] (a : ι → ℝ) (b : κ → ℝ)
    (ha1 : ∑ i, a i = 1) (hb1 : ∑ j, b j = 1) (P : ι → κ → ℝ)
    (hP : ∀ i j, 0 ≤ P i j) (hrow : ∀ i, ∑ j, P i j = a i) (hcol : ∀ j, ∑ i, P i j = b j) :
    ∑ i, ∑ j, negMulLog (P i j) ≤ ∑ i, negMulLog (a i) + ∑ j, negMulLog (b j) := by
  have hpt : ∀ i j, 0 ≤ P i j * log (P i j) - P i j * log (a i) - P i j * log (b j) - P i j
      + a i * b j := by
    intro i j
    have hai : P i j ≤ a i := eot_entry_le_row a P hP hrow i j
    have hbj : P i j ≤ b j :=
      eot_entry_le_row b (fun j i => P i j) (fun j i => hP i j) hcol j i
    rcases (hP i j).eq_or_lt with h | h
    · rw [← h]; simp; exact mul_nonneg (h ▸ hai) (h ▸ hbj)
    · have ha : 0 < a i := lt_of_lt_of_le h hai
      have hb : 0 < b j := lt_of_lt_of_le h hbj
      have g := eot_gibbs_nonneg (a i * b j) (P i j) (mul_pos ha hb) h.le
      rw [Real.log_mul ha.ne' hb.ne'] at g
      linarith
  have hsum := Finset.sum_nonneg fun i (_ : i ∈ Finset.univ) =>
    Finset.sum_nonneg fun j (_ : j ∈ Finset.univ) => hpt i j
  simp only [Finset.sum_add_distrib, Finset.sum_sub_distrib] at hsum
  have hA : ∑ i, ∑ j, P i j * log (a i) = ∑ i, a i * log (a i) :=
    Finset.sum_congr rfl fun i _ => by rw [← Finset.sum_mul, hrow i]
  have hB : ∑ i, ∑ j, P i j * log (b j) = ∑ j, b j * log (b j) := by
    rw [Finset.sum_comm]; exact Finset.sum_congr rfl fun j _ => by rw [← Finset.sum_mul, hcol j]
  have hAB : ∑ i, ∑ j, a i * b j = 1 := by rw [← Finset.sum_mul_sum, ha1, hb1, one_mul]
  have hS : ∑ i, ∑ j, P i j = 1 := by simp only [hrow]; exact ha1
  have hHP : ∑ i, ∑ j, negMulLog (P i j) = -∑ i, ∑ j, P i j * log (P i j) := by
    simp only [negMulLog, neg_mul, Finset.sum_neg_distrib]
  have hHa : ∑ i, negMulLog (a i) = -∑ i, a i * log (a i) := by
    simp only [negMulLog, neg_mul, Finset.sum_neg_distrib]
  have hHb : ∑ j, negMulLog (b j) = -∑ j, b j * log (b j) := by
    simp only [negMulLog, neg_mul, Finset.sum_neg_distrib]
  rw [hA, hB, hAB, hS] at hsum
  rw [hHP, hHa, hHb]
  linarith

#print axioms eot_joint_entropy_le

/-- The card's main claim (Step 1 with the certificate of Step 2). With entropy weight `ε > 0`,
totals that agree, and every route allowed (every kernel entry `e^(-C_ij/ε)` is positive), take
positive row factors `u` and column factors `v` for which the scaled kernel
`P_ij = u_i e^(-C_ij/ε) v_j` has row sums `a` and column sums `b`. Then this plan is the best plan
of entropic transport: every feasible plan `Q` has entropic value (moving cost minus `ε` times
entropy) at least that of `P`, and a feasible plan with the same value is `P` itself. -/
theorem scaled_kernel_plan_is_unique_entropic_optimum {ι κ : Type*} [Fintype ι] [Fintype κ]
    (a : ι → ℝ) (b : κ → ℝ) (C : ι → κ → ℝ) (ε : ℝ) (hε : 0 < ε)
    (htot : ∑ i, a i = ∑ j, b j)
    (u : ι → ℝ) (v : κ → ℝ) (hu : ∀ i, 0 < u i) (hv : ∀ j, 0 < v j)
    (hProw : ∀ i, ∑ j, u i * exp (-C i j / ε) * v j = a i)
    (hPcol : ∀ j, ∑ i, u i * exp (-C i j / ε) * v j = b j)
    (Q : ι → κ → ℝ) (hQ : ∀ i j, 0 ≤ Q i j)
    (hQrow : ∀ i, ∑ j, Q i j = a i) (hQcol : ∀ j, ∑ i, Q i j = b j) :
    (∑ i, ∑ j, C i j * (u i * exp (-C i j / ε) * v j)
        - ε * ∑ i, ∑ j, negMulLog (u i * exp (-C i j / ε) * v j)
      ≤ ∑ i, ∑ j, C i j * Q i j - ε * ∑ i, ∑ j, negMulLog (Q i j)) ∧
    (∑ i, ∑ j, C i j * Q i j - ε * ∑ i, ∑ j, negMulLog (Q i j)
        = ∑ i, ∑ j, C i j * (u i * exp (-C i j / ε) * v j)
          - ε * ∑ i, ∑ j, negMulLog (u i * exp (-C i j / ε) * v j) →
      ∀ i j, Q i j = u i * exp (-C i j / ε) * v j) := by
  have hPpos : ∀ i j, 0 < u i * exp (-C i j / ε) * v j := fun i j =>
    mul_pos (mul_pos (hu i) (exp_pos _)) (hv j)
  have hlin : ∑ i, ∑ j, ε * (Q i j - u i * exp (-C i j / ε) * v j) * (log (u i) + log (v j) + 1)
      = 0 := by
    have e1 : ∀ i, ∑ j, ε * (Q i j - u i * exp (-C i j / ε) * v j) * (log (u i) + log (v j) + 1)
        = ε * (log (u i) + 1) * (∑ j, Q i j - ∑ j, u i * exp (-C i j / ε) * v j)
          + ∑ j, ε * log (v j) * (Q i j - u i * exp (-C i j / ε) * v j) := by
      intro i
      rw [← Finset.sum_sub_distrib, Finset.mul_sum, ← Finset.sum_add_distrib]
      exact Finset.sum_congr rfl fun j _ => by ring
    simp only [e1, hQrow, hProw, sub_self, mul_zero, zero_add]
    rw [Finset.sum_comm]
    refine Finset.sum_eq_zero fun j _ => ?_
    rw [← Finset.mul_sum, Finset.sum_sub_distrib, hQcol, hPcol, sub_self, mul_zero]
  have key : (∑ i, ∑ j, C i j * Q i j - ε * ∑ i, ∑ j, negMulLog (Q i j))
      - (∑ i, ∑ j, C i j * (u i * exp (-C i j / ε) * v j)
        - ε * ∑ i, ∑ j, negMulLog (u i * exp (-C i j / ε) * v j))
      = ∑ i, ∑ j, ε * (Q i j * log (Q i j) - Q i j * log (u i * exp (-C i j / ε) * v j) - Q i j
          + u i * exp (-C i j / ε) * v j) := by
    have hexp : (∑ i, ∑ j, C i j * Q i j - ε * ∑ i, ∑ j, negMulLog (Q i j))
        - (∑ i, ∑ j, C i j * (u i * exp (-C i j / ε) * v j)
          - ε * ∑ i, ∑ j, negMulLog (u i * exp (-C i j / ε) * v j))
        = ∑ i, ∑ j, ((C i j * Q i j - ε * negMulLog (Q i j))
          - (C i j * (u i * exp (-C i j / ε) * v j)
            - ε * negMulLog (u i * exp (-C i j / ε) * v j))) := by
      simp only [Finset.mul_sum, Finset.sum_sub_distrib]
    rw [hexp]
    have hent : ∀ i j, ((C i j * Q i j - ε * negMulLog (Q i j))
          - (C i j * (u i * exp (-C i j / ε) * v j)
            - ε * negMulLog (u i * exp (-C i j / ε) * v j)))
        = ε * (Q i j - u i * exp (-C i j / ε) * v j) * (log (u i) + log (v j) + 1)
          + ε * (Q i j * log (Q i j) - Q i j * log (u i * exp (-C i j / ε) * v j) - Q i j
            + u i * exp (-C i j / ε) * v j) := fun i j =>
      eot_entry (C i j) ε (Q i j) (u i) (v j) hε (hu i) (hv j)
    simp only [hent, Finset.sum_add_distrib, hlin, zero_add]
  have hg : ∀ i j, 0 ≤ ε * (Q i j * log (Q i j) - Q i j * log (u i * exp (-C i j / ε) * v j)
      - Q i j + u i * exp (-C i j / ε) * v j) := fun i j =>
    mul_nonneg hε.le (eot_gibbs_nonneg _ _ (hPpos i j) (hQ i j))
  have hsum := Finset.sum_nonneg fun i (_ : i ∈ Finset.univ) =>
    Finset.sum_nonneg fun j (_ : j ∈ Finset.univ) => hg i j
  refine ⟨by linarith, fun heq i j => ?_⟩
  have h0 : ∑ i, ∑ j, ε * (Q i j * log (Q i j) - Q i j * log (u i * exp (-C i j / ε) * v j)
      - Q i j + u i * exp (-C i j / ε) * v j) = 0 := by linarith
  rw [Finset.sum_eq_zero_iff_of_nonneg fun i _ =>
    Finset.sum_nonneg fun j (_ : j ∈ Finset.univ) => hg i j] at h0
  have h1 := h0 i (Finset.mem_univ i)
  rw [Finset.sum_eq_zero_iff_of_nonneg fun j _ => hg i j] at h1
  have h2 := h1 j (Finset.mem_univ j)
  rcases mul_eq_zero.1 h2 with h3 | h3
  · exact absurd h3 hε.ne'
  · exact eot_gibbs_eq _ _ (hPpos i j) (hQ i j) h3

/-- Weak duality (Step 2). With `ε > 0`, for any row prices `φ` and column prices `ψ`, every
feasible plan `Q` has entropic value at least the dual value
`q(φ, ψ) = ∑ a_i φ_i + ∑ b_j ψ_j - ε ∑ e^((φ_i + ψ_j - C_ij)/ε - 1)`. -/
theorem entropic_value_ge_dual_value {ι κ : Type*} [Fintype ι] [Fintype κ]
    (a : ι → ℝ) (b : κ → ℝ) (C : ι → κ → ℝ) (ε : ℝ) (hε : 0 < ε)
    (φ : ι → ℝ) (ψ : κ → ℝ)
    (Q : ι → κ → ℝ) (hQ : ∀ i j, 0 ≤ Q i j)
    (hQrow : ∀ i, ∑ j, Q i j = a i) (hQcol : ∀ j, ∑ i, Q i j = b j) :
    ∑ i, a i * φ i + ∑ j, b j * ψ j - ε * ∑ i, ∑ j, exp ((φ i + ψ j - C i j) / ε - 1)
      ≤ ∑ i, ∑ j, C i j * Q i j - ε * ∑ i, ∑ j, negMulLog (Q i j) := by
  have hA : ∑ i, a i * φ i = ∑ i, ∑ j, Q i j * φ i :=
    Finset.sum_congr rfl fun i _ => by rw [← Finset.sum_mul, hQrow i]
  have hB : ∑ j, b j * ψ j = ∑ i, ∑ j, Q i j * ψ j := by
    rw [Finset.sum_comm]; exact Finset.sum_congr rfl fun j _ => by rw [← Finset.sum_mul, hQcol j]
  have hL : ∑ i, a i * φ i + ∑ j, b j * ψ j - ε * ∑ i, ∑ j, exp ((φ i + ψ j - C i j) / ε - 1)
      = ∑ i, ∑ j, (Q i j * φ i + Q i j * ψ j - ε * exp ((φ i + ψ j - C i j) / ε - 1)) := by
    rw [hA, hB]; simp only [Finset.mul_sum, Finset.sum_sub_distrib, Finset.sum_add_distrib]
  have hR : ∑ i, ∑ j, C i j * Q i j - ε * ∑ i, ∑ j, negMulLog (Q i j)
      = ∑ i, ∑ j, (C i j * Q i j - ε * negMulLog (Q i j)) := by
    simp only [Finset.mul_sum, Finset.sum_sub_distrib]
  rw [hL, hR]
  refine Finset.sum_le_sum fun i _ => Finset.sum_le_sum fun j _ => ?_
  have hf := eot_fenchel (Q i j) ((φ i + ψ j - C i j) / ε) (hQ i j)
  have hf' := mul_le_mul_of_nonneg_left hf hε.le
  have ht : ε * ((φ i + ψ j - C i j) / ε) = φ i + ψ j - C i j := by field_simp
  have ht' : ε * (Q i j * ((φ i + ψ j - C i j) / ε)) = Q i j * (φ i + ψ j - C i j) := by
    rw [mul_left_comm, ht]
  rw [negMulLog]
  nlinarith

/-- The bias bound (Step 5). Let the histograms `a` and `b` each add up to 1, and `ε > 0`. If `P`
is a best plan of entropic transport and `Ps` is an exact best plan (least moving cost `W` among
feasible plans), then `0 ≤ cost(P) - W ≤ ε · min(H(a), H(b))`. -/
theorem entropic_bias_le_eps_min_entropy {ι κ : Type*} [Fintype ι] [Fintype κ]
    (a : ι → ℝ) (b : κ → ℝ) (C : ι → κ → ℝ) (ε : ℝ) (hε : 0 < ε)
    (ha1 : ∑ i, a i = 1) (hb1 : ∑ j, b j = 1)
    (P : ι → κ → ℝ) (hP : ∀ i j, 0 ≤ P i j)
    (hProw : ∀ i, ∑ j, P i j = a i) (hPcol : ∀ j, ∑ i, P i j = b j)
    (hPopt : ∀ Q : ι → κ → ℝ, (∀ i j, 0 ≤ Q i j) → (∀ i, ∑ j, Q i j = a i) →
      (∀ j, ∑ i, Q i j = b j) →
      ∑ i, ∑ j, C i j * P i j - ε * ∑ i, ∑ j, negMulLog (P i j)
        ≤ ∑ i, ∑ j, C i j * Q i j - ε * ∑ i, ∑ j, negMulLog (Q i j))
    (Ps : ι → κ → ℝ) (hPs : ∀ i j, 0 ≤ Ps i j)
    (hPsrow : ∀ i, ∑ j, Ps i j = a i) (hPscol : ∀ j, ∑ i, Ps i j = b j)
    (hPsopt : ∀ Q : ι → κ → ℝ, (∀ i j, 0 ≤ Q i j) → (∀ i, ∑ j, Q i j = a i) →
      (∀ j, ∑ i, Q i j = b j) → ∑ i, ∑ j, C i j * Ps i j ≤ ∑ i, ∑ j, C i j * Q i j) :
    0 ≤ ∑ i, ∑ j, C i j * P i j - ∑ i, ∑ j, C i j * Ps i j ∧
    ∑ i, ∑ j, C i j * P i j - ∑ i, ∑ j, C i j * Ps i j
      ≤ ε * min (∑ i, negMulLog (a i)) (∑ j, negMulLog (b j)) := by
  have h0 := hPsopt P hP hProw hPcol
  have h1 := hPopt Ps hPs hPsrow hPscol
  have hJ := eot_joint_entropy_le a b ha1 hb1 P hP hProw hPcol
  have hRa := eot_row_entropy_le a Ps hPs hPsrow
  have hRb := eot_row_entropy_le b (fun j i => Ps i j) (fun j i => hPs i j) hPscol
  rw [Finset.sum_comm] at hRb
  refine ⟨by linarith, ?_⟩
  have hm : ∑ i, ∑ j, negMulLog (P i j) - ∑ i, ∑ j, negMulLog (Ps i j)
      ≤ min (∑ i, negMulLog (a i)) (∑ j, negMulLog (b j)) := le_min (by linarith) (by linarith)
  have hm' := mul_le_mul_of_nonneg_left hm hε.le
  rw [mul_sub] at hm'
  linarith

/-! ### The card's three-bin returns example, exactly

Last year `a = (3/10, 4/10, 3/10)` (75, 100, 75 of 250 days), this year
`b = (2/10, 3/10, 5/10)` (50, 75, 125 days), cost `|i - j|` percentage points. -/

-- The day counts: 250 days times each share.
example : (250 : ℚ) * (3/10) = 75 ∧ (250 : ℚ) * (4/10) = 100 ∧ (250 : ℚ) * (2/10) = 50 ∧
    (250 : ℚ) * (5/10) = 125 := by norm_num

-- The exact plan [[0.2, 0.1, 0], [0, 0.2, 0.2], [0, 0, 0.3]] has row sums a and column sums b.
example :
    let P0 : Matrix (Fin 3) (Fin 3) ℚ := !![2/10, 1/10, 0; 0, 2/10, 2/10; 0, 0, 3/10]
    let a : Fin 3 → ℚ := ![3/10, 4/10, 3/10]
    let b : Fin 3 → ℚ := ![2/10, 3/10, 5/10]
    (∀ i, ∑ j, P0 i j = a i) ∧ (∀ j, ∑ i, P0 i j = b j) := by
  intro P0 a b
  refine ⟨fun i => ?_, fun j => ?_⟩
  · fin_cases i <;> simp [P0, a, Fin.sum_univ_three] <;> norm_num
  · fin_cases j <;> simp [P0, b, Fin.sum_univ_three] <;> norm_num

-- The exact plan's moving cost is 0.3 percentage points.
example :
    let P0 : Matrix (Fin 3) (Fin 3) ℚ := !![2/10, 1/10, 0; 0, 2/10, 2/10; 0, 0, 3/10]
    let C : Matrix (Fin 3) (Fin 3) ℚ := !![0, 1, 2; 1, 0, 1; 2, 1, 0]
    ∑ i, ∑ j, C i j * P0 i j = 3/10 := by
  intro P0 C
  simp [P0, C, Fin.sum_univ_three]
  norm_num

-- The LP dual prices φ = (0, -1, -2), ψ = (0, 1, 2) are fair (φ_i + ψ_j ≤ C_ij) and give 0.3,
-- so no plan costs less than 0.3.
example :
    let φ : Fin 3 → ℚ := ![0, -1, -2]
    let ψ : Fin 3 → ℚ := ![0, 1, 2]
    let C : Matrix (Fin 3) (Fin 3) ℚ := !![0, 1, 2; 1, 0, 1; 2, 1, 0]
    let a : Fin 3 → ℚ := ![3/10, 4/10, 3/10]
    let b : Fin 3 → ℚ := ![2/10, 3/10, 5/10]
    (∀ i j, φ i + ψ j ≤ C i j) ∧ ∑ i, a i * φ i + ∑ j, b j * ψ j = 3/10 := by
  intro φ ψ C a b
  refine ⟨fun i j => ?_, ?_⟩
  · fin_cases i <;> fin_cases j <;> norm_num [φ, ψ, C]
  · simp [φ, ψ, a, b, Fin.sum_univ_three]
    norm_num

-- The running-sum formula: |0.3 - 0.2| + |0.7 - 0.5| = 0.3.
example : |(3/10 : ℚ) - 2/10| + |(7/10 : ℚ) - 5/10| = 3/10 := by norm_num [abs_of_pos]

-- The largest swap saving on three bins is θ = 4: every swap saves at most 4, and swapping the
-- routes 1 → 3 and 3 → 1 into 1 → 1 and 3 → 3 saves exactly 4.
example :
    let C : Fin 3 → Fin 3 → ℤ := fun i j => |(i : ℤ) - j|
    (∀ i i' j j' : Fin 3, C i j' + C i' j - C i j - C i' j' ≤ 4) ∧
      C 0 2 + C 2 0 - C 0 0 - C 2 2 = 4 := by
  decide

#print axioms scaled_kernel_plan_is_unique_entropic_optimum
#print axioms entropic_value_ge_dual_value
#print axioms entropic_bias_le_eps_min_entropy
