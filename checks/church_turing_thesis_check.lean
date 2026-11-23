-- Church-Turing thesis: a tape held as two base-b numbers makes the same reads, writes and moves as the tape itself, and the card's tape machine and counter machine double n in exactly 2(n + 1)^2 and 5n + 1 steps.
import Mathlib.Data.Nat.Digits.Defs

/-! The thesis itself links a precise idea to an informal one ("every reasonable machine"),
so it is not a theorem and is not stated here. This file states the card's theorems:
Step 3's two-number tape, and the step counts of the tape machine and the counter machine. -/

namespace ChurchTuring

/-! ### Run a machine for k steps -/

/-- Take `k` steps of a machine whose one-step rule is `step` (`none` means it has stopped).
The result is `none` if the machine stopped before taking all `k` steps. -/
def iterStep {C : Type} (step : C → Option C) : ℕ → C → Option C
  | 0, c => some c
  | k + 1, c => (step c).bind (iterStep step k)

/-- Running `a + b` steps is running `a` steps, then `b` more. -/
theorem iterStep_add {C : Type} (step : C → Option C) (a b : ℕ) (c : C) :
    iterStep step (a + b) c = (iterStep step a c).bind (iterStep step b) := by
  induction a generalizing c with
  | zero => simp [iterStep]
  | succ a ih =>
    rw [show a + 1 + b = (a + b) + 1 by omega]
    simp only [iterStep, ih, Option.bind_assoc]

#print axioms iterStep_add

/-- One more step: take one step, then the rest. -/
theorem iterStep_succ {C : Type} (step : C → Option C) (k : ℕ) (c : C) :
    iterStep step (k + 1) c = (step c).bind (iterStep step k) := rfl

#print axioms iterStep_succ

/-- Zero steps change nothing. -/
theorem iterStep_zero {C : Type} (step : C → Option C) (c : C) :
    iterStep step 0 c = some c := rfl

#print axioms iterStep_zero

/-! ### A tape as two lists, and as two numbers -/

/-- A head move: one cell left or one cell right. -/
inductive Dir
  | L
  | R
  deriving DecidableEq

/-- Write `w` on the head's cell, then move. The tape is two lists of symbols (digits, blank = 0):
`left` holds the cells left of the head, nearest first; `right` holds the head's cell and
everything right of it, head cell first. Cells past the ends of the lists are blank. -/
def tapeWriteMove (left right : List ℕ) (w : ℕ) : Dir → List ℕ × List ℕ
  | .R => (w :: left, right.tail)
  | .L => (left.tail, left.headD 0 :: w :: right.tail)

/-- The same write and move done on two whole numbers, as on the card:
write `r ← r - (r mod b) + w`; move right `ℓ ← bℓ + w`, `r ← ⌊r / b⌋`;
move left `r ← b r + (ℓ mod b)`, `ℓ ← ⌊ℓ / b⌋`. -/
def numWriteMove (b ℓ r w : ℕ) : Dir → ℕ × ℕ
  | .R => (b * ℓ + w, (r - r % b + w) / b)
  | .L => (ℓ / b, b * (r - r % b + w) + ℓ % b)

/-- A list of digits below `b`: its number mod `b` is its first digit. -/
theorem ofDigits_mod_eq_headD (b : ℕ) (l : List ℕ) (hl : ∀ x ∈ l, x < b) :
    Nat.ofDigits b l % b = l.headD 0 := by
  cases l with
  | nil => simp [Nat.ofDigits]
  | cons x xs =>
    have hx : x < b := hl x (by simp)
    simp [Nat.ofDigits_cons, Nat.add_mul_mod_self_left, Nat.mod_eq_of_lt hx]

#print axioms ofDigits_mod_eq_headD

/-- A list of digits below `b`: its number divided by `b` is the number of its tail. -/
theorem ofDigits_div_eq_tail (b : ℕ) (l : List ℕ) (hl : ∀ x ∈ l, x < b) :
    Nat.ofDigits b l / b = Nat.ofDigits b l.tail := by
  cases l with
  | nil => simp [Nat.ofDigits]
  | cons x xs =>
    have hx : x < b := hl x (by simp)
    have hb : 0 < b := by omega
    simp only [Nat.ofDigits_cons, List.tail_cons]
    rw [Nat.add_mul_div_left _ _ hb, Nat.div_eq_of_lt hx, Nat.zero_add]

