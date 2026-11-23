-- Lambda calculus: in normal order, plus applied to the Church numerals for m and n rewrites to the numeral for m + n in exactly 6 beta steps, succ applied to n reaches n + 1, and omega rewrites to itself forever.
import Mathlib.Logic.Function.Iterate

/-! Mathlib has no untyped lambda calculus, so this file writes one out, as the card's reducer does.
Bound names are de Bruijn indices: `var k` points to the `k`-th enclosing `λ`, counting from 0.
Substitution below shifts indices as it goes under a `λ`, so it never captures a name. This is
the card's first condition in When it holds, "bound names are renamed before substituting",
built into the representation. -/

namespace LambdaOutline

/-- A term: a variable, a function `λ. M`, or an application `M N`. -/
inductive Term
  | var : ℕ → Term
  | lam : Term → Term
  | app : Term → Term → Term
  deriving DecidableEq, Repr

open Term

/-- Add `d` to every variable index that is at least `c` (the free ones, under `c` binders). -/
def shift (d : ℕ) : ℕ → Term → Term
  | c, var k => if k < c then var k else var (k + d)
  | c, lam t => lam (shift d (c + 1) t)
  | c, app t u => app (shift d c t) (shift d c u)

/-- `substAt j s t`: put `s` in place of variable `j` in `t`, and close the gap left by the
removed binder (indices above `j` drop by one). `s` is shifted as it goes under each `λ`. -/
def substAt (j : ℕ) (s : Term) : Term → Term
  | var k => if k < j then var k else if k = j then shift j 0 s else var (k - 1)
  | lam t => lam (substAt (j + 1) s t)
  | app t u => app (substAt j s t) (substAt j s u)

/-- Beta reduction: `(λ. M) N →β M[0 := N]`. -/
def beta (body arg : Term) : Term := substAt 0 arg body

/-- One beta step in **normal order**: rewrite the leftmost, outermost spot of the shape
`(λ. M) N`. `none` means no spot is left: the term is a normal form. This is the card's `step`
with `order='normal'`. -/
def step : Term → Option Term
  | var _ => none
  | lam t => (step t).map lam
  | app (lam b) a => some (beta b a)
  | app f a =>
      match step f with
      | some f' => some (app f' a)
      | none => (step a).map (app f)

/-- One beta step **arguments first**: rewrite inside the function, then inside the argument,
and only then the outer spot. This is the card's `step` with `order='args'`. -/
def stepArgs : Term → Option Term
  | var _ => none
  | lam t => (stepArgs t).map lam
  | app f a =>
      match stepArgs f with
      | some f' => some (app f' a)
      | none =>
          match stepArgs a with
          | some a' => some (app f a')
          | none =>
              match f with
              | lam b => some (beta b a)
              | _ => none

/-- Take `k` steps with the rule `st`; `none` if a normal form is reached before all `k`. -/
def run (st : Term → Option Term) : ℕ → Term → Option Term
  | 0, t => some t
  | k + 1, t => (st t).bind (run st k)

/-- The Church numeral `n̲ = λf. λx. f (f (⋯ (f x)))`, with `n` copies of `f`.
Under the two binders, `f` is `var 1` and `x` is `var 0`. -/
def num (n : ℕ) : Term := lam (lam ((app (var 1))^[n] (var 0)))

/-- `succ = λn. λf. λx. f (n f x)`. -/
def succ : Term := lam (lam (lam (app (var 1) (app (app (var 2) (var 1)) (var 0)))))

/-- `plus = λm. λn. λf. λx. m f (n f x)`. -/
def plus : Term :=
  lam (lam (lam (lam (app (app (var 3) (var 1)) (app (app (var 2) (var 1)) (var 0))))))

/-- `times = λm. λn. λf. m (n f)`. -/
def times : Term := lam (lam (lam (app (var 2) (app (var 1) (var 0)))))

/-- The bracket moved: `λm. λn. λf. λx. m (n f) x`, which is times, not plus. -/
def badPlus : Term :=
  lam (lam (lam (lam (app (app (var 3) (app (var 2) (var 1))) (var 0)))))

/-- `K = λx. λy. x`. -/
def K : Term := lam (lam (var 1))

/-- `Ω = (λx. x x) (λx. x x)`. -/
def omega : Term := app (lam (app (var 0) (var 0))) (lam (app (var 0) (var 0)))

theorem shift_zero_id (c : ℕ) (t : Term) : shift 0 c t = t := by
  induction t generalizing c with
  | var k => simp [shift]
  | lam t ih => simp [shift, ih]
  | app t u iht ihu => simp [shift, iht, ihu]

