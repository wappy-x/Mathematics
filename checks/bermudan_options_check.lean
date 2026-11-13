-- Bermudan options: on a binomial tree, a Bermudan option priced by backward induction is worth at least the European and at most the American, adding exercise dates never lowers its price, one date gives the European price, and every date gives the American price.
import Mathlib.Analysis.Complex.Exponential
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Order.Lattice

open Finset

/-- A recombining binomial tree: Acme starts at `S₀`, and each step multiplies its price
by `u` (up, with price weight `p`) or by `d` (down, with weight `1 - p`).
Each step lasts `dt` years and is discounted at the riskless rate `r`. -/
structure BinomialTree where
  S₀ : ℝ
  u : ℝ
  d : ℝ
  p : ℝ
  r : ℝ
  dt : ℝ

namespace BinomialTree

/-- Acme's price at step `n` after `j` up moves. -/
noncomputable def price (T : BinomialTree) (n j : ℕ) : ℝ :=
  T.S₀ * T.u ^ j * T.d ^ (n - j)

/-- Holding value for one step: the discounted risk-neutral average of the two values
one step later (`a` after an up move, `b` after a down move). -/
noncomputable def hold (T : BinomialTree) (a b : ℝ) : ℝ :=
  Real.exp (-(T.r * T.dt)) * (T.p * a + (1 - T.p) * b)

/-- Bermudan value by backward induction on a tree of `N` steps with listed steps `D`.
`bermValue T g N D m j` is the worth with `m` steps left (so at step `N - m`) after `j`
up moves. At expiry it is the payoff `g`; at a listed step it is the larger of exercising
and holding; at any other step it is the holding value alone. -/
noncomputable def bermValue (T : BinomialTree) (g : ℝ → ℝ) (N : ℕ) (D : Finset ℕ) :
    ℕ → ℕ → ℝ
  | 0, j => g (T.price N j)
  | m + 1, j =>
      if N - (m + 1) ∈ D then
        max (g (T.price (N - (m + 1)) j))
          (T.hold (bermValue T g N D m (j + 1)) (bermValue T g N D m j))
      else
        T.hold (bermValue T g N D m (j + 1)) (bermValue T g N D m j)

/-- The Bermudan price today: the backward-induction value at step 0. -/
noncomputable def bermPrice (T : BinomialTree) (g : ℝ → ℝ) (N : ℕ) (D : Finset ℕ) : ℝ :=
  bermValue T g N D N 0

/-- American value: the comparison of exercising and holding is made at every step. -/
noncomputable def amerValue (T : BinomialTree) (g : ℝ → ℝ) (N : ℕ) : ℕ → ℕ → ℝ
  | 0, j => g (T.price N j)
  | m + 1, j =>
      max (g (T.price (N - (m + 1)) j))
        (T.hold (amerValue T g N m (j + 1)) (amerValue T g N m j))

/-- The American price today. -/
noncomputable def amerPrice (T : BinomialTree) (g : ℝ → ℝ) (N : ℕ) : ℝ :=
  amerValue T g N N 0

/-- The European price: the discounted risk-neutral average of the payoff at expiry,
`e^{-r N dt} · Σ_j C(N, j) p^j (1-p)^(N-j) g(S₀ u^j d^(N-j))`. -/
noncomputable def euroPrice (T : BinomialTree) (g : ℝ → ℝ) (N : ℕ) : ℝ :=
  Real.exp (-(T.r * T.dt)) ^ N *
    ∑ j ∈ range (N + 1), (N.choose j : ℝ) * T.p ^ j * (1 - T.p) ^ (N - j) * g (T.price N j)

end BinomialTree

open BinomialTree

lemma bermudan_hold_mono (T : BinomialTree) (hp0 : 0 ≤ T.p) (hp1 : T.p ≤ 1)
    {a b a' b' : ℝ} (ha : a ≤ a') (hb : b ≤ b') : T.hold a b ≤ T.hold a' b' := by
  unfold BinomialTree.hold
  apply mul_le_mul_of_nonneg_left _ (Real.exp_pos _).le
  have h1 : T.p * a ≤ T.p * a' := mul_le_mul_of_nonneg_left ha hp0
  have h2 : (1 - T.p) * b ≤ (1 - T.p) * b' := mul_le_mul_of_nonneg_left hb (by linarith)
  linarith

