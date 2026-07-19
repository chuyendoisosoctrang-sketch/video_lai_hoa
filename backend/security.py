import ntplib
import time
from datetime import datetime, timedelta
from cryptography.fernet import Fernet
import os

# Anti-Time-Tampering: Check if local time is within acceptable drift of NTP time
def check_time_tampering(max_drift_seconds: int = 300) -> bool:
    try:
        client = ntplib.NTPClient()
        response = client.request('pool.ntp.org', version=3, timeout=3)
        ntp_time = response.tx_time
        local_time = time.time()
        
        drift = abs(ntp_time - local_time)
        return drift > max_drift_seconds
    except Exception as e:
        # If NTP fails, we might block or allow depending on strictness. Let's allow for now but log.
        print(f"NTP check failed: {e}")
        return False

class LicenseManager:
    def __init__(self, secret_key: bytes):
        self.fernet = Fernet(secret_key)
        
    def generate_license(self, days_valid: int = 365) -> str:
        expiry_date = datetime.utcnow() + timedelta(days=days_valid)
        license_data = f"valid_until:{expiry_date.isoformat()}"
        return self.fernet.encrypt(license_data.encode()).decode()
        
    def verify_license(self, license_key: str) -> bool:
        if check_time_tampering():
            print("Time tampering detected! License verification failed.")
            return False
            
        try:
            decrypted = self.fernet.decrypt(license_key.encode()).decode()
            prefix, expiry_str = decrypted.split(':', 1)
            if prefix != "valid_until":
                return False
                
            expiry_date = datetime.fromisoformat(expiry_str)
            if datetime.utcnow() > expiry_date:
                print("License expired!")
                return False
                
            return True
        except Exception as e:
            print(f"Invalid license key: {e}")
            return False

# Setup a default manager for the app
# In production, this key should be securely stored in env vars.
# We generate one here for demonstration if not provided.
LICENSE_SECRET = os.environ.get("LICENSE_SECRET", Fernet.generate_key().decode())
license_manager = LicenseManager(LICENSE_SECRET.encode())
