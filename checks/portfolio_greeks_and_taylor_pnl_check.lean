-- Portfolio Greeks: every Greek of a book is the signed sum of its positions' Greeks, the explained and unexplained P&L split by position, and a future's delta, gamma and theta follow from its price.
import Mathlib.Analysis.Calculus.ContDiff.Operations
import Mathlib.Analysis.SpecialFunctions.ExpDeriv

open Finset

/-- A book's Greeks are the signed sums of its positions' Greeks. The book holds a fixed signed
quantity `n i` of each position `i`, and one unit of position `i` is worth `V i y` when the
market inputs (Acme's price, volatility, time) are `y`. If every position's value is smooth to
order `k` near today's inputs `x`, then the book's `k`-th derivative at `x` (delta and vega and
theta for `k = 1`; gamma, vanna and volga for `k = 2`) is the sum over positions of the signed
quantity times that position's `k`-th derivative. -/
theorem portfolio_greeks_are_signed_sums {ι E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (s : Finset ι) (n : ι → ℝ) (V : ι → E → ℝ) (x : E) (k : ℕ)
    (hV : ∀ i ∈ s, ContDiffAt ℝ k (V i) x) :
    iteratedFDeriv ℝ k (fun y => ∑ i ∈ s, n i * V i y) x
      = ∑ i ∈ s, n i • iteratedFDeriv ℝ k (V i) x := by
  rw [iteratedFDeriv_fun_sum_apply (f := fun i y => n i * V i y)
    (fun i hi => contDiffAt_const.mul (hV i hi))]
  refine Finset.sum_congr rfl fun i hi => ?_
  exact iteratedFDeriv_const_smul_apply' (a := n i) (hV i hi)

/-- The card's explained P&L: delta times the move in Acme, plus half gamma times that move
squared, plus vega times the volatility move, plus theta times the time gone, plus vanna times
both moves, plus half volga times the volatility move squared. -/
noncomputable def explainedPnL (delta gamma vega theta vanna volga dS dσ dt : ℝ) : ℝ :=
  delta * dS + 1 / 2 * gamma * dS ^ 2 + vega * dσ + theta * dt + vanna * dS * dσ
    + 1 / 2 * volga * dσ ^ 2

/-- The explained P&L and the unexplained P&L both add across positions. Feed the book's summed
Greeks into the expansion and you get the sum of each position's explained P&L (each position's
Greeks being its unit Greeks times its signed quantity). The book's unexplained P&L, its full
repriced change minus its explained P&L, is the sum of each position's unexplained P&L. -/
theorem explained_and_unexplained_pnl_add_by_position {ι : Type*} (s : Finset ι) (n : ι → ℝ)
    (V₀ V₁ delta gamma vega theta vanna volga : ι → ℝ) (dS dσ dt : ℝ) :
    explainedPnL (∑ i ∈ s, n i * delta i) (∑ i ∈ s, n i * gamma i) (∑ i ∈ s, n i * vega i)
        (∑ i ∈ s, n i * theta i) (∑ i ∈ s, n i * vanna i) (∑ i ∈ s, n i * volga i) dS dσ dt
      = ∑ i ∈ s, explainedPnL (n i * delta i) (n i * gamma i) (n i * vega i) (n i * theta i)
          (n i * vanna i) (n i * volga i) dS dσ dt
    ∧
    ((∑ i ∈ s, n i * V₁ i) - (∑ i ∈ s, n i * V₀ i))
        - explainedPnL (∑ i ∈ s, n i * delta i) (∑ i ∈ s, n i * gamma i)
            (∑ i ∈ s, n i * vega i) (∑ i ∈ s, n i * theta i) (∑ i ∈ s, n i * vanna i)
            (∑ i ∈ s, n i * volga i) dS dσ dt
      = ∑ i ∈ s, ((n i * V₁ i - n i * V₀ i)
          - explainedPnL (n i * delta i) (n i * gamma i) (n i * vega i) (n i * theta i)
              (n i * vanna i) (n i * volga i) dS dσ dt) := by
  unfold explainedPnL
  refine ⟨?_, ?_⟩
  · simp only [Finset.sum_add_distrib, Finset.sum_mul, Finset.mul_sum]
  · simp only [Finset.sum_sub_distrib, Finset.sum_add_distrib, Finset.sum_mul, Finset.mul_sum]

/-- A future's Greeks come from its price `F = S e^{(r - q)(T - t)}`, where `T` is its date and
`t` the time gone. Its delta is `e^{(r - q)(T - t)}`, its gamma is zero because the price is a
straight line in `S`, and its theta (the slope in time gone) is `-(r - q) F`. -/
theorem future_greeks_from_price (r q T S t : ℝ) :
    HasDerivAt (fun S' => S' * Real.exp ((r - q) * (T - t))) (Real.exp ((r - q) * (T - t))) S
    ∧ deriv (deriv (fun S' => S' * Real.exp ((r - q) * (T - t)))) S = 0
    ∧ HasDerivAt (fun t' => S * Real.exp ((r - q) * (T - t')))
        (-(r - q) * (S * Real.exp ((r - q) * (T - t)))) t := by
  have hlin : ∀ (c y : ℝ), HasDerivAt (fun S' : ℝ => S' * c) c y := fun c y => by
    simpa using (hasDerivAt_id y).mul_const c
  refine ⟨hlin _ S, ?_, ?_⟩
  · have : deriv (fun S' : ℝ => S' * Real.exp ((r - q) * (T - t))) =
        fun _ => Real.exp ((r - q) * (T - t)) := funext fun y => (hlin _ y).deriv
    rw [this]
    simp
  · have h1 : HasDerivAt (fun t' : ℝ => (r - q) * (T - t')) ((r - q) * (0 - 1)) t :=
      ((hasDerivAt_const t T).sub (hasDerivAt_id t)).const_mul (r - q)
    have h2 := (h1.exp).const_mul S
    convert h2 using 1
    ring

#print axioms portfolio_greeks_are_signed_sums
#print axioms explained_and_unexplained_pnl_add_by_position
#print axioms future_greeks_from_price