theorem shift_iter_body (d c m : ℕ) :
    shift d (c + 1 + 1) ((app (var 1))^[m] (var 0)) = (app (var 1))^[m] (var 0) := by
  induction m with
  | zero => simp [shift]
  | succ m ih => rw [Function.iterate_succ_apply']; simp [shift, ih]

theorem shift_num (d c m : ℕ) : shift d c (num m) = num m := by
  simp only [num, shift, shift_iter_body]

theorem substAt_iter_body (j : ℕ) (s : Term) (m : ℕ) :
    substAt (j + 1 + 1) s ((app (var 1))^[m] (var 0)) = (app (var 1))^[m] (var 0) := by
  induction m with
  | zero => simp [substAt]
  | succ m ih => rw [Function.iterate_succ_apply']; simp [substAt, ih]

theorem substAt_num (j : ℕ) (s : Term) (m : ℕ) : substAt j s (num m) = num m := by
  simp only [num, substAt, substAt_iter_body]

theorem substAt_one_iter (m : ℕ) :
    substAt 1 (var 1) ((app (var 1))^[m] (var 0)) = (app (var 2))^[m] (var 0) := by
  induction m with
  | zero => simp [substAt]
  | succ m ih => rw [Function.iterate_succ_apply', Function.iterate_succ_apply']; simp [substAt, ih, shift]

theorem substAt_zero_iter (a : Term) (m : ℕ) :
    substAt 0 a ((app (var 2))^[m] (var 0)) = (app (var 1))^[m] a := by
  induction m with
  | zero => simp [substAt, shift_zero_id]
  | succ m ih => rw [Function.iterate_succ_apply', Function.iterate_succ_apply']; simp [substAt, ih]

theorem step_app_var_one (x : Term) : step (app (var 1) x) = (step x).map (app (var 1)) := by
  simp [step]

theorem step_iter (m : ℕ) (t : Term) :
    step ((app (var 1))^[m] t) = (step t).map ((app (var 1))^[m]) := by
  induction m with
  | zero => simp
  | succ m ih =>
    rw [Function.iterate_succ_apply', step_app_var_one, ih, Option.map_map]
    congr 1
    funext x
    simp only [Function.comp_apply, Function.iterate_succ_apply']

theorem step_num (m : ℕ) : step (num m) = none := by
  simp [num, step, step_iter]

theorem step_num_app_var (m : ℕ) :
    step (app (num m) (var 1)) = some (lam ((app (var 2))^[m] (var 0))) := by
  simp [num, step, beta, substAt, substAt_one_iter]

#print axioms shift_zero_id
#print axioms shift_iter_body
#print axioms shift_num
#print axioms substAt_iter_body
#print axioms substAt_num
#print axioms substAt_one_iter
#print axioms substAt_zero_iter
#print axioms step_app_var_one
#print axioms step_iter
#print axioms step_num
#print axioms step_num_app_var

/-- **Plus reaches m + n in exactly 6 steps.** For any counts `m` and `n`, normal order rewrites
`plus m̲ n̲` in exactly 6 beta steps to the Church numeral `m + n`, and that numeral is a normal
form: no seventh step applies. (Every one of the 6 steps applies, so no earlier term is a
normal form.) -/
theorem plus_reaches_sum_in_six_steps (m n : ℕ) :
    run step 6 (app (app plus (num m)) (num n)) = some (num (m + n)) ∧
      step (num (m + n)) = none := by
  refine ⟨?_, step_num _⟩
  have h1 : step (app (app plus (num m)) (num n)) =
      some (app (lam (lam (lam (app (app (num m) (var 1)) (app (app (var 2) (var 1)) (var 0))))))
        (num n)) := by
    simp [step, plus, beta, substAt, shift_num]
  have h2 : step (app (lam (lam (lam (app (app (num m) (var 1)) (app (app (var 2) (var 1)) (var 0))))))
        (num n)) =
      some (lam (lam (app (app (num m) (var 1)) (app (app (num n) (var 1)) (var 0))))) := by
    simp [step, beta, substAt, shift_num, substAt_num]
  have h3 : step (lam (lam (app (app (num m) (var 1)) (app (app (num n) (var 1)) (var 0))))) =
      some (lam (lam (app (lam ((app (var 2))^[m] (var 0))) (app (app (num n) (var 1)) (var 0))))) := by
    simp [step, step_num_app_var]
  have h4 : step (lam (lam (app (lam ((app (var 2))^[m] (var 0))) (app (app (num n) (var 1)) (var 0))))) =
      some (lam (lam ((app (var 1))^[m] (app (app (num n) (var 1)) (var 0))))) := by
    simp [step, beta, substAt_zero_iter]
  have h5 : step (lam (lam ((app (var 1))^[m] (app (app (num n) (var 1)) (var 0))))) =
      some (lam (lam ((app (var 1))^[m] (app (lam ((app (var 2))^[n] (var 0))) (var 0))))) := by
    simp [step, step_iter, step_num_app_var]
  have h6 : step (lam (lam ((app (var 1))^[m] (app (lam ((app (var 2))^[n] (var 0))) (var 0))))) =
      some (num (m + n)) := by
    simp [step, step_iter, beta, substAt_zero_iter, num, Function.iterate_add_apply]
  simp [run, h1, h2, h3, h4, h5, h6]

/-- **Succ adds one more f.** For any count `n`, normal order rewrites `succ n̲` to the Church
numeral `n + 1`, and that numeral is a normal form. -/
theorem succ_reaches_next (n : ℕ) :
    ∃ k, run step k (app succ (num n)) = some (num (n + 1)) ∧ step (num (n + 1)) = none := by
  refine ⟨3, ?_, step_num _⟩
  have h1 : step (app succ (num n)) =
      some (lam (lam (app (var 1) (app (app (num n) (var 1)) (var 0))))) := by
    simp [step, succ, beta, substAt, shift_num]
  have h2 : step (lam (lam (app (var 1) (app (app (num n) (var 1)) (var 0))))) =
      some (lam (lam (app (var 1) (app (lam ((app (var 2))^[n] (var 0))) (var 0))))) := by
    simp [step, step_num_app_var]
  have h3 : step (lam (lam (app (var 1) (app (lam ((app (var 2))^[n] (var 0))) (var 0))))) =
      some (num (n + 1)) := by
    simp [step, beta, substAt_zero_iter, num, Function.iterate_succ_apply']
  simp [run, h1, h2, h3]

/-- **Ω has no normal form.** `Ω` rewrites to itself in 1 step, so however many steps normal
order takes, the term is `Ω` again and is never a normal form. -/
theorem omega_never_stops (k : ℕ) : run step k omega = some omega ∧ step omega ≠ none := by
  have h : step omega = some omega := by decide
  refine ⟨?_, by simp [h]⟩
  induction k with
  | zero => rfl
  | succ k ih => simp [run, h, ih]

/-! ### The card's worked numbers -/

-- Worked numbers, by hand: plus two three reaches the numeral 5 in 6 steps, and stops there.
example : run step 6 (app (app plus (num 2)) (num 3)) = some (num 5) := by decide
example : step (num 5) = none := by decide
-- The same term is not yet a normal form after 5 steps.
example : (run step 5 (app (app plus (num 2)) (num 3))).bind step ≠ none := by decide
-- Arguments first also reaches 5 in 6 steps.
example : run stepArgs 6 (app (app plus (num 2)) (num 3)) = some (num 5) := by decide
-- succ two gives three.
example : ∃ k, k ≤ 3 ∧ run step k (app succ (num 2)) = some (num 3) := ⟨3, by decide, by decide⟩
-- Try lines: times two three gives 6 in 7 steps; three fed two gives 8 in 14 steps;
-- plus twenty thirty gives 50 in 6 steps.
example : run step 7 (app (app times (num 2)) (num 3)) = some (num 6) := by decide
example : run step 14 (app (num 3) (num 2)) = some (num 8) := by decide
example : run step 6 (app (app plus (num 20)) (num 30)) = some (num 50) := by decide
-- What breaks: the bracket moved gives 6 on two and three, not 5.
example : ∃ k, run step k (app (app badPlus (num 2)) (num 3)) = some (num 6) :=
  ⟨8, by decide⟩
-- What breaks: (λx. λy. x) y, then fed z, gives y (free variables: y is 0, z is 1).
example : run step 1 (app K (var 0)) = some (lam (var 1)) := by decide
example : run step 1 (app (lam (var 1)) (var 1)) = some (var 0) := by decide
-- What breaks: Ω returns unchanged after 1 step.
example : step omega = some omega := by decide
-- What breaks: on (λx. λy. x) y Ω, normal order answers y in 2 steps. Arguments first
-- reduces K y, then rewrites Ω inside (λy'. y) Ω and gets the same term back: it loops.
example : run step 2 (app (app K (var 0)) omega) = some (var 0) := by decide
example : run stepArgs 1 (app (app K (var 0)) omega) = some (app (lam (var 1)) omega) := by decide
example : stepArgs (app (lam (var 1)) omega) = some (app (lam (var 1)) omega) := by decide

#print axioms plus_reaches_sum_in_six_steps
#print axioms succ_reaches_next
#print axioms omega_never_stops

end LambdaOutline