#print axioms ofDigits_div_eq_tail

/-- Every number `r` equals `r - r mod b` plus `r mod b`, and `r - r mod b = b ⌊r / b⌋`. -/
theorem sub_mod_eq_mul_div (b r : ℕ) : r - r % b = b * (r / b) := by
  have := Nat.div_add_mod r b
  omega

#print axioms sub_mod_eq_mul_div

/-- **Step 3, a tape held as two numbers.** Read each side of the tape as a number in base `b`,
nearest cell as the lowest digit (`Nat.ofDigits`). If every symbol is a digit below `b`, then
the head's symbol is `r mod b`, and writing `w` and moving left or right on the tape gives exactly
the two numbers the arithmetic gives. So a machine holding only whole numbers can follow every
step of a tape machine. -/
theorem two_number_tape_simulation (b : ℕ) (left right : List ℕ) (w : ℕ)
    (hleft : ∀ x ∈ left, x < b) (hright : ∀ x ∈ right, x < b) (hw : w < b) :
    Nat.ofDigits b right % b = right.headD 0 ∧
      ∀ m : Dir,
        (Nat.ofDigits b (tapeWriteMove left right w m).1,
            Nat.ofDigits b (tapeWriteMove left right w m).2) =
          numWriteMove b (Nat.ofDigits b left) (Nat.ofDigits b right) w m := by
  have hb : 0 < b := by omega
  refine ⟨ofDigits_mod_eq_headD b right hright, ?_⟩
  intro m
  have hr := sub_mod_eq_mul_div b (Nat.ofDigits b right)
  have hrd := ofDigits_div_eq_tail b right hright
  cases m with
  | R =>
    simp only [tapeWriteMove, numWriteMove, Nat.ofDigits_cons, Prod.mk.injEq]
    refine ⟨by ring, ?_⟩
    rw [hr, Nat.mul_comm, Nat.add_comm, Nat.add_mul_div_right _ _ hb, Nat.div_eq_of_lt hw,
      Nat.zero_add, hrd]
  | L =>
    simp only [tapeWriteMove, numWriteMove, Nat.ofDigits_cons, Prod.mk.injEq]
    refine ⟨(ofDigits_div_eq_tail b left hleft).symm, ?_⟩
    rw [hr, hrd, ofDigits_mod_eq_headD b left hleft]
    ring

/-! ### The card's tape machine (symbols: blank 0, `1` is 1, `X` is 2, `Y` is 3) -/

/-- The tape machine's states. `halt` has no rows, so the machine stops there. -/
inductive Q
  | mark
  | end_
  | back
  | fix
  | home
  | halt
  deriving DecidableEq

/-- The card's rule table: (state, read) gives (write, move, next); `none` means no row. -/
def rule : Q → ℕ → Option (ℕ × Dir × Q)
  | .mark, 1 => some (2, .R, .end_)
  | .mark, 3 => some (1, .R, .fix)
  | .mark, 0 => some (0, .R, .halt)
  | .end_, 1 => some (1, .R, .end_)
  | .end_, 3 => some (3, .R, .end_)
  | .end_, 0 => some (3, .L, .back)
  | .back, 1 => some (1, .L, .back)
  | .back, 3 => some (3, .L, .back)
  | .back, 2 => some (2, .R, .mark)
  | .fix, 3 => some (1, .R, .fix)
  | .fix, 0 => some (0, .L, .home)
  | .home, 1 => some (1, .L, .home)
  | .home, 2 => some (1, .L, .home)
  | .home, 0 => some (0, .R, .halt)
  | _, _ => none

/-- A tape machine's configuration: state, cells left of the head (nearest first), and the
head's cell with everything right of it. -/
structure TMConf where
  q : Q
  left : List ℕ
  right : List ℕ

