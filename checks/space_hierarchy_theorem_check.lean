-- Space hierarchy: the fenced diagonal problem D beats every machine whose memory bound grows strictly slower than D's fence, a fenced run that outlasts its configuration count never halts, and with fence n no machine within c · (log₂ n)² cells solves D.
import Mathlib.Analysis.Asymptotics.Defs
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.Nat.Log
import Mathlib.Data.Nat.Size
import Mathlib.Logic.Function.Iterate
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Data.Fintype.Pigeonhole

/-! ### The machine model

A memory-fenced machine model is a function `res`: `res e w s = some b` means machine `e`, started
on input `w` and confined to `s` work cells, halts inside those cells with answer `b`
(`true` = accept); `res e w s = none` means it steps outside the `s` cells or repeats a
configuration, so it never answers inside them. A run that halts inside `s` cells is the same run
inside any bigger fence, so a bigger fence sees the same answer. Inputs are strings of bits.
`decode w` is the machine whose code is the front of `w`; the rest of `w` is padding. -/

/-- Machine `e` decides the language `A` within the memory bound `S`: on every input `w` of length
at least some `n₁`, it halts without leaving `S |w|` cells, and its answer is yes exactly when
`w ∈ A`. -/
def DecidesInSpace {C : Type*} (res : C → List Bool → ℕ → Option Bool) (e : C)
    (A : Set (List Bool)) (S : ℕ → ℕ) : Prop :=
  ∃ n₁, ∀ w : List Bool, n₁ ≤ w.length →
    ∃ b, res e w (S w.length) = some b ∧ (b = true ↔ w ∈ A)

/-- The diagonal problem D with fence `g`: accept `w` exactly when the machine coded by the front
of `w` does not accept `w` inside `g |w|` cells (leaving the cells or looping counts as not
accepting). -/
def diagonalD {C : Type*} (decode : List Bool → C) (res : C → List Bool → ℕ → Option Bool)
    (g : ℕ → ℕ) : Set (List Bool) :=
  {w | res (decode w) w (g w.length) ≠ some true}

