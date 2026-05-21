import os
from typing import Dict, Any

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    HAS_FIREBASE = True
except ImportError:
    HAS_FIREBASE = False

class FirebaseService:
    def __init__(self):
        # Path to the service account key
        key_path = os.path.join(os.path.dirname(__file__), "..", "firebase_service_account.json")
        
        if HAS_FIREBASE and os.path.exists(key_path):
            try:
                cred = credentials.Certificate(key_path)
                # Prevent double initialization if service is re-instantiated
                if not firebase_admin._apps:
                    firebase_admin.initialize_app(cred)
                self.db = firestore.client()
                self.initialized = True
            except Exception as e:
                print(f"Error initializing Firebase: {e}")
                self.db = None
                self.initialized = False
        else:
            self.db = None
            self.initialized = False
            if not HAS_FIREBASE:
                print("Note: firebase-admin package is not installed. Running in mock mode.")
            else:
                print(f"Warning: {key_path} not found. Firebase not initialized.")

    async def log_trade(self, trade_data: Dict[str, Any]):
        if not self.initialized:
            print("Mock: Logged trade to console ->", trade_data)
            return
            
        try:
            self.db.collection("trades").document(trade_data["trade_id"]).set(trade_data)
        except Exception as e:
            print(f"Error logging trade: {e}")

    async def save_portfolio_snapshot(self, snapshot_data: Dict[str, Any]):
        if not self.initialized:
            print("Mock: Saved snapshot to console ->", snapshot_data)
            return
            
        try:
            self.db.collection("portfolios").document(snapshot_data["snapshot_id"]).set(snapshot_data)
        except Exception as e:
            print(f"Error saving snapshot: {e}")