#print axioms bermudan_hold_mono

lemma bermudan_value_mono (T : BinomialTree) (g : ℝ → ℝ) (N : ℕ) (D D' : Finset ℕ)
    (hDD' : D ⊆ D') (hp0 : 0 ≤ T.p) (hp1 : T.p ≤ 1) :
    ∀ m j, bermValue T g N D m j ≤ bermValue T g N D' m j := by
  intro m
  induction m with
  | zero => intro j; simp [bermValue]
  | succ m ih =>
    intro j
    have hh := bermudan_hold_mono T hp0 hp1 (ih (j + 1)) (ih j)
    simp only [bermValue]
    by_cases h : N - (m + 1) ∈ D
    · simp only [h, hDD' h, ↓reduceIte]
      exact max_le_max le_rfl hh
    · simp only [h, ↓reduceIte]
      split_ifs
      · exact le_max_of_le_right hh
      · exact hh

#print axioms bermudan_value_mono

lemma bermudan_value_le_amer (T : BinomialTree) (g : ℝ → ℝ) (N : ℕ) (D : Finset ℕ)
    (hp0 : 0 ≤ T.p) (hp1 : T.p ≤ 1) :
    ∀ m j, bermValue T g N D m j ≤ amerValue T g N m j := by
  intro m
  induction m with
  | zero => intro j; simp [bermValue, amerValue]
  | succ m ih =>
    intro j
    have hh := bermudan_hold_mono T hp0 hp1 (ih (j + 1)) (ih j)
    simp only [bermValue, amerValue]
    split_ifs
    · exact max_le_max le_rfl hh
    · exact le_max_of_le_right hh

#print axioms bermudan_value_le_amer

lemma bermudan_binom_step (p q : ℝ) (f : ℕ → ℝ) (m : ℕ) :
    ∑ i ∈ range (m + 2), (((m + 1).choose i : ℕ) : ℝ) * p ^ i * q ^ (m + 1 - i) * f i =
      p * ∑ i ∈ range (m + 1), ((m.choose i : ℕ) : ℝ) * p ^ i * q ^ (m - i) * f (i + 1) +
      q * ∑ i ∈ range (m + 1), ((m.choose i : ℕ) : ℝ) * p ^ i * q ^ (m - i) * f i := by
  rw [sum_range_succ']
  simp only [Nat.choose_succ_succ', Nat.cast_add, add_mul, sum_add_distrib,
    Nat.succ_sub_succ, Nat.choose_zero_right, Nat.sub_zero]
  rw [mul_sum, mul_sum, add_assoc]
  congr 1
  · apply sum_congr rfl; intro i _; ring
  · rw [sum_range_succ, sum_range_succ' (fun i => q * (((m.choose i : ℕ) : ℝ) * p ^ i * q ^ (m - i) * f i))]
    simp only [Nat.choose_succ_self, Nat.cast_zero, zero_mul, add_zero, Nat.choose_zero_right,
      Nat.sub_zero, pow_zero]
    congr 1
    · apply sum_congr rfl
      intro i hi
      rw [mem_range] at hi
      have : m - i = (m - (i + 1)) + 1 := by omega
      rw [this]; ring
    · push_cast; ring

#print axioms bermudan_binom_step

lemma bermudan_empty_closed (T : BinomialTree) (g : ℝ → ℝ) (N : ℕ) :
    ∀ m j, bermValue T g N ∅ m j = Real.exp (-(T.r * T.dt)) ^ m *
      ∑ i ∈ range (m + 1), ((m.choose i : ℕ) : ℝ) * T.p ^ i * (1 - T.p) ^ (m - i) *
        g (T.price N (j + i)) := by
  intro m
  induction m with
  | zero => intro j; simp [bermValue]
  | succ m ih =>
    intro j
    simp only [bermValue, Finset.notMem_empty, ↓reduceIte, BinomialTree.hold, ih]
    rw [bermudan_binom_step T.p (1 - T.p) (fun i => g (T.price N (j + i))) m]
    have e : ∀ i, j + 1 + i = j + (i + 1) := fun i => by omega
    simp only [e]
    ring

#print axioms bermudan_empty_closed

lemma bermudan_empty_eq_euro (T : BinomialTree) (g : ℝ → ℝ) (N : ℕ) :
    bermPrice T g N ∅ = euroPrice T g N := by
  unfold bermPrice euroPrice
  rw [bermudan_empty_closed]
  simp

#print axioms bermudan_empty_eq_euro

lemma bermudan_single_eq_empty (T : BinomialTree) (g : ℝ → ℝ) (N : ℕ) :
    ∀ m, m ≤ N → ∀ j, bermValue T g N {N} m j = bermValue T g N ∅ m j := by
  intro m
  induction m with
  | zero => intro _ j; simp [bermValue]
  | succ m ih =>
    intro hm j
    have h : N - (m + 1) ∉ ({N} : Finset ℕ) := by simp; omega
    simp only [bermValue, h, Finset.notMem_empty, ↓reduceIte]
    rw [ih (by omega), ih (by omega)]

#print axioms bermudan_single_eq_empty

lemma bermudan_range_eq_amer (T : BinomialTree) (g : ℝ → ℝ) (N : ℕ) :
    ∀ m, m ≤ N → ∀ j, bermValue T g N (range N) m j = amerValue T g N m j := by
  intro m
  induction m with
  | zero => intro _ j; simp [bermValue, amerValue]
  | succ m ih =>
    intro hm j
    have h : N - (m + 1) ∈ range N := by simp; omega
    simp only [bermValue, amerValue, h, ↓reduceIte]
    rw [ih (by omega), ih (by omega)]

#print axioms bermudan_range_eq_amer

/-- The card's theorem: for two lists of exercise dates `D ⊆ D'` on the same tree,
`P_E ≤ P_B(D) ≤ P_B(D') ≤ P_A`. A Bermudan is worth at least the European and at most
the American, and adding dates never lowers the price. The only model input is that the
up weight `p` is a price weight between 0 and 1; the payoff `g` may be any function
(for the put, `g s = max (K - s) 0`). -/
theorem bermudan_between_european_and_american (T : BinomialTree) (g : ℝ → ℝ) (N : ℕ)
    (D D' : Finset ℕ) (hDD' : D ⊆ D') (hp0 : 0 ≤ T.p) (hp1 : T.p ≤ 1) :
    euroPrice T g N ≤ bermPrice T g N D ∧
      bermPrice T g N D ≤ bermPrice T g N D' ∧
      bermPrice T g N D' ≤ amerPrice T g N := by
  refine ⟨?_, ?_, ?_⟩
  · rw [← bermudan_empty_eq_euro]
    exact bermudan_value_mono T g N ∅ D (Finset.empty_subset _) hp0 hp1 N 0
  · exact bermudan_value_mono T g N D D' hDD' hp0 hp1 N 0
  · exact bermudan_value_le_amer T g N D' hp0 hp1 N 0

/-- With the last day as the only listed date, the Bermudan recursion is the European
rule, and the Bermudan price equals the European price exactly. -/
theorem bermudan_one_date_eq_european (T : BinomialTree) (g : ℝ → ℝ) (N : ℕ) :
    bermPrice T g N {N} = euroPrice T g N := by
  unfold bermPrice
  rw [bermudan_single_eq_empty T g N N le_rfl 0]
  exact bermudan_empty_eq_euro T g N

/-- With every step of the tree listed, the Bermudan price is the American price. -/
theorem bermudan_every_step_eq_american (T : BinomialTree) (g : ℝ → ℝ) (N : ℕ) :
    bermPrice T g N (range N) = amerPrice T g N := by
  exact bermudan_range_eq_amer T g N N le_rfl 0

#print axioms bermudan_between_european_and_american
#print axioms bermudan_one_date_eq_european
#print axioms bermudan_every_step_eq_american
