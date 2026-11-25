-- Polyhedra and Euler's formula: from V − E + F = 2, every ball of pentagons and hexagons meeting three at a corner has exactly 12 pentagons, only five (p, q) pairs allow a regular solid (giving the five Platonic tuples for V, E, F), the same five pairs come from corner angles under 360°, and Descartes's total corner gap equals (V − E + F) × 360° = 720°.
import Mathlib.Tactic

/-- Step 2: the twelve pentagons are forced. Take any polyhedron of P pentagons and H hexagons
meeting three at every corner and two along every edge, with Euler count V − E + F = 2.
Then F = P + H, 2E = 5P + 6H, 3V = 5P + 6H, and the hexagons cancel, forcing P = 12. -/
theorem twelve_pentagons_forced {P H V E F : ℕ}
    (hF : F = P + H) (hE : 2 * E = 5 * P + 6 * H) (hV : 3 * V = 5 * P + 6 * H)
    (hEuler : (V : ℤ) - E + F = 2) :
    P = 12 := by
  omega

/-- Step 3 (algebraic core): for whole numbers p ≥ 3 and q ≥ 3, (p − 2)(q − 2) < 4 holds
for exactly five pairs: (3, 3), (4, 3), (3, 4), (5, 3), and (3, 5). -/
theorem five_regular_pairs {p q : ℕ} (hp : 3 ≤ p) (hq : 3 ≤ q) :
    (p - 2) * (q - 2) < 4 ↔
      (p, q) = (3, 3) ∨ (p, q) = (4, 3) ∨ (p, q) = (3, 4) ∨
        (p, q) = (5, 3) ∨ (p, q) = (3, 5) := by
  constructor
  · intro h
    have hp1 : 1 ≤ p - 2 := by omega
    have hq1 : 1 ≤ q - 2 := by omega
    have hp5 : p ≤ 5 := by
      have : p - 2 ≤ 3 := by nlinarith
      omega
    have hq5 : q ≤ 5 := by
      have : q - 2 ≤ 3 := by nlinarith
      omega
    interval_cases p <;> interval_cases q <;> simp_all
  · rintro (h | h | h | h | h) <;> cases h <;> decide

