-- Many steps: on a recombining binomial tree, rolling the payoff back one step at a time gives a trading plan that starts from the root value, needs no new money and ends at exactly the payoff on every history; at each node that plan is the only one and costs the rolled-back value; and the root value equals the discounted path-count-weighted average of the ending payoffs.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Tactic

open Real Finset

namespace MultiStepTree

/-- The tree's inputs: Acme's price today `S`, the bank rate `r`, the dividend yield `q`, the
volatility `σ`, the option's life `T` in years, and the number of steps `N`. -/
structure Tree where
  S : ℝ
  r : ℝ
  q : ℝ
  σ : ℝ
  T : ℝ
  N : ℕ

namespace Tree

variable (t : Tree)

/-- One step's length, `Δt = T / N`. -/
noncomputable def dt : ℝ := t.T / t.N

/-- The up factor `u = e^(σ√Δt)`. -/
noncomputable def up : ℝ := exp (t.σ * √t.dt)

/-- The down factor `d = 1/u = e^(-σ√Δt)`. -/
noncomputable def down : ℝ := exp (-(t.σ * √t.dt))

/-- Acme's own growth over one step once dividends are off, `e^((r - q)Δt)`. -/
noncomputable def growth : ℝ := exp ((t.r - t.q) * t.dt)

/-- One step of discounting, `e^(-rΔt)`. -/
noncomputable def disc : ℝ := exp (-t.r * t.dt)

/-- The weight `p = (e^((r - q)Δt) - d) / (u - d)`. -/
noncomputable def weight : ℝ := (t.growth - t.down) / (t.up - t.down)

/-- Acme's price after `n` steps of which `j` were up: `S_n(j) = S u^j d^(n - j)`. -/
noncomputable def spot (n j : ℕ) : ℝ := t.S * t.up ^ j * t.down ^ (n - j)

/-- The backward roll with `m` steps left, at the node with `j` up moves: with no steps left it is
the payoff `f` of the ending price; otherwise it is the two nodes it leads to, weighted by `p` and
`1 - p` and pulled back one step of interest. -/
noncomputable def roll (f : ℝ → ℝ) : ℕ → ℕ → ℝ
  | 0, j => f (t.spot t.N j)
  | m + 1, j => t.disc * (t.weight * roll f m (j + 1) + (1 - t.weight) * roll f m j)

/-- The option's worth `V_n(j)` after `n` steps, `j` of them up. -/
noncomputable def value (f : ℝ → ℝ) (n j : ℕ) : ℝ := t.roll f (t.N - n) j

/-- The shares held at node `(n, j)`:
`Δ_n(j) = e^(-qΔt) (V_{n+1}(j+1) - V_{n+1}(j)) / (S_{n+1}(j+1) - S_{n+1}(j))`. -/
noncomputable def hedge (f : ℝ → ℝ) (n j : ℕ) : ℝ :=
  exp (-t.q * t.dt) * (t.value f (n + 1) (j + 1) - t.value f (n + 1) j) /
    (t.spot (n + 1) (j + 1) - t.spot (n + 1) j)

/-- How many of the first `n` moves of a history were up (`true` means an up move). -/
def ups (path : ℕ → Bool) : ℕ → ℕ
  | 0 => 0
  | n + 1 => ups path n + if path n then 1 else 0

/-- The copy carried forward down one history, with no money added or taken out: it starts with
the root value `V_0(0)`; at each node it holds the tree's `Δ` shares, puts the rest of its wealth
in the bank (borrowing if negative), lets the shares grow by the dividends ploughed back,
`e^(qΔt)`, and the bank by `e^(rΔt)`, and is then worth the shares at the new price plus the bank. -/
noncomputable def wealth (f : ℝ → ℝ) (path : ℕ → Bool) : ℕ → ℝ
  | 0 => t.value f 0 0
  | n + 1 =>
      t.hedge f n (ups path n) * exp (t.q * t.dt) * t.spot (n + 1) (ups path (n + 1)) +
        (wealth f path n - t.hedge f n (ups path n) * t.spot n (ups path n)) * exp (t.r * t.dt)


lemma value_succ (f : ℝ → ℝ) (n j : ℕ) (hn : n < t.N) :
    t.value f n j = t.disc * (t.weight * t.value f (n + 1) (j + 1) +
      (1 - t.weight) * t.value f (n + 1) j) := by
  have h : t.N - n = (t.N - (n + 1)) + 1 := by omega
  simp only [value, h, roll]

