-- Kinds of claim: in the card's ten-row ledger neither field, kind or status, can be computed from the other, the status rule lets a status move backwards, and the card's whole-number instances are exact.
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Tactic.NormNum.Prime

/-- A claim's kind: what sort of claim it is, fixed when it is stated. -/
inductive Kind
  | «theorem» | conjecture | model | approximation
  deriving DecidableEq, Repr

/-- A claim's status on a date: open, claimed, proved or refuted. -/
inductive Status
  | «open» | claimed | proved | refuted
  deriving DecidableEq, Repr

instance : Inhabited Status := ⟨Status.open⟩

/-- One row of the ledger: the claim, its kind, its status and the year of that status. -/
structure Row where
  claim : String
  kind : Kind
  status : Status
  year : ℕ

open Kind Status

/-- The card's ten-row ledger, status as of 2026-11-23. -/
def ledger : List Row :=
  [⟨"central limit theorem", «theorem», proved, 1901⟩,
   ⟨"four-colour theorem", conjecture, proved, 1977⟩,
   ⟨"Fermat's last theorem", conjecture, proved, 1995⟩,
   ⟨"Poincare conjecture", conjecture, proved, 2006⟩,
   ⟨"Goldbach", conjecture, «open», 2026⟩,
   ⟨"Riemann hypothesis", conjecture, «open», 2026⟩,
   ⟨"Polya: L(n) <= 0 for n >= 2", conjecture, refuted, 1958⟩,
   ⟨"Black-Scholes call 9.23", model, proved, 1973⟩,
   ⟨"P(<= 55 heads) ~ Phi(1.1)", approximation, proved, 2026⟩,
   ⟨"pi(1e6) ~ 1e6/ln(1e6)", approximation, proved, 2026⟩]

/-- The status rule: on date `d`, a claim's status is the one set by the latest event dated on
or before `d` (events listed in date order); `none` before the claim is first stated. -/
def statusOn (timeline : List (ℕ × Status)) (d : ℕ) : Option Status :=
  ((timeline.filter (fun e => e.1 ≤ d)).getLast?).map Prod.snd

/-- The four-colour claim's dated events: asked 1852, Kempe 1879, Heawood's gap 1890,
Appel and Haken's announcement 1976, refereed and published 1977. -/
def fourColour : List (ℕ × Status) :=
  [(1852, «open»), (1879, proved), (1890, «open»), (1976, claimed), (1977, proved)]

/-- Fermat's claim's dated events: the margin note about 1637, Wiles's announcement 1993,
the repaired proof published 1995. -/
def fermat : List (ℕ × Status) :=
  [(1637, «open»), (1993, claimed), (1995, proved)]

/-- Number of ledger rows with kind `k` and status `s`: one cell of the kind-by-status grid. -/
def gridCount (k : Kind) (s : Status) : ℕ :=
  (ledger.filter (fun r => r.kind = k ∧ r.status = s)).length

/-- Kind does not determine status, and status does not determine kind: in the card's ten-row
ledger no rule from kinds to statuses fits every row, and no rule from statuses to kinds does
either, so one label cannot do both jobs. -/
theorem kind_does_not_determine_status :
    (¬ ∃ f : Kind → Status, ∀ r ∈ ledger, r.status = f r.kind) ∧
    (¬ ∃ g : Status → Kind, ∀ r ∈ ledger, r.kind = g r.status) := by
  refine ⟨?_, ?_⟩
  · rintro ⟨f, hf⟩
    have h1 := hf ⟨"four-colour theorem", conjecture, proved, 1977⟩ (by simp [ledger])
    have h2 := hf ⟨"Goldbach", conjecture, «open», 2026⟩ (by simp [ledger])
    rw [← h1] at h2
    cases h2
  · rintro ⟨g, hg⟩
    have h1 := hg ⟨"central limit theorem", «theorem», proved, 1901⟩ (by simp [ledger])
    have h2 := hg ⟨"four-colour theorem", conjecture, proved, 1977⟩ (by simp [ledger])
    rw [← h1] at h2
    cases h2