/-- Step 3 (Euler's count): if a regular solid has p ≥ 3 sides per face, q ≥ 3 faces per corner,
E > 0 edges, pF = 2E, qV = 2E, and V − E + F = 2, then (p, q, V, E, F) is one of the five
Platonic solids: tetrahedron, cube, octahedron, dodecahedron, or icosahedron. -/
theorem five_regular_polyhedra {p q V E F : ℕ} (hp : 3 ≤ p) (hq : 3 ≤ q) (hEpos : 0 < E)
    (hF : p * F = 2 * E) (hV : q * V = 2 * E) (hEuler : (V : ℤ) - E + F = 2) :
    (p, q, V, E, F) = (3, 3, 4, 6, 4) ∨
      (p, q, V, E, F) = (4, 3, 8, 12, 6) ∨
      (p, q, V, E, F) = (3, 4, 6, 12, 8) ∨
      (p, q, V, E, F) = (5, 3, 20, 30, 12) ∨
      (p, q, V, E, F) = (3, 5, 12, 30, 20) := by
  have h1 : (p : ℤ) * q * (V - E + F) = 2 * p * q := by rw [hEuler]; ring
  have h2 : (2 * p + 2 * q - p * q : ℤ) * E = 2 * p * q := by
    have hFi : (p : ℤ) * F = 2 * E := by exact_mod_cast hF
    have hVi : (q : ℤ) * V = 2 * E := by exact_mod_cast hV
    nlinarith
  have hpos : (0 : ℤ) < 2 * p + 2 * q - p * q := by nlinarith
  have hlt : (p - 2) * (q - 2) < 4 := by
    have : ((p - 2 : ℕ) : ℤ) * ((q - 2 : ℕ) : ℤ) < 4 := by
      have hp' : ((p - 2 : ℕ) : ℤ) = (p : ℤ) - 2 := by omega
      have hq' : ((q - 2 : ℕ) : ℤ) = (q : ℤ) - 2 := by omega
      rw [hp', hq']; nlinarith
    exact_mod_cast this
  rcases (five_regular_pairs hp hq).1 hlt with h | h | h | h | h
  · rcases Prod.mk.inj h with ⟨rfl, rfl⟩; left; simp only [Prod.mk.injEq, true_and]; exact ⟨by omega, by omega, by omega⟩
  · rcases Prod.mk.inj h with ⟨rfl, rfl⟩; right; left; simp only [Prod.mk.injEq, true_and]; exact ⟨by omega, by omega, by omega⟩
  · rcases Prod.mk.inj h with ⟨rfl, rfl⟩; right; right; left; simp only [Prod.mk.injEq, true_and]; exact ⟨by omega, by omega, by omega⟩
  · rcases Prod.mk.inj h with ⟨rfl, rfl⟩; right; right; right; left; simp only [Prod.mk.injEq, true_and]; exact ⟨by omega, by omega, by omega⟩
  · rcases Prod.mk.inj h with ⟨rfl, rfl⟩; right; right; right; right; simp only [Prod.mk.injEq, true_and]; exact ⟨by omega, by omega, by omega⟩

/-- Step 4 (corner angles): q regular p-sided faces meet at less than 360° if and only if
(p − 2)(q − 2) < 4, yielding the same five pairs with no edge counted. -/
theorem corner_angle_condition {p q : ℕ} (hp : 3 ≤ p) (hq : 3 ≤ q) :
    (q : ℚ) * (180 * ((p : ℚ) - 2) / p) < 360 ↔ (p - 2) * (q - 2) < 4 := by
  have hp0 : (0 : ℚ) < p := by positivity
  rw [mul_div_assoc', div_lt_iff₀ hp0]
  have hp' : ((p - 2 : ℕ) : ℚ) = (p : ℚ) - 2 := by
    have : 2 ≤ p := by omega
    exact Nat.cast_sub this
  have hq' : ((q - 2 : ℕ) : ℚ) = (q : ℚ) - 2 := by
    have : 2 ≤ q := by omega
    exact Nat.cast_sub this
  constructor
  · intro h
    have : ((p - 2 : ℕ) : ℚ) * ((q - 2 : ℕ) : ℚ) < 4 := by rw [hp', hq']; nlinarith
    exact_mod_cast this
  · intro h
    have : ((p - 2 : ℕ) : ℚ) * ((q - 2 : ℕ) : ℚ) < 4 := by exact_mod_cast h
    rw [hp', hq'] at this
    nlinarith

/-- Step 4 (Descartes's total gap): every face's interior angles sum to (sides − 2) × 180°,
and the sides of all F faces total 2E, so all face angles total (2E − 2F) × 180°. Subtracting
from V × 360° leaves (V − E + F) × 360°, which is 720° whenever V − E + F = 2. -/
theorem descartes_total_gap (V E F : ℤ) :
    V * 360 - (2 * E - 2 * F) * 180 = (V - E + F) * 360 := by
  ring

-- The 32-panel football: 12 pentagons, 20 hexagons -> 180 sides, E = 90, V = 60, V − E + F = 2.
example : 5 * 12 + 6 * 20 = 180 ∧ 180 / 2 = 90 ∧ 180 / 3 = 60 ∧ (60 : ℤ) - 90 + 32 = 2 := by
  decide
-- One corner of the football: 108° + 120° + 120° = 348°, gap 12°, 60 corners give 720°.
example : (180 * (5 - 2) : ℚ) / 5 = 108 ∧ (180 * (6 - 2) : ℚ) / 6 = 120 := by norm_num
example : 360 - (108 + 120 + 120) = 12 ∧ 60 * 12 = 720 ∧ 720 / (5 * 12) = 12 := by decide
-- Broken cases from When it holds and What breaks if you drop a piece.
example : (60 : ℤ) - 180 + 32 = -88 ∧ (40 : ℤ) - 60 + 20 = 0 := by decide
example : (8 : ℤ) - 12 + 5 = 1 ∧ (16 : ℤ) - 24 + 12 = 4 ∧ (16 : ℤ) - 32 + 16 = 0 := by decide
example : (16 : ℤ) - 24 + 11 = 3 ∧ (12 : ℤ) - 30 + 12 = -6 := by decide

#print axioms twelve_pentagons_forced
#print axioms five_regular_pairs
#print axioms five_regular_polyhedra
#print axioms corner_angle_condition
#print axioms descartes_total_gap
