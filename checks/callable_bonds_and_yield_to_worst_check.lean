-- Callable bonds: on any three-branch rate tree the callable bond's rolled-back value equals the straight bond's minus the issuer's rolled-back call option at every node, each end year's yield exists and is unique exactly when the price is above zero, and yields rise with the end year above par and fall with it below par.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum
import Mathlib

namespace CallableBond

open Finset

/-! ## The tree

A three-branch rate tree with `N` steps of length `Δt`. Node `(i, j)` is rung `j` at step `i`.
At each node the tree gives the short rate `r i j`, the branch weights `pu`, `pm`, `pd`, and the
rungs `up`, `mid`, `dn` the three branches lead to at step `i + 1` (at the edge rungs these bend
inwards, so they are left as arbitrary functions). -/

/-- A three-branch rate tree: short rates, branch weights and child rungs at every node. -/
structure Tree where
  Δt : ℝ
  r : ℕ → ℤ → ℝ
  pu : ℕ → ℤ → ℝ
  pm : ℕ → ℤ → ℝ
  pd : ℕ → ℤ → ℝ
  up : ℕ → ℤ → ℤ
  mid : ℕ → ℤ → ℤ
  dn : ℕ → ℤ → ℤ

/-- The keep value `R_{i,j}[V]` at node `(i, j)`, when `f` gives `V` on the rungs of step `i + 1`:
`e^{-r_{i,j} Δt} (p_u V_{i+1,up} + p_m V_{i+1,mid} + p_d V_{i+1,dn})`. -/
noncomputable def keep (T : Tree) (i : ℕ) (f : ℤ → ℝ) (j : ℤ) : ℝ :=
  Real.exp (-(T.r i j * T.Δt)) *
    (T.pu i j * f (T.up i j) + T.pm i j * f (T.mid i j) + T.pd i j * f (T.dn i j))

/-! ## The contract and the three rollbacks

`cpn i` is the coupon paid at step `i` (zero between coupon dates), `last` is what every node pays
at maturity, step `N` (the last coupon plus the face), `K` is the call price and `calls` is the set
of call steps. Values are indexed by `k`, the number of steps still to run, so step `i` is
`k = N - i`. -/

/-- The straight bond: `S = last` at maturity, and `S_{i,j} = cpn i + R_{i,j}[S]` before. -/
noncomputable def straight (T : Tree) (N : ℕ) (cpn : ℕ → ℝ) (last : ℝ) : ℕ → ℤ → ℝ
  | 0 => fun _ => last
  | k + 1 => fun j => cpn (N - (k + 1)) + keep T (N - (k + 1)) (straight T N cpn last k) j

/-- The callable bond: `C = last` at maturity; `C_{i,j} = cpn i + min(K, R_{i,j}[C])` at a call
date, and `C_{i,j} = cpn i + R_{i,j}[C]` otherwise. -/
noncomputable def callable (T : Tree) (N : ℕ) (cpn : ℕ → ℝ) (last K : ℝ) (calls : Finset ℕ) :
    ℕ → ℤ → ℝ
  | 0 => fun _ => last
  | k + 1 => fun j =>
      if N - (k + 1) ∈ calls then
        cpn (N - (k + 1)) + min K (keep T (N - (k + 1)) (callable T N cpn last K calls k) j)
      else
        cpn (N - (k + 1)) + keep T (N - (k + 1)) (callable T N cpn last K calls k) j

/-- The issuer's call option on the straight bond: `O = 0` at maturity;
`O_{i,j} = max(R_{i,j}[S] - K, R_{i,j}[O])` at a call date, and `O_{i,j} = R_{i,j}[O]` otherwise. -/
noncomputable def option (T : Tree) (N : ℕ) (cpn : ℕ → ℝ) (last K : ℝ) (calls : Finset ℕ) :
    ℕ → ℤ → ℝ
  | 0 => fun _ => 0
  | k + 1 => fun j =>
      if N - (k + 1) ∈ calls then
        max (keep T (N - (k + 1)) (straight T N cpn last k) j - K)
          (keep T (N - (k + 1)) (option T N cpn last K calls k) j)
      else
        keep T (N - (k + 1)) (option T N cpn last K calls k) j

/-- The keep value is linear: rolling back a difference is the difference of the rollbacks. -/
theorem keep_sub (T : Tree) (i : ℕ) (f g : ℤ → ℝ) (j : ℤ) :
    keep T i (fun x => f x - g x) j = keep T i f j - keep T i g j := by
  unfold keep; ring

#print axioms keep_sub

