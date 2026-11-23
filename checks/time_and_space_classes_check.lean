-- Time and space classes: a deterministic machine that halts inside s tape cells takes fewer than |Q| · s · |Γ|^s steps, and the card's base-4 tape counter on b cells halts after exactly 2(4^(b+1) − 1)/3 steps while visiting only b + 2 cells.
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.Card
import Mathlib.Order.Interval.Set.Basic
import Mathlib.Logic.Function.Iterate
import Mathlib.Tactic.NormNum
import Mathlib.Algebra.BigOperators.Group.Finset.Defs
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Tactic.Ring

/-! ### The configuration bound (Step 2 of the card)

A configuration of a one-tape machine that stays inside `s` cells is its state (in `Q`),
the head's cell (in `Fin s`) and the contents of the `s` cells (a map `Fin s → Γ`).
A deterministic machine is a step function on configurations: `step c = some c'` is the
one successor, and `step c = none` means no rule applies, so the machine halts.
Running for `T` steps is `T`-fold iteration of `Option.bind · step`. -/

/-- Space bounds time, for a machine that halts: a deterministic machine whose run stays
inside `s` tape cells, with state set `Q` and tape alphabet `Γ`, and which halts after `T`
steps (it reaches a configuration `c` after `T` steps and no rule applies at `c`), takes
fewer than `|Q| · s · |Γ|^s` steps. -/
theorem halting_run_steps_lt_configurations
    {Q Γ : Type*} [Fintype Q] [Fintype Γ] {s : ℕ}
    (step : Q × Fin s × (Fin s → Γ) → Option (Q × Fin s × (Fin s → Γ)))
    (c₀ c : Q × Fin s × (Fin s → Γ)) (T : ℕ)
    (hrun : (fun o => Option.bind o step)^[T] (some c₀) = some c)
    (hhalt : step c = none) :
    T < Fintype.card Q * s * Fintype.card Γ ^ s := by
  set g : Option (Q × Fin s × (Fin s → Γ)) → Option (Q × Fin s × (Fin s → Γ)) :=
    fun o => Option.bind o step with hg
  have gnone : ∀ n, g^[n] none = none := by
    intro n
    induction n with
    | zero => rfl
    | succ n ih => rw [Function.iterate_succ_apply]; exact ih
  have hT1 : g^[T + 1] (some c₀) = none := by
    rw [Function.iterate_succ_apply', hrun]; simp [hg, hhalt]
  have hsome : ∀ n ≤ T, g^[n] (some c₀) ≠ none := by
    intro n hn h
    have : g^[T] (some c₀) = none := by
      obtain ⟨k, rfl⟩ := Nat.exists_eq_add_of_le hn
      rw [add_comm, Function.iterate_add_apply, h, gnone]
    rw [hrun] at this; cases this
  let f : Fin (T + 1) → Q × Fin s × (Fin s → Γ) := fun i => (g^[i] (some c₀)).getD c₀
  have hf : ∀ i : Fin (T + 1), g^[i] (some c₀) = some (f i) := by
    intro i
    have := hsome i (Nat.lt_succ_iff.mp i.2)
    obtain ⟨x, hx⟩ := Option.ne_none_iff_exists'.mp this
    simp [f, hx]
  have hinj : Function.Injective f := by
    intro i j hij
    have heq : g^[i] (some c₀) = g^[j] (some c₀) := by rw [hf, hf, hij]
    by_contra hne
    have key : ∀ (a b : ℕ), a < b → b ≤ T → g^[a] (some c₀) = g^[b] (some c₀) → False := by
      intro a b hab hbT he
      have hp : ∀ k, g^[a + k] (some c₀) = g^[b + k] (some c₀) := by
        intro k
        rw [add_comm a, add_comm b, Function.iterate_add_apply, Function.iterate_add_apply, he]
      have h1 := hp (T + 1 - b)
      rw [show b + (T + 1 - b) = T + 1 by omega, hT1] at h1
      exact hsome (a + (T + 1 - b)) (by omega) h1
    rcases Nat.lt_or_gt_of_ne (fun h => hne (Fin.ext h)) with h | h
    · exact key i j h (Nat.lt_succ_iff.mp j.2) heq
    · exact key j i h (Nat.lt_succ_iff.mp i.2) heq.symm
  have := Fintype.card_le_of_injective f hinj
  simp only [Fintype.card_fin, Fintype.card_prod, Fintype.card_fun] at this
  rw [mul_assoc]; omega

/-! ### The card's tape counter (Step 3 of the card)

Tape symbols are whole numbers: `0` is the blank and `1` to `4` are digits. Cells are
numbered by integers. The input is `b` digits `1` in cells `0` to `b - 1`, head on cell `0`,
state `right`. Each rule reads one cell, writes one symbol, moves one cell and changes state,
exactly as in the card's rule table:

* `right` on a digit: keep it, move right, stay in `right`;
  `right` on the blank: keep it, move left, go to `carry`.
* `carry` on `4`: write `1`, move left, stay in `carry`;
  `carry` on `1`, `2` or `3`: add one, move right, go to `right`;
  `carry` on the blank: keep it, move right, go to `done`.
* `done` has no rules, so the machine halts there. -/

/-- The three states of the base-4 counter. -/
inductive CounterState
  | right
  | carry
  | done
  deriving DecidableEq

/-- One step of the counter on configuration (state, head cell, tape). `none` means no rule
applies, so the machine halts. -/
def counterStep : CounterState × ℤ × (ℤ → ℕ) → Option (CounterState × ℤ × (ℤ → ℕ))
  | (.right, h, t) =>
      if 1 ≤ t h ∧ t h ≤ 4 then some (.right, h + 1, t)
      else if t h = 0 then some (.carry, h - 1, t)
      else none
  | (.carry, h, t) =>
      if t h = 4 then some (.carry, h - 1, Function.update t h 1)
      else if 1 ≤ t h ∧ t h ≤ 3 then some (.right, h + 1, Function.update t h (t h + 1))
      else if t h = 0 then some (.done, h + 1, t)
      else none
  | (.done, _, _) => none

/-- The counter's start: `b` digits `1` in cells `0` to `b - 1`, blanks elsewhere, head on
cell `0`, state `right`. -/
def counterStart (b : ℕ) : CounterState × ℤ × (ℤ → ℕ) :=
  (.right, 0, fun i => if 0 ≤ i ∧ i < (b : ℤ) then 1 else 0)

/-- The counter's configuration after `k` steps (`none` once it has halted). -/
def counterRun (b : ℕ) (k : ℕ) : Option (CounterState × ℤ × (ℤ → ℕ)) :=
  (fun o => Option.bind o counterStep)^[k] (some (counterStart b))

/-- Helper: `n` steps of the counter lead from `c` to `c'`. -/
def CounterReach (n : ℕ) (c c' : CounterState × ℤ × (ℤ → ℕ)) : Prop :=
  (fun o => Option.bind o counterStep)^[n] (some c) = some c'

theorem counterReach_zero (c : CounterState × ℤ × (ℤ → ℕ)) : CounterReach 0 c c := rfl

theorem counterReach_one {c c' : CounterState × ℤ × (ℤ → ℕ)} (h : counterStep c = some c') :
    CounterReach 1 c c' := by
  simpa [CounterReach] using h

theorem counterReach_trans {n m : ℕ} {c c' c'' : CounterState × ℤ × (ℤ → ℕ)}
    (h1 : CounterReach n c c') (h2 : CounterReach m c' c'') : CounterReach (n + m) c c'' := by
  unfold CounterReach at *
  rw [add_comm, Function.iterate_add_apply, h1, h2]

theorem counterStep_right_digit {h : ℤ} {t : ℤ → ℕ} (h1 : 1 ≤ t h) (h4 : t h ≤ 4) :
    counterStep (.right, h, t) = some (.right, h + 1, t) := by
  simp [counterStep, h1, h4]

theorem counterStep_right_blank {h : ℤ} {t : ℤ → ℕ} (h0 : t h = 0) :
    counterStep (.right, h, t) = some (.carry, h - 1, t) := by
  simp [counterStep, h0]

theorem counterStep_carry_four {h : ℤ} {t : ℤ → ℕ} (h4 : t h = 4) :
    counterStep (.carry, h, t) = some (.carry, h - 1, Function.update t h 1) := by
  simp [counterStep, h4]

theorem counterStep_carry_inc {h : ℤ} {t : ℤ → ℕ} (h1 : 1 ≤ t h) (h3 : t h ≤ 3) :
    counterStep (.carry, h, t) = some (.right, h + 1, Function.update t h (t h + 1)) := by
  have : t h ≠ 4 := by omega
  simp [counterStep, h1, h3, this]

theorem counterStep_carry_blank {h : ℤ} {t : ℤ → ℕ} (h0 : t h = 0) :
    counterStep (.carry, h, t) = some (.done, h + 1, t) := by
  simp [counterStep, h0]

/-- Helper: the `right` state walks over `k` digits. -/
theorem counter_walk (t : ℤ → ℕ) :
    ∀ (k : ℕ) (h : ℤ), (∀ i, h ≤ i → i < h + k → 1 ≤ t i ∧ t i ≤ 4) →
      CounterReach k (.right, h, t) (.right, h + k, t) := by
  intro k
  induction k with
  | zero => intro h _; simpa using counterReach_zero (.right, h, t)
  | succ k ih =>
    intro h ht
    have h0 := ht h le_rfl (by push_cast; omega)
    have s1 := counterReach_one (counterStep_right_digit (t := t) h0.1 h0.2)
    have s2 := ih (h + 1) (fun i hi1 hi2 => ht i (by omega) (by push_cast at hi2 ⊢; omega))
    have := counterReach_trans s1 s2
    rw [add_comm 1 k] at this
    convert this using 3
    push_cast; ring

/-- Helper: the step count of the carry phase on `m` cells. -/
def counterN : ℕ → ℕ
  | 0 => 0
  | m + 1 => 4 * counterN m + 3 * m + 7

theorem counterN_closed (m : ℕ) : 3 * counterN m + 3 * m + 8 = 8 * 4 ^ m := by
  induction m with
  | zero => simp [counterN]
  | succ m ih => rw [counterN, pow_succ]; omega

/-- Helper: from `carry` at the last cell with the last `m` cells all `1`, the counter runs
through all `4^m` values of those cells and arrives at `carry` one cell left of them. -/
theorem counter_carry_phase (B : ℤ) :
    ∀ (m : ℕ) (t : ℤ → ℕ), (∀ i, B - m ≤ i → i < B → t i = 1) → t B = 0 →
      CounterReach (counterN m) (.carry, B - 1, t) (.carry, B - m - 1, t) := by
  intro m
  induction m with
  | zero => intro t _ _; simpa [counterN] using counterReach_zero (.carry, B - 1, t)
  | succ m ih =>
    intro t ht hB
    set p : ℤ := B - (m + 1 : ℕ) with hp
    -- one increment of cell p: carry at p (inner cells 1) back to carry at p
    have phase : ∀ (u : ℤ → ℕ), (∀ i, B - m ≤ i → i < B → u i = 1) → u B = 0 →
        1 ≤ u p → u p ≤ 3 →
        CounterReach (1 + m + 1 + counterN m) (.carry, p, u)
          (.carry, p, Function.update u p (u p + 1)) := by
      intro u hu huB h1 h3
      have s1 := counterReach_one (counterStep_carry_inc (t := u) h1 h3)
      set u' := Function.update u p (u p + 1) with hu'
      have hpB : p < B := by rw [hp]; push_cast; omega
      have u'i : ∀ i, B - m ≤ i → i < B → u' i = 1 := by
        intro i hi1 hi2
        have : i ≠ p := by rw [hp]; push_cast; omega
        rw [hu', Function.update_of_ne this]; exact hu i hi1 hi2
      have u'B : u' B = 0 := by
        rw [hu', Function.update_of_ne (ne_of_gt hpB)]; exact huB
      have s2 := counter_walk u' m (p + 1) (fun i hi1 hi2 => by
        rw [u'i i (by rw [hp] at hi1; push_cast at hi1; omega)
          (by rw [hp] at hi2; push_cast at hi2; omega)]; omega)
      have s3 : CounterReach 1 (.right, p + 1 + m, u') (.carry, B - 1, u') := by
        have : p + 1 + m = B := by rw [hp]; push_cast; ring
        rw [this]; exact counterReach_one (counterStep_right_blank u'B)
      have s4 := ih u' u'i u'B
      have hpm : B - m - 1 = p := by rw [hp]; push_cast; ring
      rw [hpm] at s4
      exact counterReach_trans (counterReach_trans (counterReach_trans s1 s2) s3) s4
    have hti : ∀ i, B - m ≤ i → i < B → t i = 1 := fun i h1 h2 => ht i (by omega) h2
    have htp : t p = 1 := ht p (by rw [hp]) (by rw [hp]; push_cast; omega)
    have hpB : p < B := by rw [hp]; push_cast; omega
    have upd_i : ∀ (u : ℤ → ℕ) (v : ℕ), (∀ i, B - m ≤ i → i < B → u i = 1) →
        ∀ i, B - m ≤ i → i < B → Function.update u p v i = 1 := by
      intro u v hu i h1 h2
      have : i ≠ p := by rw [hp]; push_cast; omega
      rw [Function.update_of_ne this]; exact hu i h1 h2
    have upd_B : ∀ (u : ℤ → ℕ) (v : ℕ), u B = 0 → Function.update u p v B = 0 := by
      intro u v hu
      rw [Function.update_of_ne (ne_of_gt hpB)]; exact hu
    have r0 := ih t hti hB
    have hpm : B - m - 1 = p := by rw [hp]; push_cast; ring
    rw [hpm] at r0
    have r1 := phase t hti hB (by omega) (by omega)
    rw [htp] at r1
    have r2 := phase (Function.update t p 2) (upd_i t 2 hti) (upd_B t 2 hB)
      (by simp) (by simp)
    simp only [Function.update_self, Function.update_idem] at r2
    have r3 := phase (Function.update t p 3) (upd_i t 3 hti) (upd_B t 3 hB)
      (by simp) (by simp)
    simp only [Function.update_self, Function.update_idem] at r3
    have r4 := counterReach_one
      (counterStep_carry_four (t := Function.update t p 4) (h := p) (by simp))
    simp only [Function.update_idem] at r4
    have key : Function.update t p 1 = t := by rw [← htp]; exact Function.update_eq_self p t
    rw [key] at r4
    have hfin : p - 1 = B - ((m + 1 : ℕ) : ℤ) - 1 := by rw [hp]
    rw [hfin] at r4
    have := counterReach_trans (counterReach_trans (counterReach_trans
      (counterReach_trans r0 r1) r2) r3) r4
    convert this using 1
    simp only [counterN]; ring

/-- Helper: the whole run, as reach facts. -/
theorem counter_reaches_end (b : ℕ) :
    CounterReach (b + 1 + counterN b) (counterStart b)
      (.carry, -1, fun i => if 0 ≤ i ∧ i < (b : ℤ) then 1 else 0) := by
  set t : ℤ → ℕ := fun i => if 0 ≤ i ∧ i < (b : ℤ) then 1 else 0 with ht
  have w := counter_walk t b 0 (fun i h1 h2 => by
    simp only [ht]; split_ifs <;> omega)
  have hb : t b = 0 := by simp [ht]
  simp only [zero_add] at w
  have s := counterReach_one (counterStep_right_blank hb)
  have c := counter_carry_phase (b : ℤ) b t (fun i h1 h2 => by
    simp only [ht]; split_ifs <;> omega) hb
  simp only [sub_self, zero_sub] at c
  exact counterReach_trans (counterReach_trans w s) c

theorem counter_total (b : ℕ) : 2 * (4 ^ (b + 1) - 1) / 3 = b + 1 + counterN b + 1 := by
  have := counterN_closed b
  have h1 : 1 ≤ 4 ^ b := Nat.one_le_pow _ _ (by norm_num)
  rw [pow_succ]
  omega

/-- Helper: every configuration of the run keeps the tape as digits on `0..b-1` and blanks
elsewhere, and keeps the head inside `-1..b`. -/
def CounterInv (b : ℕ) : CounterState × ℤ × (ℤ → ℕ) → Prop
  | (q, h, t) =>
    (∀ i, (0 ≤ i ∧ i < (b : ℤ)) → 1 ≤ t i ∧ t i ≤ 4) ∧
    (∀ i, ¬ (0 ≤ i ∧ i < (b : ℤ)) → t i = 0) ∧
    (match q with
      | .right => 0 ≤ h ∧ h ≤ b
      | .carry => -1 ≤ h ∧ h ≤ b - 1
      | .done => 0 ≤ h ∧ h ≤ b)

theorem counterInv_step (b : ℕ) (c c' : CounterState × ℤ × (ℤ → ℕ))
    (hc : CounterInv b c) (hs : counterStep c = some c') : CounterInv b c' := by
  obtain ⟨q, h, t⟩ := c
  obtain ⟨hd, hz, hh⟩ := hc
  cases q with
  | right =>
    simp only at hh
    by_cases h1 : 1 ≤ t h ∧ t h ≤ 4
    · rw [counterStep_right_digit h1.1 h1.2] at hs
      cases hs
      have : h < b := by
        by_contra hn; have := hz h (by omega); omega
      exact ⟨hd, hz, by simp only; omega⟩
    · by_cases h0 : t h = 0
      · rw [counterStep_right_blank h0] at hs
        cases hs
        have : h = b := by
          by_contra hn; have := hd h (by omega); omega
        exact ⟨hd, hz, by simp only; omega⟩
      · simp [counterStep, h1, h0] at hs
  | carry =>
    simp only at hh
    by_cases h4 : t h = 4
    · rw [counterStep_carry_four h4] at hs
      cases hs
      have hin : 0 ≤ h ∧ h < b := by
        by_contra hn; have := hz h hn; omega
      refine ⟨fun i hi => ?_, fun i hi => ?_, by simp only; omega⟩
      · by_cases e : i = h
        · subst e; simp
        · rw [Function.update_of_ne e]; exact hd i hi
      · have e : i ≠ h := by rintro rfl; exact hi hin
        rw [Function.update_of_ne e]; exact hz i hi
    · by_cases h13 : 1 ≤ t h ∧ t h ≤ 3
      · rw [counterStep_carry_inc h13.1 h13.2] at hs
        cases hs
        have hin : 0 ≤ h ∧ h < b := by
          by_contra hn; have := hz h hn; omega
        refine ⟨fun i hi => ?_, fun i hi => ?_, by simp only; omega⟩
        · by_cases e : i = h
          · subst e; simp; omega
          · rw [Function.update_of_ne e]; exact hd i hi
        · have e : i ≠ h := by rintro rfl; exact hi hin
          rw [Function.update_of_ne e]; exact hz i hi
      · by_cases h0 : t h = 0
        · rw [counterStep_carry_blank h0] at hs
          cases hs
          exact ⟨hd, hz, by simp only; omega⟩
        · simp [counterStep, h4, h13, h0] at hs
  | done => simp [counterStep] at hs

theorem counterInv_run (b k : ℕ) (c : CounterState × ℤ × (ℤ → ℕ))
    (hk : counterRun b k = some c) : CounterInv b c := by
  induction k generalizing c with
  | zero =>
    simp only [counterRun, Function.iterate_zero, id, Option.some.injEq] at hk
    subst hk
    refine ⟨fun i hi => by simp [hi], fun i hi => by simp [hi], ?_⟩
    simp only; omega
  | succ k ih =>
    unfold counterRun at hk
    rw [Function.iterate_succ_apply'] at hk
    cases hprev : (fun o => Option.bind o counterStep)^[k] (some (counterStart b)) with
    | none => rw [hprev] at hk; simp at hk
    | some c₁ =>
      rw [hprev] at hk
      exact counterInv_step b c₁ c (ih c₁ hprev) hk

/-- The tape counter's time, counted exactly: on `b` blank cells the base-4 counter runs
through every value from `11…1` to `44…4` and halts after exactly `2(4^(b+1) − 1)/3` steps:
after that many steps it is in a configuration where no rule applies. -/
theorem counter_halts_in_exact_steps (b : ℕ) :
    ∃ c, counterRun b (2 * (4 ^ (b + 1) - 1) / 3) = some c ∧ counterStep c = none := by
  have e := counter_reaches_end b
  have s := counterReach_one (counterStep_carry_blank
    (h := -1) (t := fun i => if 0 ≤ i ∧ i < (b : ℤ) then 1 else 0) (by simp))
  refine ⟨(.done, -1 + 1, fun i => if 0 ≤ i ∧ i < (b : ℤ) then 1 else 0), ?_, ?_⟩
  · rw [counter_total]; exact counterReach_trans e s
  · simp [counterStep]

/-- The tape counter's space: during its whole halting run the counter's head visits exactly
the `b + 2` cells numbered `-1` to `b` (the `b` digits and one blank on each side). -/
theorem counter_visits_exactly_b_plus_two_cells (b : ℕ) :
    {h : ℤ | ∃ k ≤ 2 * (4 ^ (b + 1) - 1) / 3, ∃ q t, counterRun b k = some (q, h, t)} =
      Set.Icc (-1 : ℤ) b := by
  ext h
  simp only [Set.mem_ofPred_eq, Set.mem_Icc]
  constructor
  · rintro ⟨k, -, q, t, hk⟩
    obtain ⟨-, -, hh⟩ := counterInv_run b k _ hk
    cases q <;> simp only at hh <;> omega
  · intro hh
    rw [counter_total]
    by_cases hm : h = -1
    · subst hm
      exact ⟨b + 1 + counterN b, by omega, _, _, counter_reaches_end b⟩
    · lift h to ℕ using (by omega) with n
      refine ⟨n, by omega, .right, fun i => if 0 ≤ i ∧ i < (b : ℤ) then 1 else 0, ?_⟩
      have w := counter_walk (fun i => if 0 ≤ i ∧ i < (b : ℤ) then 1 else 0) n 0
        (fun i h1 h2 => by split_ifs <;> omega)
      simp only [zero_add] at w
      exact w

/-! ### The card's whole-number worked examples -/

-- input length: 16 cells of 3 bits each (0 to 4 needs 3 bits)
example : 16 * 3 = 48 ∧ 2 ^ 2 ≤ 4 ∧ 4 < 2 ^ 3 := by norm_num
-- fillings of 8 blanks: eight 4s multiplied
example : 4 ^ 8 = 65536 := by norm_num
-- comparisons per check: 12 units of 6 pairs, that is 3d · d(d − 1)/2 at d = 4
example : 12 * 6 = 72 ∧ 3 * 4 * (4 * 3 / 2) = 72 := by norm_num
-- the whole brute-force search
example : 65536 * 72 = 4718592 := by norm_num
-- comparisons per check at d = 9, 16, 25, 36
example : 3 * 9 * (9 * 8 / 2) = 972 ∧ 3 * 16 * (16 * 15 / 2) = 5760 ∧
    3 * 25 * (25 * 24 / 2) = 22500 ∧ 3 * 36 * (36 * 35 / 2) = 68040 := by norm_num
-- input bits n at d = 9, 16, 25, 36 (4, 5, 5, 6 bits per cell) and n^4
example : 81 * 4 = 324 ∧ 256 * 5 = 1280 ∧ 625 * 5 = 3125 ∧ 1296 * 6 = 7776 := by norm_num
example : 48 ^ 4 = 5308416 ∧ 324 ^ 4 = 11019960576 ∧ 1280 ^ 4 = 2684354560000 ∧
    3125 ^ 4 = 95367431640625 ∧ 7776 ^ 4 = 3656158440062976 := by norm_num
-- the tape counter's step formula 2(4^(b+1) − 1)/3 for b = 1 to 9
example : 2 * (4 ^ 2 - 1) / 3 = 10 ∧ 2 * (4 ^ 3 - 1) / 3 = 42 ∧ 2 * (4 ^ 4 - 1) / 3 = 170 ∧
    2 * (4 ^ 5 - 1) / 3 = 682 ∧ 2 * (4 ^ 6 - 1) / 3 = 2730 ∧ 2 * (4 ^ 7 - 1) / 3 = 10922 ∧
    2 * (4 ^ 8 - 1) / 3 = 43690 ∧ 2 * (4 ^ 9 - 1) / 3 = 174762 ∧
    2 * (4 ^ 10 - 1) / 3 = 699050 := by norm_num
-- the configuration bound at b = 8: 3 states, 10 cells, 5 symbols
example : 3 * 10 * 5 ^ 10 = 292968750 ∧ 174762 < 3 * 10 * 5 ^ 10 := by norm_num
-- the configuration bounds at b = 1 to 7 (cells b + 2)
example : 3 * 3 * 5 ^ 3 = 1125 ∧ 3 * 4 * 5 ^ 4 = 7500 ∧ 3 * 5 * 5 ^ 5 = 46875 ∧
    3 * 6 * 5 ^ 6 = 281250 ∧ 3 * 7 * 5 ^ 7 = 1640625 ∧ 3 * 8 * 5 ^ 8 = 9375000 ∧
    3 * 9 * 5 ^ 9 = 52734375 := by norm_num
-- the sum in the counter's proof at b = 8: first walk, increments by trailing 4s, last pass
example : 2 * (8 + 1) + (∑ j ∈ Finset.range 8, 3 * 4 ^ (8 - 1 - j) * (2 * j + 2)) = 174762 := by
  decide
-- the puzzle's solution 1 2 3 4 / 3 4 1 2 / 2 1 4 3 / 4 3 2 1 keeps every given of
-- 0 0 3 4 / 0 4 0 2 / 2 0 4 0 / 4 3 0 0 and has no repeat in any row, column or 2 by 2 box
example :
    let puzzle : List ℕ := [0, 0, 3, 4, 0, 4, 0, 2, 2, 0, 4, 0, 4, 3, 0, 0]
    let sol : List ℕ := [1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1]
    let units : List (List ℕ) :=
      [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15],
       [0, 4, 8, 12], [1, 5, 9, 13], [2, 6, 10, 14], [3, 7, 11, 15],
       [0, 1, 4, 5], [2, 3, 6, 7], [8, 9, 12, 13], [10, 11, 14, 15]]
    (List.zip puzzle sol).all (fun p => p.1 == 0 || p.1 == p.2) = true ∧
      units.all (fun u => (u.map fun i => sol.getD i 0).Nodup) = true ∧
      (puzzle.filter (· == 0)).length = 8 := by
  decide
-- the counter on b = 1 and b = 2 blanks halts after exactly 10 and 42 steps
example : (counterRun 1 10).isSome = true ∧ (counterRun 1 10).bind counterStep = none := by
  decide
example : (counterRun 2 42).isSome = true ∧ (counterRun 2 42).bind counterStep = none := by
  decide

#print axioms CounterReach
#print axioms counterReach_zero
#print axioms counterReach_one
#print axioms counterReach_trans
#print axioms counterStep_right_digit
#print axioms counterStep_right_blank
#print axioms counterStep_carry_four
#print axioms counterStep_carry_inc
#print axioms counterStep_carry_blank
#print axioms counter_walk
#print axioms counterN
#print axioms counterN_closed
#print axioms counter_carry_phase
#print axioms counter_reaches_end
#print axioms counter_total
#print axioms CounterInv
#print axioms counterInv_step
#print axioms counterInv_run
#print axioms halting_run_steps_lt_configurations
#print axioms counter_halts_in_exact_steps
#print axioms counter_visits_exactly_b_plus_two_cells
