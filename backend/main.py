from fastapi import FastAPI, HTTPException, Header
from pydantic import BaseModel
import os
from security import license_manager

app = FastAPI(title="Video Tuyên Truyền Lai Hòa API")

class VideoRequest(BaseModel):
    topic: str
    duration: int = 60

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Video Tuyên Truyền Lai Hòa API is running"}

@app.post("/generate-video")
def generate_video(request: VideoRequest, x_license_key: str = Header(...)):
    if not license_manager.verify_license(x_license_key):
        raise HTTPException(status_code=403, detail="Invalid or expired license key")
        
    # TODO: Integrate Gemini to generate script
    # TODO: Integrate Edge-TTS to generate audio
    # TODO: Integrate FFmpeg to combine audio/video
    
    return {"status": "success", "message": f"Video about {request.topic} generated successfully (Mock)"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
