-- Hierarchy and Ladner: the clocked diagonal problem D beats every machine whose time bound its clock outgrows, so no machine within c · n² steps solves D with clock n² · ⌊log₂ n⌋, while D's one-tape cost stays under n³ from n = 702 on.
import Mathlib.Data.Nat.Log
import Mathlib.Data.Nat.Size
import Mathlib.Order.Filter.AtTopBot.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith

/-! ### The machine model

A step-counted machine model is a function `run`: `run e w s = some b` means machine `e`, started
on input `w`, has halted within `s` steps with answer `b` (`true` = accept), and `run e w s = none`
means it is still running after `s` steps. Halting is final, so a longer budget sees the same
answer. Inputs are strings of bits. `decode w` is the machine whose code is the front of `w`; the
rest of `w` is padding. -/

/-- Machine `e` decides the language `A` within the time bound `T`: on every input `w` of length
at least some `n₁`, it halts within `T |w|` steps, and its answer is yes exactly when `w ∈ A`. -/
def DecidesInTime {C : Type*} (run : C → List Bool → ℕ → Option Bool) (e : C)
    (A : Set (List Bool)) (T : ℕ → ℕ) : Prop :=
  ∃ n₁, ∀ w : List Bool, n₁ ≤ w.length →
    ∃ b, run e w (T w.length) = some b ∧ (b = true ↔ w ∈ A)

/-- The diagonal problem D with clock `t`: accept `w` exactly when the machine coded by the front
of `w` does not accept `w` within `t |w|` steps. -/
def diagonalD {C : Type*} (decode : List Bool → C) (run : C → List Bool → ℕ → Option Bool)
    (t : ℕ → ℕ) : Set (List Bool) :=
  {w | run (decode w) w (t w.length) ≠ some true}

