-- Replication: on a two-way tree whose two next prices always differ, every payoff is copied by a self-financing mix of shares and bank money, and every such copy costs the same today.
import Mathlib.Analysis.Complex.Exponential
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.LinearCombination

/-!
Setting, as on the card.

* A node of the tree is the list of moves taken so far, newest first: `true` is an up move,
  `false` a down move. The root (today) is `[]`; date `i` is a list of length `i`; the two
  children of node `p` are `true :: p` and `false :: p`. Paths need not recombine.
* `S p` is the share price at node `p`.
* A strategy is two functions of the node: `h p` shares and `b p` dollars in the bank, fixed
  just after trading at `p`. Being functions of the node, they use only what is known there.
* `g` is the bank's growth over one step. On the card `g = exp (r * Δt)`.
* The payoff `X` is owed at the final date `N` and may depend on the whole path: `X p` for
  each node `p` of length `N`.
-/


/-- Wealth just after trading at node `p`: `V = h S + b`. -/
def wealth (S h b : List Bool → ℝ) (p : List Bool) : ℝ :=
  h p * S p + b p

/-- Wealth on arrival at the child `c :: p`, before anything is traded:
`V⁻ = h S' + b g`, with the holdings chosen at `p`. -/
def arrival (S h b : List Bool → ℝ) (g : ℝ) (p : List Bool) (c : Bool) : ℝ :=
  h p * S (c :: p) + b p * g

/-- Self-financing: at every date `1, …, N` and on every path, the new holdings cost exactly
what the old ones are worth on arrival. No money goes in and none comes out. -/
def SelfFinancing (N : ℕ) (S h b : List Bool → ℝ) (g : ℝ) : Prop :=
  ∀ p : List Bool, p.length < N → ∀ c : Bool, wealth S h b (c :: p) = arrival S h b g p c

/-- The strategy ends holding exactly the payoff: `V_N = X` on every path. -/
def Replicates (N : ℕ) (S h b X : List Bool → ℝ) : Prop :=
  ∀ p : List Bool, p.length = N → wealth S h b p = X p

/-- Helper: the replicating value at node `p` with `k` steps left, built backwards from `X`. -/
noncomputable def repVal (S X : List Bool → ℝ) (g : ℝ) : ℕ → List Bool → ℝ
  | 0, p => X p
  | k + 1, p =>
      ((repVal S X g k (true :: p) - repVal S X g k (false :: p)) /
          (S (true :: p) - S (false :: p))) * S p +
        (repVal S X g k (true :: p) -
            ((repVal S X g k (true :: p) - repVal S X g k (false :: p)) /
              (S (true :: p) - S (false :: p))) * S (true :: p)) / g

/-- Helper: shares held at `p` with `k` steps left. -/
noncomputable def repDelta (S X : List Bool → ℝ) (g : ℝ) (k : ℕ) (p : List Bool) : ℝ :=
  (repVal S X g k (true :: p) - repVal S X g k (false :: p)) / (S (true :: p) - S (false :: p))

/-- Helper: bank money held at `p` with `k` steps left. -/
noncomputable def repBank (S X : List Bool → ℝ) (g : ℝ) (k : ℕ) (p : List Bool) : ℝ :=
  (repVal S X g k (true :: p) - repDelta S X g k p * S (true :: p)) / g

/-- Helper: any self-financing replicating strategy has wealth `repVal` at every node. -/
theorem rep_wealth_eq (N : ℕ) (S h b X : List Bool → ℝ) (g : ℝ) (hg : g ≠ 0)
    (hS : ∀ p : List Bool, p.length < N → S (true :: p) ≠ S (false :: p))
    (hsf : SelfFinancing N S h b g) (hrep : Replicates N S h b X) :
    ∀ k : ℕ, ∀ p : List Bool, p.length + k = N → wealth S h b p = repVal S X g k p := by
  intro k
  induction k with
  | zero => intro p hp; simpa [repVal] using hrep p (by simpa using hp)
  | succ k ih =>
    intro p hp
    have hlt : p.length < N := by omega
    have hu := ih (true :: p) (by simp; omega)
    have hd := ih (false :: p) (by simp; omega)
    rw [hsf p hlt true] at hu
    rw [hsf p hlt false] at hd
    unfold arrival at hu hd
    have hne : S (true :: p) - S (false :: p) ≠ 0 := sub_ne_zero.mpr (hS p hlt)
    have hh : h p = (repVal S X g k (true :: p) - repVal S X g k (false :: p)) /
        (S (true :: p) - S (false :: p)) := by
      rw [eq_div_iff hne]; linear_combination hu - hd
    have hb : b p = (repVal S X g k (true :: p) - h p * S (true :: p)) / g := by
      rw [eq_div_iff hg]; linear_combination hu
    simp only [repVal, wealth]
    rw [hb, ← hh]