/-- One step of the tape machine: read the head's cell, look up the row, write, move. -/
def tmStep (c : TMConf) : Option TMConf :=
  match rule c.q (c.right.headD 0) with
  | none => none
  | some (w, m, q') =>
      let t := tapeWriteMove c.left c.right w m
      some ⟨q', t.1, t.2⟩

/-- The start: state `mark`, head on the first of `n` ones, blanks everywhere else. -/
def tmStart (n : ℕ) : TMConf := ⟨.mark, [], List.replicate n 1⟩

/-- The state `halt` has no rows. -/
theorem rule_halt (x : ℕ) : rule .halt x = none := by
  rcases x with _ | _ | _ | _ | x <;> rfl

#print axioms rule_halt

/-- `end_` walks right over ones and `Y`s, leaving them as they are. -/
theorem end_run (xs : List ℕ) (hxs : ∀ x ∈ xs, x = 1 ∨ x = 3) (L R : List ℕ) :
    iterStep tmStep xs.length ⟨.end_, L, xs ++ R⟩ = some ⟨.end_, xs.reverse ++ L, R⟩ := by
  induction xs generalizing L with
  | nil => rfl
  | cons x xs ih =>
    have hx := hxs x (by simp)
    have hrest : ∀ y ∈ xs, y = 1 ∨ y = 3 := fun y hy => hxs y (by simp [hy])
    have hstep : tmStep ⟨.end_, L, x :: (xs ++ R)⟩ = some ⟨.end_, x :: L, xs ++ R⟩ := by
      rcases hx with rfl | rfl <;> rfl
    rw [List.length_cons, iterStep_succ, List.cons_append, hstep, Option.bind_some, ih hrest]
    simp

#print axioms end_run

/-- `back` walks left over ones and `Y`s to the nearest `X`, then steps right in state `mark`.
The head's cell and the cells left of it are read together as the list `xs ++ 2 :: L`. -/
theorem back_run (xs : List ℕ) (hxs : ∀ x ∈ xs, x = 1 ∨ x = 3) (L R : List ℕ) :
    iterStep tmStep (xs.length + 1)
        ⟨.back, (xs ++ 2 :: L).tail, (xs ++ 2 :: L).headD 0 :: R⟩ =
      some ⟨.mark, 2 :: L, xs.reverse ++ R⟩ := by
  induction xs generalizing R with
  | nil => rfl
  | cons x xs ih =>
    have hx := hxs x (by simp)
    have hrest : ∀ y ∈ xs, y = 1 ∨ y = 3 := fun y hy => hxs y (by simp [hy])
    have hstep : tmStep ⟨.back, xs ++ 2 :: L, x :: R⟩ =
        some ⟨.back, (xs ++ 2 :: L).tail, (xs ++ 2 :: L).headD 0 :: x :: R⟩ := by
      rcases hx with rfl | rfl <;> rfl
    rw [List.length_cons, iterStep_succ, List.cons_append, List.tail_cons, List.headD_cons, hstep,
      Option.bind_some, ih hrest]
    simp

#print axioms back_run

/-- `fix` walks right over `Y`s, turning each into a one. -/
theorem fix_run (k : ℕ) (L R : List ℕ) :
    iterStep tmStep k ⟨.fix, L, List.replicate k 3 ++ R⟩ =
      some ⟨.fix, List.replicate k 1 ++ L, R⟩ := by
  induction k generalizing L with
  | zero => rfl
  | succ k ih =>
    have hstep : tmStep ⟨.fix, L, 3 :: (List.replicate k 3 ++ R)⟩ =
        some ⟨.fix, 1 :: L, List.replicate k 3 ++ R⟩ := rfl
    rw [iterStep_succ, List.replicate_succ, List.cons_append, hstep, Option.bind_some, ih]
    simp [List.replicate_succ']

#print axioms fix_run

/-- `home` walks left over ones and `X`s, turning each into a one. -/
theorem home_run (xs : List ℕ) (hxs : ∀ x ∈ xs, x = 1 ∨ x = 2) (L R : List ℕ) :
    iterStep tmStep xs.length ⟨.home, (xs ++ L).tail, (xs ++ L).headD 0 :: R⟩ =
      some ⟨.home, L.tail, L.headD 0 :: (List.replicate xs.length 1 ++ R)⟩ := by
  induction xs generalizing R with
  | nil => rfl
  | cons x xs ih =>
    have hx := hxs x (by simp)
    have hrest : ∀ y ∈ xs, y = 1 ∨ y = 2 := fun y hy => hxs y (by simp [hy])
    have hstep : tmStep ⟨.home, xs ++ L, x :: R⟩ =
        some ⟨.home, (xs ++ L).tail, (xs ++ L).headD 0 :: 1 :: R⟩ := by
      rcases hx with rfl | rfl <;> rfl
    rw [List.length_cons, iterStep_succ, List.cons_append, List.tail_cons, List.headD_cons, hstep,
      Option.bind_some, ih hrest]
    simp [List.replicate_succ']

#print axioms home_run

/-- One round: from `X^k 1^(n-k) Y^k` in state `mark`, `2n + 1` steps mark one more one and
add one more `Y`. -/
theorem tm_round (n k : ℕ) (hk : k < n) :
    iterStep tmStep (2 * n + 1)
        ⟨.mark, List.replicate k 2, List.replicate (n - k) 1 ++ List.replicate k 3⟩ =
      some ⟨.mark, List.replicate (k + 1) 2,
        List.replicate (n - (k + 1)) 1 ++ List.replicate (k + 1) 3⟩ := by
  obtain ⟨j, rfl⟩ : ∃ j, n = k + j + 1 := ⟨n - k - 1, by omega⟩
  set M := List.replicate j 1 ++ List.replicate k 3 with hM
  have hMv : ∀ x ∈ M, x = 1 ∨ x = 3 := by
    intro x hx
    simp only [hM, List.mem_append, List.mem_replicate] at hx
    omega
  have hMr : ∀ x ∈ M.reverse, x = 1 ∨ x = 3 := fun x hx => hMv x (List.mem_reverse.mp hx)
  have hlen : M.length = j + k := by simp [hM]
  have hsteps : 2 * (k + j + 1) + 1 = 1 + (M.length + (1 + (M.reverse.length + 1))) := by
    simp only [List.length_reverse, hlen]; omega
  have h1 : tmStep ⟨.mark, List.replicate k 2, List.replicate (k + j + 1 - k) 1 ++ List.replicate k 3⟩ =
      some ⟨.end_, 2 :: List.replicate k 2, M ++ []⟩ := by
    rw [show k + j + 1 - k = j + 1 by omega, List.replicate_succ, List.append_nil]
    rfl
  have h2 := end_run M hMv (2 :: List.replicate k 2) []
  have h3 : tmStep ⟨.end_, M.reverse ++ 2 :: List.replicate k 2, []⟩ =
      some ⟨.back, (M.reverse ++ 2 :: List.replicate k 2).tail,
        (M.reverse ++ 2 :: List.replicate k 2).headD 0 :: [3]⟩ := rfl
  have h4 := back_run M.reverse hMr (List.replicate k 2) [3]
  rw [hsteps, iterStep_add, iterStep_succ, h1, Option.bind_some, iterStep_zero, Option.bind_some,
    iterStep_add, h2, Option.bind_some, iterStep_add, iterStep_succ, h3, Option.bind_some,
    iterStep_zero, Option.bind_some, h4]
  simp only [List.reverse_reverse, hM, Option.some.injEq, TMConf.mk.injEq, true_and]
  refine ⟨by simp [List.replicate_succ], ?_⟩
  rw [show k + j + 1 - (k + 1) = j by omega, List.replicate_succ', List.append_assoc]

#print axioms tm_round

/-- After `k` rounds, `k ≤ n`: `X^k 1^(n-k) Y^k`, head on the first one, state `mark`. -/
theorem tm_rounds (n k : ℕ) (hk : k ≤ n) :
    iterStep tmStep (k * (2 * n + 1)) (tmStart n) =
      some ⟨.mark, List.replicate k 2, List.replicate (n - k) 1 ++ List.replicate k 3⟩ := by
  induction k with
  | zero => simp [iterStep, tmStart]
  | succ k ih =>
    rw [Nat.succ_mul, iterStep_add, ih (by omega), Option.bind_some, tm_round n k (by omega)]

#print axioms tm_rounds

/-- **The tape machine doubles `n` in exactly `2(n + 1)^2` steps, for `n ≥ 1`.** After that many
steps it is in state `halt` and stops; the head sits on the first of `2n` ones, with only blanks
to their right and to the left of the head. -/
theorem tape_machine_doubles_in_two_n_plus_one_squared_steps (n : ℕ) (hn : 1 ≤ n) :
    ∃ c : TMConf, iterStep tmStep (2 * (n + 1) ^ 2) (tmStart n) = some c ∧
      tmStep c = none ∧ c.q = .halt ∧ (∀ x ∈ c.left, x = 0) ∧
      ∃ rest : List ℕ, c.right = List.replicate (2 * n) 1 ++ rest ∧ ∀ x ∈ rest, x = 0 := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  set xs := List.replicate m 1 ++ 1 :: List.replicate (m + 1) 2 with hxs
  have hxv : ∀ x ∈ xs, x = 1 ∨ x = 2 := by
    intro x hx
    simp only [hxs, List.mem_append, List.mem_cons, List.mem_replicate] at hx
    omega
  have hlen : xs.length = 2 * (m + 1) := by simp [hxs]; omega
  have hsteps : 2 * (m + 1 + 1) ^ 2 =
      (m + 1) * (2 * (m + 1) + 1) + (1 + (m + (1 + (xs.length + 1)))) := by
    rw [hlen]; ring
  have h1 : tmStep ⟨.mark, List.replicate (m + 1) 2,
        List.replicate (m + 1 - (m + 1)) 1 ++ List.replicate (m + 1) 3⟩ =
      some ⟨.fix, 1 :: List.replicate (m + 1) 2, List.replicate m 3 ++ []⟩ := by
    rw [Nat.sub_self, List.replicate_succ, List.append_nil]
    rfl
  have h2 := fix_run m (1 :: List.replicate (m + 1) 2) []
  have h3 : tmStep ⟨.fix, List.replicate m 1 ++ 1 :: List.replicate (m + 1) 2, []⟩ =
      some ⟨.home, xs.tail, xs.headD 0 :: [0]⟩ := rfl
  have h4 := home_run xs hxv [] [0]
  simp only [List.append_nil] at h4
  refine ⟨⟨.halt, [0], List.replicate xs.length 1 ++ [0]⟩, ?_, ?_, rfl, ?_, ?_⟩
  · rw [hsteps, iterStep_add, tm_rounds _ _ le_rfl, Option.bind_some, iterStep_add, iterStep_succ,
      h1, Option.bind_some, iterStep_zero, Option.bind_some, iterStep_add, h2, Option.bind_some,
      iterStep_add, iterStep_succ, h3, Option.bind_some, iterStep_zero, Option.bind_some,
      iterStep_add, h4, Option.bind_some, iterStep_succ]
    rfl
  · simp only [tmStep, rule_halt]
  · simp
  · exact ⟨[0], by rw [hlen], by simp⟩

/-! ### The card's counter machine -/

/-- Counter-machine instructions: add one to a box, take one from a box, jump to line `t`
if a box is empty, and halt. -/
inductive Instr
  | inc (i : ℕ)
  | dec (i : ℕ)
  | jz (i t : ℕ)
  | halt

/-- A counter machine's configuration: the line number and the contents of the boxes. -/
structure CMConf where
  pc : ℕ
  reg : ℕ → ℕ

/-- One step of a counter-machine program. -/
def cmStep (prog : List Instr) (c : CMConf) : Option CMConf :=
  match prog[c.pc]? with
  | some (.inc i) => some ⟨c.pc + 1, Function.update c.reg i (c.reg i + 1)⟩
  | some (.dec i) => some ⟨c.pc + 1, Function.update c.reg i (c.reg i - 1)⟩
  | some (.jz i t) => some ⟨if c.reg i = 0 then t else c.pc + 1, c.reg⟩
  | some .halt => none
  | none => none

/-- The card's doubling program, with boxes `a` = 0, `b` = 1, `z` = 2:
0: if a is empty, jump to 5; 1: take one from a; 2: add one to b; 3: add one to b;
4: if z is empty, jump to 0; 5: halt. -/
def double : List Instr := [.jz 0 5, .dec 0, .inc 1, .inc 1, .jz 2 0, .halt]

/-- The start: line 0, `n` in box `a`, 0 in boxes `b` and `z`. -/
def cmStart (n : ℕ) : CMConf := ⟨0, fun i => if i = 0 then n else 0⟩

/-- **The counter machine doubles `n` in exactly `5n + 1` steps.** After that many steps it is on
the `halt` line and stops, with `2n` in box `b`. -/
theorem counter_machine_doubles_in_five_n_plus_one_steps (n : ℕ) :
    ∃ c : CMConf, iterStep (cmStep double) (5 * n + 1) (cmStart n) = some c ∧
      cmStep double c = none ∧ c.pc = 5 ∧ c.reg 1 = 2 * n := by
  have key : ∀ m (r : ℕ → ℕ), r 0 = m → r 2 = 0 →
      ∃ c : CMConf, iterStep (cmStep double) (5 * m + 1) ⟨0, r⟩ = some c ∧
        cmStep double c = none ∧ c.pc = 5 ∧ c.reg 1 = r 1 + 2 * m := by
    intro m
    induction m with
    | zero =>
      intro r h0 _
      refine ⟨⟨5, r⟩, ?_, rfl, rfl, by simp⟩
      simp [iterStep, cmStep, double, h0]
    | succ m ih =>
      intro r h0 h2
      set r' := Function.update (Function.update (Function.update r 0 (r 0 - 1)) 1
        (Function.update r 0 (r 0 - 1) 1 + 1)) 1
        (Function.update (Function.update r 0 (r 0 - 1)) 1
          (Function.update r 0 (r 0 - 1) 1 + 1) 1 + 1) with hr'
      have r0 : r' 0 = m := by simp [hr', h0]
      have r1 : r' 1 = r 1 + 2 := by simp [hr']
      have r2 : r' 2 = 0 := by simp [hr', h2]
      have h5 : iterStep (cmStep double) 5 ⟨0, r⟩ = some ⟨0, r'⟩ := by
        simp [iterStep, cmStep, double, h0, hr', h2]
      obtain ⟨c, hc, hstop, hpc, hreg⟩ := ih r' r0 r2
      refine ⟨c, ?_, hstop, hpc, ?_⟩
      · rw [show 5 * (m + 1) + 1 = 5 + (5 * m + 1) by ring, iterStep_add, h5, Option.bind_some, hc]
      · rw [hreg, r1]; ring
  obtain ⟨c, hc, hstop, hpc, hreg⟩ := key n (cmStart n).reg (by simp [cmStart]) (by simp [cmStart])
  exact ⟨c, hc, hstop, hpc, by rw [hreg]; simp [cmStart]⟩

/-! ### The recursive equations, and the card's worked numbers -/

/-- The card's recursive equations: `d(0) = 0` and `d(S(x)) = S(S(d(x)))`. -/
def d : ℕ → ℕ
  | 0 => 0
  | x + 1 => d x + 2

-- The doubled recipe from the equations: 400 g flour, 600 ml milk, 4 eggs, 50 g sugar.
example : d 200 = 400 ∧ d 300 = 600 ∧ d 2 = 4 ∧ d 25 = 50 := by decide +kernel

-- The eggs on the tape machine: it halts after exactly 18 steps.
example : ((iterStep tmStep 18 (tmStart 2)).map TMConf.q = some .halt) ∧
    ((iterStep tmStep 18 (tmStart 2)).bind tmStep).isNone = true := by decide

-- The eggs on the counter machine: 5 × 2 + 1 = 11 steps, ending with 4 in box b.
example : ((iterStep (cmStep double) 11 (cmStart 2)).map (fun c => (c.pc, c.reg 1)) = some (5, 4)) ∧
    ((iterStep (cmStep double) 11 (cmStart 2)).bind (cmStep double)).isNone = true := by decide

-- Tape-machine steps: 18 for the eggs, 80,802 for the flour, 181,202 for the milk, 1,352 for the sugar.
example : 2 * (2 + 1) ^ 2 = 18 ∧ 2 * (200 + 1) ^ 2 = 80802 ∧
    2 * (300 + 1) ^ 2 = 181202 ∧ 2 * (25 + 1) ^ 2 = 1352 := by norm_num

-- Counter-machine steps: 11, 1,001, 1,501 and 126.
example : 5 * 2 + 1 = 11 ∧ 5 * 200 + 1 = 1001 ∧ 5 * 300 + 1 = 1501 ∧ 5 * 25 + 1 = 126 := by norm_num

-- Two numbers at the start: tape `11` in base 4 is r = 1 + 1 × 4 = 5, and ℓ = 0.
example : Nat.ofDigits 4 [1, 1] = 5 ∧ Nat.ofDigits 4 ([] : List ℕ) = 0 := by norm_num [Nat.ofDigits]

-- Two numbers after step 1: write X (2) and move right gives ℓ = 2, r = 1.
example : numWriteMove 4 0 5 2 .R = (2, 1) := by decide

#print axioms two_number_tape_simulation
#print axioms tape_machine_doubles_in_two_n_plus_one_squared_steps
#print axioms counter_machine_doubles_in_five_n_plus_one_steps

end ChurchTuring
