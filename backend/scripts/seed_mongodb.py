from models.database_models import Base, District
import database

DISTRICTS_DATA = [
    {"name": "Colombo", "province": "Western"},
    {"name": "Gampaha", "province": "Western"},
    {"name": "Kalutara", "province": "Western"},
    {"name": "Kandy", "province": "Central"},
    {"name": "Matale", "province": "Central"},
    {"name": "Nuwara Eliya", "province": "Central"},
    {"name": "Galle", "province": "Southern"},
    {"name": "Matara", "province": "Southern"},
    {"name": "Hambantota", "province": "Southern"},
    {"name": "Badulla", "province": "Uva"},
    {"name": "Monaragala", "province": "Uva"},
    {"name": "Kegalle", "province": "Sabaragamuwa"},
    {"name": "Ratnapura", "province": "Sabaragamuwa"},
    {"name": "Anuradhapura", "province": "North Central"},
    {"name": "Polonnaruwa", "province": "North Central"},
    {"name": "Kurunegala", "province": "North Western"},
    {"name": "Puttalam", "province": "North Western"},
    {"name": "Jaffna", "province": "Northern"},
    {"name": "Kilinochchi", "province": "Northern"},
    {"name": "Mannar", "province": "Northern"},
    {"name": "Mullaitivu", "province": "Northern"},
    {"name": "Vavuniya", "province": "Northern"},
    {"name": "Trincomalee", "province": "Eastern"},
    {"name": "Batticaloa", "province": "Eastern"},
    {"name": "Ampara", "province": "Eastern"}
]

def seed_db():
    db = database.SessionLocal()
    try:
        existing_districts = db.query(District).count()
        if existing_districts == 0:
            print("Seeding districts...")
            for district_data in DISTRICTS_DATA:
                db_district = District(name=district_data["name"], province=district_data["province"])
                db.add(db_district)
            db.commit()
            print("Districts seeded successfully!")
        else:
            print(f"Database already contains {existing_districts} districts. Skipping seed.")
    except Exception as e:
        print(f"Error seeding database: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    import database
    Base.metadata.create_all(bind=database.engine)
    seed_db()
