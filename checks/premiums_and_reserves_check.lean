-- Premiums and reserves: the prospective reserve of an n-year term policy is zero at expiry and obeys the one-year recursion, and the office's fund equals survivors times the reserve at every year exactly when the premium is set by the equivalence principle.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Algebra.BigOperators.Ring.Finset

/-!
Setting, as on the card. Policy years are counted from issue: `q k` is the chance
that a life aged `x + k` dies within the year (the card's `q_{x+k}`), so `1 - q k`
is `p_{x+k}`. Money grows at the continuously compounded rate `r`, so one year's
discount factor is `v = e^{-r}`. `S` is the sum insured, paid at the end of the
year of death; `P` is the level net premium, paid at the start of each year while
alive. The cover runs for `n` years.
-/

noncomputable section

namespace PremiumsAndReserves

open Finset

/-- `₍k₎p`: the chance that a life in policy year `t` survives the next `k` years. -/
def survival (q : ℕ → ℝ) (t k : ℕ) : ℝ :=
  ∏ j ∈ range k, (1 - q (t + j))

/-- `A_{x+t : m}`: today's value of `1` paid at the end of the year of death,
if death comes within `m` years, for a life now in policy year `t`. -/
def insurance (q : ℕ → ℝ) (v : ℝ) (t m : ℕ) : ℝ :=
  ∑ k ∈ range m, v ^ (k + 1) * survival q t k * q (t + k)

/-- `ä_{x+t : m}`: today's value of `1` paid at the start of each year while alive,
at most `m` payments, for a life now in policy year `t`. -/
def annuityDue (q : ℕ → ℝ) (v : ℝ) (t m : ℕ) : ℝ :=
  ∑ k ∈ range m, v ^ k * survival q t k

/-- The prospective reserve `V_t = S A_{x+t : n-t} - P ä_{x+t : n-t}`,
valued at rate `r` (discount factor `e^{-r}`), just before year `t`'s premium. -/
def reserve (q : ℕ → ℝ) (r S P : ℝ) (n t : ℕ) : ℝ :=
  S * insurance q (Real.exp (-r)) t (n - t) - P * annuityDue q (Real.exp (-r)) t (n - t)

/-- `l_t`: the office's expected survivors at year `t`, starting from `l0` policies. -/
def survivors (q : ℕ → ℝ) (l0 : ℝ) : ℕ → ℝ
  | 0 => l0
  | t + 1 => survivors q l0 t * (1 - q t)

/-- `l_t F_t`: the office's whole fund at year `t`, run forward from an empty fund.
Each year the survivors pay the premium, the fund grows by `e^r`, and the
expected deaths are paid `S` each. -/
def officeFund (q : ℕ → ℝ) (r S P l0 : ℝ) : ℕ → ℝ
  | 0 => 0
  | t + 1 => (officeFund q r S P l0 t + survivors q l0 t * P) * Real.exp r
      - survivors q l0 t * q t * S

lemma survival_succ (q : ℕ → ℝ) (t k : ℕ) :
    survival q t (k + 1) = (1 - q t) * survival q (t + 1) k := by
  unfold survival
  rw [prod_range_succ', mul_comm, add_zero]
  congr 1
  apply prod_congr rfl
  intro i _
  rw [show t + (i + 1) = t + 1 + i by omega]

lemma insurance_succ (q : ℕ → ℝ) (v : ℝ) (t m : ℕ) :
    insurance q v t (m + 1) = v * q t + v * (1 - q t) * insurance q v (t + 1) m := by
  unfold insurance
  rw [sum_range_succ', mul_sum]
  have h0 : v ^ (0 + 1) * survival q t 0 * q (t + 0) = v * q t := by simp [survival]
  rw [h0, add_comm]
  congr 1
  apply sum_congr rfl
  intro i _
  rw [survival_succ, show t + (i + 1) = t + 1 + i by omega]
  ring

lemma annuityDue_succ (q : ℕ → ℝ) (v : ℝ) (t m : ℕ) :
    annuityDue q v t (m + 1) = 1 + v * (1 - q t) * annuityDue q v (t + 1) m := by
  unfold annuityDue
  rw [sum_range_succ', mul_sum]
  have h0 : v ^ 0 * survival q t 0 = 1 := by simp [survival]
  rw [h0, add_comm]
  congr 1
  apply sum_congr rfl
  intro i _
  rw [survival_succ]
  ring

#print axioms survival_succ
#print axioms insurance_succ
#print axioms annuityDue_succ

/-- The card's main theorem. The prospective reserve of an `n`-year term policy is
zero when the cover expires, `V_n = 0`, and for every year `t` before expiry it obeys
the one-year recursion `(V_t + P) e^r = q_{x+t} S + p_{x+t} V_{t+1}`: the reserve plus
this year's premium, grown for one year at interest, pays the death benefit to those
who die and the next reserve to those who live. -/
theorem reserve_recursion (q : ℕ → ℝ) (r S P : ℝ) (n : ℕ) :
    reserve q r S P n n = 0 ∧
      ∀ t < n, (reserve q r S P n t + P) * Real.exp r
        = q t * S + (1 - q t) * reserve q r S P n (t + 1) := by
  constructor
  · simp [reserve, insurance, annuityDue]
  · intro t ht
    obtain ⟨m, hm⟩ : ∃ m, n - t = m + 1 := ⟨n - t - 1, by omega⟩
    have hm' : n - (t + 1) = m := by omega
    unfold reserve
    rw [hm, hm', insurance_succ, annuityDue_succ]
    have he : Real.exp (-r) * Real.exp r = 1 := by
      rw [← Real.exp_add]; simp
    linear_combination (q t * S + (1 - q t) *
      (S * insurance q (Real.exp (-r)) (t + 1) m
        - P * annuityDue q (Real.exp (-r)) (t + 1) m)) * he

/-- Retrospective equals prospective. Start an office with `l0 ≠ 0` policies and an
empty fund. Its fund at every year `t ≤ n` equals the survivors times the reserve,
`l_t F_t = l_t V_t`, exactly when the premium is set by the equivalence principle,
`P ä_{x:n} = S A_{x:n}`: equivalence is the condition that makes "what the pool has
saved" and "what the pool will need" the same number. -/
theorem office_fund_eq_reserve_iff_equivalence (q : ℕ → ℝ) (r S P l0 : ℝ) (n : ℕ)
    (hl0 : l0 ≠ 0) :
    (∀ t ≤ n, officeFund q r S P l0 t = survivors q l0 t * reserve q r S P n t) ↔
      P * annuityDue q (Real.exp (-r)) 0 n = S * insurance q (Real.exp (-r)) 0 n := by
  have key : ∀ t < n, officeFund q r S P l0 (t + 1) - survivors q l0 (t + 1) * reserve q r S P n (t + 1)
      = (officeFund q r S P l0 t - survivors q l0 t * reserve q r S P n t) * Real.exp r := by
    intro t ht
    have h := (reserve_recursion q r S P n).2 t ht
    simp only [officeFund, survivors]
    linear_combination (survivors q l0 t) * h
  constructor
  · intro h
    have h0 := h 0 (Nat.zero_le _)
    simp only [officeFund, survivors, reserve, Nat.sub_zero] at h0
    have h1 := (mul_eq_zero.mp h0.symm).resolve_left hl0
    linarith
  · intro heq t ht
    induction t with
    | zero =>
      simp only [officeFund, survivors, reserve, Nat.sub_zero]
      rw [heq, sub_self, mul_zero]
    | succ t ih =>
      have h1 := key t (by omega)
      have ih' := ih (by omega)
      linear_combination h1 + Real.exp r * ih'

#print axioms reserve_recursion
#print axioms office_fund_eq_reserve_iff_equivalence

end PremiumsAndReserves

end
