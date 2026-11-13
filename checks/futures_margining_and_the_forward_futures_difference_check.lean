-- Futures: with a known bank account, tailing the position by the bank's growth to expiry turns the daily margin ledger into the forward's payoff on every record, and in general the forward price is the futures price plus a covariance.
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Algebra.BigOperators.Ring.Finset

open Finset BigOperators

/-- Helper: the ledger run to any date `n ≤ N`. -/
theorem margin_ledger_sum_upto
    (N : ℕ) (F B h V : ℕ → ℝ)
    (hB : ∀ i, 0 < B i)
    (hV0 : V 0 = 0)
    (hledger : ∀ i < N, V (i + 1) = V i * (B (i + 1) / B i) + h i * (F (i + 1) - F i)) :
    ∀ n ≤ N, V n = ∑ i ∈ range n, h i * (B n / B (i + 1)) * (F (i + 1) - F i) := by
  intro n
  induction n with
  | zero => intro _; simp [hV0]
  | succ n ih =>
    intro hn
    have hn' : n < N := hn
    rw [hledger n hn', ih (le_of_lt hn'), Finset.sum_range_succ, Finset.sum_mul]
    have hBn : B n ≠ 0 := (hB n).ne'
    have hBn1 : B (n + 1) ≠ 0 := (hB (n + 1)).ne'
    congr 1
    · apply Finset.sum_congr rfl
      intro i _
      have hBi : B (i + 1) ≠ 0 := (hB (i + 1)).ne'
      field_simp
    · field_simp

#print axioms margin_ledger_sum_upto

/-- Tailing replicates the forward. Settlement dates run 0, 1, ..., N. On every record `ω`
the futures quote is `F ω i`, starting from today's quote `F₀` and ending at the share's own
price `F ω N = S ω`. The bank account `B i` is positive and known in advance (the same on every
record). The margin account starts empty and follows the ledger
`V (i+1) = V i * B (i+1) / B i + h i * (F (i+1) - F i)`. If the contracts carried over each
period are the fixed tail `h i = B (i+1) / B N`, then on every record the account ends at
`S ω - F₀`, the payoff of a forward struck at today's quote. -/
theorem tailed_futures_replicates_forward
    {Ω : Type*} (N : ℕ) (F : Ω → ℕ → ℝ) (S : Ω → ℝ) (F₀ : ℝ) (B : ℕ → ℝ)
    (h : ℕ → ℝ) (V : Ω → ℕ → ℝ)
    (hB : ∀ i, 0 < B i)
    (hstart : ∀ ω, F ω 0 = F₀)
    (hlast : ∀ ω, F ω N = S ω)
    (hV0 : ∀ ω, V ω 0 = 0)
    (hledger : ∀ ω, ∀ i < N, V ω (i + 1) = V ω i * (B (i + 1) / B i) + h i * (F ω (i + 1) - F ω i))
    (htail : ∀ i < N, h i = B (i + 1) / B N) :
    ∀ ω, V ω N = S ω - F₀ := by
  intro ω
  have hsum := margin_ledger_sum_upto N (F ω) B h (V ω) hB (hV0 ω) (hledger ω) N le_rfl
  rw [hsum]
  have hterm : ∀ i ∈ range N, h i * (B N / B (i + 1)) * (F ω (i + 1) - F ω i)
      = F ω (i + 1) - F ω i := by
    intro i hi
    rw [htail i (Finset.mem_range.mp hi)]
    have hBi : B (i + 1) ≠ 0 := (hB (i + 1)).ne'
    have hBN : B N ≠ 0 := (hB N).ne'
    field_simp
  rw [Finset.sum_congr rfl hterm, Finset.sum_range_sub (fun i => F ω i), hlast ω, hstart ω]

/-- The ledger, run to expiry. If the margin account starts empty and each evening its balance
grows at the bank rate and then the settlement `h i * (F (i+1) - F i)` is added, then at expiry
every settlement has been carried forward from its own date:
`V N = ∑ i < N, h i * (B N / B (i+1)) * (F (i+1) - F i)`. The sizes `h i` may be any real
numbers. -/
theorem margin_ledger_sum
    (N : ℕ) (F B h V : ℕ → ℝ)
    (hB : ∀ i, 0 < B i)
    (hV0 : V 0 = 0)
    (hledger : ∀ i < N, V (i + 1) = V i * (B (i + 1) / B i) + h i * (F (i + 1) - F i)) :
    V N = ∑ i ∈ range N, h i * (B N / B (i + 1)) * (F (i + 1) - F i) := by
  exact margin_ledger_sum_upto N F B h V hB hV0 hledger N le_rfl

/-- The gap is a covariance. On finitely many records with risk-neutral weights `p` (nonnegative,
summing to 1), let `D` be today's worth of a dollar paid at expiry (positive) and `S` the
finishing price. The futures price is the plain average `E[S]`; the forward price is
`E[D S] / E[D]`. Then the forward price equals the futures price plus
`Cov(D, S) / E[D]`, where `Cov(D, S) = E[(D - E[D]) (S - E[S])]`. -/
theorem forward_price_eq_futures_price_add_cov
    {Ω : Type*} [Fintype Ω] (p D S : Ω → ℝ)
    (hp : ∀ ω, 0 ≤ p ω) (hp1 : ∑ ω, p ω = 1) (hD : ∀ ω, 0 < D ω) :
    (∑ ω, p ω * (D ω * S ω)) / (∑ ω, p ω * D ω) =
      (∑ ω, p ω * S ω) +
        (∑ ω, p ω * ((D ω - ∑ ω', p ω' * D ω') * (S ω - ∑ ω', p ω' * S ω'))) /
          (∑ ω, p ω * D ω) := by
  have hpos : 0 < ∑ ω, p ω * D ω := by
    have hex : ∃ ω, 0 < p ω := by
      by_contra hc
      push Not at hc
      have : ∑ ω, p ω ≤ 0 := Finset.sum_nonpos (fun ω _ => hc ω)
      linarith
    obtain ⟨ω₀, hω₀⟩ := hex
    exact Finset.sum_pos' (fun ω _ => mul_nonneg (hp ω) (hD ω).le)
      ⟨ω₀, Finset.mem_univ _, mul_pos hω₀ (hD ω₀)⟩
  have hcov : (∑ ω, p ω * ((D ω - ∑ ω', p ω' * D ω') * (S ω - ∑ ω', p ω' * S ω')))
      = (∑ ω, p ω * (D ω * S ω)) - (∑ ω, p ω * D ω) * (∑ ω, p ω * S ω) := by
    set ED := ∑ ω', p ω' * D ω'
    set ES := ∑ ω', p ω' * S ω'
    have e : ∀ ω, p ω * ((D ω - ED) * (S ω - ES))
        = p ω * (D ω * S ω) - ES * (p ω * D ω) - ED * (p ω * S ω) + ED * ES * p ω := by
      intro ω; ring
    simp only [e, Finset.sum_add_distrib, Finset.sum_sub_distrib, ← Finset.mul_sum, hp1]
    ring
  rw [hcov]
  field_simp
  ring

#print axioms tailed_futures_replicates_forward
#print axioms margin_ledger_sum
#print axioms forward_price_eq_futures_price_add_cov
