-- Symplectic steps: for the spring q'' = -q, the leapfrog step keeps a hidden energy exactly and so traps the energy started from (1, 0) between b/2 and 1/2 at every step when 0 < h < 2, while Euler's step multiplies the energy by 1 + h^2 every step.
import Mathlib.Basic.Real.Basic
import Mathlib.Logic.Function.Iterate
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity

noncomputable section

/-- One leapfrog (kick–drift–kick, velocity Verlet) step of size `h` for `q' = v`, `v' = -q`,
on the state `(q, v)`: half kick `v - (h/2) q`, drift the position a whole step at that
velocity, then the second half kick felt at the new position. -/
def leapfrog (h : ℝ) (s : ℝ × ℝ) : ℝ × ℝ :=
  let v₁ := s.2 - h / 2 * s.1
  let q₁ := s.1 + h * v₁
  (q₁, v₁ - h / 2 * q₁)

/-- One Euler step of size `h` for `q' = v`, `v' = -q`: `(q + h v, v - h q)`. -/
def eulerStep (h : ℝ) (s : ℝ × ℝ) : ℝ × ℝ :=
  (s.1 + h * s.2, s.2 - h * s.1)

/-- The energy `E = (q^2 + v^2)/2` of the state `(q, v)`. -/
def energy (s : ℝ × ℝ) : ℝ :=
  (s.1 ^ 2 + s.2 ^ 2) / 2

/-- The hidden energy `Ẽ = (b q^2 + v^2)/2` with `b = 1 - h^2/4`. -/
def hiddenEnergy (h : ℝ) (s : ℝ × ℝ) : ℝ :=
  ((1 - h ^ 2 / 4) * s.1 ^ 2 + s.2 ^ 2) / 2

/-- One leapfrog step keeps the hidden energy. -/
theorem leapfrog_hidden_step (h : ℝ) (s : ℝ × ℝ) :
    hiddenEnergy h (leapfrog h s) = hiddenEnergy h s := by
  simp only [hiddenEnergy, leapfrog]
  ring

/-- One Euler step multiplies the energy by `1 + h^2`. -/
theorem euler_energy_step (h : ℝ) (s : ℝ × ℝ) :
    energy (eulerStep h s) = (1 + h ^ 2) * energy s := by
  simp only [energy, eulerStep]
  ring

/-- At `h = 5/2`, a leapfrog step sends `(c, -3/4 c)` to `(-4 c, 3 c)`. -/
theorem leapfrog_five_halves_stretch (c : ℝ) :
    leapfrog (5 / 2) (c, -3 / 4 * c) = (-4 * c, -3 / 4 * (-4 * c)) := by
  simp only [leapfrog, Prod.mk.injEq]
  constructor <;> ring

/-- Leapfrog keeps the hidden energy over any number of steps. -/
theorem leapfrog_hidden_iterate (h : ℝ) (s : ℝ × ℝ) (n : ℕ) :
    hiddenEnergy h ((leapfrog h)^[n] s) = hiddenEnergy h s := by
  induction n with
  | zero => rfl
  | succ n ih => rw [Function.iterate_succ_apply', leapfrog_hidden_step, ih]

#print axioms leapfrog_hidden_step
#print axioms leapfrog_hidden_iterate
#print axioms euler_energy_step
#print axioms leapfrog_five_halves_stretch

/-- The band: for the frictionless spring `q'' = -q`, run leapfrog with one fixed step size
`h` below the limit 2, starting at `q = 1`, `v = 0`. Then after every number of steps `n`,
however large, the energy stays between `b/2` and `1/2`, where `b = 1 - h^2/4`. -/
theorem leapfrog_energy_stays_in_band (h : ℝ) (hpos : 0 < h) (hlt : h < 2) (n : ℕ) :
    (1 - h ^ 2 / 4) / 2 ≤ energy ((leapfrog h)^[n] (1, 0)) ∧
      energy ((leapfrog h)^[n] (1, 0)) ≤ 1 / 2 := by
  have hid := leapfrog_hidden_iterate h (1, 0) n
  generalize (leapfrog h)^[n] (1, 0) = st at hid ⊢
  obtain ⟨q, v⟩ := st
  simp only [hiddenEnergy, energy] at hid ⊢
  have hb : 0 < 1 - h ^ 2 / 4 := by nlinarith
  have hb1 : 1 - h ^ 2 / 4 ≤ 1 := by nlinarith
  have hq : q ^ 2 ≤ 1 := by nlinarith [sq_nonneg v, sq_nonneg q]
  constructor
  · nlinarith [sq_nonneg v, sq_nonneg q, sq_nonneg h]
  · nlinarith [sq_nonneg v, sq_nonneg q, sq_nonneg h]

/-- Leapfrog keeps the hidden energy `(b q^2 + v^2)/2`, `b = 1 - h^2/4`, exactly: for every
step size `h`, every starting state and every number of steps, it never changes. -/
theorem leapfrog_keeps_hidden_energy (h : ℝ) (s : ℝ × ℝ) (n : ℕ) :
    hiddenEnergy h ((leapfrog h)^[n] s) = hiddenEnergy h s := by
  exact leapfrog_hidden_iterate h s n

/-- Euler's step multiplies the energy by exactly `1 + h^2` each step, so after `n` steps
the energy is `(1 + h^2)^n` times the starting energy. -/
theorem euler_energy_grows_by_one_plus_h_sq (h : ℝ) (s : ℝ × ℝ) (n : ℕ) :
    energy ((eulerStep h)^[n] s) = (1 + h ^ 2) ^ n * energy s := by
  induction n with
  | zero => simp
  | succ n ih => rw [Function.iterate_succ_apply', euler_energy_step, ih]; ring

-- Beyond the limit, h = 5/2: a = 1 - h^2/2 = -17/8, and the larger stretch factor is
-- a - sqrt(a^2 - 1) = -17/8 - 15/8 = -4.
example : (1 : ℚ) - (5 / 2) ^ 2 / 2 = -17 / 8 ∧ (-17 / 8 : ℚ) ^ 2 - 1 = (15 / 8) ^ 2 ∧
    (-17 / 8 : ℚ) - 15 / 8 = -4 := by norm_num

-- At h = 5/2 the start (1, -3/4) lies along that stretch: one step sends it to (-4, 3).
example : leapfrog (5 / 2) (1, -3 / 4) = (-4, 3) := by
  have := leapfrog_five_halves_stretch 1
  norm_num at this ⊢
  exact this

-- At h = 5/2, six steps from (1, -3/4) reach q = 4096, v = -3072.
example : (leapfrog (5 / 2))^[6] (1, -3 / 4) = (4096, -3072) := by
  have key : ∀ k : ℕ, (leapfrog (5 / 2))^[k] (1, -3 / 4) =
      ((-4 : ℝ) ^ k, -3 / 4 * (-4 : ℝ) ^ k) := by
    intro k
    induction k with
    | zero => simp
    | succ k ih =>
      rw [Function.iterate_succ_apply', ih, leapfrog_five_halves_stretch, pow_succ]
      simp only [Prod.mk.injEq]
      constructor <;> ring
  rw [key]
  norm_num

#print axioms leapfrog_energy_stays_in_band
#print axioms leapfrog_keeps_hidden_energy
#print axioms euler_energy_grows_by_one_plus_h_sq

end
