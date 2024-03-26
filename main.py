import mysql.connector
from faker import Faker
import random

fake = Faker()

def connect_db():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="!yevhen!",
        database="hiking"
    )
def insert_users(cursor, n=200000):
    for _ in range(n):
        cursor.execute(
            "INSERT INTO users (name, email, password, profile) VALUES (%s, %s, %s, %s)",
            (fake.name(), fake.unique.email(), fake.password(length=12), random.choice(['noob', 'regular', 'pro']))
        )

def insert_locations(cursor, n=200000):
    for _ in range(n):
        cursor.execute(
            "INSERT INTO locations (name, country, region, coordinates) VALUES (%s, %s, %s, ST_GeomFromText(%s))",
            (fake.city(), fake.country(), fake.state(), f'POINT({fake.longitude()} {fake.latitude()})')
        )

def insert_difficulty(cursor):
    difficulties = [('Easy', 'Suitable for beginners'), ('Medium', 'Moderate difficulty'), ('Hard', 'Challenging for experienced hikers')]
    for name, description in difficulties:
        cursor.execute(
            "INSERT INTO difficulty (name, description) VALUES (%s, %s)",
            (name, description)
        )

def insert_trails(cursor, n=200000):
    cursor.execute("SELECT location_id FROM locations")
    location_ids = [loc[0] for loc in cursor.fetchall()]
    for _ in range(n):
        cursor.execute(
            "INSERT INTO trails (name, length, elevation, description, image_url, location_id) VALUES (%s, %s, %s, %s, %s, %s)",
            (fake.text(max_nb_chars=20), round(random.uniform(0.5, 50.0), 2), random.randint(100, 3000),
             fake.text(max_nb_chars=200), fake.image_url(), random.choice(location_ids))
        )

def insert_trail_difficulty(cursor):
    cursor.execute("SELECT trail_id FROM trails")
    trail_ids = [trail[0] for trail in cursor.fetchall()]
    cursor.execute("SELECT difficulty_id FROM difficulty")
    difficulty_ids = [difficulty[0] for difficulty in cursor.fetchall()]
    for trail_id in trail_ids:
        cursor.execute(
            "INSERT INTO trail_difficulty (trail_id, difficulty_id) VALUES (%s, %s)",
            (trail_id, random.choice(difficulty_ids))
        )

def insert_ratings_reviews(cursor, n=200000):
    cursor.execute("SELECT user_id FROM users")
    user_ids = [user[0] for user in cursor.fetchall()]
    cursor.execute("SELECT trail_id FROM trails")
    trail_ids = [trail[0] for trail in cursor.fetchall()]
    for _ in range(n):
        user_id = random.choice(user_ids)
        trail_id = random.choice(trail_ids)
        cursor.execute(
            "INSERT INTO ratings (user_id, trail_id, score) VALUES (%s, %s, %s)",
            (user_id, trail_id, random.randint(1, 5))
        )
        cursor.execute(
            "INSERT INTO reviews (user_id, trail_id, title, content, review_date) VALUES (%s, %s, %s, %s, %s)",
            (user_id, trail_id, fake.text(max_nb_chars=50), fake.text(max_nb_chars=200), fake.date_between(start_date='-3y', end_date='today'))
        )

def main():
    db = connect_db()
    cursor = db.cursor()
    insert_users(cursor)
    insert_locations(cursor)
    insert_difficulty(cursor)
    db.commit()

    insert_trails(cursor)
    insert_trail_difficulty(cursor)
    insert_ratings_reviews(cursor)
    db.commit()

    cursor.close()
    db.close()
    print("Data generation completed.")

if __name__ == "__main__":
    main()