lemma roll_S_zero (hS : t.S = 0) (f : ℝ → ℝ) (m j : ℕ) : t.roll f m j = t.roll f m 0 := by
  induction m generalizing j with
  | zero => simp [roll, spot, hS]
  | succ m ih => simp only [roll]; rw [ih (j + 1), ih j, ih (0 + 1)]

lemma N_ne_zero (hd : t.down < t.growth) : t.N ≠ 0 := by
  intro h
  simp [down, growth, dt, h] at hd

lemma down_lt_up (hd : t.down < t.growth) (hu : t.growth < t.up) : t.down < t.up :=
  lt_trans hd hu

lemma spot_succ_up (n j : ℕ) : t.spot (n + 1) (j + 1) = t.spot n j * t.up := by
  simp only [spot, Nat.add_sub_add_right]; ring

lemma spot_succ_down (n j : ℕ) (hj : j ≤ n) : t.spot (n + 1) j = t.spot n j * t.down := by
  have h : n + 1 - j = (n - j) + 1 := by omega
  simp only [spot, h, pow_succ]; ring

lemma exp_facts : exp (-t.q * t.dt) = (exp (t.q * t.dt))⁻¹ ∧ t.disc = (exp (t.r * t.dt))⁻¹ ∧
    t.growth = exp (t.r * t.dt) / exp (t.q * t.dt) := by
  refine ⟨?_, ?_, ?_⟩
  · rw [neg_mul, Real.exp_neg]
  · rw [disc, neg_mul, Real.exp_neg]
  · rw [growth, ← Real.exp_sub]; ring_nf