/-- Helper: the backward-built strategy is self-financing and replicates `X`. -/
theorem rep_exists (N : ℕ) (S X : List Bool → ℝ) (g : ℝ) (hg : g ≠ 0)
    (hS : ∀ p : List Bool, p.length < N → S (true :: p) ≠ S (false :: p)) :
    ∃ h b : List Bool → ℝ, SelfFinancing N S h b g ∧ Replicates N S h b X ∧
      wealth S h b [] = repVal S X g N [] := by
  let h : List Bool → ℝ := fun p => if p.length < N then repDelta S X g (N - 1 - p.length) p else 0
  let b : List Bool → ℝ := fun p => if p.length < N then repBank S X g (N - 1 - p.length) p else X p
  have hw : ∀ p : List Bool, p.length ≤ N → wealth S h b p = repVal S X g (N - p.length) p := by
    intro p hp
    rcases Nat.lt_or_ge p.length N with hlt | hge
    · obtain ⟨k, hk⟩ : ∃ k, N - p.length = k + 1 := ⟨N - 1 - p.length, by omega⟩
      have hk' : N - 1 - p.length = k := by omega
      simp only [wealth, h, b, if_pos hlt, hk, hk', repVal, repDelta, repBank]
    · have : p.length = N := by omega
      simp [wealth, h, b, this, repVal]
  refine ⟨h, b, ?_, ?_, ?_⟩
  · intro p hp c
    have hne : S (true :: p) - S (false :: p) ≠ 0 := sub_ne_zero.mpr (hS p hp)
    rw [hw (c :: p) (by simp; omega)]
    have hk : N - (c :: p).length = N - 1 - p.length := by simp; omega
    rw [hk]
    simp only [arrival, h, b, if_pos hp, repBank, repDelta]
    cases c <;> field_simp <;> ring
  · intro p hp
    rw [hw p hp.le, hp, Nat.sub_self]; rfl
  · simpa using hw [] (by simp)

/-- Replication on a two-way tree. If the bank grows by `g = exp (r Δt)` over each step and,
at every node before the final date, the two next share prices differ, then every payoff `X`
due at date `N` has a self-financing strategy of shares and bank money that ends holding `X`
on every path, and all such strategies cost the same today: the cost `V_0` is one number,
not a range. -/
theorem replication_cost_exists_unique (N : ℕ) (S X : List Bool → ℝ) (r Δt : ℝ)
    (hS : ∀ p : List Bool, p.length < N → S (true :: p) ≠ S (false :: p)) :
    ∃! v : ℝ, ∃ h b : List Bool → ℝ,
      SelfFinancing N S h b (Real.exp (r * Δt)) ∧ Replicates N S h b X ∧ wealth S h b [] = v := by
  have hg : Real.exp (r * Δt) ≠ 0 := (Real.exp_pos _).ne'
  refine ⟨repVal S X (Real.exp (r * Δt)) N [], rep_exists N S X _ hg hS, ?_⟩
  rintro v ⟨h, b, hsf, hrep, hv⟩
  rw [← hv]
  exact rep_wealth_eq N S h b X _ hg hS hsf hrep N [] (by simp)

/-- The gains identity. For a self-financing strategy, wealth moves over one step only
because the shares held changed in price and the bank paid interest:
`V_{i+1} - V_i = h_i (S_{i+1} - S_i) + b_i (g - 1)`. -/
theorem gains_identity (N : ℕ) (S h b : List Bool → ℝ) (g : ℝ)
    (hsf : SelfFinancing N S h b g) (p : List Bool) (hp : p.length < N) (c : Bool) :
    wealth S h b (c :: p) - wealth S h b p = h p * (S (c :: p) - S p) + b p * (g - 1) := by
  rw [hsf p hp c]
  unfold arrival wealth
  ring

/-- The discounted gains identity. Measure date `i` in today's dollars with
`D_i = exp (-r t_i)`, `t_i = i Δt`, and let the bank grow by `g = exp (r Δt)` a step. For a
self-financing strategy the bank term disappears:
`D_{i+1} V_{i+1} - D_i V_i = h_i (D_{i+1} S_{i+1} - D_i S_i)`. -/
theorem discounted_gains_identity (N : ℕ) (S h b : List Bool → ℝ) (r Δt : ℝ)
    (hsf : SelfFinancing N S h b (Real.exp (r * Δt))) (p : List Bool) (hp : p.length < N)
    (c : Bool) :
    Real.exp (-r * ((p.length + 1 : ℕ) * Δt)) * wealth S h b (c :: p)
        - Real.exp (-r * (p.length * Δt)) * wealth S h b p
      = h p * (Real.exp (-r * ((p.length + 1 : ℕ) * Δt)) * S (c :: p)
        - Real.exp (-r * (p.length * Δt)) * S p) := by
  rw [hsf p hp c]
  unfold arrival wealth
  have he : Real.exp (-r * ((p.length + 1 : ℕ) * Δt)) * Real.exp (r * Δt)
      = Real.exp (-r * (p.length * Δt)) := by
    rw [← Real.exp_add]; congr 1; push_cast; ring
  linear_combination b p * he


/-! Worked numbers from the card, in cents so that they are whole numbers. -/

-- Step 4, the up node: holding `h` shares and `c = b g` dollars at expiry must pay
-- 32.69 where Acme ends at 132.69 and 0 where it ends at 100.00. Subtracting gives one
-- whole share, and the bank must owe the strike, 100.00, at expiry.
example (h c : ℝ) (hu : h * 13269 + c = 3269) (hd : h * 10000 + c = 0) :
    h = 1 ∧ c = -10000 := by
  constructor <;> linarith

-- The copy at the up node: 115.19 of share less 97.53 of loan is 17.66.
example : (11519 : ℤ) - 9753 = 1766 := by norm_num

-- The call's payoffs at expiry: the gap above the 100.00 strike, or nothing.
example : max ((13269 : ℤ) - 10000) 0 = 3269 ∧ max ((10000 : ℤ) - 10000) 0 = 0 ∧
    max ((7536 : ℤ) - 10000) 0 = 0 := by decide

#print axioms repVal
#print axioms repDelta
#print axioms repBank
#print axioms rep_wealth_eq
#print axioms rep_exists
#print axioms replication_cost_exists_unique
#print axioms gains_identity
#print axioms discounted_gains_identity