/-- Helper: if the memory bound `S` is eventually at most D's fence `g`, no machine within `S`
solves D. -/
theorem not_decides_diagonal_of_eventually_le {C : Type*}
    (res : C → List Bool → ℕ → Option Bool)
    (hmono : ∀ e w s s' b, res e w s = some b → s ≤ s' → res e w s' = some b)
    (decode : List Bool → C) (hpad : ∀ e N, ∃ w : List Bool, N ≤ w.length ∧ decode w = e)
    (g S : ℕ → ℕ) (hSg : ∃ N, ∀ n, N ≤ n → S n ≤ g n) (e : C) :
    ¬ DecidesInSpace res e (diagonalD decode res g) S := by
  rintro ⟨n₁, h⟩
  obtain ⟨N, hN⟩ := hSg
  obtain ⟨w, hw, hdec⟩ := hpad e (max n₁ N)
  obtain ⟨b, hb, hiff⟩ := h w (le_trans (le_max_left _ _) hw)
  have hg : res e w (g w.length) = some b :=
    hmono e w _ _ b hb (hN _ (le_trans (le_max_right _ _) hw))
  have hmem : w ∈ diagonalD decode res g ↔ b ≠ true := by
    show res (decode w) w (g w.length) ≠ some true ↔ _
    rw [hdec, hg]; simp
  have hcon := hiff.trans hmem
  cases b <;> simp at hcon

/-- Helper: `k ^ 3 ≤ 2 ^ k` from `k = 10` on. -/
theorem cube_le_two_pow (k : ℕ) (hk : 10 ≤ k) : k ^ 3 ≤ 2 ^ k := by
  induction k, hk using Nat.le_induction with
  | base => norm_num
  | succ k hk ih =>
    have : (k + 1) ^ 3 ≤ 2 * k ^ 3 := by nlinarith [sq_nonneg k]
    rw [pow_succ 2 k]; linarith

/-- The space hierarchy, diagonal half: in any memory-fenced machine model where a bigger fence
keeps every answer and every machine's code can be padded to inputs as long as we like, if the
smaller memory bound `f` grows strictly slower than D's fence `g` (`f(n) = o(g(n))`), then no
machine that uses at most `c · f(n)` cells, for any constant `c`, solves D. Each such machine gets
D wrong on its own long padded code. -/
theorem no_machine_within_smaller_space_solves_diagonal {C : Type*}
    (res : C → List Bool → ℕ → Option Bool)
    (hmono : ∀ e w s s' b, res e w s = some b → s ≤ s' → res e w s' = some b)
    (decode : List Bool → C) (hpad : ∀ e N, ∃ w : List Bool, N ≤ w.length ∧ decode w = e)
    (f g : ℕ → ℕ)
    (hfg : Asymptotics.IsLittleO Filter.atTop (fun n => (f n : ℝ)) (fun n => (g n : ℝ)))
    (e : C) (c : ℕ) :
    ¬ DecidesInSpace res e (diagonalD decode res g) (fun n => c * f n) := by
  apply not_decides_diagonal_of_eventually_le res hmono decode hpad g _ _ e
  have hpos : (0 : ℝ) < 1 / ((c : ℝ) + 1) := by positivity
  obtain ⟨N, hN⟩ := Filter.eventually_atTop.1 (hfg.def hpos)
  refine ⟨N, fun n hn => ?_⟩
  have h1 := hN n hn
  simp only [Real.norm_natCast] at h1
  have hc : (0 : ℝ) ≤ c := Nat.cast_nonneg c
  have hg0 : (0 : ℝ) ≤ g n := Nat.cast_nonneg _
  have h2 : ((c : ℝ) + 1) * (f n : ℝ) ≤ g n := by
    rw [div_mul_eq_mul_div, one_mul, le_div_iff₀ (by positivity)] at h1
    linarith
  have h3 : ((c * f n : ℕ) : ℝ) ≤ g n := by
    push_cast
    nlinarith [Nat.cast_nonneg (α := ℝ) (f n)]
  exact_mod_cast h3

/-- A fenced run has few configurations: a deterministic machine with state set `Q` and tape
symbols `Γ`, confined to `s` cells, has configurations (state, head position, tape contents), at
most `|Q| · s · |Γ|^s` of them. If its run has not reached a halting configuration in its first
`|Q| · s · |Γ|^s` steps, it repeats a configuration and never halts. -/
theorem fenced_run_past_configuration_count_never_halts {Q Γ : Type*} [Fintype Q] [Fintype Γ]
    {s : ℕ} (step : Q × Fin s × (Fin s → Γ) → Q × Fin s × (Fin s → Γ))
    (H : Set (Q × Fin s × (Fin s → Γ))) (x : Q × Fin s × (Fin s → Γ))
    (hrun : ∀ t < Fintype.card Q * s * Fintype.card Γ ^ s, step^[t] x ∉ H) :
    ∀ t, step^[t] x ∉ H := by
  set N := Fintype.card Q * s * Fintype.card Γ ^ s with hNdef
  have hcard : Fintype.card (Q × Fin s × (Fin s → Γ)) = N := by
    simp [Fintype.card_prod, Fintype.card_fin, hNdef, mul_assoc]
  obtain ⟨a, b, hab, heq⟩ := Fintype.exists_ne_map_eq_of_card_lt
    (fun i : Fin (N + 1) => step^[(i : ℕ)] x) (by simp [hcard])
  -- get i < j ≤ N with equal iterates
  obtain ⟨i, j, hij, hjN, hiter⟩ : ∃ i j : ℕ, i < j ∧ j ≤ N ∧ step^[i] x = step^[j] x := by
    rcases lt_or_gt_of_ne (Fin.val_ne_of_ne hab) with h | h
    · exact ⟨a, b, h, Nat.lt_succ_iff.1 b.2, heq⟩
    · exact ⟨b, a, h, Nat.lt_succ_iff.1 a.2, heq.symm⟩
  have key : ∀ t, ∃ t' < N, step^[t] x = step^[t'] x := by
    intro t
    induction t using Nat.strong_induction_on with
    | _ t ih =>
      by_cases ht : t < j
      · exact ⟨t, lt_of_lt_of_le ht hjN, rfl⟩
      · replace ht : j ≤ t := Nat.le_of_not_lt ht
        have e1 : step^[t] x = step^[t - j + i] x := by
          rw [show t = (t - j) + j by omega, Function.iterate_add_apply, ← hiter,
            ← Function.iterate_add_apply]
          congr 1; omega
        obtain ⟨t', ht', he⟩ := ih (t - j + i) (by omega)
        exact ⟨t', ht', e1.trans he⟩
  intro t
  obtain ⟨t', ht', he⟩ := key t
  rw [he]; exact hrun t' ht'

/-- The card's separation of L and NL from PSPACE, diagonal half: with D's fence at `n` cells, no
machine that uses at most `c · (log₂ n)²` cells, for any constant `c`, solves D. So D is in no
SPACE((log₂ n)²) class, the class that holds NL by Savitch's theorem. -/
theorem diagonal_with_fence_n_not_in_log_squared_space {C : Type*}
    (res : C → List Bool → ℕ → Option Bool)
    (hmono : ∀ e w s s' b, res e w s = some b → s ≤ s' → res e w s' = some b)
    (decode : List Bool → C) (hpad : ∀ e N, ∃ w : List Bool, N ≤ w.length ∧ decode w = e)
    (e : C) (c : ℕ) :
    ¬ DecidesInSpace res e (diagonalD decode res (fun n => n))
      (fun n => c * Nat.log 2 n ^ 2) := by
  apply not_decides_diagonal_of_eventually_le res hmono decode hpad _ _ _ e
  refine ⟨2 ^ max 10 c, fun n hn => ?_⟩
  have hn0 : n ≠ 0 := by
    intro h; subst h; simp at hn
  have hK : max 10 c ≤ Nat.log 2 n := Nat.le_log_of_pow_le (by norm_num) hn
  set k := Nat.log 2 n
  have h1 : c * k ^ 2 ≤ k ^ 3 := by
    rw [pow_succ, mul_comm]; exact Nat.mul_le_mul_left _ (le_trans (le_max_right _ _) hK)
  have h2 : k ^ 3 ≤ 2 ^ k := cube_le_two_pow k (le_trans (le_max_left _ _) hK)
  have h3 : 2 ^ k ≤ n := Nat.pow_log_le_self 2 hn0
  omega

-- The family: 4 rules × 4 bits = 16-bit codes, 2¹⁶ = 65,536 two-state machines; 508D is 20,621.
example : 4 * 4 = 16 ∧ 2 ^ 16 = 65536 ∧ 0x508D = 20621 := by norm_num
-- On own codes inside 20 cells: accept 22,192, reject 22,217, leave 20,180, loop 947.
example : 22192 + 22217 + 20180 + 947 = 65536 := by norm_num
-- D accepts reject + leave + loop = 43,344.
example : 22217 + 20180 + 947 = 43344 := by norm_num
-- Configurations of a two-state machine in s cells, 2 · s · 2^s, for s = 16 to 21.
example : [16, 17, 18, 19, 20, 21].map (fun s => 2 * s * 2 ^ s) =
    [2097152, 4456448, 9437184, 19922944, 41943040, 88080384] := by decide +kernel
-- Machine 508D's exit steps for s = 16 to 21: each extra cell adds 2^s - 1 steps.
example : 40422 + (2 ^ 17 - 1) = 171493 ∧ 171493 + (2 ^ 18 - 1) = 433636 ∧
    433636 + (2 ^ 19 - 1) = 957923 ∧ 957923 + (2 ^ 20 - 1) = 2006498 ∧
    2006498 + (2 ^ 21 - 1) = 4103649 := by norm_num
-- Machine 508D runs 4,103,649 steps in 21 cells, inside its 88,080,384 configurations.
example : 4103649 < 2 * 21 * 2 ^ 21 := by norm_num
-- D's memory model at n = 16: g = 256, counter k = bits of 2 · 256 · 2^256 = 2^265, so k = 266,
-- and 16 + 256 + 266 = 538 cells.
example : 16 ^ 2 = 256 ∧ 2 * 256 * 2 ^ 256 = 2 ^ 265 ∧ Nat.size (2 ^ 265) = 266 ∧
    16 + 256 + 266 = 538 := by
  decide +kernel
-- The model at n = 64 and 256: 16 + 4,096 + 4,110 = 8,222 and 16 + 65,536 + 65,554 = 131,106.
example : 64 ^ 2 = 4096 ∧ 16 + 4096 + 4110 = 8222 ∧ 256 ^ 2 = 65536 ∧
    16 + 65536 + 65554 = 131106 := by norm_num
-- At n = 1,024: g = 1,048,576 = 2^20, so 2 · g · 2^g = 2^(g + 21), k = g + 22 = 1,048,598,
-- and D uses 16 + 1,048,576 + 1,048,598 = 2,097,190 cells.
example : 1024 ^ 2 = 2 ^ 20 ∧ 2 ^ 20 + 22 = 1048598 ∧ 16 + 1048576 + 1048598 = 2097190 := by
  norm_num
-- D squeezed into 16 cells: counter bits of 2 · 16 · 2^16 = 2^21 is 22, so 16 + 16 + 22 = 54.
example : 2 * 16 * 2 ^ 16 = 2 ^ 21 ∧ Nat.size (2 ^ 21) = 22 ∧ 16 + 16 + 22 = 54 := by
  refine ⟨by norm_num, by decide +kernel, by norm_num⟩
-- The ladder: log₂ n, (log₂ n)², n, n² at n = 2^10, 2^20, 2^30.
example : [10, 20, 30].map (fun e => (Nat.log 2 (2 ^ e), Nat.log 2 (2 ^ e) ^ 2, 2 ^ e, (2 ^ e) ^ 2)) =
    [(10, 100, 1024, 1048576), (20, 400, 1048576, 1099511627776),
     (30, 900, 1073741824, 1152921504606846976)] := by decide +kernel
-- At n = 16, (log₂ n)² = 16 = n, the first point from which it never exceeds n again.
example : Nat.log 2 16 ^ 2 = 16 := by decide +kernel

#print axioms not_decides_diagonal_of_eventually_le
#print axioms cube_le_two_pow
#print axioms no_machine_within_smaller_space_solves_diagonal
#print axioms fenced_run_past_configuration_count_never_halts
#print axioms diagonal_with_fence_n_not_in_log_squared_space
