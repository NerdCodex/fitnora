import sqlite3
import random
import time
from datetime import datetime, timedelta

# Connect to database
db_path = "1_workout.db"
conn = sqlite3.connect(db_path)
cur = conn.cursor()

# Enable foreign keys
cur.execute("PRAGMA foreign_keys = ON")

# Start date (60 days ago)
now = datetime.now()
start_date = now - timedelta(days=60)

def ms(dt):
    return int(dt.timestamp() * 1000)

# ================= BODY MEASUREMENTS =================
# Start weight 85kg, reducing down to ~80kg over 60 days
weight = 85.0
body_fat = 24.0 # start at 24%
for i in range(60):
    dt = start_date + timedelta(days=i, hours=8) # morning measurement
    weight += random.uniform(-0.15, 0.05) # slight downward trend
    body_fat += random.uniform(-0.08, 0.02) # downward trend
    
    cur.execute('''
        INSERT INTO body_measurement (weight, height, body_fat, chest, waist, hips, measured_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', (round(weight, 1), 175.0, round(body_fat, 1), 100.0, 90.0, 100.0, ms(dt)))

# ================= EXERCISES (No Cardio) =================
exercises = [
    ("Bench Press", "Barbell", "reps"),
    ("Squat", "Barbell", "reps"),
    ("Deadlift", "Barbell", "reps"),
    ("Pull Up", "None", "reps"),
    ("Overhead Press", "Dumbbell", "reps"),
    ("Bicep Curl", "Dumbbell", "reps"),
    ("Tricep Extension", "Machine", "reps")
]

ex_ids = []
for ex in exercises:
    cur.execute('''
        INSERT INTO exercise (exercise_name, exercise_equipment, exercise_type, created_at)
        VALUES (?, ?, ?, ?)
    ''', (ex[0], ex[1], ex[2], ms(now)))
    ex_ids.append(cur.lastrowid)

# ================= ROUTINES =================
cur.execute('''
    INSERT INTO routine (routine_name, created_at) VALUES (?, ?)
''', ("Push Day", ms(now)))
routine_push_id = cur.lastrowid

cur.execute('''
    INSERT INTO routine (routine_name, created_at) VALUES (?, ?)
''', ("Pull Day", ms(now)))
routine_pull_id = cur.lastrowid

cur.execute('''
    INSERT INTO routine (routine_name, created_at) VALUES (?, ?)
''', ("Leg Day", ms(now)))
routine_leg_id = cur.lastrowid

# Push exercises: Bench, OHP, Tricep
for idx, ex_id in enumerate([ex_ids[0], ex_ids[4], ex_ids[6]]):
    cur.execute("INSERT INTO routine_exercise (routine_id, exercise_id, exercise_order) VALUES (?, ?, ?)", (routine_push_id, ex_id, idx+1))

# Pull exercises: Pull up, Bicep
for idx, ex_id in enumerate([ex_ids[3], ex_ids[5]]):
    cur.execute("INSERT INTO routine_exercise (routine_id, exercise_id, exercise_order) VALUES (?, ?, ?)", (routine_pull_id, ex_id, idx+1))

# Leg exercises: Squat, Deadlift
for idx, ex_id in enumerate([ex_ids[1], ex_ids[2]]):
    cur.execute("INSERT INTO routine_exercise (routine_id, exercise_id, exercise_order) VALUES (?, ?, ?)", (routine_leg_id, ex_id, idx+1))


# ================= WORKOUT SESSIONS (4 days a week) =================
routines = [routine_push_id, routine_pull_id, routine_leg_id]
routine_exs = {
    routine_push_id: [ex_ids[0], ex_ids[4], ex_ids[6]],
    routine_pull_id: [ex_ids[3], ex_ids[5]],
    routine_leg_id:  [ex_ids[1], ex_ids[2]]
}

current_weights = {
    ex_ids[0]: 50, # Bench
    ex_ids[1]: 60, # Squat
    ex_ids[2]: 70, # Deadlift
    ex_ids[3]: 0,  # Pull Up
    ex_ids[4]: 20, # OHP
    ex_ids[5]: 15, # Bicep
    ex_ids[6]: 20  # Tricep
}

for i in range(60):
    if i % 7 in [0, 1, 3, 4]:
        dt = start_date + timedelta(days=i, hours=17) # Evening workout
        end_dt = dt + timedelta(hours=1.5)
        r_id = routines[(i % 7) % 3]
        
        cur.execute("INSERT INTO workout_session (routine_id, started_at, completed_at) VALUES (?, ?, ?)", (r_id, ms(dt), ms(end_dt)))
        session_id = cur.lastrowid
        
        for idx, ex_id in enumerate(routine_exs[r_id]):
            cur.execute("INSERT INTO session_exercise (session_id, exercise_id, exercise_order) VALUES (?, ?, ?)", (session_id, ex_id, idx+1))
            se_id = cur.lastrowid
            
            if random.random() > 0.8:
                current_weights[ex_id] += 2.5
                
            for set_num in range(3):
                weight = current_weights[ex_id]
                reps = random.randint(8, 12)
                cur.execute('''
                    INSERT INTO session_set (session_exercise_id, set_order, weight, value, is_completed)
                    VALUES (?, ?, ?, ?, 1)
                ''', (se_id, set_num+1, weight, reps))


# ================= FOOD ITEMS (Including South Indian) =================
foods = {
    "Idli": (39, 1.2, 8, 0.1, "1 piece (30g)"),
    "Dosa (Plain)": (133, 2.7, 20.4, 4.3, "1 medium (80g)"),
    "Sambar": (139, 5, 20, 4.5, "1 cup (240g)"),
    "Upma": (192, 4.2, 29.5, 6, "1 cup (150g)"),
    "White Rice (Cooked)": (130, 2.7, 28, 0.3, "100g"),
    "Chicken Curry (South Indian Style)": (180, 16, 5, 10, "100g"),
    "Fish Fry": (220, 20, 2, 14, "100g"),
    "Curd / Plain Yogurt": (98, 3.5, 4.7, 4.3, "100g"),
    "Whey Protein": (120, 24, 3, 1.5, "1 scoop"),
    "Eggs (Boiled)": (155, 13, 1.1, 11, "100g"),
    "Peanut Chutney": (120, 4, 6, 9, "2 tbsp (30g)")
}

food_ids = {}
for name, f in foods.items():
    cur.execute('''
        INSERT INTO food_item (food_name, calories, protein, carbs, fat, serving_size, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', (name, f[0], f[1], f[2], f[3], f[4], ms(now)))
    food_ids[name] = cur.lastrowid

# ================= MEAL LOGS =================
for i in range(60):
    dt = start_date + timedelta(days=i)
    
    # BREAKFAST
    b_dt = dt + timedelta(hours=8)
    if i % 2 == 0:
        # Idli + Sambar + Chutney + Eggs
        cur.execute("INSERT INTO meal_log (food_id, meal_type, servings, logged_at) VALUES (?, 'Breakfast', ?, ?)", (food_ids["Idli"], 4, ms(b_dt)))
        cur.execute("INSERT INTO meal_log (food_id, meal_type, servings, logged_at) VALUES (?, 'Breakfast', ?, ?)", (food_ids["Sambar"], 1, ms(b_dt)))
        cur.execute("INSERT INTO meal_log (food_id, meal_type, servings, logged_at) VALUES (?, 'Breakfast', ?, ?)", (food_ids["Peanut Chutney"], 1, ms(b_dt)))
        cur.execute("INSERT INTO meal_log (food_id, meal_type, servings, logged_at) VALUES (?, 'Breakfast', ?, ?)", (food_ids["Eggs (Boiled)"], 1.5, ms(b_dt)))
    else:
        # Dosa + Sambar + Chutney 
        cur.execute("INSERT INTO meal_log (food_id, meal_type, servings, logged_at) VALUES (?, 'Breakfast', ?, ?)", (food_ids["Dosa (Plain)"], 3, ms(b_dt)))
        cur.execute("INSERT INTO meal_log (food_id, meal_type, servings, logged_at) VALUES (?, 'Breakfast', ?, ?)", (food_ids["Sambar"], 1, ms(b_dt)))
        cur.execute("INSERT INTO meal_log (food_id, meal_type, servings, logged_at) VALUES (?, 'Breakfast', ?, ?)", (food_ids["Peanut Chutney"], 1.5, ms(b_dt)))

    # LUNCH
    l_dt = dt + timedelta(hours=13)
    # White Rice + Chicken Curry + Curd
    cur.execute("INSERT INTO meal_log (food_id, meal_type, servings, logged_at) VALUES (?, 'Lunch', ?, ?)", (food_ids["White Rice (Cooked)"], 2.0, ms(l_dt)))
    cur.execute("INSERT INTO meal_log (food_id, meal_type, servings, logged_at) VALUES (?, 'Lunch', ?, ?)", (food_ids["Chicken Curry (South Indian Style)"], 2.5, ms(l_dt)))
    cur.execute("INSERT INTO meal_log (food_id, meal_type, servings, logged_at) VALUES (?, 'Lunch', ?, ?)", (food_ids["Curd / Plain Yogurt"], 1.0, ms(l_dt)))
    
    # SNACK
    s_dt = dt + timedelta(hours=16)
    cur.execute("INSERT INTO meal_log (food_id, meal_type, servings, logged_at) VALUES (?, 'Snack', ?, ?)", (food_ids["Whey Protein"], 1.5, ms(s_dt)))
    
    # DINNER
    d_dt = dt + timedelta(hours=20)
    if i % 3 == 0:
        # Upma + Chicken Curry
        cur.execute("INSERT INTO meal_log (food_id, meal_type, servings, logged_at) VALUES (?, 'Dinner', ?, ?)", (food_ids["Upma"], 1.5, ms(d_dt)))
        cur.execute("INSERT INTO meal_log (food_id, meal_type, servings, logged_at) VALUES (?, 'Dinner', ?, ?)", (food_ids["Chicken Curry (South Indian Style)"], 1.5, ms(d_dt)))
    else:
        # White Rice + Fish Fry + Curd
        cur.execute("INSERT INTO meal_log (food_id, meal_type, servings, logged_at) VALUES (?, 'Dinner', ?, ?)", (food_ids["White Rice (Cooked)"], 1.0, ms(d_dt)))
        cur.execute("INSERT INTO meal_log (food_id, meal_type, servings, logged_at) VALUES (?, 'Dinner', ?, ?)", (food_ids["Fish Fry"], 2.0, ms(d_dt)))
        cur.execute("INSERT INTO meal_log (food_id, meal_type, servings, logged_at) VALUES (?, 'Dinner', ?, ?)", (food_ids["Curd / Plain Yogurt"], 1.0, ms(d_dt)))

conn.commit()
conn.close()
print("Data generation complete.")