/-- **Callable equals straight minus call.** On one tree, with one coupon schedule, one maturity
payment, one call price and one set of call dates used by all three rollbacks, the callable bond
is worth the straight bond minus the issuer's call option at every node `(i, j)` with `i ≤ N`,
today's root included. -/
theorem callable_eq_straight_sub_option (T : Tree) (N : ℕ) (cpn : ℕ → ℝ) (last K : ℝ)
    (calls : Finset ℕ) (i : ℕ) (hi : i ≤ N) (j : ℤ) :
    callable T N cpn last K calls (N - i) j =
      straight T N cpn last (N - i) j - option T N cpn last K calls (N - i) j := by
  have key : ∀ k : ℕ, ∀ j : ℤ, callable T N cpn last K calls k j =
      straight T N cpn last k j - option T N cpn last K calls k j := by
    intro k
    induction k with
    | zero => intro j; simp [callable, straight, option]
    | succ k ih =>
      intro j
      have hf : callable T N cpn last K calls k =
          fun x => straight T N cpn last k x - option T N cpn last K calls k x := funext ih
      simp only [callable, straight, option]
      rw [hf, keep_sub]
      split_ifs
      · simp only [min_def, max_def]
        split_ifs <;> linarith
      · ring
  exact key (N - i) j

/-! ## Yields

The schedule "coupon `c` each year to year `e`, then `K` at year `e`" priced at the annual
yield `y`: `Σ_{t=1}^{e} c/(1+y)^t + K/(1+y)^e`. -/

/-- Value of the fixed schedule ending at year `e`, at annual yield `y`. -/
noncomputable def schedValue (c K : ℝ) (e : ℕ) (y : ℝ) : ℝ :=
  (∑ t ∈ Icc 1 e, c / (1 + y) ^ t) + K / (1 + y) ^ e

theorem schedValue_sub_eq (c K : ℝ) (e : ℕ) (y : ℝ) (hy : -1 < y) :
    schedValue c K e y - K = (c - K * y) * ∑ t ∈ Icc 1 e, 1 / (1 + y) ^ t := by
  have hx : (1 + y) ≠ 0 := by linarith
  induction e with
  | zero => simp [schedValue]
  | succ n ih =>
    unfold schedValue at ih ⊢
    rw [Finset.sum_Icc_succ_top (by omega), Finset.sum_Icc_succ_top (by omega), mul_add]
    have h2 : (∑ t ∈ Icc 1 n, c / (1 + y) ^ t) = (c - K * y) * ∑ t ∈ Icc 1 n, 1 / (1 + y) ^ t
        + K - K / (1 + y) ^ n := by linarith
    rw [h2]
    field_simp
    ring

#print axioms schedValue_sub_eq

theorem schedValue_strictAntiOn (c K : ℝ) (e : ℕ) (hc : 0 ≤ c) (hK : 0 < K) (he : 1 ≤ e) :
    StrictAntiOn (schedValue c K e) (Set.Ioi (-1)) := by
  intro a ha b hb hab
  simp only [Set.mem_Ioi] at ha hb
  unfold schedValue
  have h1 : (∑ t ∈ Icc 1 e, c / (1 + b) ^ t) ≤ ∑ t ∈ Icc 1 e, c / (1 + a) ^ t := by
    apply Finset.sum_le_sum
    intro t _
    have : 0 < 1 + a := by linarith
    apply div_le_div_of_nonneg_left hc (by positivity)
    exact pow_le_pow_left₀ (by linarith) (by linarith) t
  have h2 : K / (1 + b) ^ e < K / (1 + a) ^ e := by
    apply div_lt_div_of_pos_left hK (by have : 0 < 1 + a := by linarith
                                        positivity)
    exact pow_lt_pow_left₀ (by linarith) (by linarith) (by omega)
  linarith

#print axioms schedValue_strictAntiOn

theorem schedValue_pos (c K : ℝ) (e : ℕ) (y : ℝ) (hc : 0 ≤ c) (hK : 0 < K) (hy : -1 < y) :
    0 < schedValue c K e y := by
  have : 0 < 1 + y := by linarith
  unfold schedValue
  have : 0 ≤ ∑ t ∈ Icc 1 e, c / (1 + y) ^ t := Finset.sum_nonneg (fun t _ => by positivity)
  have : 0 < K / (1 + y) ^ e := by positivity
  linarith

#print axioms schedValue_pos