/-- The time hierarchy, diagonal half: in any machine model where halting is final and every
machine's code can be padded to inputs as long as we like, if D's clock `t` eventually outgrows
every constant multiple of the bound `f`, then no machine that runs within `c · f(n)` steps
solves D. Each such machine gets D wrong on its own long padded code. -/
theorem no_machine_within_smaller_time_solves_diagonal {C : Type*}
    (run : C → List Bool → ℕ → Option Bool)
    (hfinal : ∀ e w s s' b, run e w s = some b → s ≤ s' → run e w s' = some b)
    (decode : List Bool → C) (hpad : ∀ e N, ∃ w : List Bool, N ≤ w.length ∧ decode w = e)
    (f t : ℕ → ℕ) (hgap : ∀ c : ℕ, ∀ᶠ n in Filter.atTop, c * f n ≤ t n)
    (e : C) (c : ℕ) :
    ¬ DecidesInTime run e (diagonalD decode run t) (fun n => c * f n) := by
  rintro ⟨n₁, h⟩
  obtain ⟨N, hN⟩ := Filter.eventually_atTop.1 (hgap c)
  obtain ⟨w, hw, hdec⟩ := hpad e (max n₁ N)
  obtain ⟨b, hb, hiff⟩ := h w (le_trans (le_max_left _ _) hw)
  have ht : run e w (t w.length) = some b :=
    hfinal e w _ _ b hb (hN _ (le_trans (le_max_right _ _) hw))
  have hmem : w ∈ diagonalD decode run t ↔ run e w (t w.length) ≠ some true := by
    simp [diagonalD, hdec]
  rw [hmem, ht] at hiff
  cases b <;> simp at hiff

/-- The card's case: with D's clock `n² · ⌊log₂ n⌋`, no machine that runs within `c · n²` steps,
for any constant `c`, solves D. So D is not in TIME(n²). -/
theorem diagonal_with_clock_n_sq_log_not_in_quadratic_time {C : Type*}
    (run : C → List Bool → ℕ → Option Bool)
    (hfinal : ∀ e w s s' b, run e w s = some b → s ≤ s' → run e w s' = some b)
    (decode : List Bool → C) (hpad : ∀ e N, ∃ w : List Bool, N ≤ w.length ∧ decode w = e)
    (e : C) (c : ℕ) :
    ¬ DecidesInTime run e (diagonalD decode run (fun n => n ^ 2 * Nat.log 2 n))
      (fun n => c * n ^ 2) := by
  refine no_machine_within_smaller_time_solves_diagonal run hfinal decode hpad
    (fun n => n ^ 2) (fun n => n ^ 2 * Nat.log 2 n) ?_ e c
  intro c'
  refine Filter.eventually_atTop.2 ⟨2 ^ c', fun n hn => ?_⟩
  have : c' ≤ Nat.log 2 n := Nat.le_log_of_pow_le (by norm_num) hn
  calc c' * n ^ 2 = n ^ 2 * c' := Nat.mul_comm _ _
    _ ≤ n ^ 2 * Nat.log 2 n := Nat.mul_le_mul_left _ this

/-- The card's one-tape cost model of D: `n² · ⌊log₂ n⌋` simulated steps, each a sweep of
`2(16 + k)` moves over the 16-cell rule block and the `k`-bit step counter, where `k` is the bit
length of the clock. This cost is at most `n³` for every input length `n` from 702 on. -/
theorem diagonal_cost_le_cube_from_702 (n : ℕ) (hn : 702 ≤ n) :
    n ^ 2 * Nat.log 2 n * (2 * (16 + Nat.size (n ^ 2 * Nat.log 2 n))) ≤ n ^ 3 := by
  have hn0 : n ≠ 0 := by omega
  set L := Nat.log 2 n with hL
  have hlo : 2 ^ L ≤ n := Nat.pow_log_le_self 2 hn0
  have hhi : n < 2 ^ (L + 1) := Nat.lt_pow_succ_log_self (by norm_num) n
  have hL9 : 9 ≤ L := Nat.le_log_of_pow_le (by norm_num) (by omega)
  have key : ∀ K, n ^ 2 * L < 2 ^ K → 2 * L * (16 + K) ≤ n →
      n ^ 2 * L * (2 * (16 + Nat.size (n ^ 2 * L))) ≤ n ^ 3 := by
    intro K hK hle
    have hs : Nat.size (n ^ 2 * L) ≤ K := Nat.size_le.2 hK
    calc n ^ 2 * L * (2 * (16 + Nat.size (n ^ 2 * L)))
        ≤ n ^ 2 * L * (2 * (16 + K)) := Nat.mul_le_mul_left _ (by omega)
      _ = n ^ 2 * (2 * L * (16 + K)) := by ring
      _ ≤ n ^ 2 * n := Nat.mul_le_mul_left _ hle
      _ = n ^ 3 := by ring
  by_cases hsmall : n ≤ 965
  · have hL' : L = 9 := by
      have : L < 10 := by
        by_contra hc
        have : 2 ^ 10 ≤ 2 ^ L := Nat.pow_le_pow_right (by norm_num) (by omega)
        omega
      omega
    refine key 23 ?_ (by rw [hL']; omega)
    rw [hL']
    have : n ^ 2 ≤ 965 ^ 2 := Nat.pow_le_pow_left hsmall 2
    norm_num at this ⊢
    omega
  · refine key (3 * L + 2) ?_ ?_
    · have hLlt : L < 2 ^ L := Nat.lt_two_pow_self
      have hsq : n ^ 2 < (2 ^ (L + 1)) ^ 2 := Nat.pow_lt_pow_left hhi (by norm_num)
      calc n ^ 2 * L < (2 ^ (L + 1)) ^ 2 * 2 ^ L :=
            Nat.mul_lt_mul_of_lt_of_lt hsq hLlt
        _ = 2 ^ (3 * L + 2) := by rw [← pow_mul, ← pow_add]; ring_nf
    · rcases Nat.eq_or_lt_of_le hL9 with h9 | h10
      · rw [← h9]; omega
      · have aux : ∀ m, 10 ≤ m → 2 * m * (16 + (3 * m + 2)) ≤ 2 ^ m := by
          intro m hm
          induction m, hm using Nat.le_induction with
          | base => norm_num
          | succ k hk ih =>
            rw [pow_succ]
            nlinarith
        exact le_trans (aux L h10) hlo

/-! ### The card's two-state machines

A machine is a 16-bit code: four 4-bit rules, one per (state, symbol), in the order (A, 0),
(A, 1), (B, 0), (B, 1). Each rule's bits are write, move (1 = right), and two bits of next state
(0 A, 1 B, 2 accept, 3 reject). The tape is binary and blank cells read 0. -/

/-- The 4-bit rule of machine `i` for state `s` reading symbol `a`. -/
def rule (i s a : ℕ) : ℕ := i / 2 ^ (12 - 4 * (2 * s + a)) % 16

/-- Run machine `i` for at most `k` more steps from the configuration with cells `l` left of the
head (nearest first), symbol `x` under the head, cells `r` right of the head, and state `s`.
Returns 1 = accepted, 0 = rejected, 2 = still running. -/
def runTM (i : ℕ) : ℕ → List ℕ → ℕ → List ℕ → ℕ → ℕ
  | 0, _, _, _, _ => 2
  | k + 1, l, x, r, s =>
    match rule i s x with
    | ru =>
      if ru % 4 = 2 then 1 else if ru % 4 = 3 then 0
      else if ru / 4 % 2 = 1 then
        match r with
        | [] => runTM i k (ru / 8 :: l) 0 [] (ru % 4)
        | y :: r' => runTM i k (ru / 8 :: l) y r' (ru % 4)
      else
        match l with
        | [] => runTM i k [] 0 (ru / 8 :: r) (ru % 4)
        | y :: l' => runTM i k l' y (ru / 8 :: r) (ru % 4)

/-- The 16 bits of code `j`, most significant first: the input string. -/
def codeBits (j : ℕ) : List ℕ := (List.range 16).reverse.map fun p => j / 2 ^ p % 2

/-- Run machine `i` on input `w` for at most `k` steps, head on the first symbol, in state A. -/
def runOn (i : ℕ) (w : List ℕ) (k : ℕ) : ℕ :=
  match w with
  | [] => runTM i k [] 0 [] 0
  | x :: r => runTM i k [] x r 0

/-- Row machine `i` on column code `j`: 1 if it accepts within D's clock of 1,024 steps, else 0. -/
def cell (i j : ℕ) : ℕ := if runOn i (codeBits j) 1024 = 1 then 1 else 0

/-- The five machines of the card's table: 7E77, 5D7E, 6E66, 0000, 6F77 in hexadecimal. -/
def five : List ℕ := [0x7E77, 0x5D7E, 0x6E66, 0x0000, 0x6F77]

-- D's clock at n = 16 is 16² × 4 = 1,024 steps, and the family has 2¹⁶ = 65,536 machines.
example : 16 ^ 2 * Nat.log 2 16 = 1024 ∧ 2 ^ 16 = 65536 := by decide +kernel
-- The table, rows on columns: first bit 1, second bit 1, always yes, walks left, first bit 0.
example : five.map (fun i => five.map (cell i)) =
    [[0, 0, 0, 0, 0], [1, 1, 1, 0, 1], [1, 1, 1, 1, 1], [0, 0, 0, 0, 0], [1, 1, 1, 1, 1]] := by
  decide +kernel
-- The diagonal reads 0 1 1 0 1, so D reads 1 0 0 1 0.
example : (List.range 5).map (fun r => 1 - cell (five.getD r 0) (five.getD r 0)) =
    [1, 0, 0, 1, 0] := by
  decide +kernel
-- Machine 41,424 accepts its own code at step 111, inside the clock and not before.
example : runOn 41424 (codeBits 41424) 110 = 2 ∧
    runOn 41424 (codeBits 41424) 111 = 1 := by
  decide +kernel
-- No clock: machine 0 on its own code is still running after 10,000 steps.
example : runOn 0 (codeBits 0) 10000 = 2 := by decide +kernel
-- The counts on own codes: accept 26,310, reject 26,336, still running 12,890; D accepts 39,226.
example : 26310 + 26336 + 12890 = 65536 ∧ 26336 + 12890 = 39226 := by norm_num
-- The cost model at n = 16, 64, 256, 1,024: clock, counter bits k, cost clock × 2(16 + k), n³.
example : [16, 64, 256, 1024].map (fun n => n ^ 2 * Nat.log 2 n) =
    [1024, 24576, 524288, 10485760] := by decide +kernel
example : [16, 64, 256, 1024].map (fun n => Nat.size (n ^ 2 * Nat.log 2 n)) = [11, 15, 20, 24] := by
  decide +kernel
example : [16, 64, 256, 1024].map
      (fun n => n ^ 2 * Nat.log 2 n * (2 * (16 + Nat.size (n ^ 2 * Nat.log 2 n)))) =
    [55296, 1523712, 37748736, 838860800] := by decide +kernel
example : 1024 ^ 3 = 1073741824 ∧ 838860800 ≤ 1024 ^ 3 := by norm_num
-- At n = 701 the cost is still above n³; at n = 702 it meets n³ exactly.
example : 701 ^ 2 * Nat.log 2 701 * (2 * (16 + Nat.size (701 ^ 2 * Nat.log 2 701))) > 701 ^ 3 ∧
    702 ^ 2 * Nat.log 2 702 * (2 * (16 + Nat.size (702 ^ 2 * Nat.log 2 702))) = 702 ^ 3 := by
  decide +kernel
-- Hoping D fits in n² steps: at n = 64 D costs 1,523,712 steps, against 64² = 4,096.
example : 64 ^ 2 = 4096 ∧ 4096 < 1523712 := by norm_num
-- 2ⁿ passes n³ at n = 10 (2⁹ = 512 < 729 = 9³), and n¹⁰ at n = 59 (2⁵⁸ < 58¹⁰).
example : 2 ^ 10 = 1024 ∧ 10 ^ 3 = 1000 ∧ 2 ^ 9 < 9 ^ 3 := by norm_num
example : 2 ^ 59 = 576460752303423488 ∧ 59 ^ 10 = 511116753300641401 ∧ 59 ^ 10 < 2 ^ 59 ∧
    2 ^ 58 < 58 ^ 10 := by norm_num
-- Ladner padding of a 4 by 4 sudoku, m = 48 bits: tails of m^H bits for H = 1 to 4.
example : [1, 2, 3, 4].map (fun H => 48 ^ H) = [48, 2304, 110592, 5308416] := by decide +kernel
-- Budgets at n = 1,000: n² = 1,000,000 and n³ = 1,000,000,000.
example : 1000 ^ 2 = 1000000 ∧ 1000 ^ 3 = 1000000000 := by norm_num

#print axioms no_machine_within_smaller_time_solves_diagonal
#print axioms diagonal_with_clock_n_sq_log_not_in_quadratic_time
#print axioms diagonal_cost_le_cube_from_702
