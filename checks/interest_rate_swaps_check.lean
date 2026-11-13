-- Interest rate swaps: on a reset date, with one curve for forwards and discounting, the payer's swap valued as a strip of forwards equals a par floating-rate note less a fixed-coupon bond.
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Real.Basic
import Mathlib

open Finset

/-- The forward rate for period `i`, read off the discount curve `D` with year fractions `α`:
`F_i = (1 / α_i) * (D_{i-1} / D_i - 1)`. -/
noncomputable def forwardRate (α D : ℕ → ℝ) (i : ℕ) : ℝ :=
  (1 / α i) * (D (i - 1) / D i - 1)

/-- Telescoping helper: `∑_{i=1}^n (D_{i-1} - D_i) = D_0 - D_n`. -/
theorem sum_Icc_telescope_aux (n : ℕ) (D : ℕ → ℝ) :
    ∑ i ∈ Icc 1 n, (D (i - 1) - D i) = D 0 - D n := by
  induction n with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_Icc_succ_top (by omega), ih]
    simp

#print axioms sum_Icc_telescope_aux

/-- Helper: the floating leg as a telescoping sum, `∑ N α_i F_i D_i = N (D_0 - D_n)`. -/
theorem floating_leg_telescopes_aux (n : ℕ) (N : ℝ) (α D : ℕ → ℝ)
    (hD : ∀ i ∈ Icc 1 n, D i ≠ 0) (hα : ∀ i ∈ Icc 1 n, α i ≠ 0) :
    ∑ i ∈ Icc 1 n, N * α i * forwardRate α D i * D i = N * (D 0 - D n) := by
  rw [← sum_Icc_telescope_aux n D, Finset.mul_sum]
  refine Finset.sum_congr rfl fun i hi => ?_
  have h1 := hD i hi
  have h2 := hα i hi
  unfold forwardRate
  field_simp

#print axioms floating_leg_telescopes_aux

/-- The card's main claim. On a reset date (`D 0 = 1`), with the floating rates projected from the
same curve that discounts them, the payer's swap valued as a strip of forwards,
`∑ N α_i (F_i - K) D_i`, equals the two-bond value: a floating-rate note worth its face `N`, less a
fixed-coupon bond `∑ N α_i K D_i + N D_n`. -/
theorem swap_strip_of_forwards_eq_note_less_fixed_bond (n : ℕ) (N K : ℝ) (α D : ℕ → ℝ)
    (hD0 : D 0 = 1)
    (hD : ∀ i ∈ Icc 1 n, D i ≠ 0) (hα : ∀ i ∈ Icc 1 n, α i ≠ 0) :
    ∑ i ∈ Icc 1 n, N * α i * (forwardRate α D i - K) * D i
      = N - (∑ i ∈ Icc 1 n, N * α i * K * D i + N * D n) := by
  have hfl := floating_leg_telescopes_aux n N α D hD hα
  rw [hD0] at hfl
  have : ∑ i ∈ Icc 1 n, N * α i * (forwardRate α D i - K) * D i
      = ∑ i ∈ Icc 1 n, N * α i * forwardRate α D i * D i - ∑ i ∈ Icc 1 n, N * α i * K * D i := by
    rw [← Finset.sum_sub_distrib]
    refine Finset.sum_congr rfl fun i _ => ?_
    ring
  rw [this, hfl]
  ring

/-- The floating leg telescopes: the floating payments, each valued at its forward rate and
discounted, add up to the notional less its discounted repayment, `N (1 - D_n)`. -/
theorem floating_leg_telescopes (n : ℕ) (N : ℝ) (α D : ℕ → ℝ)
    (hD0 : D 0 = 1)
    (hD : ∀ i ∈ Icc 1 n, D i ≠ 0) (hα : ∀ i ∈ Icc 1 n, α i ≠ 0) :
    ∑ i ∈ Icc 1 n, N * α i * forwardRate α D i * D i = N * (1 - D n) := by
  rw [floating_leg_telescopes_aux n N α D hD hα, hD0]

/-- A floating-rate note is worth its face on every reset date, whatever rates do. Let `L i` be the
rate read at the start of period `i` (any path of rates), and roll the note back from its end:
it is worth `N` at the last date, and at each earlier reset it is worth the coupon `N α_i L_i` plus
the note's value at the next date, discounted over the period at that same rate. Then its value
is `N` on every reset date. -/
theorem floating_rate_note_par_at_every_reset (n : ℕ) (N : ℝ) (α L V : ℕ → ℝ)
    (hL : ∀ i ∈ Icc 1 n, 1 + α i * L i ≠ 0)
    (hVn : V n = N)
    (hstep : ∀ i ∈ Icc 1 n, V (i - 1) = (N * α i * L i + V i) / (1 + α i * L i)) :
    ∀ i ≤ n, V i = N := by
  have key : ∀ k ≤ n, V (n - k) = N := by
    intro k
    induction k with
    | zero => intro _; simpa using hVn
    | succ k ih =>
      intro hk
      have hmem : n - k ∈ Icc 1 n := Finset.mem_Icc.mpr ⟨by omega, by omega⟩
      have h1 := hstep (n - k) hmem
      have h2 := hL (n - k) hmem
      rw [ih (by omega)] at h1
      have e : n - (k + 1) = n - k - 1 := by omega
      rw [e, h1]
      field_simp
      ring
  intro i hi
  have := key (n - i) (by omega)
  rwa [show n - (n - i) = i by omega] at this

#print axioms swap_strip_of_forwards_eq_note_less_fixed_bond
#print axioms floating_leg_telescopes
#print axioms floating_rate_note_par_at_every_reset