/-- **Each yield exists and is unique.** For a positive coupon, a positive repayment and an end
year `e ≥ 1`, a price `P` has exactly one yield above `-1` for that end year when `P` is above
zero, and none when `P` is zero or less. -/
theorem yield_exists_unique_iff_price_pos (c K P : ℝ) (e : ℕ) (hc : 0 < c) (hK : 0 < K)
    (he : 1 ≤ e) :
    (∃! y : ℝ, -1 < y ∧ schedValue c K e y = P) ↔ 0 < P := by
  constructor
  · rintro ⟨y, ⟨hy, hP⟩, _⟩
    rw [← hP]; exact schedValue_pos c K e y hc.le hK hy
  · intro hP
    set g : ℝ → ℝ := fun v => (∑ t ∈ Icc 1 e, c * v ^ t) + K * v ^ e with hg
    have gcont : Continuous g := by rw [hg]; fun_prop
    set M : ℝ := max 1 (P / K)
    have hM1 : 1 ≤ M := le_max_left _ _
    have g0 : g 0 = 0 := by
      simp only [hg]
      rw [Finset.sum_eq_zero]
      · simp; exact Or.inr (Nat.ne_of_gt he)
      · intro t ht
        simp at ht
        simp; omega
    have gM : P ≤ g M := by
      simp only [hg]
      have : 0 ≤ ∑ t ∈ Icc 1 e, c * M ^ t := Finset.sum_nonneg (fun t _ => by positivity)
      have h1 : M ≤ M ^ e := by
        calc M = M ^ 1 := (pow_one M).symm
          _ ≤ M ^ e := pow_le_pow_right₀ hM1 he
      have h2 : P ≤ K * M := by
        have : P / K ≤ M := le_max_right _ _
        rw [div_le_iff₀ hK] at this; linarith
      nlinarith
    obtain ⟨v, ⟨hv0, _⟩, hv⟩ := intermediate_value_Icc (by linarith : (0:ℝ) ≤ M)
      gcont.continuousOn ⟨by rw [g0]; exact hP.le, gM⟩
    have hvpos : 0 < v := by
      rcases hv0.lt_or_eq with h | h
      · exact h
      · subst h; rw [g0] at hv; linarith
    refine ⟨v⁻¹ - 1, ⟨?_, ?_⟩, ?_⟩
    · have : 0 < v⁻¹ := inv_pos.mpr hvpos
      linarith
    · rw [← hv]
      simp only [hg, schedValue]
      simp [div_eq_mul_inv, inv_pow]
    · rintro z ⟨hz, hzP⟩
      have hyv : -1 < v⁻¹ - 1 := by
        have : 0 < v⁻¹ := inv_pos.mpr hvpos
        linarith
      have hval : schedValue c K e (v⁻¹ - 1) = P := by
        rw [← hv]
        simp only [hg, schedValue]
        simp [div_eq_mul_inv, inv_pow]
      exact (schedValue_strictAntiOn c K e hc.le hK he).injOn hz hyv (hzP.trans hval.symm)

/-- **Which end is worst.** With a positive coupon `c` and call price and face `K`, take two end
years `1 ≤ e < e'` and the yields `y`, `y'` above `-1` that price both schedules at the same `P`.
Above par (`P > K`) the later end has the higher yield, so the first call is worst; below par
(`P < K`) the later end has the lower yield, so maturity is worst. -/
theorem yield_order_above_and_below_par (c K P : ℝ) (e e' : ℕ) (hc : 0 < c) (hK : 0 < K)
    (he : 1 ≤ e) (hee' : e < e') (y y' : ℝ) (hy : -1 < y) (hy' : -1 < y')
    (hPy : schedValue c K e y = P) (hPy' : schedValue c K e' y' = P) :
    (K < P → y < y') ∧ (P < K → y' < y) := by
  have hA : (∑ t ∈ Icc 1 e, 1 / (1 + y) ^ t) < ∑ t ∈ Icc 1 e', 1 / (1 + y) ^ t := by
    have : 0 < 1 + y := by linarith
    apply Finset.sum_lt_sum_of_subset (i := e') (Finset.Icc_subset_Icc le_rfl hee'.le)
    · simp; omega
    · simp; omega
    · positivity
    · intro j _ _; positivity
  have hE := schedValue_sub_eq c K e y hy
  have hE' := schedValue_sub_eq c K e' y hy
  have anti := schedValue_strictAntiOn c K e' hc.le hK (by omega)
  constructor
  · intro hKP
    by_contra hcon
    rw [not_lt] at hcon
    have hpos : 0 < c - K * y := by
      by_contra h; rw [not_lt] at h
      have : 0 ≤ ∑ t ∈ Icc 1 e, 1 / (1 + y) ^ t := Finset.sum_nonneg (fun t _ => by
        have : 0 < 1 + y := by linarith
        positivity)
      nlinarith
    have h1 : schedValue c K e' y ≤ schedValue c K e' y' := anti.antitoneOn hy' hy hcon
    nlinarith
  · intro hPK
    by_contra hcon
    rw [not_lt] at hcon
    have hneg : c - K * y < 0 := by
      by_contra h; rw [not_lt] at h
      have : 0 ≤ ∑ t ∈ Icc 1 e, 1 / (1 + y) ^ t := Finset.sum_nonneg (fun t _ => by
        have : 0 < 1 + y := by linarith
        positivity)
      nlinarith
    have h1 : schedValue c K e' y' ≤ schedValue c K e' y := anti.antitoneOn hy hy' hcon
    nlinarith

/-! ## The card's exact check: at par every yield is the coupon rate

At a price of `$100` the 6 percent bond's yield to the first call (year 5) and to maturity
(year 10) are both `6/100`. -/

example : schedValue 6 100 5 (6 / 100) = 100 := by
  norm_num [schedValue, Finset.sum_Icc_succ_top]

example : schedValue 6 100 10 (6 / 100) = 100 := by
  norm_num [schedValue, Finset.sum_Icc_succ_top]

#print axioms callable_eq_straight_sub_option
#print axioms yield_exists_unique_iff_price_pos
#print axioms yield_order_above_and_below_par

end CallableBond