/-- The grid test, for any ledger: a rule from kinds to statuses fits every row exactly when
any two rows with the same kind have the same status, that is, when each kind's row of the
grid has at most one non-zero cell. -/
theorem status_is_function_of_kind_iff (L : List Row) :
    (∃ f : Kind → Status, ∀ r ∈ L, r.status = f r.kind) ↔
      ∀ r ∈ L, ∀ s ∈ L, r.kind = s.kind → r.status = s.status := by
  classical
  constructor
  · rintro ⟨f, hf⟩ r hr s hs hk
    rw [hf r hr, hf s hs, hk]
  · intro h
    refine ⟨fun k => if hk : ∃ r ∈ L, r.kind = k then hk.choose.status else default, ?_⟩
    intro r hr
    have hk : ∃ t ∈ L, t.kind = r.kind := ⟨r, hr, rfl⟩
    simp only [hk, ↓reduceDIte]
    exact h r hr _ hk.choose_spec.1 hk.choose_spec.2.symm

/-- The status rule lets a status move backwards: the four-colour claim was proved on one date
and open again on a later one (Kempe's proof 1879, Heawood's gap 1890). -/
theorem status_can_move_backwards :
    ∃ d₁ d₂ : ℕ, d₁ < d₂ ∧ statusOn fourColour d₁ = some proved ∧
      statusOn fourColour d₂ = some «open» := by
  exact ⟨1885, 1900, by norm_num, by decide, by decide⟩

-- The kind-by-status grid: kinds down (theorem, conjecture, model, approximation),
-- statuses across (open, claimed, proved, refuted).
example : [«theorem», conjecture, model, approximation].map
      (fun k => [«open», claimed, proved, refuted].map (gridCount k)) =
    [[0, 0, 1, 0], [2, 0, 3, 1], [0, 0, 1, 0], [0, 0, 2, 0]] := by decide
-- One kind, conjecture, sits under three statuses; one status, proved, sits beside all four kinds.
example : (((ledger.filter (·.kind = conjecture)).map (·.status)).dedup).length = 3 := by decide
example : (((ledger.filter (·.status = proved)).map (·.kind)).dedup).length = 4 := by decide
-- The four-colour claim read on five dates: 1860 open, 1885 proved, 1900 open, 1976 claimed,
-- 2010 proved.
example : [1860, 1885, 1900, 1976, 2010].map (statusOn fourColour) =
    [some «open», some proved, some «open», some claimed, some proved] := by decide
-- Fermat's claim: 1900 open, 1994 claimed, 2000 proved.
example : [1900, 1994, 2000].map (statusOn fermat) =
    [some «open», some claimed, some proved] := by decide
-- The Goldbach count r(100) = 6: primes p ≤ 50 with 100 − p also prime.
example : ((Finset.Icc 2 50).filter (fun p => p.Prime ∧ (100 - p).Prime)).card = 6 := by decide

/-- Borders among Belgium (0), France (1), Germany (2), Luxembourg (3), Netherlands (4). -/
def borders : List (Fin 5 × Fin 5) :=
  [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 0), (4, 2)]

-- The five countries have 0 proper colourings with 3 colours and 48 with 4, by trying every
-- colour list, matching the formula k(k − 1)(k − 2)^2(k − 3).
example : (Finset.univ.filter
    (fun c : Fin 5 → Fin 3 => ∀ e ∈ borders, c e.1 ≠ c e.2)).card = 0 := by decide
example : (Finset.univ.filter
    (fun c : Fin 5 → Fin 4 => ∀ e ∈ borders, c e.1 ≠ c e.2)).card = 48 := by decide
example : 3 * 2 * 1 ^ 2 * 0 = 0 ∧ 4 * 3 * 2 ^ 2 * 1 = 48 := by norm_num
-- P(at most 55 heads in 100 fair flips) = (sum of C(100, k) for k ≤ 55) / 2^100 lies between
-- 864,373 and 864,374 millionths.
example : 864373 * 2 ^ 100 ≤ 10 ^ 6 * (∑ k ∈ Finset.range 56, Nat.choose 100 k) ∧
    10 ^ 6 * (∑ k ∈ Finset.range 56, Nat.choose 100 k) < 864374 * 2 ^ 100 := by
  simp only [Finset.sum_range_succ, Finset.sum_range_zero]
  norm_num [Nat.choose_eq_factorial_div_factorial, Nat.factorial]

#print axioms kind_does_not_determine_status
#print axioms status_is_function_of_kind_iff
#print axioms status_can_move_backwards