/-- The one-step identities at a node `(n, j)` with `j ≤ n`. -/
lemma step_identities (f : ℝ → ℝ) (n j : ℕ) (hj : j ≤ n) (hn : n < t.N)
    (hd : t.down < t.growth) (hu : t.growth < t.up) :
    t.hedge f n j * exp (t.q * t.dt) * t.spot (n + 1) (j + 1) +
        (t.value f n j - t.hedge f n j * t.spot n j) * exp (t.r * t.dt) =
      t.value f (n + 1) (j + 1) ∧
    t.hedge f n j * exp (t.q * t.dt) * t.spot (n + 1) j +
        (t.value f n j - t.hedge f n j * t.spot n j) * exp (t.r * t.dt) =
      t.value f (n + 1) j := by
  obtain ⟨hq, hr, hg⟩ := t.exp_facts
  have hud : t.up - t.down ≠ 0 := sub_ne_zero.mpr (ne_of_gt (t.down_lt_up hd hu))
  have hEq : exp (t.q * t.dt) ≠ 0 := (exp_pos _).ne'
  have hEr : exp (t.r * t.dt) ≠ 0 := (exp_pos _).ne'
  have hV := t.value_succ f n j hn
  unfold hedge
  rw [t.spot_succ_up n j, t.spot_succ_down n j hj]
  by_cases hs : t.spot n j = 0
  · have hS : t.S = 0 := by
      have hu0 : t.up ≠ 0 := (exp_pos _).ne'
      have hd0 : t.down ≠ 0 := (exp_pos _).ne'
      simp only [spot, mul_eq_zero, pow_eq_zero_iff', hu0, hd0, false_and, or_false] at hs
      exact hs
    have hUL : t.value f (n + 1) (j + 1) = t.value f (n + 1) j := by
      simp only [value]; rw [t.roll_S_zero hS f _ (j + 1), t.roll_S_zero hS f _ j]
    rw [hs, hV, hUL, hr]
    field_simp
    constructor <;> ring
  · rw [hV, hq, hr, weight, hg]
    constructor
    · field_simp
      ring
    · field_simp
      ring

#print axioms value_succ
#print axioms roll_S_zero
#print axioms N_ne_zero
#print axioms down_lt_up
#print axioms spot_succ_up
#print axioms spot_succ_down
#print axioms exp_facts
#print axioms step_identities


lemma ups_le (path : ℕ → Bool) (n : ℕ) : ups path n ≤ n := by
  induction n with
  | zero => simp [ups]
  | succ n ih => simp only [ups]; split_ifs <;> omega

lemma pascal_sum (a b : ℝ) (g : ℕ → ℝ) (m : ℕ) :
    ∑ k ∈ range (m + 2), ((m + 1).choose k : ℝ) * a ^ k * b ^ (m + 1 - k) * g k =
      a * ∑ k ∈ range (m + 1), (m.choose k : ℝ) * a ^ k * b ^ (m - k) * g (k + 1) +
        b * ∑ k ∈ range (m + 1), (m.choose k : ℝ) * a ^ k * b ^ (m - k) * g k := by
  have e1 : b * ∑ k ∈ range (m + 1), (m.choose k : ℝ) * a ^ k * b ^ (m - k) * g k =
      ∑ k ∈ range (m + 2), (m.choose k : ℝ) * a ^ k * b ^ (m + 1 - k) * g k := by
    rw [sum_range_succ _ (m + 1), Nat.choose_succ_self, Nat.cast_zero, zero_mul, zero_mul,
      zero_mul, add_zero, mul_sum]
    refine sum_congr rfl fun k hk => ?_
    have hk' : m + 1 - k = (m - k) + 1 := by rw [mem_range] at hk; omega
    rw [hk', pow_succ]; ring
  rw [e1, mul_sum, sum_range_succ' _ (m + 1), sum_range_succ' (fun k => (m.choose k : ℝ) * a ^ k *
    b ^ (m + 1 - k) * g k) (m + 1)]
  simp only [Nat.choose_succ_succ', Nat.cast_add, Nat.add_sub_add_right, Nat.choose_zero_right]
  rw [← add_assoc, ← sum_add_distrib]
  congr 1
  · refine sum_congr rfl fun k _ => ?_
    rw [pow_succ]; ring

lemma roll_eq_sum (f : ℝ → ℝ) (m j : ℕ) :
    t.roll f m j = t.disc ^ m * ∑ k ∈ range (m + 1),
      (m.choose k : ℝ) * t.weight ^ k * (1 - t.weight) ^ (m - k) * f (t.spot t.N (j + k)) := by
  induction m generalizing j with
  | zero => simp [roll]
  | succ m ih =>
    rw [roll, ih (j + 1), ih j, pascal_sum t.weight (1 - t.weight) (fun k => f (t.spot t.N (j + k)))]
    have : ∀ k, j + 1 + k = j + (k + 1) := fun k => by omega
    simp only [this]
    ring

#print axioms ups_le
#print axioms pascal_sum
#print axioms roll_eq_sum


/-- **Backward induction prices and copies the option.** On an `N`-step tree with the same up
factor `u = e^(σ√Δt)` and down factor `d = 1/u` at every node, two prices per step, and Acme's own
growth strictly between the branches, `d < e^((r - q)Δt) < u`, take any payoff `f` that depends
only on Acme's ending price. Fill the last column with the payoff and roll back one step at a time.
Then on every history the copy that starts with the root value, holds the tree's `Δ` shares at
each node, banks the rest and adds no new money is worth the tree's value at every node it passes
through, and on expiry day it is worth exactly the payoff. -/
theorem backward_induction_copies_payoff (f : ℝ → ℝ) (path : ℕ → Bool)
    (hd : t.down < t.growth) (hu : t.growth < t.up) :
    (∀ n ≤ t.N, t.wealth f path n = t.value f n (ups path n)) ∧
      t.wealth f path t.N = f (t.spot t.N (ups path t.N)) := by
  have key : ∀ n ≤ t.N, t.wealth f path n = t.value f n (ups path n) := by
    intro n
    induction n with
    | zero => intro _; simp [wealth, ups]
    | succ n ih =>
      intro hn
      have hlt : n < t.N := by omega
      rw [wealth, ih hlt.le]
      obtain ⟨h1, h2⟩ := t.step_identities f n (ups path n) (ups_le path n) hlt hd hu
      cases hp : path n
      · simp only [ups, hp, Bool.false_eq_true, ite_false, add_zero]
        exact h2
      · simp only [ups, hp, ite_true]
        exact h1
  refine ⟨key, ?_⟩
  rw [key t.N le_rfl]
  simp only [value, Nat.sub_self, roll]

/-- **One step back is the one-step problem, unchanged** (Step 1). At any node of the tree
(`j ≤ n` ups so far) with at least one step to go, with Acme's price `S > 0` and `d < e^((r - q)Δt) < u`, a holding of `Δ` shares and `B`
dollars in the bank is worth the next node's value whichever way Acme moves exactly when
`Δ = e^(-qΔt) (U - L) / (S_{n+1}(j+1) - S_{n+1}(j))` and `B = e^(-rΔt) (uL - dU) / (u - d)`, where
`U` and `L` are the upper and lower next values; and that holding costs `ΔS_n(j) + B`, which is the
rolled-back value `V_n(j)`. -/
theorem one_step_back_unique_copy_costs_value (f : ℝ → ℝ) (n j : ℕ) (hj : j ≤ n) (hn : n < t.N)
    (hS : 0 < t.S) (hd : t.down < t.growth) (hu : t.growth < t.up) (Δ B : ℝ) :
    ((Δ * exp (t.q * t.dt) * t.spot (n + 1) (j + 1) + B * exp (t.r * t.dt) =
          t.value f (n + 1) (j + 1) ∧
        Δ * exp (t.q * t.dt) * t.spot (n + 1) j + B * exp (t.r * t.dt) = t.value f (n + 1) j) ↔
      (Δ = t.hedge f n j ∧
        B = t.disc * (t.up * t.value f (n + 1) j - t.down * t.value f (n + 1) (j + 1)) /
          (t.up - t.down))) ∧
    t.hedge f n j * t.spot n j +
        t.disc * (t.up * t.value f (n + 1) j - t.down * t.value f (n + 1) (j + 1)) /
          (t.up - t.down) = t.value f n j := by
  obtain ⟨hq, hr, hg⟩ := t.exp_facts
  have hud : t.up - t.down ≠ 0 := sub_ne_zero.mpr (ne_of_gt (t.down_lt_up hd hu))
  have hEq : exp (t.q * t.dt) ≠ 0 := (exp_pos _).ne'
  have hEr : exp (t.r * t.dt) ≠ 0 := (exp_pos _).ne'
  have hs : t.spot n j ≠ 0 := by
    have : 0 < t.spot n j := by
      unfold spot
      have := exp_pos (t.σ * √t.dt)
      have := exp_pos (-(t.σ * √t.dt))
      unfold up down
      positivity
    exact this.ne'
  have hsud : t.spot n j * t.up - t.spot n j * t.down ≠ 0 := by
    rw [← mul_sub]; exact mul_ne_zero hs hud
  have hV := t.value_succ f n j hn
  unfold hedge
  rw [t.spot_succ_up n j, t.spot_succ_down n j hj]
  refine ⟨⟨fun ⟨h1, h2⟩ => ⟨?_, ?_⟩, fun ⟨h1, h2⟩ => ⟨?_, ?_⟩⟩, ?_⟩
  · rw [eq_div_iff hsud, ← h1, ← h2, hq]
    field_simp
    ring
  · rw [eq_div_iff hud, ← h1, ← h2, hr]
    field_simp
    ring
  · rw [h1, h2, hq, hr]
    field_simp
    ring
  · rw [h1, h2, hq, hr]
    field_simp
    ring
  · rw [hV, hq, hr, weight, hg]
    field_simp
    ring

/-- **The same number, written as one average** (Step 4). With `d < e^((r - q)Δt) < u`, the price
at the root is the ending payoffs, each weighted by its path count `N choose j` and by the chance
`p^j (1 - p)^(N - j)` of that many ups, added up and discounted over the whole life `T`:
`V_0 = e^(-rT) Σ_j (N choose j) p^j (1 - p)^(N - j) f(S u^j d^(N - j))`. -/
theorem root_value_eq_weighted_sum (f : ℝ → ℝ)
    (hd : t.down < t.growth) (hu : t.growth < t.up) :
    t.value f 0 0 = exp (-t.r * t.T) * ∑ j ∈ range (t.N + 1),
      (t.N.choose j : ℝ) * t.weight ^ j * (1 - t.weight) ^ (t.N - j) *
        f (t.S * t.up ^ j * t.down ^ (t.N - j)) := by
  have hN : (t.N : ℝ) ≠ 0 := Nat.cast_ne_zero.mpr (t.N_ne_zero hd)
  have hdisc : t.disc ^ t.N = exp (-t.r * t.T) := by
    rw [disc, ← Real.exp_nat_mul, dt]
    congr 1
    field_simp
  simp only [value, Nat.sub_zero]
  rw [roll_eq_sum, hdisc]
  congr 1
  refine sum_congr rfl fun k _ => ?_
  simp only [spot, zero_add]

-- Four steps: the path counts across the five ending prices run 1, 4, 6, 4, 1.
example : (List.range 5).map (Nat.choose 4) = [1, 4, 6, 4, 1] := by decide
-- Two ups out of four can be arranged six ways.
example : Nat.choose 4 2 = 6 := by decide
-- Kept apart, four steps give sixteen histories; merged, they give five ending prices.
example : 2 ^ 4 = 16 ∧ ∑ j ∈ range 5, Nat.choose 4 j = 16 ∧ 4 + 1 = 5 := by decide
-- After fifty steps: about a thousand trillion histories against fifty-one ending prices.
example : 2 ^ 50 = 1125899906842624 ∧ 50 + 1 = 51 := by norm_num

#print axioms backward_induction_copies_payoff
#print axioms one_step_back_unique_copy_costs_value
#print axioms root_value_eq_weighted_sum

end Tree

end MultiStepTree
